defmodule GroupherServer.Test.Query.CMS.ChangelogTags do
  @moduledoc false

  use GroupherServer.TestTools
  alias GroupherServer.CMS

  setup do
    guest_conn = simu_conn(:guest)
    {:ok, community} = db_insert(:community)
    {:ok, community2} = db_insert(:community)
    {:ok, user} = db_insert(:user)

    article_tag_attrs = mock_attrs(:article_tag)
    article_tag_attrs2 = mock_attrs(:article_tag)

    {:ok, ~m(guest_conn community community2 article_tag_attrs article_tag_attrs2 user)a}
  end

  describe "[cms query tags]" do
    @query """
    query($filter: ArticleTagsFilter) {
      pagedArticleTags(filter: $filter) {
        entries {
          id
          title
          raw
          color
          thread
          extra
          community {
            id
            title
            logo
          }
        }
        totalCount
        totalPages
        pageSize
        pageNumber
      }
    }
    """
    test "guest user can get paged tags without filter",
         ~m(guest_conn community article_tag_attrs user)a do
      variables = %{}
      {:ok, _article_tag} = CMS.create_article_tag(community, :changelog, article_tag_attrs, user)
      results = guest_conn |> query_result(@query, variables, "pagedArticleTags")

      assert results |> is_valid_pagination?
      assert results["totalCount"] == 1
    end

    test "guest user can get all paged tags belongs to a community",
         ~m(guest_conn community article_tag_attrs user)a do
      {:ok, _article_tag} = CMS.create_article_tag(community, :changelog, article_tag_attrs, user)

      variables = %{filter: %{community: community.raw}}
      results = guest_conn |> query_result(@query, variables, "pagedArticleTags")

      assert results |> is_valid_pagination?
      assert results["totalCount"] == 1
    end

    test "guest user can get tags by community and thread",
         ~m(guest_conn community  article_tag_attrs user)a do
      {:ok, article_tag} = CMS.create_article_tag(community, :changelog, article_tag_attrs, user)

      variables = %{filter: %{community: community.raw, thread: "CHANGELOG"}}
      results = guest_conn |> query_result(@query, variables, "pagedArticleTags")

      assert results["totalCount"] == 1

      tag = results["entries"] |> List.first()
      assert tag["id"] == to_string(article_tag.id)
    end
  end
end
