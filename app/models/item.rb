class Item < ActiveRecord::Base
  acts_as_votable
  acts_as_taggable

  validates_presence_of :title, :start_date, :end_date

  belongs_to :created_by, class_name: "User"

end
