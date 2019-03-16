defmodule OpenAdventureCapitalist.Game do
  use GenServer

  require Logger

  # alias OpenAdventureCapitalist.Game
  alias OpenAdventureCapitalist.Business

  def start_link(_) do
    Logger.info("Starting #{__MODULE__}")

    {:ok, lemonade_stand} =
      Business.start_link(%Business{name: "Lemonade Stand", level: 1, working?: true})

    start_state = %{
      prev_tick: 0,
      money: 0,
      businesses: [
        lemonade_stand
      ]
    }

    GenServer.start_link(__MODULE__, start_state, name: __MODULE__)
  end

  @impl true
  def init(state) do
    :timer.send_interval(100, :tick)

    {:ok, %{state | prev_tick: DateTime.utc_now()}}
  end

  @impl true
  def handle_info(:tick, state = %{prev_tick: prev_tick}) do
    now = DateTime.utc_now()
    diff = DateTime.diff(now, prev_tick, :millisecond)

    state = tick(state, diff)

    {:noreply, %{state | prev_tick: now}}
  end

  def tick(state, duration) do
    payout =
      Enum.map(state.businesses, fn business ->
        {:ok, payout} = Business.tick(business, duration)
        payout
      end)
      |> Enum.sum()

    %{state | money: state.money + payout}
  end
end
