require 'digest/md5'


# helper to encrypt the content of one colunm into another before saving
class ArticlePrepper

  def before_save(article)
    # make the cache hash
    if article.src_url_md5 ==nil
      if article.has_url?
        url = article.src_url
      else 
        url = article.fake_url
      end
      article.src_url_md5 = encrypt( url )
    end
    # clean some strings
    article.headline.strip! if article.headline!=nil
    article.abstract.strip! if article.abstract!=nil 
  end
  
  private

    def encrypt(value)
      Digest::MD5.hexdigest(value)
    end

end

class Article < ActiveRecord::Base

  self.per_page = 100

  has_many      :answers
  has_many      :golds
  
  before_save   ArticlePrepper.new
  
  scope :completed, where(:queue_status=>:complete).order(:pub_date)
  scope :with_scans, where("scan_src_url IS NOT NULL").order(:pub_date)
  
  GENDERS = {
    'F'=>'Female Author',
    'M'=>'Male Author',
    'U'=>'Unknown Gender Author',
    'X'=>'No Author'
  }
  
  # we need these held here so we can export the CSV for CrowdFlower correcltly
  # @see https://crowdflower.com/solutions/self-service/#learning_resources 
  QUESTIONS = {
    "arts"=>"Is this newspaper clip about the arts or entertainment",
    "foreign"=>"Does this article contain International News that does not involve the United States", 
    "international"=>"Is this newspaper clip about International News that involves the United States or NATO", 
    "local"=>"Does this article contain local news about a town city state or region in the United States", 
    "national"=>"Does this newspaper clip contain United States National news", 
    "sports"=>"Is this article about sports"
  }
  
  def self.all_genders
    GENDERS.keys.sort
  end
  
  def self.gender_name key
    GENDERS[key]
  end
  
  def self.question_text type
    QUESTIONS[type]
  end
  
  # get the url to the local copy of the PDF file
  def url_to_scan_local_file
    url = ""
    url = "http://"+File.join(NewsScrapers::public_base_url, scan_subdir, scan_local_filename) if has_scan_local_filename?
    url
  end
  
  # has the scan file been download already?
  def scan_local_file_exists?
    return false if !has_scan_file_url?
    return File.exists?( File.join( path_to_scan_dir, scan_local_filename ))
  end
  
  def download_scan(requester=nil)
    # bail if no scan file to download
    return nil if !has_scan_file_url?
    # create downloader
    requester = NewsScrapers::requester if requester==nil
    # download it
    result = FALSE
    extension = scan_file_url.split('.').pop()
    scan_local_filename = id.to_s + "." + extension
    begin
      # request and save all in one step
      requester.get(scan_file_url).save( File.join(path_to_scan_dir, scan_local_filename) )
      result = TRUE
    rescue Exception => e
      logger.error "  FAILED: #{scan_file_url}"
      set_queue_status(:in_progress_error)
      save
    end
    result
  end
  
  # HACK for NYT edge case where some articles from the API don't have URLs :-(
  def fake_url
    return source.to_s + pub_date.to_s + headline.to_s
  end
  
  def has_url?
    return src_url!=nil && !src_url.empty?
  end
  
  def has_scan_src_url?
    return scan_src_url!=nil && !scan_src_url.empty?
  end
    
  def path_to_scan_dir
    dir = File.join( Rails.public_path , scan_dir) 
    FileUtils::makedirs(dir) unless File.exists?(dir)
    dir
  end
  
  def has_scan_file_url?
    return scan_file_url!=nil && !scan_file_url.empty?
  end

  def has_scan_local_filename?
    return scan_local_filename!=nil && !scan_local_filename.empty?
  end

  def self.scraped_already? src_url
    src_url_md5 = Digest::MD5.hexdigest(src_url)
    where("src_url_md5 = ?",src_url_md5).first
  end
  
  def self.count_without_abstracts
    where("abstract is null").count
  end

  def set_queue_status(val)
    raise ArgumentError.new("Argument is not a valid queue status. Received :#{val.to_s}. Valid responses include :queued, :in_progress, :complete, :blacklisted, :in_progress_error") if !([:queued, :in_progress, :complete, :blacklisted, :in_progress_error].include? val)
    self.queue_status = val.to_s
  end

  def add_blacklist_tag(tag)
    if self.blacklist_tag.nil?
      self.blacklist_tag =""
    end
    return nil if get_blacklist_tags.include? tag
    divider =""
    divider ="," if get_blacklist_tags.size > 0
    self.blacklist_tag +="#{divider}#{tag}"
  end

  def get_blacklist_tags()
    return [] if self.blacklist_tag.nil?
    self.blacklist_tag.split(",")
  end

  # assumes you've loaded the article with the linked has_many :articles
  def answers_by_type(type)
    answers.select do |answer|
      answer.is_type type
    end
  end

  def answers_from_user_for_type(uid, type)
    answers.select do |answer|
      answer.user_id == uid && answer.type == Answer.classname_for_type(type)
    end
  end

  def missing_gold_by_type(type)
    gold_by_type(type) == nil
  end
  
  def has_gold_by_type(type)
    !missing_gold_by_type(type)
  end

  # assumes you've loaded the article with the linked has_many :golds
  def gold_by_type(type)
    gold = nil
    found_golds = golds.select { |g| g.is_type type }
    gold = found_golds.first if found_golds.count > 0   # there should be only one!
    gold
  end

  # return a summary hash about agreement between the answers already loaded
  def agreement_info_for_type(type)
    answers_of_type = answers_by_type(type)
    info = {
      :yes => (answers_of_type.count {|a| (a.answer==true)}).to_f / answers_of_type.count.to_f,
      :no => (answers_of_type.count {|a| (a.answer==false)}).to_f / answers_of_type.count.to_f,
      :count => answers_of_type.count
    }
    info[:yes] = 0 if info[:yes].nan?
    info[:no] = 0 if info[:no].nan?
    if info[:yes] > info[:no]
      info[:is_of_type] = true 
    elsif info[:no] > info[:yes]
      info[:is_of_type] = false
    else 
      info[:is_of_type] = nil
    end
    info
  end   
  
  def self.average_stories_per_day_by_source_and_year
    sources = Article.pluck(:source).uniq
    results = Hash.new
    sources.each do |source|
      results[source] = Hash.new
      totals = Article.where(:source=>source).group("YEAR(pub_date)").count
      totals.each do |year,total_articles|
        results[source][year] = (total_articles / 5).round
      end 
    end
    results
  end
  
  def self.sampletag_counts
    Article.where("sampletag is not null").group(:sampletag).count
  end

  def self.all_sampletags
    Article.where("sampletag is not null").pluck(:sampletag).uniq.sort
  end

  def self.all_sources
    Article.group(:source).pluck(:source).sort
  end
  
  def self.all_years
    Article.pluck("YEAR(pub_date)").uniq.sort
  end
  
  def self.counts_by_source_year sampletags
    results = Hash.new
    Article.completed.where(:sampletag=>sampletags).group(:source,"YEAR(pub_date)").
      where('YEAR(articles.pub_date) > 0').count.each do |key, value|
      source = key[0]
      year = key[1]
      article_count = value
      results[source] = Hash.new unless results.has_key? source
      results[source][year] = article_count
    end
    results
  end
  
  def self.gender_counts_by_source_year sampletags
    results = Hash.new
    Article.completed.where(:sampletag=>sampletags).group(:gender,:source,"YEAR(pub_date)").
      where('YEAR(articles.pub_date) > 0').count.each do |key, value|
      gender = key[0]
      source = key[1]
      year = key[2]
      article_count = value
      results[gender] = Hash.new unless results.has_key? gender
      results[gender][source] = Hash.new unless results[gender].has_key? source
      results[gender][source][year] = value
    end
    results
  end

  private 

    def scan_dir
      File.join("article_scans" , scan_subdir)
    end
    
    def scan_subdir
      File.join(source.gsub(" ","_").downcase , pub_date.year.to_s , pub_date.month.to_s , pub_date.day.to_s)
    end

end
