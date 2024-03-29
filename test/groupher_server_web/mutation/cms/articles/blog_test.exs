defmodule GroupherServer.Test.Mutation.Articles.Blog do
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.{CMS, Repo}

  alias CMS.Model.{Blog, Author}

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    blog_attrs = mock_attrs(:blog, %{community_id: community.id})
    {:ok, blog} = CMS.create_article(community, :blog, blog_attrs, user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:owner, blog)

    {:ok, ~m(user_conn guest_conn owner_conn user community blog)a}
  end

  describe "[mutation blog curd]" do
    @create_blog_query """
    mutation(
      $title: String!
      $body: String!
      $communityId: ID!
      $articleTags: [ID]
      $linkAddr: String
    ) {
      createBlog(
        title: $title
        body: $body
        communityId: $communityId
        articleTags: $articleTags
        linkAddr: $linkAddr
      ) {
        id
        title
        linkAddr
        document {
          bodyHtml
        }
        originalCommunity {
          id
        }
      }
    }
    """
    test "create blog with valid attrs and make sure author exsit" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)
      blog_attr = mock_attrs(:blog) |> Map.merge(%{linkAddr: "https://helloworld"})

      # body = """
      # {"time":1639375020110,"blocks":[{"type":"list","data":{"mode":"unordered_list","items":[{"text":"CP 的图标是字母 C (Coder / China) 和 Planet 的意象结合，斜向的条饰灵感来自于 NASA Logo 上的 \"red chevron\"。","label":null,"labelType":null,"checked":false,"hideLabel":true,"prefixIndex":"","indent":0},{"text":"所有的 Upvote 的图标都是小火箭，点击它会有一个起飞的动画 — 虽然它目前看起来像爆炸。。","label":null,"labelType":null,"checked":false,"hideLabel":true,"prefixIndex":"","indent":0}]}}],"version":"2.19.38"}
      # """
      body = """
      {"time":1639375020110,"blocks":[{"type":"list","data":{"mode":"unordered_list","items":[{"text":"CP 的图标是字母 C (Coder / China) 和 Planet 的意象结合，斜向的条饰灵感来自于 NASA Logo 上的 red chevron。","label":null,"labelType":null,"checked":false,"hideLabel":true,"prefixIndex":"","indent":0},{"text":"所有的 Upvote 的图标都是小火箭，点击它会有一个起飞的动画 — 虽然它目前看起来像爆炸。。","label":null,"labelType":null,"checked":false,"hideLabel":true,"prefixIndex":"","indent":0}]}}],"version":"2.19.38"}
      """

      variables = blog_attr |> Map.merge(%{communityId: community.id, body: body})

      created = user_conn |> mutation_result(@create_blog_query, variables, "createBlog")

      {:ok, blog} = ORM.find(Blog, created["id"])

      assert created["id"] == to_string(blog.id)
      assert created["originalCommunity"]["id"] == to_string(community.id)
      assert created["linkAddr"] == "https://helloworld"

      assert {:ok, _} = ORM.find_by(Author, user_id: user.id)
    end

    test "create blog with valid tags id list", ~m(user_conn user community)a do
      article_tag_attrs = mock_attrs(:article_tag)
      {:ok, article_tag} = CMS.create_article_tag(community, :blog, article_tag_attrs, user)

      blog_attr = mock_attrs(:blog)

      variables =
        blog_attr |> Map.merge(%{communityId: community.id, articleTags: [article_tag.id]})

      created = user_conn |> mutation_result(@create_blog_query, variables, "createBlog")

      {:ok, blog} = ORM.find(Blog, created["id"], preload: :article_tags)

      assert exist_in?(%{id: article_tag.id}, blog.article_tags)
    end

    test "create blog should excape xss attracts" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)

      blog_attr = mock_attrs(:blog, %{body: mock_xss_string()})
      variables = blog_attr |> Map.merge(%{communityId: community.id}) |> camelize_map_key
      result = user_conn |> mutation_result(@create_blog_query, variables, "createBlog")
      {:ok, blog} = ORM.find(Blog, result["id"], preload: :document)
      body_html = blog |> get_in([:document, :body_html])

      assert not String.contains?(body_html, "script")
    end

    test "create blog should excape xss attracts 2" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)

      blog_attr = mock_attrs(:blog, %{body: mock_xss_string(:safe)})
      variables = blog_attr |> Map.merge(%{communityId: community.id}) |> camelize_map_key
      result = user_conn |> mutation_result(@create_blog_query, variables, "createBlog")
      {:ok, blog} = ORM.find(Blog, result["id"], preload: :document)
      body_html = blog |> get_in([:document, :body_html])

      assert String.contains?(body_html, "&lt;script&gt;blackmail&lt;/script&gt;")
    end

    # NOTE: this test is IMPORTANT, cause json_codec: Jason in router will cause
    # server crash when GraphQL parse error

    test "create blog with missing non_null field should get 200 error" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)
      blog_attr = mock_attrs(:blog)
      variables = blog_attr |> Map.merge(%{communityId: community.id}) |> Map.delete(:title)

      assert user_conn |> mutation_get_error?(@create_blog_query, variables)
    end

    @query """
    mutation($id: ID!){
      deleteBlog(id: $id) {
        id
      }
    }
    """

    test "delete a blog by blog's owner", ~m(owner_conn blog)a do
      deleted = owner_conn |> mutation_result(@query, %{id: blog.id}, "deleteBlog")

      assert deleted["id"] == to_string(blog.id)
      assert {:error, _} = ORM.find(Blog, deleted["id"])
    end

    test "can delete a blog by auth user", ~m(blog)a do
      blog = blog |> Repo.preload(:communities)
      belongs_community_title = blog.communities |> List.first() |> Map.get(:title)

      rule_conn = simu_conn(:user, cms: %{belongs_community_title => %{"blog.delete" => true}})

      deleted = rule_conn |> mutation_result(@query, %{id: blog.id}, "deleteBlog")

      assert deleted["id"] == to_string(blog.id)
      assert {:error, _} = ORM.find(Blog, deleted["id"])
    end

    test "delete a blog without login user fails", ~m(guest_conn blog)a do
      assert guest_conn |> mutation_get_error?(@query, %{id: blog.id}, ecode(:account_login))
    end

    test "login user with auth passport delete a blog", ~m(blog)a do
      blog = blog |> Repo.preload(:communities)
      blog_communities_0 = blog.communities |> List.first() |> Map.get(:title)
      passport_rules = %{blog_communities_0 => %{"blog.delete" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      # assert conn |> mutation_get_error?(@query, %{id: blog.id})

      deleted = rule_conn |> mutation_result(@query, %{id: blog.id}, "deleteBlog")

      assert deleted["id"] == to_string(blog.id)
    end

    test "unauth user delete blog fails", ~m(user_conn guest_conn blog)a do
      variables = %{id: blog.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!, $title: String, $body: String, $articleTags: [ID]){
      updateBlog(id: $id, title: $title, body: $body, articleTags: $articleTags) {
        id
        title
        document {
          bodyHtml
        }
        meta {
          isEdited
        }
        commentsParticipants {
          id
          nickname
        }
        articleTags {
          id
        }
      }
    }
    """
    test "update a blog without login user fails", ~m(guest_conn blog)a do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: blog.id,
        title: "updated title #{unique_num}",
        body: mock_rich_text("updated body #{unique_num}")
      }

      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end

    test "blog can be update by owner", ~m(owner_conn blog)a do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: blog.id,
        title: "updated title #{unique_num}",
        # body: mock_rich_text("updated body #{unique_num}"),,
        body: mock_rich_text("updated body #{unique_num}")
      }

      result = owner_conn |> mutation_result(@query, variables, "updateBlog")
      assert result["title"] == variables.title

      assert result
             |> get_in(["document", "bodyHtml"])
             |> String.contains?(~s(updated body #{unique_num}))

      assert result["title"] == variables.title
    end

    test "update blog with valid attrs should have is_edited meta info update",
         ~m(owner_conn blog)a do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: blog.id,
        title: "updated title #{unique_num}",
        body: mock_rich_text("updated body #{unique_num}")
      }

      updated_blog = owner_conn |> mutation_result(@query, variables, "updateBlog")

      assert true == updated_blog["meta"]["isEdited"]
    end

    test "login user with auth passport update a blog", ~m(blog)a do
      blog = blog |> Repo.preload(:communities)
      belongs_community_title = blog.communities |> List.first() |> Map.get(:title)

      passport_rules = %{belongs_community_title => %{"blog.edit" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      # assert conn |> mutation_get_error?(@query, %{id: blog.id})
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: blog.id,
        title: "updated title #{unique_num}",
        body: mock_rich_text("updated body #{unique_num}")
      }

      updated_blog = rule_conn |> mutation_result(@query, variables, "updateBlog")

      assert updated_blog["id"] == to_string(blog.id)
    end

    test "unauth user update blog fails", ~m(user_conn guest_conn blog)a do
      unique_num = System.unique_integer([:positive, :monotonic])

      variables = %{
        id: blog.id,
        title: "updated title #{unique_num}",
        body: mock_rich_text("updated body #{unique_num}")
      }

      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end
  end
end
