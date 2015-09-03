class Item < ActiveRecord::Base
  acts_as_votable
  acts_as_taggable

  validates_presence_of :url, :thumbnail, :title, :sort_order

  belongs_to :created_by, class_name: "User"

  def affiliate_url
    uri = URI::parse(url)
    return url unless uri.host.to_s.include?("amazon.com")
    query_array = uri.query.to_s.split("&")
    query_array.delete_if{ |item| item.starts_with?("tag=") }
    query_array << "tag=dilutionofpre-20"
    uri.query = query_array.join("&")
    uri.to_s
  end

  def self.get_listings(current_user: nil)
    # Gets a listing of links from reddit.
    #
    # @param (see LinksComments#info)
    # @option opts [String] :subreddit The subreddit targeted. Can be psuedo-subreddits like `all` or `mod`. If blank, the front page
    # @option opts [new, controversial, top, saved] :page The page to view.
    # @option opts [new, rising] :sort The sorting method. Only relevant on the `new` page
    # @option opts [hour, day, week, month, year] :t The timeframe. Only relevant on some pages, such as `top`. Leave empty for all time
    # @option opts [1..100] :limit The number of things to return.
    # @option opts [String] :after Get things *after* this thing id
    # @option opts [String] :before Get things *before* this thing id
    # @return (see #clear_sessions)

    reddit = Snoo::Client.new
    result = reddit.get_listing(subreddit: "amazontoprated")
    result["data"]["children"].each do |child|
      data = child["data"]

      i = Item.find_or_initialize_by(reddit_id: data["id"])
      next unless i.new_record?

      i.url = data["url"]
      i.title = data["title"]
      i.ups = data["ups"]
      i.sort_order = i.ups * -1 if i.ups.present?
      i.sort_order ||= 0
      i.thumbnail = data["thumbnail"]
      price_string = data["title"][/\[\$\d+\.?\d?\d?\]/].to_s.gsub("[", "").gsub("$", "").gsub("]", "").presence
      price_string ||= data["title"][/\d+\.\d\d/].to_s.gsub("[", "").gsub("$", "").gsub("]", "")
      i.price = price_string.to_d if price_string.present?

      i.created_by = current_user if current_user.present?

      i.save! if i.price.present? && i.thumbnail != "nsfw"
    end
  end
end
