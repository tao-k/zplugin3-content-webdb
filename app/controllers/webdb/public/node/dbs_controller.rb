class Webdb::Public::Node::DbsController < Cms::Controller::Public::Base
  skip_after_action :render_public_layout, :only => [:file_content, :qrcode]
  before_action :login_users, except: [:index, :editors]
  before_action :set_target_date_idx, except: [:index, :show, :destroy]

  def pre_dispatch
    @content = ::Webdb::Content::Db.find_by(id: Page.current_node.content.id)
    return http_error(404) unless @content
    @node = Page.current_node
    if params[:db_id]
      @db    = @content.public_dbs.find_by(id: params[:db_id])
      return http_error(404) unless @db
    end
  end

  def index
    @dbs = @content.public_dbs
  end

  def show
    @db    = @content.public_dbs.find_by(id: params[:id])
    return http_error(404) unless @db
    Page.title = @db.title
    @items = @db.public_items.target_search_state
  end

  def remnant
    @db    = @content.public_dbs.find_by(id: params[:db_id])
    return http_error(404) unless @db
    Page.title = @db.title
    @date_items = @db.public_items.item_type_is('blank_date')
    @number_items = @db.public_items.item_type_is('blank_integer')
    @week_items = @db.public_items.item_type_is('blank_weekday')
    @search_url = "#{@node.try(:public_uri)}#{@db.id}/search"
  end

  def result
    @list_style = @member_user.present? || @editor_user.present? ? :member_list : :list
    Page.title = @db.title
    @entries = @db.entries.public_state
    criteria = entry_criteria
    @items = Webdb::EntriesFinder.new(@db, @entries).search(criteria, keyword, sort_key)
      .paginate(page: params[:page], per_page: @db.display_limit || params[:limit])
  end


  def file_content
    @entry = @db.entries.find_by(name: params[:name])
    params[:file] = File.basename(params[:path])
    params[:type] = :thumb if params[:path] =~ /(\/|^)thumb\//

    file = @entry.files.find_by!(name: "#{params[:file]}.#{params[:format]}")
    send_file file.upload_path(type: params[:type]), filename: file.name
  end

  def entry
    @list_style = @member_user.present? || @editor_user.present? ? :member_detail : :detail
    @item = @db.entries.find_by(name: params[:name])
    return http_error(404) unless @item
    title_item = @db.items.public_state.first
    Page.title = @item.item_values.dig(title_item.name) if title_item
  end

  def editors
    @items = []
    @content.dbs.each do |db|
      @db = db
      login_users
      next if @editor_user.blank?
      entries = db.entries.where(editor_id: @editor_user.id)
      next if entries.blank?
      @items.concat(entries)
    end
  end

  def edit
    entry
    return http_error(404) if @editor_user.blank?
    return http_error(404) if @editor_user.id != @item.editor_id
  end

  def update
    entry
    return http_error(404) if @editor_user.blank?
    return http_error(404) if @editor_user.id != @item.editor_id
    @item.attributes = entry_params
    if @item.save
      return redirect_to "#{@node.public_uri}list/"
    else
      render :edit
    end
  end

  def delete_event
    entry
    return http_error(404) if @editor_user.blank?
    @event = @item.dates.find_by(id: params[:event_id])
    return http_error(404) unless @event
    if @event.destroy
      render plain: "OK"
    else
      render plain: "NG"
    end
  end

  private

  def login_users
    return if @db.blank?
    @member_user = @db.member_content ? @db.member_content.login_user : nil
    @editor_user = @db.editor_content ? @db.editor_content.login_user : nil
  end

  def entry_criteria
    params[:criteria] ? params[:criteria].to_unsafe_h : {}
  end

  def sort_key
    params[:sort] ? params[:sort] : nil
  end

  def keyword
    params[:keyword] ? params[:keyword] : nil
  end


  def entry_params
    params.require(:item).permit(:title, :editor_id, :item_values, :in_target_date,
      :maps_attributes => [:id, :name, :title, :map_lat, :map_lng, :map_zoom,
      :markers_attributes => [:id, :name, :lat, :lng]]).tap do |whitelisted|
      whitelisted[:item_values] = params[:item][:item_values].permit! if params[:item][:item_values]
      whitelisted[:in_target_dates] = params[:item][:in_target_dates].permit! if params[:item][:in_target_dates]
    end
  end

  def set_target_date_idx
    @date_idx = 0
  end

end