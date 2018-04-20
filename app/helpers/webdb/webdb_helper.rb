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
    template_body = template_body.html_safe
    template_body = template_body.gsub(/\[\[link\/detail_url\]\]/i, entry.public_uri)
    template_body = template_body.gsub(/\[\[view\/map\]\]/i, render_map(entry)) if template_body =~ /\[\[view\/map\]\]/
    return_body = nil
    files = entry.files
    db.items.inject(template_body.to_s) do |body, item|
      replace_body = (type == :list || type == :detail) && item.is_limited_access ? '' : entry_item_value(item, entry, files)
      body.gsub(/\[\[item\/#{item.name}\]\]/i, replace_body)
    end
  end

  def marker_window_text(entry, piece)
    window_text = piece.window_text
    if window_text.present?
      window_text = window_text.gsub(/\[\[link\/detail_url\]\]/i, entry.public_uri)
      entry.db.items.inject(window_text.to_s) do |body, item|
        replace_body = item.is_limited_access ? '' : entry_item_value(item, entry, [])
        body.gsub(/\[\[item\/#{item.name}\]\]/i, replace_body)
      end
    else
      first_item = entry.db.items.first
      return "" if first_item.blank?
      return entry.item_values[first_item.name]
    end
  end

  def entry_item_value(item, entry, files)
    return '' if item.blank? || entry.blank?
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
      else
        value = ''
      end
    when 'select_data', 'radio_data'
      if select_data = item.item_options_for_select_data
        select_data.each{|e| value = e[0] if e[1]== entry.item_values[item.name].to_i }
      end
    when 'blank_date'
      qp = query_params(request.fullpath)
      qs = query_string(qp)
      head = Date.parse(params[:date]) rescue Date.today
      tail = head.since(7.days)
      links = content_tag(:div, class:"week") do
        concat content_tag(:a, "前の週",
           href: %Q(#{qs}#{(qs.blank? ? '?' : '&')}date=#{head.ago(7.days).strftime("%Y-%m-%d")}), class: "prev")
        concat content_tag(:a, "次の週",
           href: %Q(#{qs}#{(qs.blank? ? '?' : '&')}date=#{tail.strftime("%Y-%m-%d")}), class: "next")
      end
      event_dates = entry.dates.where(name: item.name)
          .where(Webdb::EntryDate.arel_table[:event_date].gteq(head))
          .where(Webdb::EntryDate.arel_table[:event_date].lt(tail))
          .group_by {|item| item.event_date.strftime("%m/%d") }
      thead = content_tag(:thead) do
        content_tag(:tr) do
            (head..tail).each { |date|
              concat content_tag(:th, date.strftime("%m/%d"), class: "text-center")
            }
        end
      end
      tbody = content_tag(:tbody) do
        tags = []
        content_tag(:tr, class: "text-center") do
            (head..tail).each { |date|
              tags << content_tag(:td) do
                if event_dates[date.strftime("%m/%d")]
                  event_dates[date.strftime("%m/%d")].each{|d| concat d.option_value }
                end
              end
            }
            safe_join tags
        end
      end
      value = content_tag(:div, class: item.name) do
        content_tag(:table) do
          links + thead + tbody
        end
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
          open_at_am = entry.item_values.dig(item.name, 'open', i.to_s)
          close_at_am = entry.item_values.dig(item.name, 'close', i.to_s)
          open_at_pm = entry.item_values.dig(item.name, 'open2', i.to_s)
          close_at_pm = entry.item_values.dig(item.name, 'close2', i.to_s)
          next if open_at_am.blank? && close_at_am.blank? && open_at_pm.blank? && close_at_pm.blank?
          tags << content_tag(:tr) do
            concat content_tag(:th, w)
            concat content_tag(:th, "午前")
            concat content_tag(:td, (open_at_am.present? || close_at_am.present? ? "#{open_at_am}　～　#{close_at_am}" : ""))
            concat content_tag(:th, "午後")
            concat content_tag(:td, (open_at_pm.present? || close_at_pm.present? ? "#{open_at_pm}　～　#{close_at_pm}" : ""))
          end
        end
        safe_join tags
      end
      if entry.item_values.dig(item.name, 'remark').present?
        rbody = content_tag(:tbody) do
          content_tag(:tr, class: "text-center") do
            concat content_tag(:th, "備考")
            concat content_tag(:td, entry.item_values.dig(item.name, 'remark'), colspan: 4)
          end
        end
      else
        rbody = ""
      end
      value = content_tag(:table, class: item.name) do
        tbody + rbody
      end
    when 'check_box', 'check_data'
      if entry.item_values[item.name].present? && entry.item_values[item.name].kind_of?(Hash)
        value = entry.item_values.dig(item.name, 'text').present? ? entry.item_values[item.name]['text'] : ''
      else
        value = ''
      end
    when 'rich_text'
      value
    else
      uri_reg = URI.regexp(%w[http https])
      value.gsub!(uri_reg) {%Q{<a href="#{$&}" target="_blank">#{$&}</a>}} if value.present? && value =~ uri_reg
    end
    value.html_safe
  end

  def render_map(item)
    return render('webdb/public/shared/map_view', item: item) || ''
  end

  def map_icon(icon_id, db)
    icon_column = db.items.icon_items.first
    return nil if icon_column.blank? || icon_column.icon_item.try(:name).blank?
    icon = Webdb::Entry.find_by(id: icon_id)
    return nil if icon.blank? || icon.item_values.blank?
    return icon.item_values[icon_column.icon_item.try(:name)]
  end


  ## paginates
  def public_paginate(items, options = {})
    return '' unless items
    defaults = {
      :params         => p,
      :previous_label => '前',
      :next_label     => '次',
      :link_separator => '<span class="separator"> | </span' + "\n" + '>'
    }
    if request.mobile? && !request.smart_phone?
      defaults[:page_links]     = false
      defaults[:previous_label] = '&lt;&lt;*前へ'
      defaults[:next_label]     = '次へ#&gt;&gt;'
    end
    links = will_paginate(items, defaults.merge!(options))
    return links if links.blank?

    links.gsub!(/href="([^"]+)/im) do |m|
      qp = query_params(m)
      page = qp['page'].to_s =~ /^\d+$/ ? qp['page'].to_i : 1
      uri = Page.uri.dup
      qs = query_string(qp)
      %(href="#{uri.force_encoding('UTF-8')}#{qs.force_encoding('UTF-8')})
    end

    if request.mobile? && !request.smart_phone?
      if options[:previous_accesskey] && options[:next_accesskey]
        links.gsub!(/<a [^>]*?rel="prev( |")/) {|m| m.gsub(/<a /, "<a accesskey='#{options[:previous_accesskey]}' ")}
        links.gsub!(/<a [^>]*?rel="next( |")/) {|m| m.gsub(/<a /, "<a accesskey='#{options[:next_accesskey]}' ")}
      else
        links.gsub!(/<a [^>]*?rel="prev( |")/) {|m| m.gsub(/<a /, '<a accesskey="*" ')}
        links.gsub!(/<a [^>]*?rel="next( |")/) {|m| m.gsub(/<a /, '<a accesskey="#" ')}
      end
    end
    links.html_safe
  end

  def query_params(url)
    (url =~ /\?/) ? Rack::Utils.parse_query(url.gsub(/.*\?/, '').gsub(/&amp;/, '&')) : {}
  end

  def query_string(qp)
    qs = qp.size > 0 ? '?' + qp.map { |k, v|
        if v.kind_of?(Array)
          ret = v.map{|vp| "#{k}=#{vp}" }
          ret.join('&')
        else
          "#{k}=#{v}"
        end
      }.join('&') : ''
    qs
  end

end
