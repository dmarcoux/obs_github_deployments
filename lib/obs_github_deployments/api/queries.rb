module ObsGithubDeployments::API::Queries
  Example = ObsGithubDeployments::API::Client.parse <<-'GRAPHQL'
  query {
        viewer {
          login
        }
      }
  GRAPHQL

  LastDeploymentState = ObsGithubDeployments::API::Client.parse <<-'GRAPHQL'
      query {
        repository(owner: "openSUSE", name: "open-build-service") {
          deployments(last: 1) {
            nodes {
              state
            }
          }
        }
      }
  GRAPHQL
end
