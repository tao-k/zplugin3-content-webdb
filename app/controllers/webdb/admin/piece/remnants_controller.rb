# Controller For Managing Piece Settings
class Webdb::Admin::Piece::RemnantsController < Cms::Admin::Piece::BaseController
  private

  def base_params_item_in_settings
    [:target_db_id, :target_field_id]
  end
end
