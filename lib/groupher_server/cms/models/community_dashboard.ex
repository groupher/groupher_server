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
  @optional_fields ~w(base_info)a

  schema "community_dashboards" do
    belongs_to(:community, Community)
    embeds_one(:base_info, Embeds.DashboardBaseInfo, on_replace: :delete)

    # posts_block_list ...
    timestamps(type: :utc_datetime)
  end

  def default() do
    %{
      base_info: Embeds.DashboardBaseInfo.default()
    }
  end

  @doc false
  def changeset(%CommunityDashboard{} = community_dashboard, attrs) do
    community_dashboard
    |> cast(attrs, @required_fields)
    |> cast_embed(:base_info, with: &Embeds.DashboardBaseInfo.changeset/2)
  end

  @doc false
  def update_changeset(%CommunityDashboard{} = community_dashboard, attrs) do
    community_dashboard
    |> cast(attrs, @optional_fields ++ @required_fields)

    # |> cast(attrs, @optional_fields ++ @required_fields)
  end
end
