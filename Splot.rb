#! /usr/bin/ruby

require 'github/markdown'
require 'uri'

#	The splot interface is the class that sits between, me, memcached and the content. 

class Splot

attr_accessor :article, :user, :dates, :filter
	
def initialize(params)
	if params[:filter] then 
		@filter = params[:filter]
	else 
		@filter = {
			:date => "any", 
			:user => "everybody", 
		} 
	end

	@filter[:page] = params[:page].to_i
	if @filter[:page] == 0 then @filter[:page] = 1 end

	@article = []
	@user = {}
	@dates = {}

	fetch
end

# draws the selected page
def render
	content = ""

	f = File.new("public/blog.html", "r")
	template = f.read
	f.close

	template = render_pageurls(template, count_pages)
	template = render_dateselect(template)
	# Render articles is destroys the article list so should probably be called last
	template = render_articles(template)
end

def render_dateselect(template)
	date_select = ""
	@dates.keys.sort.reverse.each { |date|
		selected = ""
		if date == filter[:date] then
			selected = " selected"
		end
		date_select += "<OPTION value=\"#{date}\"#{selected}>#{@dates[date]}</OPTION>\n"
	}
	template.sub(/<!-- DATE OPTIONS -->/, date_select)
end

def render_articles(template)
	#	Get rid of the articles on previous pages
	if (@filter[:page] - 1) > 0 then
		for i in 0 .. ((@filter[:page] - 1) * 10)
			next_article;
		end
	end

	for i in 0..10
		if not a = next_article then break end

		css = "content"
		if a[:sticky] then css += " sticky" end

		template.sub!(/<!-- CONTENT HERE -->/, "<DIV class=\"#{css}\">#{a[:text]}</DIV><BR><!-- CONTENT HERE -->")
	end
	template
end

def render_pageurls(template, pages)
	filters = ""
	filters = "&filter[user]=#{@filter[:user]}"
	filters += "&filter[date]=#{@filter[:date]}"
	filters = URI.encode(filters)

	if @filter[:page] > 1 then 
		template.gsub!(/<!-- PREV NEXT URLS -->/, "<DIV style=\"float:left\"><A href=\"?page=#{filter[:page] - 1}#{filters}\">Prev</A></DIV><!-- PREV NEXT URLS -->")
	end

	if @filter[:page] < pages then 
		template.gsub!(/<!-- PREV NEXT URLS -->/, "<DIV style=\"float:right\"><A href=\"?page=#{filter[:page] + 1}#{filters}\">Next</A></DIV><!-- PREV NEXT URLS -->")
	end

	template.gsub!(/<!-- PREV NEXT URLS -->/, "<DIV style=\"text-align:center\">Page #{filter[:page]} of #{pages}</DIV>")
end


#	populate pushes the article data in to the cache
def populate
	Dir.foreach("/home") { |u|
		get_articles(u)
	}
end

def user?(u)
	@user[u]
end


private

def count_pages
	pages = 0
	@article.each { |a|
		date = user = true
		if(@filter[:date] != "any" and @filter[:date] != Time.at(a[:modified]).strftime("%Y %m"))
			date = false
		elsif @filter[:user] != "everybody" and @filter[:user] != a[:user]
			user = false
		end

		if(date and user) then pages += 1 end
	}
	pages / 12 + 1
end

#	get pops the next article and renders it - filter the user with the param
def next_article(u=nil)
	if @filter[:user] and  @filter[:user] != "everybody" then u = @filter[:user] end
	
	if u and not user?(u) then return nil end

	a = nil
	while a = @article.pop do
		if (u and u != a[:user]) then next end
		if ( @filter[:date] != "any") and (@filter[:date] != Time.at(a[:modified]).strftime("%Y %m")) then next end
		break
	end

	if not a then return nil end

	f = File.new(a[:filename], "r")
		body = { :text => f.read, :modified => File::mtime(a[:filename]).to_i}
	f.close

	body[:title] = a[:filename].match(/\/home\/.*\/!*(.*)/).captures[0]	#	filthy...
	body[:user] = a[:user]
	body[:sticky] = a[:sticky]
	body[:text] = user_widget(body) + GitHub::Markdown.render_gfm(body[:text])
	body
end

def get_articles(user)
	path = "/home/#{user}/splot/"
    if not Dir.exists?(path) then return nil end

	articles = []
	Dir.foreach(path) { |f|
		p = "#{path}#{f}"
		if readable?(p)
			articles.push({:filename => p, :modified => File::mtime(p).to_i })
		end
	}

	articles
end

#	fetch pulls all the cache data in to splot, if per chance it isn't 
#	there (a lot of hits) we generate the cache for that user

def fetch
	sticky = []
	Dir.foreach("/home") { |u|
		tmp = get_articles(u)
		if not tmp then next end

		tmp.each { |a|
			date_filter(a[:modified])
			a[:user] = u
			
			if a[:filename].match(/\/![^\/]*?$/) then
				a[:sticky] = true
				sticky.push(a)
			else
				@article.push(a)
			end

			@user[u] = true
		}
	}

	sticky.sort! { |x, y| x[:modified] <=> y[:modified] }
	@article.sort! { |x, y|  x[:modified] <=> y[:modified]}

	sticky.each { |s|
		@article.push(s)
	}

end

def readable?(f)
	(File::file?(f) and File::readable?(f))
end
	
def user_widget(a)
	date = Time.at(a[:modified]).strftime("%d-%m-%Y")
	user = "Ploe"
	if a[:user] == "miffy" then user = "Miffy" end
	w = 
"<DIV class=\"user_widget\"> 
<B>#{a[:title]}</B>
<BR>
#{date}
<BR>
<IMG src=\"#{a[:user]}.png\" alt=\"#{a[:user]}\" width=\"200\" height=\"200\" align=\"middle\">
<BR>
#{user}
</DIV>"

	return w
end

def date_filter(t)
	# push date: {'September 2013' => '2013 09'}
	t = Time.at(t)
	@dates[t.strftime("%Y %m")] = t.strftime("%B %Y")
end

end
