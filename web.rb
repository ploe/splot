#! /usr/bin/ruby
require 'sinatra'
set :bind, '0.0.0.0'

require './Splot.rb'
require './Navi.rb'

#	Keeps homepage URL clean...
get '/' do
	File.new('public/index.html').readlines
end

#	A 'lardon' is a small chunk of functionality within the chorizo system.
get '/:name' do
	begin
		lardon = Kernel.const_get(params[:name].capitalize)
		lardon.new(params).render
	rescue NameError
		status 404
		body '<H1>404 - Not Found</H1>'
	end
end

