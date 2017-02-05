defmodule Doucheracer.PageView do
  use Doucheracer.Web, :view

  def profile_image(login) do
    case login do
      "realDonaldTrump" -> "https://pbs.twimg.com/profile_images/1980294624/DJT_Headshot_V2.jpg"
      "stephenbannon" -> "https://pbs.twimg.com/profile_images/2553459118/mtv9myvsmiupsc40opjc.jpeg"
      "RichardBSpencer" -> "https://pbs.twimg.com/profile_images/783806530588061696/DvXsjqbk.jpg"
    end
  end

  def tweet_link(login) do
    text = URI.encode_query(text: "@#{login}, you're such a tool", hashtags: "DoucheElection")
    "https://twitter.com/intent/tweet?#{text}"
  end
end
