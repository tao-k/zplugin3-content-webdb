class Webdb::Entry < ApplicationRecord
  include Sys::Model::Base
  include Sys::Model::Auth::Manager
  include Sys::Model::Rel::Creator
  include Sys::Model::Rel::Editor
  include Sys::Model::Rel::File
  include Cms::Model::Rel::Map
  include Zplugin3::Content::Webdb::Model::Rel::TargetDate

  enum_ish :state, [:public, :draft], predicate: true

  WEEKDAY_OPTIONS = ['日', '月', '火', '水', '木', '金', '土','祝']

  belongs_to :db
  validates :db_id, presence: true

  delegate :content, to: :db

  validates :db, presence: true

  after_initialize :set_defaults
  before_save :set_name
  before_save :set_text

  scope :public_state, -> { where(state: 'public') }

  def default_map_position
    content.default_map_position
  end

  def site
    content.site
  end

  def file_content_uri
    if content.public_node.present?
      %Q("#{content.public_node.public_uri}#{name}/file_contents/)
    else
      %Q(#{content.admin_uri}/#{id}/file_contents/)
    end
  end

  def public_uri
    return nil if content.public_node.blank?
    "#{content.public_node.public_uri}#{self.db_id}/entry/#{name}/"
  end

  def edit_uri
    return nil if content.public_node.blank?
    "#{content.public_node.public_uri}#{self.db_id}/edit/#{name}/"
  end

  def delete_event_uri
    return nil if content.public_node.blank?
    "#{content.public_node.public_uri}#{self.db_id}/delete_event/#{name}/"
  end

  def preview_uri(terminal: nil, params: {})
    return if (path = public_uri).blank?

    flag = { mobile: 'm', smart_phone: 's' }[terminal]
    query = "?#{params.to_query}" if params.present?
    "/_preview/#{format('%04d', content.site_id)}#{flag}#{path}"
  end

  def editor_user
    return nil unless defined?(Zplugin3::Content::Login::Engine)
    return nil if editor_id.blank?
    Login::User.find_by(id: editor_id)
  end

  def map_icon
    return nil if item_values.blank?
    icon_column = db.items.icon_items.first
    return nil if icon_column.blank?
    if select_data = icon_column.item_options_for_icons
      value = case icon_column.item_type
      when 'check_data'
        item_values.dig(icon_column.name, 'check')
      else
        item_values[icon_column.name]
      end
      icon = Webdb::Entry.where(id: value).first
      return nil if icon.blank? || icon.item_values.blank?
      return icon.item_values[icon_column.icon_item.try(:name)]
    end
    return nil
  end

  def map_marker
    marker_title = item_values.present? && db.items.present? ? item_values[db.items.first.try(:name)] : title
    self.maps.first.markers.map do |m|
      marker = Map::Marker.new(
        title: marker_title,
        latitude: m.lat,
        longitude: m.lng,
        window_text: %Q(<p>#{marker_title}</p><p><a href="#{self.public_uri}">詳細</a></p>),
        created_at: self.created_at,
        updated_at: self.updated_at
      )
      marker.files = self.files
      marker.readonly!
      marker
    end
  end

  private

  def set_name
    return if self.name.present?
    date = (created_at || Time.now).strftime('%Y%m%d')
    seq = Util::Sequencer.next_id('webdb_entry', version: date, site_id: content.site_id)
    self.name = Util::String::CheckDigit.check(date + format('%04d', seq))
  end

  def set_text
    return if item_values.blank?
    db.items.each do |item|
      case item.item_type
      when 'check_box'
        if item_values[item.name]
          item_values[item.name]['text'] = item_values.dig(item.name, 'check').present? ? item_values[item.name]['check'].join('，') : nil
        end
      when 'check_data'
        if item_values.dig(item.name, 'check').present?
          checks = []
          item_values[item.name]['check'].each{|w|
            item.item_options_for_select_data.each{|a| checks << a[0] if a[1] == w.to_i}
          }
          item_values[item.name]['text'] = checks.join('，')
        end
      when 'ampm'
        if item_values[item.name]
          weeks = []
          WEEKDAY_OPTIONS.each_with_index{|w, i|
            week_hours = "#{w} "
            week_hours += "午前：#{item_values[item.name]['am'].present? && item_values[item.name]['am'][i.to_s].present? ? '○' : '×'}"
            week_hours += "　午後：#{item_values[item.name]['pm'].present? && item_values[item.name]['pm'][i.to_s].present? ? '○' : '×'}"
            weeks << week_hours
          }
          value = weeks.join("／")
          item_values[item.name]['text'] = value
        end
      when 'office_hours'
        if item_values[item.name]
          office_hours = []
          if item_values[item.name]['open']
            item_values[item.name]['open'].each{|key, val|
              open_at  = val
              close_at = item_values[item.name]['close'].present? ? item_values[item.name]['close'][key] : nil
              office_hours << "#{self.class::WEEKDAY_OPTIONS[key.to_i]}：#{open_at}～#{close_at}"
            }
          end
          value = "　#{office_hours.join('／')}"
          value += "／備考：#{item_values[item.name]['remark']}"
          item_values[item.name]['text'] = value
        end
      when 'blank_weekday'
        if item_values.dig(item.name, 'weekday')
          days = []
          item_values[item.name]['weekday'].each{|key, val|
            days << "#{self.class::WEEKDAY_OPTIONS[key.to_i]}：#{val}"
          }
          value = days.join('／')
          item_values[item.name]['text'] = value
        end
      when 'blank_date'
        blank_dates = []
        dates.where(name: item.name).each{|e| blank_dates << %Q(#{e.event_date.strftime("%Y-%m-%d")}：#{e.option_value}) }
        value = blank_dates.join('／')
        item_values[item.name] = value
      end
    end
  end


  def set_defaults
    self.state ||= 'draft'
    self.item_values ||= {} if self.has_attribute?(:item_values)
  end
end
