class Webdb::EntriesFinder < ApplicationFinder
  def initialize(db, entries)
    @db = db
    @entries = entries
  end

  def search(criteria, keyword, sort_key)
    @db.items.target_search_state.each do |item|
      value = criteria[item.name.to_sym]
      next if value.blank?
      case item.item_type
      when 'check_box', 'check_data'
        @entries = @entries.where("item_values -> '#{item.name}' -> 'check' ?| array[:keys]", keys: value)
      when 'ampm'
        am_idx = value['am'].present? ? value['am'].keys : []
        pm_idx = value['pm'].present? ? value['pm'].keys : []
        if am_idx.present? && pm_idx.present?
          @entries = @entries.where(
            "(item_values -> '#{item.name}' -> 'am' ?| array[:am_keys]) OR" +
            "(item_values -> '#{item.name}' -> 'pm' ?| array[:pm_keys])", am_keys:am_idx, pm_keys: pm_idx
            )
        elsif am_idx.present?
          @entries = @entries.where("item_values -> '#{item.name}' -> 'am' ?| array[:keys]", keys: am_idx)
        elsif pm_idx.present?
          @entries = @entries.where("item_values -> '#{item.name}' -> 'pm' ?| array[:keys]", keys: pm_idx)
        end
      else
        if value.kind_of?(Array)
          @entries = @entries.where("item_values ->> '#{item.name}' IN(:keys)", keys: value)
        else
          @entries = @entries.where("item_values ->> '#{item.name}' like :keyword", keyword: "%#{value}%")
        end
      end
    end

    keyword_columns = @db.items.target_keyword_state.pluck(:name)
    if keyword && keyword_columns
      queries = keyword_columns.map{|w| %Q(item_values ->> '#{w}' like :keyword)}
      @entries = @entries.where(queries.join(" OR "), keyword: "%#{keyword}%")
    end

    sort_columns = @db.items.target_sort_state.pluck(:name)
    if sort_key && sort_columns
      key, order  = sort_key.split(/\s/)
      if idx = sort_columns.index(key)
        @entries = @entries.order("item_values -> '#{sort_columns[idx]}' #{ordering(order)}")
      end
    end
    @entries
  end

  private

  def arel_table
    @entries.arel_table
  end

  def ordering(order)
    order == "desc" ? "DESC" : "ASC"
  end

end
