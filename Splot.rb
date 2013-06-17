#! /usr/bin/ruby

require 'dalli'
require 'github/markdown'

#	The splot interface is the class that sits between, me, memcached and the content. 

class Splot
	attr_accessor :dc, :article, :user
	
	def initialize
		options = {:namespace => "splot", :compress => true, :expires_in => 7200}
		@dc = Dalli::Client.new('localhost:11211', options)
	
		@article = []
		@user = {}
		fetch

	end

	#	get pops the next article and renders it - filter the user with the param
	def next(u=nil)
		if u and not user?(u) then return nil end
	
		a = nil	
		while a = @article.pop do
			if u and u != a[:user] then next
			else break end
		end
		if not a then return nil end
	
		body = @dc.get(a[:filename])
		if (not body or body[:modified] != a[:modified]) and readable?(a[:filename])
			f = File.new(a[:filename], "r")
			body = { :text => f.read, :modified => File::mtime(a[:filename]).to_i}
			@dc.set("#{a[:filename]}", body)
			f.close
		end

		body[:text] = GitHub::Markdown.render_gfm(body[:text])
		body[:title] = a[:filename].match(/\/home\/.*\/(.*)/).captures[0]	#	filthy...
		body[:user] = a[:user]
		body
	end

	#	populate pushes the article data in to the cache
	def populate
		Dir.foreach("/home") { |u|
			path = "/home/#{u}/splot/"
			if not Dir.exists?(path) then next end

			article = []
			Dir.foreach(path) { |f|
				p = "#{path}#{f}"
				if readable?(p)
					article.push({:filename => p, :modified => File::mtime(p).to_i })
				end
			}
			@dc.set("#{u}-articles", article)
		}
	end

	def user?(u)
		@user[u]
	end


private
	#	fetch pulls all the cache data in to splot
	def fetch
		Dir.foreach("/home") { |u|
			tmp = @dc.get("#{u}-articles") 
			if not tmp then next end
			tmp.each { |a|
				a[:user] = u
				@article.push(a)
				@user[u] = true
			}
		}
		@article.sort! { |x, y|  x[:modified] <=> y[:modified]}
	end

	def readable?(f)
		(File::file?(f) and File::readable?(f))
	end
	
end
# splot = Splot.new()
# splot.populate
# puts splot.user?('myke')
# for i in 0..10
#	puts splot.next
#end

#m if splot.user["myke"] then puts "Yey, you exist." end
#puts splot.next
