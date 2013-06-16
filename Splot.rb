#! /usr/bin/ruby

require 'dalli'

#	The splot interface is the class that sits between, me, memcached and the content. 

class Splot
	attr_accessor :dc, :article
	
	def initialize
		options = {:namespace => "splot", :compress => true, :expires_in => 7200}
		@dc = Dalli::Client.new('localhost:11211', options)
	
		@article = []
		fetch

		user = {}
	end

	# get the next article - might amend this so you can ask for a specific user
	def next
		a = @article.pop
		if not a then return nil end
		body = @dc.get("#{a[:filename]}")
		# chunk of logic here if we haven't pulled anything out of the cache or the timestamps don't match
		if (not body or body[:modified] != a[:modified]) and File::file?(a[:filename]) and File::readable?(a[:filename])
			f = File.new(a[:filename], "r")
			body = { :text => f.read, :modified => File::mtime(a[:filename]).to_i }
			@dc.set("#{a[:filename]}", body)
			f.close
		end
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
				if File::file?(p) and File::readable?(p)
					article.push({:filename => p, :modified => File::mtime(p).to_i })
				end
			}
			@dc.set("#{u}-articles", article)
		}
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
				# @user[u] = true
			}
		}
		@article.sort! { |x, y|  x[:modified] <=> y[:modified]}
	end
	
end

splot = Splot.new()
splot.populate
for i in 0..10
	puts splot.next
end
#m if splot.user["myke"] then puts "Yey, you exist." end
puts splot.next
