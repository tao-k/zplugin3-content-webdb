class Webdb::Publisher::DbCallbacks < PublisherCallbacks
  def enqueue(item)
    @item = item
    return unless enqueue?
    enqueue_pieces
  end

  private

  def enqueue?
    return unless super
    @item.state.in?(%w(public closed draft))
  end

  def enqueue_pieces
    pieces = @item.content.public_pieces
    Cms::Publisher::PieceCallbacks.new.enqueue(pieces)
  end

end
