defmodule OpenAdventureCapitalist.Business do
  use GenServer

  alias OpenAdventureCapitalist.Business

  defstruct name: "", level: 0, working?: false, progress: 0

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl true
  def init(business = %Business{}) do
    {:ok, business}
  end

  def tick(pid, progress) when is_integer(progress) do
    GenServer.call(pid, {:tick, progress})
  end

  def progress(pid) do
    GenServer.call(pid, :progress)
  end

  @progress_required 1000

  @impl true
  def handle_call({:tick, progress}, _from, business) do
    {business, earning} =
      business
      |> advance(progress)
      |> maybe_payout()

    {:reply, {:ok, earning}, business}
  end

  @impl true
  def handle_call(:progress, _from, business) do
    progress_percent = business.progress / @progress_required * 100

    {:reply, progress_percent, business}
  end

  def advance(business, progress) do
    %{business | progress: business.progress + progress}
  end

  def maybe_payout(business) do
    if business.progress >= @progress_required do
      business = %{business | progress: business.progress - @progress_required}
      {business, 5}
    else
      {business, 0}
    end
  end
end
