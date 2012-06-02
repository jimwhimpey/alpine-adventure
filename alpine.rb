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

	# Get photos
  call = Curl::Easy.perform("http://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=cb1cb6d2a45be697d708497bb9a3989d&user_id=40575690%40N00&tags=alpine-adventure&format=rest")
	
  # Parse the XML
  doc = Nokogiri::XML(call.body_str)
	
  # Grab all the photo elements
  photos_xml = doc.css('rsp photos photo')
	
  # Create an array for holding all the photos information
  @photos = Array.new

  # Loop through each returned photo and make another 
  # API call to get the correct size
  photos_xml.each do |photo_xml|

    # Make the call for this individual photo's sizes and it's info
    sizes_call = Curl::Easy.perform("http://api.flickr.com/services/rest/?method=flickr.photos.getSizes&api_key=cb1cb6d2a45be697d708497bb9a3989d&photo_id=#{photo_xml['id']}")
    info_call = Curl::Easy.perform("http://api.flickr.com/services/rest/?method=flickr.photos.getInfo&api_key=cb1cb6d2a45be697d708497bb9a3989d&photo_id=#{photo_xml['id']}")
  
    # Parse the sizes and info XML
    sizes_doc = Nokogiri::XML(sizes_call.body_str)
    info_doc = Nokogiri::XML(info_call.body_str)
  
    # Find the XML element of the large photo
    large = sizes_doc.css('sizes size[label=Large]')
    
    # If a large photo isn't found then we'll use the original
    if large.length == 0 then large = sizes_doc.css('sizes size[label=Original]') end
    
    # Make sure there actually is a large size. There should always at least be an original, no matter 
    # how small so I'm not sure what's happening here. In any case, if there's no big version returned then
    # we just skip it.
    if large.length > 0
      
      # Grab the large image's info
      large_url = large[0]['source']
      large_width = large[0]['width']
      large_height = large[0]['height']
  
      # Get the title, description, comment count and URL of the photo
      title = info_doc.css('photo title')[0].content
      description = Maruku.new(info_doc.css('photo description')[0].content).to_html
      url = info_doc.css('photo urls url[type=photopage]')[0].content
			date = Time.at(info_doc.css('photo dates')[0]['posted'].to_i)
			date = date.strftime("%A, #{date.day.ordinalize} of %b, %Y")
  
      # Create hash of this photo's data
      photo = Hash[ "large_url" => large_url,
                    "title" => title,
                    "description" => description,
                    "url" => url,
										"date" => date,
                    "width" => large_width,
                    "height" => large_height]
  
      # Add that hash to the photos array
      @photos << photo

    end
  
  end
	
  # Render the HAML template
  haml :home

end


class Fixnum
  def ordinalize
    if (11..13).include?(self % 100)
      "#{self}th"
    else
      case self % 10
        when 1; "#{self}st"
        when 2; "#{self}nd"
        when 3; "#{self}rd"
        else    "#{self}th"
      end
    end
  end
end