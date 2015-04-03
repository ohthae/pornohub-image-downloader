#!/usr/bin/env ruby
require 'bundler'
Bundler.require

require 'uri'
require 'nokogiri'
require 'rest-client'

class Web
  UA = 'Mozilla/5.0 (Windows NT 5.1; rv:37.0) Gecko/20100101 Firefox/37.0'

  class << self
    def get url, referer = '', ua=Web::UA
       Nokogiri::HTML RestClient.get(url, user_agent: UA, referer: referer)
    end
  end
end

get '/' do
  slim :index
end

post '/' do
  log = File.open 'public/save.log', 'a'
  log.puts Time.now
  @albums = {}
  params['urls'].split("\n").each do |url|
    url.chomp!
    log.print "#{url} "
    album_id = url.match(/album\/(\d+)\Z/)[1]
    save_dir = 'public/'+album_id
    album = Web.get url
    Dir.mkdir save_dir unless File.exist? save_dir
    image_pages = album.search('.photoAlbumListBlock a').map{|link| 'http://www.pornhub.com'+link.attr('href') }
    @albums[album_id] = 0
    image_pages.each do |page_url|
      puts "Process page #{page_url}"
      image_url = Web.get(page_url).search('#photoImageSection > .centerImage > a > img').first.attr('src')
      puts "wget '#{image_url}' -P #{album_id}"
      `wget '#{image_url}' -P #{save_dir}`
      @albums[album_id] += 1
    end
    log.puts "Done #{@albums[album_id]}"
  end
  log.close
  slim :results
end
