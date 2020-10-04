defmodule PearsWeb.PageLive do
  use PearsWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event("validate_name", %{"team-name" => team_name}, socket) do
    case Pears.validate_name(team_name) do
      :ok -> {:noreply, clear_flash(socket)}
      error -> handle_validation_error(error, socket, team_name)
    end
  end

  @impl true
  def handle_event("create_team", %{"team-name" => team_name}, socket) do
    case Pears.add_team(team_name) do
      {:ok, team} ->
        {:noreply,
         socket
         |> put_flash(:info, "Congratulations, your team has been created!")
         |> redirect(to: Routes.team_path(socket, :show, team))}

      error ->
        handle_validation_error(error, socket, team_name)
    end
  end

  defp handle_validation_error({:error, :name_taken}, socket, team_name) do
    {:noreply, put_flash(socket, :error, "Sorry, the name \"#{team_name}\" is already taken")}
  end

  defp handle_validation_error({:error, :name_blank}, socket, _team_name) do
    {:noreply, put_flash(socket, :error, "Sorry, team name cannot be blank")}
  end

  defp handle_validation_error({:error, _}, socket, team_name) do
    {:noreply, put_flash(socket, :error, "Sorry, the name \"#{team_name}\" is not valid")}
  end
end
