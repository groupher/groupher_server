defmodule GroupherServer.CMS.Model.CommunityDashboard do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  use Accessible

  import Ecto.Changeset

  alias GroupherServer.CMS.Model.CommunityDashboard
  alias GroupherServer.CMS

  alias CMS.Model.{
    Embeds,
    Community
  }

  @required_fields ~w(community_id)a
  @optional_fields ~w(base_info seo layout)a

  def default() do
    %{
      base_info: Embeds.DashboardBaseInfo.default(),
      seo: Embeds.DashboardSEO.default(),
      layout: Embeds.DashboardLayout.default()
    }
  end

  schema "community_dashboards" do
    belongs_to(:community, Community)
    embeds_one(:base_info, Embeds.DashboardBaseInfo, on_replace: :delete)
    embeds_one(:seo, Embeds.DashboardSEO, on_replace: :delete)
    embeds_one(:layout, Embeds.DashboardLayout, on_replace: :delete)

    # posts_block_list ...
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%CommunityDashboard{} = community_dashboard, attrs) do
    community_dashboard
    |> cast(attrs, @required_fields)
    |> cast_embed(:base_info, with: &Embeds.DashboardBaseInfo.changeset/2)
    |> cast_embed(:seo, with: &Embeds.DashboardSEO.changeset/2)
    |> cast_embed(:layout, with: &Embeds.DashboardLayout.changeset/2)
  end

  @doc false
  def update_changeset(%CommunityDashboard{} = community_dashboard, attrs) do
    community_dashboard
    |> cast(attrs, @optional_fields ++ @required_fields)

    # |> cast(attrs, @optional_fields ++ @required_fields)
  end
end
