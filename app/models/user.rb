class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  has_many :union_pay_merchants
  has_many :union_pay_banks
  has_many :chef_wumujyis
  validates_length_of :telephone_number, minimum: 10, maximum: 10
end
