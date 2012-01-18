require 'logger'
require 'csv'
 
module CrowdFlower

  @@logger_instance = nil
  
  # Main Public API
  def self.import(answer_type, file, answer_col, confidence_col)
    row_count = 0
    col_headers = Array.new
    col_indices = {
      "id"=>nil,
      "_trusted_judgments"=>nil,
      answer_col=>nil,
      confidence_col=>nil,
    }
    answer_col_index = nil
    confidence_col_index = nil
    CSV.foreach(file) do |row|
      if row_count==0
        # check out col headers and validate we can find the 3 cols we need (id, _trusted_judgments, answer, confidence)
        col_headers = row
        found_all_cols = true
        col_indices.each_key do |key|
          col_indices[key] = col_headers.index(key)
          found_all_cols = false if col_indices[key]==nil  
        end
        if !found_all_cols
          CrowdFlower.logger.error("Didn't find one of the required cols - bailing!")
          pp col_indices
          exit
        end
      else
        # create and save an answer
        answer = Answer.new_by_type(answer_type)
        answer.confidence = row[ col_indices[confidence_col] ].to_f
        answer.answer = (row[ col_indices[answer_col] ] == "Yes")
        answer.judgements = row[ col_indices["_trusted_judgments"] ].to_i
        answer.article_id = row[ col_indices["id"] ].to_i
        answer.save
      end
      row_count = row_count + 1
    end
    CrowdFlower.logger.info("Imported #{row_count} rows")
  end
  
  def self.export(answer_type, file_path)
    row_count = 0
    CSV.open(file_path, "wb") do |csv|
      csv << ["id", "newspaper", "page", "headline","date","abstract","byline","content_url"]
      Article.all.each do |a|
        csv << [  a.id, 
                  a.source, 
                  a.page, 
                  a.headline, 
                  (a.pub_date.year.to_s+"/"+a.pub_date.month.to_s+"/"+a.pub_date.day.to_s),
                  a.abstract,
                  a.byline,
                  a.scan_file_url
                ]
        row_count = row_count + 1
      end
    end
    CrowdFlower.logger.info("Exported #{row_count} rows to #{file_path}")
  end
  
  # Be smart about logging while running inside or outside of Rails
  def self.logger
    return Rails.logger if defined? Rails
    if @@logger_instance == nil
      @@logger_instance = Logger.new("crowd_flower_development.log")
    end
    @@logger_instance
  end
  
end

# for debugging in standalone mode
#NewsScrapers::scrape_all