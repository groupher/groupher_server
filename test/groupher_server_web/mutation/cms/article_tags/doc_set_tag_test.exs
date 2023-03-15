defmodule GroupherServer.Test.Mutation.ArticleTags.DocSetTag do
  @moduledoc false

  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS
  alias CMS.Model.Doc

  setup do
    {:ok, doc} = db_insert(:doc)
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:owner, doc)

    article_tag_attrs = mock_attrs(:article_tag)
    article_tag_attrs2 = mock_attrs(:article_tag)

    {:ok,
     ~m(user_conn guest_conn owner_conn community doc article_tag_attrs article_tag_attrs2 user)a}
  end

  describe "[mutation doc tag]" do
    @set_tag_query """
    mutation($id: ID!, $thread: Thread, $articleTagId: ID!, $communityId: ID!) {
      setArticleTag(id: $id, thread: $thread, articleTagId: $articleTagId, communityId: $communityId) {
        id
      }
    }
    """
    @tag :wip
    test "auth user can set a valid tag to doc",
         ~m(community doc article_tag_attrs user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :doc, article_tag_attrs, user)

      passport_rules = %{community.title => %{"doc.article_tag.set" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      variables = %{
        id: doc.id,
        thread: "DOC",
        articleTagId: article_tag.id,
        communityId: community.id
      }

      rule_conn |> mutation_result(@set_tag_query, variables, "setArticleTag")
      {:ok, found} = ORM.find(Doc, doc.id, preload: :article_tags)

      assoc_tags = found.article_tags |> Enum.map(& &1.id)
      assert article_tag.id in assoc_tags
    end

    @unset_tag_query """
    mutation($id: ID!, $thread: Thread, $articleTagId: ID!, $communityId: ID!) {
      unsetArticleTag(id: $id, thread: $thread, articleTagId: $articleTagId, communityId: $communityId) {
        id
        title
      }
    }
    """

    @tag :wip
    test "can unset tag to a doc",
         ~m(community doc article_tag_attrs article_tag_attrs2 user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :doc, article_tag_attrs, user)

      {:ok, article_tag2} = CMS.create_article_tag(community, :doc, article_tag_attrs2, user)

      {:ok, _} = CMS.set_article_tag(:doc, doc.id, article_tag.id)
      {:ok, _} = CMS.set_article_tag(:doc, doc.id, article_tag2.id)

      passport_rules = %{community.title => %{"doc.article_tag.unset" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      variables = %{
        id: doc.id,
        thread: "DOC",
        articleTagId: article_tag.id,
        communityId: community.id
      }

      rule_conn |> mutation_result(@unset_tag_query, variables, "unsetArticleTag")

      {:ok, doc} = ORM.find(Doc, doc.id, preload: :article_tags)
      assoc_tags = doc.article_tags |> Enum.map(& &1.id)

      assert article_tag.id not in assoc_tags
      assert article_tag2.id in assoc_tags
    end
  end
end
