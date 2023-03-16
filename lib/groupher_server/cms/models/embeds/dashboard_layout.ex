defmodule GroupherServer.CMS.Model.Embeds.DashboardLayout do
  @moduledoc """
  general article comment meta info
  """
  use Ecto.Schema
  use Accessible

  import Ecto.Changeset

  @optional_fields ~w(primary_color post_layout kanban_layout help_layout help_faq_layout avatar_layout brand_layout banner_layout topbar_layout topbar_bg broadcast_layout broadcast_bg broadcast_enable broadcast_article_layout broadcast_article_bg broadcast_article_enable changelog_layout footer_layout)a

  @doc "for test usage"
  def default() do
    %{
      primary_color: "",
      post_layout: "",
      kanban_layout: "",
      kanban_bg_colors: [],
      help_layout: "",
      help_faq_layout: "",
      avatar_layout: "",
      brand_layout: "",
      banner_layout: "",
      topbar_layout: "",
      topbar_bg: "",
      broadcast_layout: "",
      broadcast_bg: "",
      broadcast_enable: false,
      broadcast_article_layout: "",
      broadcast_article_bg: "",
      broadcast_article_enable: false,
      changelog_layout: "",
      footer_layout: ""
    }
  end

  embedded_schema do
    field(:primary_color, :string, default: "")
    field(:post_layout, :string, default: "")
    field(:kanban_layout, :string, default: "")
    field(:kanban_bg_colors, {:array, :string}, default: [])
    field(:help_layout, :string, default: "")
    field(:help_faq_layout, :string, default: "")
    field(:avatar_layout, :string, default: "")
    field(:brand_layout, :string, default: "")
    field(:banner_layout, :string, default: "")
    field(:topbar_layout, :string, default: "")
    field(:topbar_bg, :string, default: "")
    field(:changelog_layout, :string, default: "")
    field(:footer_layout, :string, default: "")

    field(:broadcast_layout, :string, default: "")
    field(:broadcast_bg, :string, default: "")

    field(:broadcast_enable, :boolean, default: false)
    field(:broadcast_article_layout, :string, default: "")
    field(:broadcast_article_bg, :string, default: "")
    field(:broadcast_article_enable, :boolean, default: false)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, @optional_fields)
  end
end
