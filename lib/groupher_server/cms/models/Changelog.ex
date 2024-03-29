defmodule GroupherServer.CMS.Model.Changelog do
  @moduledoc false
  alias __MODULE__

  use Ecto.Schema
  use Accessible

  import Ecto.Changeset
  import GroupherServer.CMS.Helper.Macros

  alias GroupherServer.CMS
  alias CMS.Model.Embeds

  alias Helper.HTML

  @timestamps_opts [type: :utc_datetime_usec]

  @required_fields ~w(title digest)a
  @article_cast_fields general_article_cast_fields()
  @optional_fields ~w(updated_at inserted_at active_at archived_at inner_id)a ++
                     @article_cast_fields

  @type t :: %Changelog{}
  schema "cms_changelogs" do
    article_tags_field(:changelog)
    article_communities_field(:changelog)
    general_article_fields(:changelog)
  end

  @doc false
  def changeset(%Changelog{} = changelog, attrs) do
    changelog
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> cast_embed(:meta, required: false, with: &Embeds.ArticleMeta.changeset/2)
    |> generl_changeset
  end

  @doc false
  def update_changeset(%Changelog{} = changelog, attrs) do
    changelog
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> generl_changeset
  end

  defp generl_changeset(changeset) do
    changeset
    |> validate_length(:title, min: 3, max: 100)
    |> cast_embed(:emotions, with: &Embeds.ArticleEmotion.changeset/2)
    |> validate_length(:link_addr, min: 5, max: 400)
    |> HTML.safe_string(:body)
  end
end
