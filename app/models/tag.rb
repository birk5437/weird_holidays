class Tag < ActsAsTaggableOn::Tag

  # #TODO: this...so bad
  def items
    Item.where(["id in (select taggable_id from taggings where taggable_type = 'Item' and tag_id = ?)", self.id])
  end

end