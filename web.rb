#! /usr/bin/ruby
require 'sinatra'
set :bind, '0.0.0.0'

require './Splot.rb'

get '/' do
	splot = Splot.new
	content = ""
	for i in 0..10
		if not a = splot.next then break end
		content.concat("<H2>#{a[:title]} by  #{a[:user]}  #{a[:modified]}</H2><P>#{a[:text]}</P>")
	end
	content
end

get '/:name' do

end
