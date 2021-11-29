class ChefWumujyi < ApplicationRecord
  belongs_to :user
  validates_length_of :telephone_number, minimum: 10, maximum: 10
  validates_length_of :plate_number, minimum: 5, maximum: 7
end
