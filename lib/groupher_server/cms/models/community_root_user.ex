defmodule GroupherServer.CMS.Model.CommunityRootUser do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  use Accessible

  import Ecto.Changeset

  alias GroupherServer.CMS.Model.CommunityRootUser
  alias GroupherServer.{Accounts, CMS}

  alias CMS.Model.Community
  alias Accounts.Model.User

  @required_fields ~w(community_id user_id)a

  schema "community_root_users" do
    belongs_to(:community, Community)
    belongs_to(:user, User)

    # posts_block_list ...
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%CommunityRootUser{} = ru, attrs) do
    ru
    |> cast(attrs, @required_fields)
  end

  @doc false
  def update_changeset(%CommunityRootUser{} = ru, attrs) do
    ru
    |> cast(attrs, @required_fields)
  end
end
