class Webdb::Public::Piece::MapsController < Sys::Controller::Public::Base
  def pre_dispatch
    @piece = Webdb::Piece::Map.find_by(id: Page.current_piece.id)
    render plain: '' if @piece.nil?
    @content = @piece.content
    @db      = @piece.target_db
    render plain: '' if @db.nil?
  end

  def index
    @items   = @db.entries.public_state
    @markers = @items.joins(maps: :markers)
    markers = []
    @markers.each do |entry|
      markers << entry.map_marker
    end
    @all_markers = markers.flatten
  end

end
