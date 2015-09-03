class ItemsController < ApplicationController
  before_filter :redirect_unless_admin, only: [:new, :create, :edit, :update, :destroy, :get_image_list, :get_listings]
  before_action :set_item, only: [:show, :edit, :update, :destroy, :vote]

  # GET /items
  # GET /items.json
  def index
    # TODO: replace sort_order with acts_as_votable
    @items = Item.order("sort_order asc")

    respond_to do |format|
      format.html
      format.json { render json: @items }
    end

  end

  # GET /items/1
  # GET /items/1.json
  def show
  end

  # GET /items/new
  def new
    @item = Item.new
  end

  # GET /items/1/edit
  def edit
  end

  # POST /items
  # POST /items.json
  def create
    @item = Item.new(item_params)
    @item.created_by = current_user

    respond_to do |format|
      if @item.save
        format.html { redirect_to @item, notice: 'Item was successfully created.' }
        format.json { render :show, status: :created, location: @item }
      else
        format.html { render :new }
        format.json { render json: @item.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /items/1
  # PATCH/PUT /items/1.json
  def update
    respond_to do |format|
      if @item.update(item_params)
        format.html { redirect_to @item, notice: 'Item was successfully updated.' }
        format.json { render :show, status: :ok, location: @item }
      else
        format.html { render :edit }
        format.json { render json: @item.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /items/1
  # DELETE /items/1.json
  def destroy
    @item.destroy
    respond_to do |format|
      format.html { redirect_to items_url, notice: 'Item was successfully destroyed.' }
      format.json { head :no_content }
    end
  end


  #->Prelang (voting/acts_as_votable)
  def vote

    direction = params[:direction]

    # Make sure we've specified a direction
    raise "No direction parameter specified to #vote action." unless direction

    # Make sure the direction is valid
    unless ["like", "bad"].member? direction
      raise "Direction '#{direction}' is not a valid direction for vote method."
    end

    @item.vote_by voter: current_user, vote: direction

    redirect_to action: :index
  end


  def get_image_list
    #TODO: This should really be JSON and restful and stuff
    begin
      url = params[:url]
      uri = URI::parse(url)
      #TODO: DRY this up
      md5_url = Digest::SHA256.hexdigest(url)
      page_html = DbCacheItem.get(md5_url, valid_for: 14.days) do
        require 'open-uri'
        doc = Nokogiri::HTML(open(url))
        # TODO: put this in DbCacheItem?
        # http://po-ru.com/diary/fixing-invalid-utf-8-in-ruby-revisited/
        ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
        ic.iconv(doc.to_html + ' ')[0..-2]
      end

      nokogiri_from_html = Nokogiri::HTML(page_html)
      image_list = nokogiri_from_html.css('img').map{ |i| i.attributes["src"].value }
      product_title = nokogiri_from_html.css('#productTitle').first.try(:content).to_s
      if product_title.blank?
        product_title = nokogiri_from_html.css("[id*='Title']").first.try(:content).to_s
      end

      product_price = nokogiri_from_html.css("#priceblock_ourprice").first.try(:content).to_s.gsub("$", "")

      # title_for_url = product_title.match(/[a-zA-Z0-9 ]+/).to_s.gsub(" ", "%20")
      # google_url = "http://www.google.com/search?q=#{title_for_url}&tbm=isch"

      # #TODO: DRY this up
      # md5_url = Digest::SHA256.hexdigest(google_url)
      # page_html = DbCacheItem.get(md5_url, valid_for: 14.days) do
      #   require 'open-uri'
      #   doc = Nokogiri::HTML(open(google_url))
      #   # TODO: put this in DbCacheItem?
      #   # http://po-ru.com/diary/fixing-invalid-utf-8-in-ruby-revisited/
      #   ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
      #   ic.iconv(doc.to_html + ' ')[0..-2]
      # end

      # nokogiri_from_html = Nokogiri::HTML(page_html)

      if product_title.present?
        # TODO: cache the google results
        # title_for_url = product_title.match(/[a-zA-Z0-9 ]+/).to_s.gsub(" ", "%20")
        Google::Search::Image.new(:query => product_title).each do |image|
          image_list << image.uri
        end
      end

      image_list.map! do |i|
        i.gsub!(" ", "%20")
        begin
          img_uri = URI::parse(i)
          img_uri.host = uri.host if img_uri.host.blank?
          img_uri.scheme = uri.scheme if img_uri.scheme.blank?
          img_uri.path = img_uri.path.prepend("/") unless img_uri.path.starts_with?("/")
          img_uri.to_s
        rescue Exception => e
          Rails::logger.warn("WARNING - URI parse failed - #{e.inspect}")
          nil
        end
      end
      image_list.select!(&:present?)


      render partial: "image_list", locals: {images: image_list, product_title: product_title, product_price: product_price }
    rescue Exception => e
      Rails::logger.warn("ERROR - #{e.inspect}")
      render partial: "image_list_error", :status => 500
    end
  end

  def get_listings
    Item.get_listings(current_user: current_user)
    redirect_to root_path, notice: 'Pulled new listings from Reddit!'
  end


  private ##################################################################################################################################

  # TODO: use declarative_authorization gem when roles/CRUD gets more complex
  def redirect_unless_admin
    redirect_to root_path unless current_user && current_user.admin?
  end

    # Use callbacks to share common setup or constraints between actions.
    def set_item
      @item = Item.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def item_params
      params.require(:item).permit(:url, :title, :description, :price, :thumbnail, :sort_order, :tag_list)
    end
end
