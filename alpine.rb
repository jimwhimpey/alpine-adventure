# encoding: utf-8

require 'rubygems'
require 'haml'
require 'sass'
require 'sinatra'
require 'curb'
require 'nokogiri'
require 'maruku'
require 'open-uri'
require 'json'

enable :sessions

configure :development do
  require "sinatra/reloader"
end

# Default is xhtml, do not want!
set :haml, {:format => :html5, :escape_html => false}

# Conversion of the SCSS to regular CSS
get '/style.css' do
  scss :style
end

# Homepage
get '/' do
	
  # Render the HAML template
  haml :home

end
