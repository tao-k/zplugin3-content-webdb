class Webdb::Admin::EntriesController < Cms::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  before_action :set_target_date_idx, except: [:index, :show, :destroy]

  def pre_dispatch
    @content = Webdb::Content::Db.find(params[:content])
    return error_auth unless Core.user.has_priv?(:read, item: @content.concept)
    @db = @content.dbs.find(params[:db_id])
  end

  def index
    @items = @db.entries
    if params[:csv]
      return export_csv(@items)
    else
      @items = @items.paginate(page: params[:page], per_page: 30).order(updated_at: :desc)
    end
    _index @items
  end

  def show
    @item = @db.entries.find(params[:id])
    _show @item
  end

  def new
    @item = @db.entries.build
  end

  def create
    @item = @db.entries.build(entry_params)
    new_state = params.keys.detect{|k| k =~ /^commit_/ }.try(:sub, /^commit_/, '')
    @item.state = new_state if new_state.present?

    _create @item
  end

  def update
    @item = @db.entries.find(params[:id])
    @item.attributes = entry_params
    new_state = params.keys.detect{|k| k =~ /^commit_/ }.try(:sub, /^commit_/, '')
    @item.state = new_state if new_state.present?

    _update @item
  end

  def destroy
    @item = @db.entries.find(params[:id])
    _destroy @item
  end

  def import
    if params.dig(:item, :file)
      item = Webdb::Entry::Csv.new
      item.db_id = @db.id
      item.file = params[:item][:file]
      if item.save
        flash[:notice] = "CSVの登録を完了しました。"
        Webdb::ImportEntryJob.perform_now(item.id)
        return redirect_to url_for({:action=>:import})
      else
        flash[:notice] = "CSVの解析に失敗しました。"
        return redirect_to url_for({:action=>:import})
      end
    end
  end

  def delete_event
    @item = @db.entries.find(params[:id])
    @event = @item.dates.find_by(id: params[:event_id])
    return http_error(404) unless @event
    if @event.destroy
      render plain: "OK"
    else
      render plain: "NG"
    end
  end

  private

  def set_target_date_idx
    @date_idx = 0
  end

  def entry_params
    params.require(:item).permit(:title, :editor_id, :item_values, :in_target_date,
      :maps_attributes => [:id, :name, :title, :map_lat, :map_lng, :map_zoom,
      :markers_attributes => [:id, :name, :lat, :lng]]).tap do |whitelisted|
      whitelisted[:item_values] = params[:item][:item_values].permit! if params[:item][:item_values]
      whitelisted[:in_target_dates] = params[:item][:in_target_dates].permit! if params[:item][:in_target_dates]
    end
  end

  def export_csv(entries)
    require 'csv'
    db_items = @db.items.public_state
    bom = %w(EF BB BF).map { |e| e.hex.chr }.join
    data = CSV.generate(bom, force_quotes: true) do |csv|
      columns = [ "ID", "状態" ]
      db_items.each do |item|
        case item.item_type
        when 'office_hours'
          8.times do |i|
            w = Webdb::Entry::WEEKDAY_OPTIONS[i]
            columns << "#{item.title}_#{w}_午前_開始"
            columns << "#{item.title}_#{w}_午前_終了"
            columns << "#{item.title}_#{w}_午後_開始"
            columns << "#{item.title}_#{w}_午後_終了"
          end
          columns << "#{item.title}_備考"
        else
          columns << item.title
        end
      end
      columns += ["緯度", "経度", "編集許可ログイン"]
      csv << columns
      entries.each do |entry|
        item_array = [entry.id, entry.state_text]
        files = entry.files
        db_items.each do |item|
          case item.item_type
          when 'office_hours'
            8.times do |i|
              item_array << entry.item_values.dig(item.name, 'open', i.to_s)
              item_array << entry.item_values.dig(item.name, 'close', i.to_s)
              item_array << entry.item_values.dig(item.name, 'open2', i.to_s)
              item_array << entry.item_values.dig(item.name, 'close2', i.to_s)
            end
            item_array << entry.item_values.dig(item.name, 'remark')
          when 'ampm', 'blank_weekday', 'check_box', 'check_data'
            item_array << entry.item_values.dig(item.name, 'text')
          when 'select_data', 'radio_data'
            val = ""
            if select_data = item.item_options_for_select_data
              select_data.each{|e| value = e[0] if e[1]== entry.item_values[item.name].to_i }
            end
            item_array << val
          else
            item_array << entry.item_values[item.name]
          end
        end
        latlng = []
        if map = entry.maps.first
          first_marker = map.markers.first
          item_array += [first_marker.lat, first_marker.lng] if first_marker
        end
        item_array += latlng
        item_array << entry.editor_user.try(:account)
        csv << item_array
      end
    end

    send_data data, type: 'text/csv', filename: "#{@db.title}_データ一覧_#{Time.now.to_i}.csv"
  end


end
