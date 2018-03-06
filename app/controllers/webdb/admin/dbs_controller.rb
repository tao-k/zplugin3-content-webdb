# Controller For Managing Data
class Webdb::Admin::DbsController < Cms::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout  'admin/cms'

  def pre_dispatch
    @content = Webdb::Content::Db.find(params[:content])
    return error_auth unless Core.user.has_priv?(:read, item: @content.concept)
  end

  def index
    items = @content.dbs
    @items = items.paginate(page: params[:page], per_page: params[:limit])
    respond_to do |format|
      format.html { render }
      format.json  { render :json => items.to_json }
    end
  end

  def show
    @item = @content.dbs.find(params[:id])
    return error_auth unless @item.readable?
    _show @item
  end

  def new
    @item = @content.dbs.new
  end

  def create
    @item = @content.dbs.new(db_params)
    _create(@item)
  end

  def update
    @item = @content.dbs.find(params[:id])
    return error_auth if !Core.user.root? && @item.root?
    @item.attributes = db_params
    _update(@item)
  end

  def destroy
    @item = @content.dbs.find(params[:id])
    return error_auth if !Core.user.root? && @item.root?
    _destroy(@item)
  end

  private

  def db_params
    params.require(:item).permit(:body, :list_body, :detail_body, :sort_no, :state, :title,
      :member_list_body, :member_detail_body, :display_limit,
      :member_content_id, :editor_content_id,
      :creator_attributes => [:id, :group_id, :user_id])
  end
end