# frozen_string_literal: true

require 'hako'
require 'hako/env_providers'
require 'hako/loader'
require 'json'
require 'jsonnet'

module Hako
  class JsonnetLoader
    def initialize(no_expand)
      @vm = Jsonnet::VM.new
      define_provider_functions(no_expand)
    end

    def load(path)
      @root_path = path.parent
      JSON.parse(@vm.evaluate_file(path.to_s))
    ensure
      @root_path = nil
    end

    private

    def define_provider_functions(no_expand)
      Gem.loaded_specs.each do |gem_name, spec|
        spec.require_paths.each do |path|
          Dir.glob(File.join(spec.full_gem_path, path, 'hako/env_providers/*.rb')).each do |provider_path|
            provider_name = File.basename(provider_path, '.rb')
            provider_class = Loader.new(Hako::EnvProviders, 'hako/env_providers').load(provider_name)
            Hako.logger.debug("Loaded #{provider_class} from '#{gem_name}' gem")
            @vm.define_function("provide.#{provider_name}") do |options, name|
              if no_expand
                "\#{#{name}}"
              else
                provider_class.new(@root_path, JSON.parse(options)).ask([name]).fetch(name)
              end
            end
          end
        end
      end
    end
  end
end
