defmodule LTPWeb.Tournament.AddPlayerComponent do
  use LTPWeb, :live_component
  alias LTP.App
  alias LTP.Tournament

  def update(assigns, socket) do
    form = to_form(%{"id" => nil, "nickname" => nil})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(form: form)}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.header><%= gettext("Add player") %></.header>
      <.simple_form for={@form} phx-target={@myself} phx-change="validate" phx-submit="save">
        <.input field={@form[:id]} label="Number" />
        <.input field={@form[:nickname]} label={gettext("Name")} />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("save", %{"id" => id, "nickname" => nickname}, socket) do
    command = %Tournament.CreatePlayer{
      id: id,
      nickname: nickname,
      tournament_id: socket.assigns.tournament_id
    }

    case App.dispatch(command) do
      :ok ->
        {:noreply,
         socket
         |> put_flash(
           :info,
           gettext("Player %{number} has been registered.", number: id)
         )
         |> push_patch(to: socket.assigns.patch)}

      {:error, :player_already_registered} ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           gettext("Player %{number} was already registered for this tournament.", number: id)
         )
         |> push_patch(to: socket.assigns.patch)}
    end
  end
end
