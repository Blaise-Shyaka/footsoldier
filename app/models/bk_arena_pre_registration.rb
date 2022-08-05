class BkArenaPreRegistration < ApplicationRecord
  belongs_to :user

  validates :first_name,
            :format => {with: /[a-zA-Z]/, :message => "Should only be made of characters"},
            :length => {minimum: 2, maximum: 50, :message => "should be at least 2 characters"}
  validates :last_name,
            :format => {with: /[a-zA-Z]/, :message => "Should only be made of characters"},
            :length => {minimum: 2, maximum: 50, :message => "should be at least 2 characters"}
  validates :id_type,
            :format => {with: /[a-zA-Z]/, :message => "Should only be made of characters"}
  validates :id_number,
            :format => {with: /[A-Za-z0-9]/, :message => "Should only be made of numbers"},
            :length => {minimum: 6, maximum: 16, :message => "should be at least 6 characters or numbers"}
  validates :tel_no,
            :length => {minimum: 10, maximum: 10, :message => "should be 10 digits"}
  validates :email,
            :format => {with: Devise::email_regexp, :message => "is invalid"}
  validates :province,
            :presence => {:message => "can't be empty"}
  validates :district,
            :presence => {:message => "can't be empty"}
  validates :preferred_branch,
            :presence => {:message => "can't be empty"}
  validates :gender,
            :presence => {:message => "can't be empty"}
end
