defmodule GroupherServer.CMS.Model.Community do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  use Accessible

  import Ecto.Changeset

  alias GroupherServer.{Accounts, CMS}
  alias Accounts.Model.User

  alias CMS.Model.{
    Embeds,
    CommunityDashboard,
    Category,
    CommunityThread,
    CommunitySubscriber,
    CommunityModerator
  }

  @max_pinned_article_count_per_thread 2

  @required_fields ~w(title desc user_id logo slug)a
  # @required_fields ~w(title desc user_id)a
  @optional_fields ~w(favicon label geo_info index aka contributes_digest pending)a

  def max_pinned_article_count_per_thread, do: @max_pinned_article_count_per_thread

  schema "communities" do
    field(:title, :string)
    field(:aka, :string)
    field(:desc, :string)
    field(:logo, :string)
    field(:favicon, :string)
    # field(:category, :string)
    field(:label, :string)
    field(:slug, :string)
    field(:index, :integer)
    field(:geo_info, :map)
    field(:views, :integer)

    embeds_one(:meta, Embeds.CommunityMeta, on_replace: :delete)
    belongs_to(:author, User, foreign_key: :user_id)

    has_many(:threads, {"communities_threads", CommunityThread}, on_delete: :delete_all)
    has_many(:subscribers, {"communities_subscribers", CommunitySubscriber})

    # this field will be rewrite as virtual for GQ workflow
    has_many(:moderators, {"communities_moderators", CommunityModerator})

    has_one(:dashboard, CommunityDashboard)

    field(:articles_count, :integer, default: 0)
    field(:moderators_count, :integer, default: 0)
    field(:subscribers_count, :integer, default: 0)
    field(:article_tags_count, :integer, default: 0)
    field(:threads_count, :integer, default: 0)

    field(:pending, :integer, default: 0)

    field(:viewer_has_subscribed, :boolean, default: false, virtual: true)
    field(:viewer_is_moderator, :boolean, default: false, virtual: true)
    field(:contributes_digest, {:array, :integer}, default: [])

    many_to_many(
      :categories,
      Category,
      join_through: "communities_categories",
      join_keys: [community_id: :id, category_id: :id],
      # :delete_all will only remove data from the join source
      on_delete: :delete_all
      # on_replace: :delete
    )

    # posts_block_list ...
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%Community{} = community, attrs) do
    # |> cast_assoc(:author)
    # |> unique_constraint(:title, name: :communities_title_index)
    community
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> cast_embed(:meta, with: &Embeds.CommunityMeta.changeset/2)
    |> cast_assoc(:dashboard)
    |> validate_length(:title, min: 1, max: 30)
    |> validate_length(:slug, min: 1, max: 30)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:slug, name: :communities_raw_index)
    |> unique_constraint(:aka, name: :communities_aka_index)

    # |> foreign_key_constraint(:communities_author_fkey)
  end

  @doc false
  def update_changeset(%Community{} = community, attrs) do
    # |> cast_assoc(:author)
    # |> unique_constraint(:title, name: :communities_title_index)
    community
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> cast_embed(:meta, with: &Embeds.CommunityMeta.changeset/2)
    |> validate_length(:title, min: 1, max: 30)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:title, name: :communities_title_index)
    |> unique_constraint(:aka, name: :communities_aka_index)

    # |> foreign_key_constraint(:communities_author_fkey)
  end
end
