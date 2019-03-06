defmodule Companies.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Start the Ecto repository
      Companies.Repo,
      # Start the endpoint when the application starts
      CompaniesWeb.Endpoint,
      # Supervisor to run one-off tasks like email sending
      {Task.Supervisor, name: Companies.TaskSupervisor}
    ]

    children =
      if Application.get_env(:companies, :jobs_url_checker)[:enabled] do
        children ++ [{Companies.JobChecker.Scheduler, name: Companies.JobChecker.Scheduler}]
      else
        children
      end

    :telemetry.attach(
      "elixir-companies-ecto",
      [:companies, :repo, :query],
      &Appsignal.Ecto.handle_event/4,
      nil
    )

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Companies.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    CompaniesWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
