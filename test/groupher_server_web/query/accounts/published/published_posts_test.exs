defmodule GroupherServer.Test.Query.Accounts.Published.Posts do
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  @publish_count 10

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, post} = db_insert(:post)
    {:ok, community} = db_insert(:community)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    {:ok, ~m(guest_conn user_conn community post user)a}
  end

  describe "[published posts]" do
    @query """
    query($login: String!, $filter: PagiFilter!) {
      pagedPublishedPosts(login: $login, filter: $filter) {
        entries {
          id
          title
          author {
            id
          }
        }
        totalPages
        totalCount
        pageSize
        pageNumber
      }
    }
    """

    test "can get published posts", ~m(guest_conn community user)a do
      post_attrs = mock_attrs(:post, %{community_id: community.id})

      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)
      {:ok, post2} = CMS.create_article(community, :post, post_attrs, user)

      variables = %{login: user.login, filter: %{page: 1, size: 20}}
      results = guest_conn |> query_result(@query, variables, "pagedPublishedPosts")

      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(post.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(post2.id)))
    end
  end

  describe "[account published comments on post]" do
    @query """
    query($login: String!, $thread: Thread, $filter: PagiFilter!) {
      pagedPublishedComments(login: $login, thread: $thread, filter: $filter) {
        entries {
          id
          bodyHtml
          author {
            id
          }
          article {
            id
            title
            thread
            author {
              nickname
              login
            }
          }
        }
        totalPages
        totalCount
        pageSize
        pageNumber
      }
    }
    """
    test "user can get paged published comments on post", ~m(guest_conn user post)a do
      pub_comments =
        Enum.reduce(1..@publish_count, [], fn _, acc ->
          {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), user)
          acc ++ [comment]
        end)

      random_comment_id = pub_comments |> Enum.random() |> Map.get(:id) |> to_string

      # variables = %{login: user.login, thread: "POST", filter: %{page: 1, size: 20}}
      variables = %{login: user.login, filter: %{page: 1, size: 20}}

      results = guest_conn |> query_result(@query, variables, "pagedPublishedComments")

      entries = results["entries"]
      assert results |> is_valid_pagination?
      assert results["totalCount"] == @publish_count

      assert entries |> Enum.all?(&(not is_nil(&1["article"]["author"])))

      assert entries |> Enum.all?(&(&1["article"]["id"] == to_string(post.id)))
      assert entries |> Enum.all?(&(&1["author"]["id"] == to_string(user.id)))
      assert entries |> Enum.any?(&(&1["id"] == random_comment_id))
    end
  end
end
