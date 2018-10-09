class Webdb::GroupPage < ApplicationRecord
  include Sys::Model::Base
  belongs_to :db
  validates :db_id, presence: true

  delegate :content, to: :db

  def group
    return nil unless defined?(Zplugin3::Content::Login::Engine)
    Login::Group.find_by(id: group_id)
  end

end
