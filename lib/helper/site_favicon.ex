defmodule Helper.SiteFavicon do
  @moduledoc """
  this lib coming from https://github.com/ikeikeikeike/exfavicon/blob/master/lib/exfavicon/finder.ex
  fix edge case at line:60
  """
  use HTTPoison.Base

  def find_page(url) do
    req(url)
  end

  def parse_favicon(html, location) do
    icon_url = find_from_html(html, location)
    if icon_url, do: icon_url, else: default_path(location)
  end

  def find(url) do
    {:ok, location, resp} = req(url)

    IO.inspect(OpenGraph.parse(resp.body), label: "## 直接解析")

    icon_url = find_from_html(resp.body, location)
    if icon_url, do: icon_url, else: default_path(location)
  end

  def find_from_html(html, url) do
    case detect(html, url) do
      {:ok, icon_url} ->
        if valid_favicon_url?(icon_url), do: icon_url, else: nil

      _ ->
        nil
    end
  end

  def valid_favicon_url?(url) do
    case head(url) do
      {:ok, resp} ->
        ctype =
          resp.headers
          |> get_header("content-type")

        if Regex.match?(~r/image/, ctype), do: true, else: false

      _ ->
        false
    end
  end

  defp req(url) do
    with {:ok, resp} <- get(url) do
      headers =
        resp.headers
        |> Enum.map(fn {k, v} -> {k |> String.downcase(), v} end)

      case List.keyfind(headers, "location", 0) do
        {"location", location} ->
          req(location)

        _ ->
          {:ok, url, resp}
      end
    end
  end

  defp detect(html, url) do
    {:ok, ptn} = Regex.compile("^(shortcut )?icon$", "i")

    favicon_url_or_path =
      html
      |> Floki.find("link")
      |> Enum.filter(&Regex.match?(ptn, List.first(Floki.attribute(&1, "rel")) || ""))
      |> Enum.flat_map(&Floki.attribute(&1, "href"))
      |> List.first()

    case favicon_url_or_path do
      "" ->
        {:error, "blank"}

      nil ->
        {:error, "blank"}

      _ ->
        case Regex.match?(~r/^https?/, favicon_url_or_path) do
          true ->
            {:ok, favicon_url_or_path}

          false ->
            uri = URI.parse(favicon_url_or_path)

            case uri do
              %URI{host: nil} ->
                {:ok, %{URI.parse(url) | path: uri.path} |> URI.to_string()}

              %URI{scheme: nil} ->
                {:ok, %{uri | scheme: "http"} |> URI.to_string()}

              _ ->
                {:error, "unknown uri"}
            end
        end
    end
  end

  defp get_header(headers, key) do
    ctype =
      headers
      |> Enum.map(fn {k, v} -> {k |> String.downcase(), v} end)
      |> Enum.filter(fn {k, _} -> k == key |> String.downcase() end)

    case ctype do
      [] ->
        ""

      _ ->
        ctype |> hd |> elem(1)
    end
  end

  defp default_path(url) do
    %{URI.parse(url) | path: "/favicon.ico", query: nil, fragment: nil}
    |> URI.to_string()
  end
end
