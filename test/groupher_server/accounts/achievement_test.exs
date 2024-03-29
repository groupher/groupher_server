defmodule GroupherServer.Test.Accounts.Achievement do
  use GroupherServer.TestTools
  import Helper.Utils, only: [get_config: 2]

  alias GroupherServer.{Accounts, CMS}
  alias Accounts.Model.{User, Achievement}
  alias Helper.ORM

  @follow_weight get_config(:general, :user_achieve_follow_weight)
  @collect_weight get_config(:general, :user_achieve_collect_weight)
  @upvote_weight get_config(:general, :user_achieve_upvote_weight)
  # @watch_weight get_config(:general, :user_achieve_watch_weight)

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, user3} = db_insert(:user)

    {:ok, ~m(user user2 user3)a}
  end

  describe "[Accounts Achievement communities]" do
    test "normal user should have a empty editable communities list", ~m(user)a do
      {:ok, results} = Accounts.paged_moderatorable_communities(user, %{page: 1, size: 20})

      assert results |> is_valid_pagination?(:raw)
      assert results.total_count == 0
    end

    test "community moderator should get a editable community list",
         ~m(user user2 user3)a do
      community_attrs = mock_attrs(:community) |> Map.merge(%{user_id: user.id})
      {:ok, community} = CMS.create_community(community_attrs)

      community_attrs = mock_attrs(:community) |> Map.merge(%{user_id: user2.id})
      {:ok, community2} = CMS.create_community(community_attrs)

      role = "moderator"

      {:ok, _} = CMS.add_moderator(community.slug, role, user3, user)
      {:ok, _} = CMS.add_moderator(community2.slug, role, user3, user2)
      {:ok, _} = CMS.add_moderator(community.slug, role, user2, user)

      {:ok, moderatorable_communities} =
        Accounts.paged_moderatorable_communities(user3, %{page: 1, size: 20})

      assert moderatorable_communities.total_count == 2
      assert moderatorable_communities.entries |> Enum.any?(&(&1.id == community.id))
      assert moderatorable_communities.entries |> Enum.any?(&(&1.id == community2.id))
    end
  end

  describe "[Accounts Achievement funtion]" do
    test "Accounts.achieve should inc / dec achievement by parts", ~m(user)a do
      user |> Accounts.achieve(:inc, :follow)
      user |> Accounts.achieve(:inc, :upvote)
      user |> Accounts.achieve(:inc, :collect)
      {:ok, achievement} = Achievement |> ORM.find_by(user_id: user.id)

      assert achievement.followers_count == 1
      assert achievement.articles_upvotes_count == 1
      assert achievement.articles_collects_count == 1

      reputation = @follow_weight + @upvote_weight + @collect_weight
      assert achievement.reputation == reputation

      user |> Accounts.achieve(:dec, :follow)
      user |> Accounts.achieve(:dec, :upvote)
      user |> Accounts.achieve(:dec, :collect)

      {:ok, achievement} = Achievement |> ORM.find_by(user_id: user.id)
      assert achievement.followers_count == 0
      assert achievement.followers_count == 0
      assert achievement.followers_count == 0
      assert achievement.reputation == 0
    end

    test "Accounts.achieve can not minus count < 0", ~m(user)a do
      user |> Accounts.achieve(:dec, :follow)
      user |> Accounts.achieve(:dec, :upvote)
      user |> Accounts.achieve(:dec, :collect)

      {:ok, achievement} = Achievement |> ORM.find_by(user_id: user.id)
      assert achievement.followers_count == 0
      assert achievement.followers_count == 0
      assert achievement.followers_count == 0
      assert achievement.reputation == 0
    end
  end

  describe "[follow achievement]" do
    test "user get achievement inc after other user follows", ~m(user)a do
      total_count = 20
      {:ok, users} = db_insert_multi(:user, 20)

      Enum.each(users, fn cool_user ->
        {:ok, _} = cool_user |> Accounts.follow(user)
      end)

      {:ok, user} = User |> ORM.find(user.id, preload: :achievement)

      assert user.achievement.followers_count == total_count
      assert user.achievement.reputation == @follow_weight * total_count
    end

    test "user get achievement down after other user undo follows", ~m(user)a do
      total_count = 20
      {:ok, users} = db_insert_multi(:user, 20)

      Enum.each(users, fn cool_user ->
        {:ok, _} = cool_user |> Accounts.follow(user)
      end)

      one_folloer = users |> List.first()
      one_folloer |> Accounts.undo_follow(user)

      {:ok, user} = User |> ORM.find(user.id, preload: :achievement)

      assert user.achievement.followers_count == total_count - 1
      assert user.achievement.reputation == @follow_weight * total_count - @follow_weight
    end
  end
end
