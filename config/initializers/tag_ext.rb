class ActsAsTaggableOn::Tag

  def name=(input)
    self.dehumanized_name = input.to_s.underscore.gsub(" ", "_").presence
    super(input.to_s.titlecase.presence)
  end

end