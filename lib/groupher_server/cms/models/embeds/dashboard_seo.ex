defmodule GroupherServer.CMS.Model.Embeds.DashboardSEO do
  @moduledoc """
  general article comment meta info
  """
  use Ecto.Schema
  use Accessible

  import Ecto.Changeset

  @optional_fields ~w(og_site_name og_title og_description og_url og_image og_locale og_publisher tw_title tw_description tw_url tw_card tw_site tw_image tw_image_width tw_image_height)a

  @doc "for test usage"
  def default() do
    %{
      og_site_name: "",
      og_title: "",
      og_description: "",
      og_url: "",
      og_image: "",
      og_locale: "",
      og_publisher: "",
      # twitter
      tw_title: "",
      tw_description: "",
      tw_url: "",
      tw_card: "",
      tw_site: "",
      tw_image: "",
      tw_image_width: "",
      tw_image_height: ""
    }
  end

  embedded_schema do
    field(:og_site_name, :string, default: "")
    field(:og_title, :string, default: "")
    field(:og_description, :string, default: "")
    field(:og_url, :string, default: "")
    field(:og_image, :string, default: "")
    field(:og_locale, :string, default: "")
    field(:og_publisher, :string, default: "")

    # for twitter
    field(:tw_title, :string, default: "")
    field(:tw_description, :string, default: "")
    field(:tw_url, :string, default: "")
    field(:tw_card, :string, default: "")
    field(:tw_site, :string, default: "")
    field(:tw_image, :string, default: "")
    field(:tw_image_width, :string, default: "")
    field(:tw_image_height, :string, default: "")
  end

  def changeset(struct, params) do
    struct
    |> cast(params, @optional_fields)
  end
end
