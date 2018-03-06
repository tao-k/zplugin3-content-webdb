class Webdb::Public::Piece::FormsController < Sys::Controller::Public::Base
  def pre_dispatch
    @piece = Webdb::Piece::Form.find_by(id: Page.current_piece.id)
    render plain: '' if @piece.nil?
    @content = @piece.content
    @db      = @piece.target_db
    @node    = @content.public_node
    render plain: '' if @db.nil?
  end

  def index
    @items = @db.public_items.target_search_state
  end

end
