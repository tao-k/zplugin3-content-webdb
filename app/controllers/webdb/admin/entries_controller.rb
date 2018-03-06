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
      @items = @items.paginate(page: params[:page], per_page: 30)
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
    data = CSV.generate(force_quotes: true) do |csv|
      colums = [ "ID", "タイトル" ] + db_items.pluck(:title)
      csv << colums
      entries.each do |entry|
        item_array = [entry.id, entry.title]
        files = entry.files
        db_items.each do |item|
          value = entry.item_values[item.name]
          case item.item_type
          when 'ampm', 'office_hours', 'blank_weekday', 'check_box', 'check_data'
            value = entry.item_values[item.name].blank? ? nil : entry.item_values[item.name]['text']
          when 'select_data', 'radio_data'
            if select_data = item.item_options_for_select_data
              select_data.each{|e| value = e[0] if e[1]== entry.item_values[item.name].to_i }
            end
          end
          item_array << value
        end
        csv << item_array
      end
    end

    data = NKF.nkf('-s', data)
    send_data data, type: 'text/csv', filename: "#{@db.title}_データ一覧_#{Time.now.to_i}.csv"
  end


end
