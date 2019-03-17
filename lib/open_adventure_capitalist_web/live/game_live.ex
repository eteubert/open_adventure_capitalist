defmodule OpenAdventureCapitalistWeb.GameLive do
  use Phoenix.LiveView

  require Logger

  # 17 for 60fps
  @tick 17

  defmodule Business do
    @revenue_multiplier 4

    def upgrade_cost(%{level: level, initial_cost: initial_cost, coefficient: coefficient}) do
      initial_cost * :math.pow(coefficient, level)
    end

    def revenue(%{level: level, initial_revenue: initial_revenue}) do
      level * initial_revenue * @revenue_multiplier
    end

    def time_required(%{initial_time: initial_time}) do
      initial_time * 1000
    end

    def buy_button_class(business, money) do
      if upgrade_cost(business) > money do
        "buy-disabled"
      else
        "buy-enabled"
      end
    end
  end

  defmodule Currency do
    def format(num) when is_float(num) do
      "$#{Number.Delimit.number_to_delimited(Float.round(num, 2))}"
    end

    def format(num) when is_integer(num) do
      "$#{Number.Delimit.number_to_delimited(num)}"
    end

    def format(num) do
      num
    end
  end

  defmodule Duration do
    def format(num) when is_float(num) do
      num |> Float.round() |> trunc() |> format()
    end

    def format(num) when is_integer(num) do
      seconds = (num / 1000) |> Float.round() |> trunc()

      s = Integer.mod(seconds, 60)
      m = trunc((seconds - s) / 60)
      h = trunc((seconds - s - m * 60) / 3600)

      {:ok, time} = Time.new(h, m, s)
      Time.to_string(time)
    end
  end

  def render(assigns) do
    ~L"""
    <div class="" style="max-width: 375px; background-color: #736961; color: #f0ece5">
      <div class="w-full text-3xl p-3" style="background-color: #504b45">
        <strong><%= Currency.format(@money) %></strong>
      </div>
      <div class="py-2">
      <%= for {business, index} <- Enum.with_index(@businesses) do %>
        <div class="flex mb-3 mx-2">
          <div class="mr-2">
            <div phx-click="start_work" phx-value="<%= index %>" class="cursor-pointer rounded-full relative" style="width: 50px; height: 50px; background-color: #4a6373; border: 3px solid #818f95; box-shadow: 0 0 0 2px #38362f;">
              <div class="absolute w-full text-xs bg-grey-darker rounded px-1" style="text-align: center; top: 10px;"><%= business.name %></div>
              <div class="absolute w-full text-sm font-bold rounded px-2" style="text-align: center; top: 30px; background-color: #38362f; padding-top: 2px; padding-bottom: 2px;"><%= business.level %></div>
            </div>
          </div>
          <div class="w-full text-black">
            <div class="relative w-full mb-1 rounded" style="height: 30px; border: 2px solid #47393e">
              <div style="width: <%= business.percent %>%; height: 26px; background-color: #74b22f;"></div>
              <div class="w-full absolute pin-y text-center font-bold text-xl" style="margin-top: 3px"><%= Currency.format Business.revenue(business) %></div>
            </div>
            <div class="flex">
              <div class="relative w-2/3 rounded <%= Business.buy_button_class(business, @money) %>" style="text-align: center; height: 30px;" phx-click="upgrade_business" phx-value="<%= index %>">
                <%= Currency.format Business.upgrade_cost(business) %>
                <div class="absolute text-xs" style="top: 1px; left: 2px; color: #efeae2;">
                  Buy
                </div>
              </div>
              <div class="w-1/3 rounded" style="text-align: center; height: 30px; background-color: #8a8277; border: 2px solid #6f675f" phx-click="upgrade_business" phx-value="<%= index %>">
                <%= Duration.format business.time_left %>
              </div>
            </div>
          </div>
        </div>
      <% end %>
      </div>
    </div>

    <style>
    .buy-enabled {
      cursor: pointer;
      background-color: #de884a;
      border: 2px solid #bc6624
    }
    .buy-disabled {
      background-color: #8a8277;
      border: 2px solid #6f675f
    }
    </style>
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
          name: "lemon",
          level: 1,
          time_left: 600,
          percent: 0,
          payout: 0,
          running: false,
          initial_cost: 4,
          coefficient: 1.07,
          initial_time: 0.6,
          initial_revenue: 1
        },
        %{
          name: "paper",
          level: 0,
          time_left: 3000,
          percent: 0,
          payout: 0,
          running: false,
          initial_cost: 60,
          coefficient: 1.15,
          initial_time: 3,
          initial_revenue: 60
        },
        %{
          name: "car",
          level: 0,
          time_left: 6000,
          percent: 0,
          payout: 0,
          running: false,
          initial_cost: 720,
          coefficient: 1.14,
          initial_time: 6,
          initial_revenue: 540
        },
        %{
          name: "pizza",
          level: 0,
          time_left: 24000,
          percent: 0,
          payout: 0,
          running: false,
          initial_cost: 8640,
          coefficient: 1.13,
          initial_time: 24,
          initial_revenue: 51840
        },
        %{
          name: "donut",
          level: 0,
          time_left: 96000,
          percent: 0,
          payout: 0,
          running: false,
          initial_cost: 103_680,
          coefficient: 1.12,
          initial_time: 96,
          initial_revenue: 51840
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
          percent = 100 - business.time_left / Business.time_required(business) * 100

          if time_left > 0 do
            %{business | percent: percent, time_left: time_left}
          else
            %{
              business
              | running: false,
                percent: 0,
                time_left: Business.time_required(business),
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
