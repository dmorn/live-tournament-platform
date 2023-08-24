defmodule LTPWeb.Tournament.AddScoreComponent do
  use LTPWeb, :live_component
  alias LTP.App
  alias LTP.Tournament

  def update(assigns, socket) do
    form = to_form(%{"player_id" => nil, "score" => nil})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(form: form)}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.header><%= gettext("Add score") %></.header>
      <.simple_form for={@form} phx-target={@myself} phx-change="validate" phx-submit="save">
        <.input field={@form[:player_id]} label="Player number" />
        <.input field={@form[:score]} type="number" label={gettext("Score")} />
        <:actions>
          <.button><%= gettext("Save") %></.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("save", %{"player_id" => player_id, "score" => score} = params, socket) do
    command = %Tournament.AddScore{
      player_id: player_id,
      game_id: socket.assigns.game_id,
      score: score,
      tournament_id: socket.assigns.tournament_id
    }

    case App.dispatch(command) do
      :ok ->
        {:noreply,
         socket
         |> put_flash(
           :info,
           gettext("Score for player %{number} has been registered.", number: player_id)
         )
         |> push_patch(to: socket.assigns.patch)}

      {:error, :player_not_found} ->
        form = to_form(params, errors: [player_id: {gettext("Player is not registered."), []}])
        {:noreply, assign(socket, form: form)}
    end
  end
end
