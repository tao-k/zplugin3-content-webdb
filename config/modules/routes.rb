mod = "webdb"
ZomekiCMS::Application.routes.draw do
  ## admin
  scope "#{ZomekiCMS::ADMIN_URL_PREFIX}/#{mod}/c:concept", :module => mod, :as => mod do
    resources :content_base,
      :controller => 'admin/content/base'

    resources :content_settings, :only => [:index, :show, :edit, :update],
      :controller => 'admin/content/settings',
      :path       => ':content/content_settings'

  #  ## contents
    resources(:dbs,
      :controller => 'admin/dbs',
      :path       => ':content/dbs') do
      resources :items,
        :controller => 'admin/items'
      resources :entries,
        :controller => 'admin/entries' do
          get 'file_contents/(*path)' => 'admin/entries/files#content'
          collection do
            post :import
            get  :import
          end
        end
      end

    ## nodes
    resources :node_dbs,
      :controller => 'admin/node/dbs',
      :path       => ':parent/node_dbs'

    resources :node_remnants,
      :controller => 'admin/node/remnants',
      :path       => ':parent/node_remnants'

    ## pieces
    resources :piece_forms,
      :controller => 'admin/piece/forms'
    resources :piece_maps,
      :controller => 'admin/piece/maps'
  end


  ## public
  scope "_public/#{mod}", :module => mod, :as => '' do
    #db search
    get  'node_dbs(/index)'            => 'public/node/dbs#index'
    get  'node_dbs/list(/index)'       => 'public/node/dbs#editors'
    get  'node_dbs/:id(/index)'        => 'public/node/dbs#show'
    get  'node_dbs/:db_id/map'         => 'public/node/dbs#map'
    get  'node_dbs/:db_id/search'      => 'public/node/dbs#result'
    get  'node_dbs/:db_id/entry/:name(/index)' => 'public/node/dbs#entry'
    get  'node_dbs/:db_id/entry/:name/file_contents/(*path)' => 'public/node/dbs#file_content'
    get  'node_dbs/:db_id/edit/:name(/index)' => 'public/node/dbs#edit'
    put  'node_dbs/:db_id/edit/:name(/index)' => 'public/node/dbs#update'

    ## remnants
    get  'node_remnants(/index)'         => 'public/node/remnants#index'
    get  'node_remnants/:id(/index)'     => 'public/node/remnants#show'
  end

end
