# frozen_string_literal: true

require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect("cli" => "CLI")
loader.inflector.inflect("api" => "API")
loader.setup

require "active_support/core_ext/object/blank"
require "graphql/client"
require "graphql/client/http"

module ObsGithubDeployments
  class Error < StandardError; end
end
