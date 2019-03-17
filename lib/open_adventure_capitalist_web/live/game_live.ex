defmodule OpenAdventureCapitalistWeb.GameLive do
  use Phoenix.LiveView

  require Logger

  defmodule Business do
    def upgrade_cost(%{level: level, initial_cost: initial_cost, coefficient: coefficient}) do
      initial_cost * :math.pow(coefficient, level)
    end

    def revenue(%{level: level, initial_revenue: initial_revenue}) do
      level * initial_revenue
    end
  end

  defmodule Currency do
    def format(num) when is_float(num) do
      "$#{Float.round(num, 2)}"
    end

    def format(num) when is_integer(num) do
      "$#{num}"
    end

    def format(num) do
      num
    end
  end

  @tick 40

  def render(assigns) do
    ~L"""
    <div>
      <h1><%= Currency.format(@money) %></h1>
      <%= for {business, index} <- Enum.with_index(@businesses) do %>
        <div>
          <%= business.name %> (<%= business.level %>) ... $<%= Business.revenue(business) %> ... <%= business.time_left %> ... <%= business.percent %>
          <div style="width: 200px; height: 20px; border: 1px solid #333">
            <div style="width: <%= business.percent %>%; height: 20px; background-color: #74b22f;"></div>
          </div>
          <button phx-click="start_work" phx-value="<%= index %>">Sell <%= business.name %></button>
          <button phx-click="upgrade_business" phx-value="<%= index %>">Upgrade for <%= Currency.format Business.upgrade_cost(business) %></button>
        </div>
      <% end %>
    </div>
    """
  end

  def mount(_session, socket) do
    {:ok, socket |> new_game() |> schedule_tick()}
  end

  def new_game(socket) do
    defaults = %{
      money: 0,
      tick: @tick,
      businesses: [
        %{
          name: "lemonade",
          level: 1,
          time_required: 1000,
          time_left: 1000,
          percent: 0,
          payout: 0,
          running: false,
          initial_cost: 4,
          coefficient: 1.07,
          initial_time: 0.6,
          initial_revenue: 1,
          initial_productivity: 1.67
        },
        %{
          name: "newspaper",
          level: 0,
          time_required: 5000,
          time_left: 5000,
          percent: 0,
          payout: 0,
          running: false,
          initial_cost: 60,
          coefficient: 1.15,
          initial_time: 3,
          initial_revenue: 60,
          initial_productivity: 20
        }
      ]
    }

    new_socket =
      socket
      |> assign(defaults)

    if connected?(new_socket) do
      Logger.info("connected")
      new_socket
    else
      Logger.warn("not connected")
      new_socket
    end
  end

  defp schedule_tick(socket) do
    Process.send_after(self(), :tick, socket.assigns.tick)
    socket
  end

  def handle_info(:tick, socket) do
    new_socket =
      socket
      |> game_loop()
      |> schedule_tick()

    {:noreply, new_socket}
  end

  def handle_event("start_work", value, socket) do
    business_index = String.to_integer(value)
    business = socket.assigns.businesses |> Enum.at(business_index)
    business = %{business | running: true}

    {:noreply,
     assign(
       socket,
       :businesses,
       List.replace_at(socket.assigns.businesses, business_index, business)
     )}
  end

  def handle_event("upgrade_business", value, socket) do
    business_index = String.to_integer(value)
    business = socket.assigns.businesses |> Enum.at(business_index)

    upgrade_cost = Business.upgrade_cost(business)

    if upgrade_cost <= socket.assigns.money do
      business = %{business | level: business.level + 1}

      {
        :noreply,
        socket
        |> assign(
          :businesses,
          List.replace_at(socket.assigns.businesses, business_index, business)
        )
        |> assign(:money, socket.assigns.money - upgrade_cost)
      }
    else
      {:noreply, socket}
    end
  end

  def game_loop(socket) do
    socket
    |> tick_businesses()
  end

  def tick_businesses(socket) do
    new_businesses =
      socket.assigns.businesses
      |> Enum.map(fn business ->
        if business.running do
          time_left = business.time_left - @tick
          percent = 100 - business.time_left / business.time_required * 100

          if time_left > 0 do
            %{business | percent: percent, time_left: time_left}
          else
            %{
              business
              | running: false,
                percent: 0,
                time_left: business.time_required,
                payout: Business.revenue(business)
            }
          end
        else
          business
        end
      end)

    payout = new_businesses |> Enum.map(fn b -> b.payout end) |> Enum.sum()

    new_businesses = new_businesses |> Enum.map(fn b -> %{b | payout: 0} end)

    socket
    |> assign(:businesses, new_businesses)
    |> assign(:money, socket.assigns.money + payout)
  end
end
