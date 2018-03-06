class Webdb::Item < ApplicationRecord
  include Sys::Model::Base
  include Sys::Model::Auth::Manager
  include Sys::Model::Rel::Creator
  include Sys::Model::Rel::Editor
  include Sys::Model::Rel::EditableGroup
  enum_ish :state, [:public, :closed], predicate: true

  STATE_OPTIONS = [['公開', 'public'], ['非公開', 'closed']]
  ITEM_TYPE_OPTIONS = [['入力/1行（テキストフィールド）', 'text_field'], ['入力/複数行（テキストエリア）', 'text_area'], ['入力/フリー（エディタ付）', 'rich_text'],
                       ['選択/単数回答（プルダウン）', 'select'], ['選択/単数回答（ラジオボタン）', 'radio_button'],
                       ['データベース参照選択/単数回答（プルダウン）', 'select_data'],['データベース参照選択/単数回答（ラジオボタン）', 'radio_data'],
                       ['選択/複数回答（チェックボックス）', 'check_box'],['データベース参照選択/複数回答（チェックボックス）', 'check_data'],['添付ファイル', 'attachment_file'],
                       ['郵便番号', 'postal_code'],['曜日／午前・午後', 'ampm'],['曜日／時間', 'office_hours'],
                       ['空枠/数値', 'blank_integer'],['空枠/数値（曜日）', 'blank_weekday'],['空枠/記号（日程）', 'blank_date']]

  default_scope { order("#{self.table_name}.sort_no IS NULL, #{self.table_name}.sort_no") }

  belongs_to :db
  validates :db_id, presence: true

  belongs_to :reference_db, foreign_key: :reference_id, class_name: 'Webdb::Db'
  belongs_to :reference_item, foreign_key: :reference_item_id, class_name: 'Webdb::Item'

  delegate :content, to: :db

  validates :state, presence: true

  validates :db, presence: true

  validates :name, presence: true, uniqueness: { scope: :db_id, case_sensitive: false },
                   format: { with: /\A[-\w]*\z/ }

  validates :item_type, presence: true

  after_initialize :set_defaults

  nested_scope :in_site, through: :db

  scope :public_state, -> { where(state: 'public') }

  scope :target_search_state, ->{
    public_state.where(is_target_search: true)
  }

  scope :target_keyword_state, ->{
    public_state.where(is_target_keyword: true)
  }

  scope :target_sort_state, ->{
    public_state.where(is_target_sort: true)
  }

  def state_public?
    state == 'public'
  end

  def state_closed?
    state == 'closed'
  end

  def item_options_for_select_data
    return [] if reference_db.blank? || reference_item.blank?
    reference_db.entries.public_state.map{|e| [e.item_values[reference_item.name], e.id] }
  end

  def item_options_for_select
    item_options.split(/[\r\n]+/)
  end

  def item_type_label
    ITEM_TYPE_OPTIONS.detect{|o| o.last == item_type}.try(:first)
  end

  private

  def set_defaults
    self.state     = STATE_OPTIONS.first.last     if self.has_attribute?(:state) && self.state.nil?
    self.item_type = ITEM_TYPE_OPTIONS.first.last if self.has_attribute?(:item_type) && self.item_type.nil?
    self.sort_no = 10 if self.has_attribute?(:sort_no) && self.sort_no.nil?
  end

end
