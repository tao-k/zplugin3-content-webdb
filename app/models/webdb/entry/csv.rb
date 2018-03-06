class Webdb::Entry::Csv < Webdb::Csv
  default_scope { where(:csv_type => self.name) }

  def parse_line(row, i)

    line = csv_lines.build(:line_no => i+2, :data => row.fields, :data_type => 'Webdb::Entry')

    entry = db.entries.where(id: row['ID']).first || db.entries.new
    entry_attributes = {}
    entry_attributes['db_id'] = db.id
    entry_attributes['id']    = row['ID']
    entry_attributes['title'] = row['タイトル']
    json_attributes = {}
    in_target_dates = {}
    date_idx = 0
    db.items.each do |item|
      if row[item.title].blank?
        json_attributes[item.name] = nil
        next
      end
      case item.item_type
      when 'check_box'
        json_attributes[item.name] = {}
        checks = []
        row[item.title].split(/／/).each_with_index do |w, n|
          checks << w
        end
        json_attributes[item.name]['check'] = checks
      when 'check_data'
        json_attributes[item.name] = {}
        checks = []
        row[item.title].split(/／/).each{|w|
          item.item_options_for_select_data.each{|a| checks << a[1].to_s if a[0] == w}
        }
        json_attributes[item.name]['check'] = checks
      when 'office_hours'
        json_attributes[item.name] = {}
        json_attributes[item.name]['open'] = {}
        json_attributes[item.name]['close'] = {}
        row[item.title].split(/／/).each do |d|
          week = d.gsub(/(.*)：(.*)/, '\1')
          opt = d.gsub(/(.*)：(.*)/, '\2')
          idx = entry.class::WEEKDAY_OPTIONS.index(week)
          if idx.present?
            hours = opt.split(/～/)
            json_attributes[item.name]['open'][idx.to_s]  = hours[0]
            json_attributes[item.name]['close'][idx.to_s] = hours[1]
          else
            json_attributes[item.name]['remark'] = opt
          end
        end
      when 'blank_weekday'
        json_attributes[item.name] = {}
        json_attributes[item.name]['weekday']= {}
        row[item.title].split(/／/).each do |d|
          week = d.gsub(/(.*)：(.*)/, '\1')
          opt = d.gsub(/(.*)：(.*)/, '\2')
          idx = entry.class::WEEKDAY_OPTIONS.index(week)
          next if idx.blank?
          json_attributes[item.name]['weekday'][idx.to_s] = opt
        end
      when 'blank_date'
        row[item.title].split(/／/).each do |d|
          date_val = d.split(/：/)
          in_target_dates[date_idx.to_s] = {
            option_value: date_val[1],
            name: item.name,
            event_date: date_val[0]
          }
          date_idx += 1
        end
      when 'ampm'
        json_attributes[item.name] = {}
        json_attributes[item.name]['am'] = {}
        json_attributes[item.name]['pm'] = {}
        row[item.title].split(/／/).each do |d|
          w = d.scan(/(.*?)(\s|　)午前：(.*?)(\s|　)午後：(.*)/)
          next if w.blank?
          idx = entry.class::WEEKDAY_OPTIONS.index(w[0][0])
          next if idx.blank?
          json_attributes[item.name]['am'][idx.to_s] = w[0][2].present? && w[0][2] == '○'
          json_attributes[item.name]['pm'][idx.to_s] = w[0][4].present? && w[0][4] == '○'
        end
      else
        json_attributes[item.name] = row[item.title]
      end
    end

    entry_attributes[:item_values] = json_attributes

    entry_attributes.each do |key , value|
      next if key == :rid
      entry[key] = value
    end
    entry.validate
    line.data_attributes = {
      entry_attributes: entry_attributes,
      date_attributes: in_target_dates
    }
    line.data_invalid = entry.errors.blank? ? 0 : 1
    line.data_errors = entry.errors.full_messages.to_a if entry.errors.present?
    line
  end

  def register(line)
    entry_attributes = line.csv_data_attributes['entry_attributes']
    date_attributes  = line.csv_data_attributes['date_attributes']
    entry = db.entries.where(id: entry_attributes['id']).first || db.entries.new
    entry_attributes.each do |key , value|
      next if key == :id
      entry[key] = value
    end
    entry.in_target_dates = date_attributes.with_indifferent_access if date_attributes.present?

    entry.save
    entry
  end
end
