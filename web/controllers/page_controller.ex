defmodule Doucheracer.PageController do
  use Doucheracer.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
