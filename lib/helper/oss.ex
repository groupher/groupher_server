defmodule Helper.OSS do
  @moduledoc """
  find city info by ip
  refer: https://lbs.amap.com/api/webservice/guide/api/ipconfig/?sug_index=0
  """
  use Tesla, only: [:get]

  import Helper.ErrorCode

  @role_arn "acs:ram::1974251283640986:role/groupheross"
  @role_session_name "GroupherOSS"

  @timeout_limit 4000

  plug(Tesla.Middleware.JSON)
  plug(Tesla.Middleware.Retry, delay: 200, max_retries: 2)
  plug(Tesla.Middleware.Timeout, timeout: @timeout_limit)
  plug(Tesla.Middleware.PathParams)
  # plug(Tesla.Middleware.Logger, debug: false)

  # defp get_token(), do: get_config(:plausible, :token)
  def get_sts_token() do
    params = %{
      "Action" => "AssumeRole",
      "RoleArn" => @role_arn,
      "RoleSessionName" => @role_session_name,
      "DurationSeconds" => 1000
    }

    with {:ok, %{status: 200, body: body}} <- ExAliyun.OpenAPI.call_sts(params) do
      {:ok, body}
    else
      {:ok, %{status: 404, body: body}} ->
        {:error, body["Code"]}
        {:error, [message: "oss sts token error", code: ecode(:oss_sts_token)]}

      _ ->
        {:error, [message: "oss sts token error", code: ecode(:oss_sts_token)]}
    end
  end
end
