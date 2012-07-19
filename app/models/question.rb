class Question < ActiveRecord::Base

  has_many :answers
  
  alias_attribute :name, :title

  def export_safe_text
    title.downcase.gsub(/ /,"_")
  end

  def self.for_answer_type answer_type
    Question.where(:key=>answer_type.camelize).first
  end
  
  def answer_text answer_num
    text = ""
    case answer_num
    when 1
      text = answer_one
    when 2 
      text = answer_two
    when 3 
      text = answer_three
    when 4 
      text = answer_four
    when 5 
      text = answer_five
    end
    text
  end

end
