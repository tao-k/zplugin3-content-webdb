class Webdb::Public::Piece::RemnantsController < Sys::Controller::Public::Base
  def pre_dispatch
    @piece = Webdb::Piece::Remnant.find_by(id: Page.current_piece.id)
    return render plain: '' if @piece.blank?
    @content = @piece.content
    @db      = @piece.target_db
    @node    = @content.public_node
    return render plain: '' if @db.blank?
  end

  def index
    @items = @piece.target_fields
  end

end
