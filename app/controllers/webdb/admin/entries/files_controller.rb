class Webdb::Admin::Entries::FilesController < Cms::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base

  def pre_dispatch
    @content = Webdb::Content::Db.find(params[:content])
    return error_auth unless Core.user.has_priv?(:read, item: @content.concept)
    @db = @content.dbs.find(params[:db_id])
    @entry = @db.entries.find(params[:entry_id])
  end

  def content
    params[:name] = File.basename(params[:path])
    params[:type] = :thumb if params[:path] =~ /(\/|^)thumb\//

    file = @entry.files.find_by!(name: "#{params[:name]}.#{params[:format]}")
    send_file file.upload_path(type: params[:type]), filename: file.name
  end
end
