defmodule Doucheracer.PageController do
  use Doucheracer.Web, :controller

  def index(conn, _params) do
    {:ok, redix_conn} = Redix.start_link(Application.get_env(:redix, :url))
    scores =
      Redix.command!(redix_conn, ~w(HGETALL scores))
      |> Doucheracer.RedisToMap.redis_to_map(fn([l, s]) ->
        {score, _} = Integer.parse(s)
        [l, score] end
      )
      |> IO.inspect

    score_sum = scores
      |> Enum.map(fn({login, score}) -> score end)
      |> Enum.sum

    contenders = scores
      |> Enum.map(fn({login, score}) ->
        %{ score: score, login: login, percentage: (score / score_sum * 100) } end
      )
      |> Enum.sort_by(fn(contender) -> contender.score end, &>/2)

    render conn, "index.html", contenders: contenders
  end
end
