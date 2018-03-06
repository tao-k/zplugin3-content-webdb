module Zplugin3
  module Content
    module Webdb
      class Engine < ::Rails::Engine
        config.autoload_paths << File.expand_path("../../../../../lib", __FILE__)
        #config.paths.add "../../../../lib", eager_load: true
        config.after_initialize do |app|
          app.config.x.engines << self
        end
      end
    end
  end
end
