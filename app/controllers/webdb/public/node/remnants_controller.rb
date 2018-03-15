class Webdb::Public::Node::RemnantsController < Cms::Controller::Public::Base
  skip_after_action :render_public_layout, :only => [:file_content, :qrcode]

  def pre_dispatch
    @content = ::Webdb::Content::Db.find_by(id: Page.current_node.content.id)
    return http_error(404) unless @content
    @node = Page.current_node
    @main_node = @content.public_node
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
    @date_items = @db.public_items.item_type_is('blank_date')
    @number_items = @db.public_items.item_type_is('blank_integer')
    @week_items = @db.public_items.item_type_is('blank_weekday')
    @search_url = "#{@main_node.try(:public_uri)}#{@db.id}/search"
  end

  def result
    @list_style = @member_user.present? || @editor_user.present? ? :member_list : :list
    Page.title = @db.title
    @entries = @db.entries.public_state
    criteria = entry_criteria
    @items = Webdb::EntriesFinder.new(@db, @entries).search(criteria, keyword, sort_key)
      .paginate(page: params[:page], per_page: @db.display_limit || params[:limit])
  end

  private

  def entry_criteria
    params[:criteria] ? params[:criteria].to_unsafe_h : {}
  end

  def sort_key
    params[:sort] ? params[:sort] : nil
  end

  def keyword
    params[:keyword] ? params[:keyword] : nil
  end

end