defmodule GroupherServer.Test.Query.Articles.Kanban do
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  alias CMS.Constant

  @article_cat Constant.article_cat()
  @article_state Constant.article_state()

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, post} = db_insert(:post)
    {:ok, community} = db_insert(:community)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    post_attrs = mock_attrs(:post, %{community_id: community.id})

    {:ok, ~m(user_conn guest_conn post user community post_attrs)a}
  end

  @query """
  query($id: ID!) {
    post(id: $id) {
      id
      title
      cat
      state
    }
  }
  """
  test "basic graphql query on kanban post with logined user",
       ~m(user_conn community user post_attrs)a do
    kanban_attrs =
      post_attrs |> Map.merge(%{cat: @article_cat.feature, state: @article_state.todo})

    {:ok, post} = CMS.create_article(community, :post, kanban_attrs, user)

    variables = %{id: post.id}
    result = user_conn |> query_result(@query, variables, "post")

    assert result["id"] == to_string(post.id)
    assert result["cat"] == "FEATURE"
    assert result["state"] == "TODO"
  end
end
