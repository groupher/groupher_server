defmodule GroupherServer.Test.Accounts.ReactedContents do
  @moduledoc false

  use GroupherServer.TestTools

  alias GroupherServer.{Accounts, CMS}

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, post} = db_insert(:post)

    {:ok, ~m(user post)a}
  end

  describe "[user upvoted articles]" do
    test "user can get paged upvoted common articles", ~m(user post)a do
      {:ok, _} = CMS.upvote_article(:post, post.id, user)

      filter = %{page: 1, size: 20}
      {:ok, articles} = Accounts.paged_upvoted_articles(user.id, filter)

      article_post = articles |> Map.get(:entries) |> List.last()

      assert articles |> is_valid_pagination?(:raw)
      assert post.id == article_post |> Map.get(:id)

      assert [:author, :id, :thread, :title, :upvotes_count] == article_post |> Map.keys()
    end

    test "user can get paged upvoted posts by thread filter", ~m(user post)a do
      {:ok, _} = CMS.upvote_article(:post, post.id, user)

      filter = %{thread: :post, page: 1, size: 20}
      {:ok, articles} = Accounts.paged_upvoted_articles(user.id, filter)

      assert articles |> is_valid_pagination?(:raw)
      assert post.id == articles |> Map.get(:entries) |> List.last() |> Map.get(:id)
      assert 1 == articles |> Map.get(:total_count)
    end
  end
end
