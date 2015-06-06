# Add a method to String class
class String
  def indices(character)
    all_indices = []
    split(/\.*/).each_with_index do |char, i|
      all_indices << i if char == character
    end
    all_indices
  end
end
