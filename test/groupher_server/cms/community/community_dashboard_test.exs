defmodule GroupherServer.Test.Community.CommunityDashboard do
  @moduledoc false

  use GroupherServer.TestTools

  import Helper.Utils, only: [strip_struct: 1]

  alias GroupherServer.CMS
  alias CMS.Model.{Community, CommunityDashboard}

  alias Helper.ORM

  @default_dashboard CommunityDashboard.default()

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    community_attrs = mock_attrs(:community) |> Map.merge(%{user_id: user.id})

    {:ok, ~m(user community  community_attrs)a}
  end

  describe "[community dashboard base info]" do
    @tag :wip
    test "created community should have default dashboard.", ~m(community_attrs)a do
      {:ok, community} = CMS.create_community(community_attrs)
      {:ok, find_community} = ORM.find(Community, community.id, preload: :dashboard)

      assert find_community.dashboard.base_info.homepage == @default_dashboard.base_info.homepage
    end

    @tag :wip
    test "read a exist community should have default dashboard field", ~m(community)a do
      {:ok, community} = CMS.read_community(community.raw)

      {:ok, find_community} = ORM.find(Community, community.id, preload: :dashboard)

      assert not is_nil(find_community.dashboard)
    end

    @tag :wip
    test "can update base info in community dashboard", ~m(community_attrs)a do
      {:ok, community} = CMS.create_community(community_attrs)

      {:ok, _} =
        CMS.update_dashboard(community.id, :base_info, %{homepage: "https://groupher.com"})

      {:ok, find_community} = ORM.find(Community, community.id, preload: :dashboard)

      assert find_community.dashboard.base_info.homepage == "https://groupher.com"
    end

    @tag :wip
    test "can update seo in community dashboard", ~m(community_attrs)a do
      {:ok, community} = CMS.create_community(community_attrs)

      {:ok, _} = CMS.update_dashboard(community.id, :seo, %{og_title: "groupher"})

      {:ok, find_community} = ORM.find(Community, community.id, preload: :dashboard)

      assert find_community.dashboard.seo.og_title == "groupher"
    end

    @tag :wip
    test "can update layout in community dashboard", ~m(community_attrs)a do
      {:ok, community} = CMS.create_community(community_attrs)

      {:ok, _} = CMS.update_dashboard(community.id, :layout, %{post_layout: "upvote_first"})

      {:ok, find_community} = ORM.find(Community, community.id, preload: :dashboard)

      assert find_community.dashboard.layout.post_layout == "upvote_first"
    end
  end
end