defmodule PearsWeb.TeamLive do
  use PearsWeb, :live_view

  @impl true
  def mount(params, _session, socket) do
    {
      :ok,
      socket
      |> assign_team_or_redirect(params)
      |> assign(selected_pear: nil, selected_pear_track: nil, editing_track: nil)
      |> apply_action(socket.assigns.live_action)
    }
  end

  @impl true
  def handle_params(_params, _url, socket) do
    if connected?(socket), do: Pears.subscribe(team_name(socket))

    {:noreply, apply_action(socket, socket.assigns.live_action)}
  end

  def list_tracks(team) do
    team.tracks
    |> Enum.sort_by(fn {_, %{id: id}} -> id end)
    |> Enum.map(fn {_track_name, track} -> track end)
  end

  @impl true
  def handle_event("recommend-pears", _params, socket) do
    {:ok, team} = Pears.recommend_pears(socket.assigns.team.name)
    {:noreply, assign(socket, :team, team)}
  end

  @impl true
  def handle_event("reset-pears", _params, socket) do
    {:ok, team} = Pears.reset_pears(socket.assigns.team.name)
    {:noreply, assign(socket, :team, team)}
  end

  @impl true
  def handle_event("remove-track", %{"track-name" => track_name}, socket) do
    {:ok, team} = Pears.remove_track(socket.assigns.team.name, track_name)
    {:noreply, assign(socket, team: team)}
  end

  @impl true
  def handle_event("lock-track", %{"track-name" => track_name}, socket) do
    {:ok, team} = Pears.lock_track(socket.assigns.team.name, track_name)
    {:noreply, assign(socket, team: team)}
  end

  @impl true
  def handle_event("unlock-track", %{"track-name" => track_name}, socket) do
    {:ok, team} = Pears.unlock_track(socket.assigns.team.name, track_name)
    {:noreply, assign(socket, team: team)}
  end

  @impl true
  def handle_event("edit-track-name", %{"track-name" => track_name}, socket) do
    {:noreply, assign(socket, :editing_track, track_name)}
  end

  @impl true
  def handle_event("save-track-name", %{"new-track-name" => new_track_name}, socket) do
    track_name = socket.assigns.editing_track
    {:ok, team} = Pears.rename_track(team_name(socket), track_name, new_track_name)

    {
      :noreply,
      socket
      |> assign(team: team)
      |> cancel_editing_track()
    }
  end

  @impl true
  def handle_event(
        "pear-selected",
        %{"pear-name" => pear_name, "track-name" => track_name},
        socket
      ) do
    {:noreply, assign(socket, selected_pear: pear_name, selected_pear_track: track_name)}
  end

  @impl true
  def handle_event("pear-selected", %{"pear-name" => pear_name}, socket) do
    {:noreply, assign(socket, selected_pear: pear_name)}
  end

  @impl true
  def handle_event("unselect-pear", _params, socket) do
    {
      :noreply,
      socket
      |> unselect_pear()
      |> cancel_editing_track()
    }
  end

  @impl true
  def handle_event("record-pears", _params, socket) do
    case Pears.record_pears(socket.assigns.team.name) do
      {:ok, team} ->
        {
          :noreply,
          socket
          |> unselect_pear()
          |> cancel_editing_track()
          |> assign(team: team)
          |> put_flash(:info, "Today's assigned pears have been recorded!")
        }

      {:error, _} ->
        {
          :noreply,
          socket
          |> unselect_pear()
          |> cancel_editing_track()
          |> put_flash(:error, "Sorry! Something went wrong, please try again.")
        }
    end
  end

  @impl true
  def handle_event("unassign-pear", _params, socket) do
    team_name = socket.assigns.team.name

    with {:ok, pear_name} <- selected_pear(socket),
         {:ok, track_name} <- selected_track(socket),
         {:ok, team} <- Pears.remove_pear_from_track(team_name, pear_name, track_name) do
      {
        :noreply,
        socket
        |> unselect_pear()
        |> cancel_editing_track()
        |> assign(team: team)
      }
    else
      _ ->
        {
          :noreply,
          socket
          |> unselect_pear()
          |> cancel_editing_track()
        }
    end
  end

  @impl true
  def handle_event("track-clicked", %{"track-name" => track_name}, socket) do
    from_track = socket.assigns.selected_pear_track

    with {:ok, pear_name} <- selected_pear(socket),
         {:ok, team} <-
           Pears.move_pear_to_track(socket.assigns.team.name, pear_name, from_track, track_name) do
      {:noreply,
       socket
       |> assign(team: team)
       |> unselect_pear()
       |> cancel_editing_track()}
    else
      _ ->
        {:noreply, unselect_pear(socket)}
    end
  end

  @impl true
  def handle_info({Pears, [:team, :updated], team}, socket) do
    {:noreply, assign(socket, team: team)}
  end

  defp team_name(socket), do: socket.assigns.team.name

  defp selected_pear(socket) do
    case socket.assigns.selected_pear do
      nil -> {:error, :none_selected}
      pear_name -> {:ok, pear_name}
    end
  end

  defp selected_track(socket) do
    case socket.assigns.selected_pear_track do
      nil -> {:error, :none_selected}
      track_name -> {:ok, track_name}
    end
  end

  defp unselect_pear(socket) do
    assign(socket, selected_pear: nil, selected_pear_track: nil)
  end

  defp cancel_editing_track(socket) do
    assign(socket, :editing_track, nil)
  end

  defp assign_team_or_redirect(socket, %{"id" => name}) do
    case Pears.lookup_team_by(name: name) do
      {:ok, team} ->
        assign(socket, :team, team)

      {:error, :not_found} ->
        socket
        |> push_redirect(to: Routes.page_path(socket, :index))
        |> put_flash(:error, "Sorry, that team was not found")
    end
  end

  defp apply_action(socket, :show), do: socket
  defp apply_action(socket, :add_pear), do: socket
  defp apply_action(socket, :add_track), do: socket
end
