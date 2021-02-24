# frozen_string_literal: true

module ObsGithubDeployments
  class Deployment
    attr_reader :client, :access_token

    def initialize(repository:, access_token:, ref: "main")
      @client = Octokit::Client.new(access_token: access_token)
      # TODO: We could also receive the repository and pass it to the queries. It's always the same though... it can be hard-coded for now
      @repository = repository
      @ref = ref

      # FIXME: As described in ObsGithubDeployments::API, it shouldn't be needed to pass the access token with every query...
      @access_token = ObsGithubDeployments::API::AccessToken
    end

    def example
      result = ObsGithubDeployments::API::Client.query(ObsGithubDeployments::API::Queries::Example, variables: {}, context: { access_token: @access_token })
      result.data.viewer.login
    end

    # def locked?
    #   # Nothing stops us to deploy for the first time, so not having deployments means unlocked.
    #   local_status = latest_status
    #   return false unless local_status

    #   local_status.state == "queued"
    #   # TODO: handle the possible exceptions properly
    # end

    def locked?
      result = ObsGithubDeployments::API::Client.query(
        ObsGithubDeployments::API::Queries::LastDeploymentState,
        variables: {},
        context: { access_token: @access_token }
      )

      if result.errors.any?
        # TODO: Decide how we proceed with errors
        return 'ERROR'
      end

      # The safe navigation operator is needed for state since it's possible that there are no deployments for the repository
      state = result.data.repository.deployments.nodes.first.&state
      state == "queued"
    end

    def lock(reason:)
      raise ObsGithubDeployments::Deployment::NoReasonGivenError if reason.blank?

      deployment = latest

      if deployment.blank?
        create_and_set_state(state: "queued", payload: payload_reason(reason: reason))
        return true
      end

      deployment_status = latest_status

      raise ObsGithubDeployments::Deployment::PendingError if deployment_status.blank?
      raise ObsGithubDeployments::Deployment::AlreadyLockedError if deployment_status.state == "queued"

      true if create_and_set_state(state: "queued", payload: payload_reason(reason: reason))
    end

    def unlock
      deployment_status = latest_status

      if deployment_status.blank? || deployment_status.state != "queued"
        raise ObsGithubDeployments::Deployment::NothingToUnlockError
      end

      add_state(deployment: latest, state: "inactive")
      true
    end

    private

    def all
      client.deployments(@repository)
    end

    def create(payload:)
      options = { auto_merge: false }
      options[:payload] = payload if payload

      @client.create_deployment(@repository, @ref, options)
    end

    def add_state(deployment:, state:)
      options = { accept: "application/vnd.github.flash-preview+json" }
      options[:accept] = "application/vnd.github.ant-man-preview+json" if state == "inactive"

      @client.create_deployment_status(deployment.url, state, options)
    end

    def create_and_set_state(state:, payload:)
      deployment = create(payload: payload)
      add_state(deployment: deployment, state: state)
    end

    def payload_reason(reason:)
      "{\"reason\": \"#{reason}\"}"
    end
  end
end
