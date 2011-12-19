require 'rubygems'
require 'open-uri'
require 'cgi'
require 'nokogiri'
require 'pp'

module NewsScrapers

  class HistoricalNewsScraper
    
    def initialize
      @cache = NewsScrapers::WebpageCache.new( File.join("/tmp","scraper") )
    end
  
    def fetch_url(base_url, params={})
      #NewsScrapers.logger.info("      about to build url")
      full_url = base_url + "?" + encode_url_params(params)
      NewsScrapers.logger.info("      fetch #{full_url}")
      
      if @cache.exists?(full_url)
        #NewsScrapers.logger.info("      from cache")
        contents = @cache.get(full_url)
      else
        #NewsScrapers.logger.info("      from interwebs")
        file_handle = open(full_url, 
          "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_2) AppleWebKit/534.52.7 (KHTML, like Gecko) Version/5.1.2 Safari/534.52.7",
          "Accept" => "Accept:text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
          "Cache-Control:max-age" => "0",    
          "Referer" => "http://pqasb.pqarchiver.com/washingtonpost/advancedsearch.html")
        #NewsScrapers.logger.info("      fetched")
        contents = file_handle.read
        #NewsScrapers.logger.info("      got contents")
        @cache.put(full_url,contents)
      end
      #NewsScrapers.logger.info("      about to parse")
      Nokogiri::HTML(contents)
    end
    
    private
      
      def encode_url_params(value, key = nil)
        case value
        when Hash  then value.map { |k,v| 
          str = ""
          if v.is_a? Array
            str = v.map { |v2| encode_url_params(v2, "#{k}") }.join('&')
          else 
            str = encode_url_params(v, append_key(key,k)) 
          end
          str
        }.join('&')
        when Array then value.map { |v| encode_url_params(v, "#{key}[]") }.join('&')
        when nil   then ''
        else            
          "#{key}=#{CGI.escape(value.to_s)}" 
        end
      end
    
      def append_key(root_key, key)
        root_key.nil? ? key : "#{root_key}[#{key.to_s}]"
      end
    
  end

end