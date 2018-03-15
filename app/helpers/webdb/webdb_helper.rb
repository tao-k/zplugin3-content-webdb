require "uri"
module Webdb::WebdbHelper

  def entry_body(type, db, entry, mode: :body)
    template_body = case type
    when :list
      db.list_body
    when :detail
      db.detail_body
    when :member_list
      db.member_list_body
    when :member_detail
      db.member_detail_body
    else
      nil
    end
    return nil if template_body.blank?
    template_body   = template_body.html_safe
    #template_header = template_body.gsub(/\[\[view\/header\]\](.*)[\[view\/header\]\]/i, '\1')
    #template_footer = template_body.gsub(/\[\[view\/footer\]\](.*)[\[view\/footer\]\]/i, '\1')
    template_body   = template_body.gsub(/\[\[link\/detail_url\]\]/i, entry.public_uri)
    template_body   = template_body.gsub(/\[\[view\/map\]\]/i, render_map(entry))
    return_body = nil
    files = entry.files
    db.items.inject(template_body.to_s) do |body, item|
      replace_body = (type == :list || type == :detail) && item.is_limited_access ? '' : entry_item_value(item, entry, files)
      body.gsub(/\[\[item\/#{item.name}\]\]/i, replace_body)
    end
  end

  def entry_item_value(item, entry, files)
    return nil if item.blank? || entry.blank?
    value = entry.item_values[item.name].present? ? entry.item_values[item.name] : ''
    case item.item_type
    when 'text_area'
      value = br(value) if value.present?
    when 'attachment_file'
      if file = files.detect {|f| f.name == value }
        if file.image_is == 1
          value = content_tag('image', '', src: "file_contents/#{file.name}", title: file.title)
        else
          value = content_tag('a', file.united_name, href: "file_contents/#{file.name}", class: file.css_class)
        end
      end
    when 'select_data', 'radio_data'
      if select_data = item.item_options_for_select_data
        select_data.each{|e| value = e[0] if e[1]== entry.item_values[item.name].to_i }
      end
    when 'blank_date'
      blank_dates = []
      thead = content_tag(:thead) do
        content_tag(:tr) do
          entry.dates.where(name: item.name).each{|e|
            blank_dates << e.option_value
            concat content_tag(:th, e.event_date.strftime("%m/%d"), class: "text-center")
          }
        end
      end
      tbody = content_tag(:tbody) do
        content_tag(:tr, class: "text-center") do
          blank_dates.each_with_index do |k, v|
            concat content_tag(:td, k)
          end
        end
      end
      value = content_tag(:table, class: item.name) do
        thead + tbody
      end
    when 'blank_weekday'
      if entry.item_values.dig(item.name, 'weekday')
        thead = content_tag(:thead) do
          content_tag(:tr, class: "text-center") do
            entry.item_values[item.name]['weekday'].each do |k, v|
              concat content_tag(:th, entry.class::WEEKDAY_OPTIONS[k.to_i])
            end
          end
        end
        tbody = content_tag(:tbody) do
          content_tag(:tr, class: "text-center") do
            entry.item_values[item.name]['weekday'].each do |k, v|
              concat content_tag(:td, v)
            end
          end
        end
        value = content_tag(:table, class: item.name) do
          thead + tbody
        end
      else
        value = ""
      end
    when 'ampm'
      if entry.item_values[item.name]
        thead = content_tag(:thead) do
          content_tag(:tr, class: "text-center") do
            concat content_tag(:th, "")
            entry.class::WEEKDAY_OPTIONS.each { |w|
              concat content_tag(:th, w)
            }
          end
        end
        amtbody = content_tag(:tbody) do
          content_tag(:tr, class: "text-center") do
            concat content_tag(:th, "午前")
            8.times do |i|
              v = entry.item_values[item.name]['am'].present? && entry.item_values[item.name]['am'][i.to_s]
              concat content_tag(:td, (v ? '○' : '×'))
            end
          end
        end
        pmtbody = content_tag(:tbody) do
          content_tag(:tr, class: "text-center") do
            concat content_tag(:th, "午後")
            8.times do |i|
              v = entry.item_values[item.name]['pm'].present? && entry.item_values[item.name]['pm'][i.to_s]
              concat content_tag(:td, (v ? '○' : '×'))
            end
          end
        end
        value = content_tag(:table, class: item.name) do
          thead + amtbody + pmtbody
        end
      else
        value = ""
      end
    when 'office_hours'
      tbody = content_tag(:tbody) do
        tags = []
        8.times do |i|
          w = entry.class::WEEKDAY_OPTIONS[i]
          open_at = entry.item_values.dig(item.name, 'open', i.to_s)
          close_at = entry.item_values.dig(item.name, 'close', i.to_s)
          Rails.logger.debug [open_at, close_at]
          next if open_at.blank? && close_at.blank?
          tags << content_tag(:tr) do
            concat content_tag(:th, w)
            concat content_tag(:td, "#{open_at}　～　#{close_at}")
          end
        end
        safe_join tags
      end
      rbody = content_tag(:tbody) do
        content_tag(:tr, class: "text-center") do
          concat content_tag(:th, "備考")
          concat content_tag(:td, entry.item_values.dig(item.name, 'remark'))
        end
      end
      value = content_tag(:table, class: item.name) do
        tbody + rbody
      end
    when 'check_box', 'check_data'
      value = entry.item_values.dig(item.name, 'text').present? ? entry.item_values[item.name]['text'] : ''
    else
      uri_reg = URI.regexp(%w[http https])
      value.gsub!(uri_reg) {%Q{<a href="#{$&}">#{$&}</a>}} if value.present?
    end
    value.html_safe
  end

  def render_map(item)
    render 'cms/public/_partial/maps/view', item: item
  end

  def map_icon(icon_id, db)
    icon_column = db.items.icon_items.first
    return nil if icon_column.blank? || icon_column.icon_item.try(:name).blank?
    icon = Webdb::Entry.find_by(id: icon_id)
    return nil if icon.blank? || icon.item_values.blank?
    return icon.item_values[icon_column.icon_item.try(:name)]
  end

end
