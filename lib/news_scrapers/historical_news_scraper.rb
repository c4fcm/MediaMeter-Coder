require 'rubygems'
require 'mechanize'
require 'open-uri'
require 'cgi'
require 'nokogiri'
require 'pp'

module NewsScrapers

  class HistoricalNewsScraper
    
    def initialize
      @requester = NewsScrapers::requester
    end
  
    def blacklist_scrape(d)
      # by default this doesn't do anything
    end
  
    def scrape(d)
      raise NotImplementedError.new("Hey! You gotta implement a public scrape method in your subclass!")
    end
    
    def in_cache?(base_url,params={})
      NewsScrapers.cache.exists?( get_full_url(base_url, params) )
    end
    
    def fetch_url(base_url, params={}, bypass_cache=false, fetch_with_mechanize=true)
      full_url = get_full_url(base_url,params)
      NewsScrapers.logger.info("      fetch_url #{full_url}")
      NewsScrapers.logger.info("        forcing bypass cache") if bypass_cache

      if !bypass_cache && NewsScrapers.cache.exists?(full_url)
        NewsScrapers.logger.debug("      from cache ("+NewsScrapers.cache.path_for(full_url)+")")
        contents = NewsScrapers.cache.get(full_url)
      else
        NewsScrapers.logger.debug("      from interwebs")
        sleep(0.1)
        if fetch_with_mechanize
          page = @requester.get(full_url)
          contents = page.body          
        else
          file_handle = open(full_url, 
            "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_2) AppleWebKit/534.52.7 (KHTML, like Gecko) Version/5.1.2 Safari/534.52.7",
            "Accept" => "Accept:text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Cache-Control:max-age" => "0")
          contents = file_handle.read
        end
        if bypass_cache
          NewsScrapers.logger.debug("      fetched")  
        else
          NewsScrapers.cache.put(full_url,contents)
          NewsScrapers.logger.debug("      fetched (cached to "+NewsScrapers.cache.path_for(full_url)+")")
        end
      end
      NewsScrapers.logger.debug("      about to parse")
      NewsScrapers.logger.flush
      Nokogiri::HTML(contents)
    end
    
    private
      
      def get_full_url(base_url,params)
        base_url + "?" + encode_url_params(params)
      end
      
      # needed to write my own to allow multiple parameteres with the same name (key maps to an array or values, not just one)
      def encode_url_params(value, key = nil)
        case value
        when Hash then value.map { |k,v| 
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
