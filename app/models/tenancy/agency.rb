module Tenancy
  # The tenant root: every tenant-owned row belongs to exactly one agency.
  class Agency < ApplicationRecord
    # Slugs can become subdomains, so they follow DNS label rules: lowercase letters, digits
    # and single hyphens between them, at most 63 characters.
    SLUG_FORMAT = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/

    enum :status, { active: "active", suspended: "suspended" }, default: :active, validate: true

    # An agency is created in one cell and its data never leaves it (doc 07), so its region is
    # fixed once the record exists.
    attr_readonly :data_region

    normalizes :slug, with: ->(slug) { slug.strip.downcase }

    validates :name, presence: true
    validates :slug, presence: true, length: { maximum: 63 }, format: { with: SLUG_FORMAT },
      uniqueness: true
    validates :data_region, presence: true, format: { with: /\A[a-z][a-z0-9-]*\z/ }
  end
end
