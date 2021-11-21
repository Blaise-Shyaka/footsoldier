class UnionPayMerchant < ApplicationRecord
  belongs_to :promoter, class_name: 'User'
end
