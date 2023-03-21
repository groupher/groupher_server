defmodule GroupherServer.Test.CMS.Articles.Kanban do
  use GroupherServer.TestTools

  alias GroupherServer.CMS
  alias Helper.ORM

  alias CMS.Model.Author

  alias CMS.Constant

  @article_cat Constant.article_cat()
  @article_state Constant.article_state()

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, post} = db_insert(:post)
    {:ok, community} = db_insert(:community)

    post_attrs = mock_attrs(:post, %{community_id: community.id})

    {:ok, ~m(user user2 community post post_attrs)a}
  end

  describe "[cms kanban curd]" do
    @tag :wip
    test "can create kanban post should have default cat & state",
         ~m(user community post_attrs)a do
      assert {:error, _} = ORM.find_by(Author, user_id: user.id)

      kanban_attrs = post_attrs

      {:ok, kanban} = CMS.create_article(community, :post, kanban_attrs, user)

      assert kanban.cat == nil
      assert kanban.state == nil
    end

    @tag :wip
    test "can create kanban post with valid attrs", ~m(user community post_attrs)a do
      assert {:error, _} = ORM.find_by(Author, user_id: user.id)

      kanban_attrs =
        post_attrs |> Map.merge(%{cat: @article_cat.feature, state: @article_state.done})

      {:ok, kanban} = CMS.create_article(community, :post, kanban_attrs, user)

      assert kanban.cat == @article_cat.feature
      assert kanban.state == @article_state.done
    end

    @tag :wip
    test "can get paged kanban posts", ~m(user community post_attrs)a do
      kanban_attrs =
        post_attrs |> Map.merge(%{cat: @article_cat.feature, state: @article_state.todo})

      {:ok, _} = CMS.create_article(community, :post, kanban_attrs, user)
      {:ok, _} = CMS.create_article(community, :post, kanban_attrs, user)

      kanban_attrs =
        post_attrs |> Map.merge(%{cat: @article_cat.feature, state: @article_state.wip})

      {:ok, _} = CMS.create_article(community, :post, kanban_attrs, user)

      kanban_attrs =
        post_attrs |> Map.merge(%{cat: @article_cat.feature, state: @article_state.done})

      {:ok, _} = CMS.create_article(community, :post, kanban_attrs, user)
      {:ok, _} = CMS.create_article(community, :post, kanban_attrs, user)

      {:ok, paged_todo_posts} =
        CMS.paged_kanban_posts(community.id, %{state: @article_state.todo, page: 1, size: 20})

      {:ok, paged_wip_posts} =
        CMS.paged_kanban_posts(community.id, %{state: @article_state.wip, page: 1, size: 20})

      {:ok, paged_done_posts} =
        CMS.paged_kanban_posts(community.id, %{state: @article_state.done, page: 1, size: 20})

      assert paged_todo_posts |> is_valid_pagination?(:raw)
      assert paged_wip_posts |> is_valid_pagination?(:raw)
      assert paged_done_posts |> is_valid_pagination?(:raw)

      assert paged_todo_posts.entries
             |> Enum.filter(&(&1.state == @article_state.todo))
             |> length == 2

      assert paged_wip_posts.entries
             |> Enum.filter(&(&1.state == @article_state.wip))
             |> length == 1

      assert paged_done_posts.entries
             |> Enum.filter(&(&1.state == @article_state.done))
             |> length == 2
    end

    @tag :wip
    test "can get default empty grouped kanban posts", ~m(community)a do
      {:ok, grouped_kanban_posts} = CMS.grouped_kanban_posts(community.id)

      assert grouped_kanban_posts.todo |> is_valid_pagination?(:raw)
      assert grouped_kanban_posts.wip |> is_valid_pagination?(:raw)
      assert grouped_kanban_posts.done |> is_valid_pagination?(:raw)

      assert grouped_kanban_posts.todo.entries
             |> Enum.filter(&(&1.state == @article_state.todo))
             |> length == 0

      assert grouped_kanban_posts.wip.entries
             |> Enum.filter(&(&1.state == @article_state.wip))
             |> length == 0

      assert grouped_kanban_posts.done.entries
             |> Enum.filter(&(&1.state == @article_state.done))
             |> length == 0
    end

    @tag :wip
    test "can get grouped kanban posts", ~m(user community post_attrs)a do
      kanban_attrs =
        post_attrs |> Map.merge(%{cat: @article_cat.feature, state: @article_state.todo})

      {:ok, _} = CMS.create_article(community, :post, kanban_attrs, user)
      {:ok, _} = CMS.create_article(community, :post, kanban_attrs, user)

      kanban_attrs =
        post_attrs |> Map.merge(%{cat: @article_cat.feature, state: @article_state.wip})

      {:ok, _} = CMS.create_article(community, :post, kanban_attrs, user)

      kanban_attrs =
        post_attrs |> Map.merge(%{cat: @article_cat.feature, state: @article_state.done})

      {:ok, _} = CMS.create_article(community, :post, kanban_attrs, user)
      {:ok, _} = CMS.create_article(community, :post, kanban_attrs, user)

      {:ok, grouped_kanban_posts} = CMS.grouped_kanban_posts(community.id)

      assert grouped_kanban_posts.todo |> is_valid_pagination?(:raw)
      assert grouped_kanban_posts.wip |> is_valid_pagination?(:raw)
      assert grouped_kanban_posts.done |> is_valid_pagination?(:raw)

      assert grouped_kanban_posts.todo.entries
             |> Enum.filter(&(&1.state == @article_state.todo))
             |> length == 2

      assert grouped_kanban_posts.wip.entries
             |> Enum.filter(&(&1.state == @article_state.wip))
             |> length == 1

      assert grouped_kanban_posts.done.entries
             |> Enum.filter(&(&1.state == @article_state.done))
             |> length == 2
    end
  end
end
