defmodule GroupherServer.CMS.Model.Embeds.DashboardBaseInfo do
  @moduledoc """
  general article comment meta info
  """
  use Ecto.Schema
  use Accessible

  import Ecto.Changeset

  @optional_fields ~w(favicon title logo homepage city techstack)a

  @doc "for test usage"
  def default() do
    %{
      favicon: "",
      title: "",
      logo: "",
      homepage: "",
      city: "",
      techstack: ""
    }
  end

  embedded_schema do
    field(:favicon, :string, default: "")
    field(:title, :string, default: "")
    field(:logo, :string, default: "")
    field(:homepage, :string, default: "")
    field(:city, :string, default: "")
    field(:techstack, :string, default: "")
  end

  def changeset(struct, params) do
    struct
    |> cast(params, @optional_fields)
  end
end
