# frozen_string_literal: true

require 'jsonnet'
require 'json'
require 'hako/env_providers'
require 'hako/loader'

module Hako
  class JsonnetLoader
    def initialize
      @vm = Jsonnet::VM.new
      define_provider_functions
    end

    def load(path)
      @root_path = path.parent
      JSON.parse(@vm.evaluate_file(path.to_s))
    ensure
      @root_path = nil
    end

    private

    def define_provider_functions
      # TODO: List all available env providers
      %w[
        file
        yaml
      ].each do |provider_name|
        provider_class = Loader.new(Hako::EnvProviders, 'hako/env_providers').load(provider_name)
        @vm.define_function("provide.#{provider_name}") do |options, name|
          provider_class.new(@root_path, JSON.parse(options)).ask([name]).fetch(name)
        end
      end
    end
  end
end
