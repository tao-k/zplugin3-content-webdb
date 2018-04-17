class Webdb::Db < ApplicationRecord
  include Sys::Model::Base
  include Sys::Model::Auth::Manager
  include Sys::Model::Rel::Creator
  include Sys::Model::Rel::Editor
  include Sys::Model::Rel::EditableGroup

  enum_ish :state, [:public, :closed], predicate: true

  # Content
  belongs_to :content, :foreign_key => :content_id, :class_name => 'Webdb::Content::Db'
  validates :content_id, :presence => true

  has_many :items, foreign_key: :db_id, class_name: 'Webdb::Item', dependent: :destroy
  has_many :entries, foreign_key: :db_id, class_name: 'Webdb::Entry', dependent: :destroy

  after_save     Webdb::Publisher::DbCallbacks.new, if: :changed?
  before_destroy Webdb::Publisher::DbCallbacks.new

  STATE_OPTIONS = [['公開', 'public'], ['非公開', 'closed']]
  ORDERING_OPTIONS = [['昇順', 'asc'], ['降順', 'desc']]

  default_scope { order("#{self.table_name}.sort_no IS NULL, #{self.table_name}.sort_no") }

  belongs_to :content, :foreign_key => :content_id, :class_name => 'Webdb::Content::Db'
  validates :content_id, presence: true

  validates :title, presence: true

  after_initialize :set_defaults

  scope :public_state, -> { where(state: 'public') }

  def public_items
    items.public_state
  end

  def state_public?
    state == 'public'
  end

  def duplicate
    item = self.class.new(self.attributes.except('id', 'created_at', 'updated_at'))
    item.title = item.title.gsub(/^(【複製】)*/, "【複製】")

    return false unless item.save(validate: false)

    items.each do |i|
      dupe_item = GpTemplate::Item.new(i.attributes.except('id', 'created_at', 'updated_at'))
      dupe_item.template_id = item.id
      dupe_item.save(validate: false)
    end

    return item
  end

  def member_content
    return nil unless defined?(Zplugin3::Content::Login::Engine)
    return nil if member_content_id.blank?
    Login::Content::User.find_by(id: member_content_id)
  end

  def editor_content
    return nil unless defined?(Zplugin3::Content::Login::Engine)
    return nil if editor_content_id.blank?
    Login::Content::User.find_by(id: editor_content_id)
  end

private

  def set_defaults
    self.state   = STATE_OPTIONS.first.last if self.has_attribute?(:state) && self.state.nil?
    self.sort_no = 10 if self.has_attribute?(:sort_no) && self.sort_no.nil?
  end

end
