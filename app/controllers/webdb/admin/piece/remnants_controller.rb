# Controller For Managing Piece Settings
class Webdb::Admin::Piece::RemnantsController < Cms::Admin::Piece::BaseController

  def update
    item_in_settings = (params[:item][:in_settings] || {})

    if target_field_ids = params[:target_field_id]
      item_in_settings[:target_field_ids] = target_field_ids.join(' ')
    else
      item_in_settings[:target_field_ids] = ''
    end

    params[:item][:in_settings] = item_in_settings

    super
  end

  private

  def base_params_item_in_settings
    [:target_db_id, :target_field_ids]
  end
end
