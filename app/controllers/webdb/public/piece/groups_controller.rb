class Webdb::Public::Piece::GroupsController < Sys::Controller::Public::Base
  def pre_dispatch
    @piece = Webdb::Piece::Group.find_by(id: Page.current_piece.id)
    return render plain: '' if @piece.nil?
    @content = @piece.content
    @db      = @piece.target_db
    @target_field = @piece.target_field
    @node    = @content.public_node
    return render plain: '' if @db.nil?
    return render plain: '' if @target_field.nil?
  end

  def index
    @reference_db = @target_field.reference_db
    return render plain: '' if @reference_db.blank?
    return render plain: '' unless @group_field = @piece.grouping_field
    return render plain: '' unless @value_field = @piece.value_field

    @groups = @reference_db.entries.public_state.map{|a|
        { group: a.item_values.dig(@group_field.name),
          title: a.item_values.dig(@value_field.name),
          value: a.id} }
    @forms = @groups.group_by{ |i| i[:group]}
  end

end
