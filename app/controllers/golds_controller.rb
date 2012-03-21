
# STI fixes copied from http://stackoverflow.com/questions/5246767/sti-one-controller/5252136#5252136
class GoldsController < ApplicationController
  layout 'browse'

  def export_by_sampletags

    @all_sampletags = Article.where("sampletag is not null").pluck(:sampletag).uniq
    @all_answer_types = Gold.types 
    
    respond_to do |format|
      format.html
      format.csv {
        # collect the passed params from the user 
        @sampletags = (params[:sampletag].keep_if {|k,v| v.to_i==1}).keys
        @answer_type = params[:answer]['type']
        # pull out the articles we care about
        @articles = Article.where(:sampletag=>@sampletags).includes(:golds)
        timestamp = Time.now.strftime('%Y-%m-%d_%H:%M:%S')
        # do some csv config
        @filename = @answer_type + "_" + "articles" + "_" + timestamp + ".csv"
        @output_encoding = 'UTF-8'
      }
    end
        
  end

  # see a list of articles with the gold answers
  def edit_reasons
    
    @sampletag = params[:sampletag]
    @answer_type = params[:answer_type]

    @articles = Article.where(:sampletag=>[@sampletag]).includes(:golds)
    
  end

  # GET /golds
  # GET /golds.json
  def index
    @golds = gold_type.includes(:article).page(params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @golds }
    end
  end

  # GET /golds/1
  # GET /golds/1.json
  def show
    @gold = Gold.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @gold }
    end
  end

  # GET /golds/new
  # GET /golds/new.json
  def new
    @gold = gold_type.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @gold }
    end
  end

  # GET /golds/1/edit
  def edit
    @gold = Gold.find(params[:id])
  end

  # POST /golds
  # POST /golds.json
  def create
    @gold = gold_type.new(params[:gold])

    respond_to do |format|
      if @gold.save
        format.html { redirect_to @gold, notice: 'Gold was successfully created.' }
        format.json { render json: @gold, status: :created, location: @gold }
      else
        format.html { render action: "new" }
        format.json { render json: @gold.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /golds/1
  # PUT /golds/1.json
  def update
    @gold = Gold.find(params[:id])

    respond_to do |format|
      if @gold.update_attributes(params[ params[:type].underscore ])
        format.html { redirect_to @gold, notice: 'Gold was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @gold.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /golds/1
  # DELETE /golds/1.json
  def destroy
    @gold = Gold.find(params[:id])
    @gold.destroy

    respond_to do |format|
      format.html { redirect_to golds_url }
      format.json { head :ok }
    end
  end

  private
    def gold_type
      params[:type].constantize if params.has_key? :type
      Gold
    end

end
