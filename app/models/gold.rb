class Gold < ActiveRecord::Base

  self.per_page = 100

  belongs_to      :article
  belongs_to      :question
  
  def unanswered?
    answer==nil
  end
  
  def answered?
    answer!=nil
  end

  def has_reason?
    (reason!=nil) && (reason.length > 0)
  end

  # return a hash of type=>total, reasoned, pct of golds with reasons
  def self.reasoned_percent_by_type
    with_reasons = Gold.group(:type).where('reason is not null').count
    logger.info with_reasons
    all = Gold.group(:type).count
    pcts = {}
    all.each do |type_classname,count|
      type_short_name = type_for_classname(type_classname)
      pct = 0.0 
      pct = with_reasons[type_classname].to_f / count.to_f if with_reasons.has_key? type_classname
      pcts[type_short_name] = { 
        :total => all[type_classname],
        :reasoned => with_reasons[type_classname], 
        :pct => pct
        }   
    end
    pcts
  end

end

