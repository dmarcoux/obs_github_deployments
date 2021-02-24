module ObsGithubDeployments::API
  AccessToken = ENV.fetch('GITHUB_TOKEN', 'NO ACCESS TOKEN PROVIDED')

  HTTP = GraphQL::Client::HTTP.new('https://api.github.com/graphql') do
    def headers(context)
      { "Authorization": "bearer #{context[:access_token]}" }
    end
  end

  # TODO:
  # Dumping the schema should be done somewhere else, maybe a rake task as recommended in upstream in graphql-client's documentation.
  # The access token is not available in the headers (see above), even though it's passed here.
  # Somehow the changes from https://github.com/github/graphql-client/pull/196 don't work. For now, we pass the access token in the context of every query.
  Schema = GraphQL::Client.load_schema(GraphQL::Client.dump_schema(HTTP, nil, context: { access_token: AccessToken }))

  Client = GraphQL::Client.new(schema: Schema, execute: HTTP)
end
