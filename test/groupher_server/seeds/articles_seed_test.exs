defmodule GroupherServer.Test.Seeds.Articles do
  @moduledoc false
  use GroupherServer.TestTools

  # alias GroupherServer.Accounts.Model.User
  alias GroupherServer.CMS

  alias CMS.Model.{Post, Job, Radar}
  # alias CMS.Delegate.SeedsConfig

  alias Helper.ORM

  describe "[posts seed]" do
    test "can seed posts" do
      {:ok, community} = CMS.seed_community(:home)
      CMS.seed_articles(community, :post, 5)

      {:ok, posts} = ORM.find_all(Post, %{page: 1, size: 20})
      ramdom_post = posts.entries |> List.first()

      {:ok, ramdom_post} = ORM.find(Post, ramdom_post.id, preload: [:article_tags, :document])

      assert ramdom_post.article_tags |> length == 1
      assert ramdom_post.upvotes_count !== 0
      assert ramdom_post.meta.latest_upvoted_users |> length !== 0
      assert not is_nil(ramdom_post.document.body_html)

      original_community_ids =
        posts.entries |> Enum.map(& &1.original_community_id) |> Enum.uniq()

      assert original_community_ids === [community.id]

      {:ok, paged_comments} =
        CMS.paged_comments(:post, ramdom_post.id, %{page: 1, size: 10}, :timeline)

      # IO.inspect(paged_comments, label: "paged_comments -> ")
      assert paged_comments.total_count !== 0
    end

    test "can seed radars" do
      {:ok, community} = CMS.seed_community(:home)
      CMS.seed_articles(community, :radar, 5)

      {:ok, radars} = ORM.find_all(Radar, %{page: 1, size: 20})
      ramdom_radar = radars.entries |> List.first()
      {:ok, ramdom_radar} = ORM.find(Radar, ramdom_radar.id, preload: [:article_tags])

      assert ramdom_radar.upvotes_count !== 0
      assert ramdom_radar.meta.latest_upvoted_users |> length !== 0

      original_community_ids =
        radars.entries |> Enum.map(& &1.original_community_id) |> Enum.uniq()

      assert original_community_ids === [community.id]

      {:ok, paged_comments} =
        CMS.paged_comments(:radar, ramdom_radar.id, %{page: 1, size: 20}, :timeline)

      assert paged_comments.total_count !== 0
    end
  end
end
