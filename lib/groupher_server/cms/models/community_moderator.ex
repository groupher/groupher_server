defmodule GroupherServer.CMS.Model.CommunityModerator do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  alias GroupherServer.{Accounts, CMS}

  alias Accounts.Model.User
  alias CMS.Model.Community
  # alias Helper.Certification

  @required_fields ~w(user_id community_id role)a

  @type t :: %CommunityModerator{}

  schema "communities_moderators" do
    field(:role, :string)
    belongs_to(:user, User, foreign_key: :user_id)
    belongs_to(:community, Community, foreign_key: :community_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%CommunityModerator{} = community_moderator, attrs) do
    community_moderator
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    # |> validate_inclusion(:title, Certification.moderator_titles(:cms))
    |> foreign_key_constraint(:community_id)
    |> foreign_key_constraint(:user_id)

    # |> unique_constraint(:user_id, name: :communities_editors_user_id_community_id_index)
  end
end
