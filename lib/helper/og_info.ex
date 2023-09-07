defmodule Helper.OgInfo do
  import Helper.Utils, only: [done: 1]

  alias Helper.SiteFavicon

  def get(url) do
    with {:ok, location, resp} <- SiteFavicon.find_page(url),
         og <- OpenGraph.parse(resp.body),
         true <- is_valid_og?(og),
         %URI{host: host} <- URI.parse(url),
         favicon <- SiteFavicon.parse_favicon(resp.body, location) do
      og |> Map.merge(%{favicon: favicon}) |> fmt_field(host) |> done
    else
      {:error, %HTTPoison.Error{reason: :nxdomain, id: nil}} ->
        {:error, "get url page error"}

      {:error, %HTTPoison.Error{reason: :timeout, id: nil}} ->
        {:error, "get url page timeout"}

      # {:error, false} ->
      #   {:error,
      #    [message: "only community root can add moderator", code: ecode(:community_root_only)]}
      false ->
        {:error, "invalid open graph info"}

      _ ->
        {:error, "og info parse error"}
    end
  end

  defp fmt_field(og, "sspai.com"), do: %{og | site_name: "少数派"}
  defp fmt_field(og, "36kr.com"), do: %{og | site_name: "36kr"}

  defp fmt_field(og, _host), do: og

  defp is_valid_og?(og) do
    not is_nil(og.title)
  end
end
