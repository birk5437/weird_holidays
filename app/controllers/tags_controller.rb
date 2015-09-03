class TagsController < ApplicationController

  def index
    Tag.where(taggings_count: 0).map(&:destroy)
    @tags = Tag.where(["name ilike(?)", "%" + params[:q] + "%"]).order(:name)

    if !@tags.map(&:name).map(&:downcase).include?(params[:q].downcase)
      t = Tag.new(name: params[:q])
      t.save!
      @tags.unshift(t)
    end

    respond_to do |format|
      format.json { render json: @tags }
    end
  end

  def show
    @tag = Tag.where(dehumanized_name: params[:dehumanized_name]).first
    redirect_to "/" unless @tag.present?
    @items = @tag.items
    render "items/index"
  end

end