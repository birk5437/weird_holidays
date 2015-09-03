module ApplicationHelper
  def money_format(value)
    "$#{'%.02f' % value.to_d}"
  end
end
