defmodule Doucheracer.TwitterUpdate do
  require Logger
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    {:ok, conn} = Redix.start_link(Application.get_env(:redix, :url))
    send(self(), :work)
    {:ok, {conn}}
  end

  def handle_info(:work, state) do
    fetch_recent_tweets(state)
    schedule_work()
    {:noreply, state}
  end

  defp fetch_recent_tweets({conn} = state) do
    new_cursors =
      Redix.command!(conn, ~w(HGETALL cursors))
      |> Doucheracer.RedisToMap.redis_to_map
      |> Enum.map(fn({login, last_id}) -> {login, fetch_new_tweet_count(login, last_id, state)} end)
      |> Enum.each(fn({login, {new_count, last_id}}) ->
        Redix.pipeline(
          conn, [
            ~w(HSET cursors #{login} #{last_id}),
            ~w(HINCRBY scores #{login} #{new_count}),
          ]
        )
      end)


  end

  defp fetch_new_tweet_count(login, last_id, {conn} = state, count \\ 0) do
    Logger.info("[TwitterUpdate] Fetching recent tweets for #{login} starting at #{last_id}")

    {fetched_count, last_id, continue} = fetch_next(last_id, login)
    new_count = count + fetched_count

    Logger.info("[TwitterUpdate] Found #{fetched_count} new tweets")

    if continue do
      Logger.info("[TwitterUpdate] Continuing")
      fetch_new_tweet_count(login, last_id, state, new_count)
    else
      Logger.info("[TwitterUpdate] Exhausted list of tweets, waiting a while...")
      {new_count, last_id}
    end
  end

  defp fetch_next(last_id, login) do
    try do
      tweets = ExTwitter.search("to:#{login}", [count: 100, since_id: last_id])
      count = Enum.count(tweets)
      last_id = if count != 0 do
        List.first(tweets).id
      else
        last_id
      end
      {count, last_id, count == 100}
    rescue
      e in ExTwitter.RateLimitExceededError ->
        seconds = (e.reset_in + 1)
        Logger.info("[TwitterUpdate] Rate limited, sleeping for #{seconds}")
        :timer.sleep(seconds * 1000)
        fetch_next(last_id, login)
    end
  end

  defp schedule_work() do
    Process.send_after(self(), :work, 2 * 60 * 1000) # In 2 min
  end
end
