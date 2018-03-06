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
    when 'ampm', 'office_hours', 'blank_weekday', 'check_box', 'check_data'
      if entry.item_values[item.name].present?
        value =  entry.item_values[item.name]['text']
      else
        value = ''
      end
    else
      uri_reg = URI.regexp(%w[http https])
      value.gsub!(uri_reg) {%Q{<a href="#{$&}">#{$&}</a>}} if value.present?
    end
    value
  end

  def render_map(item)
    render 'cms/public/_partial/maps/view', item: item
  end
end
