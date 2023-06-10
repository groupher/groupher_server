defmodule GroupherServer.Test.Community.CommunityDashboard do
  @moduledoc false

  use GroupherServer.TestTools

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
    test "created community should have default dashboard.", ~m(community_attrs)a do
      {:ok, community} = CMS.create_community(community_attrs)
      {:ok, find_community} = ORM.find(Community, community.id, preload: :dashboard)

      assert find_community.dashboard.base_info.homepage == @default_dashboard.base_info.homepage
    end

    test "read a exist community should have default dashboard field", ~m(community)a do
      {:ok, community} = CMS.read_community(community.raw)

      {:ok, find_community} = ORM.find(Community, community.id, preload: :dashboard)

      assert not is_nil(find_community.dashboard)
    end

    test "can update base info in community dashboard", ~m(community_attrs)a do
      {:ok, community} = CMS.create_community(community_attrs)

      {:ok, _} =
        CMS.update_dashboard(community.raw, :base_info, %{homepage: "https://groupher.com"})

      {:ok, find_community} = ORM.find(Community, community.id, preload: :dashboard)

      assert find_community.dashboard.base_info.homepage == "https://groupher.com"
    end

    test "can update seo in community dashboard", ~m(community_attrs)a do
      {:ok, community} = CMS.create_community(community_attrs)

      {:ok, _} =
        CMS.update_dashboard(community.raw, :seo, %{
          og_title: "groupher",
          og_description: "forum sass provider"
        })

      {:ok, find_community} = ORM.find(Community, community.id, preload: :dashboard)

      assert find_community.dashboard.seo.og_title == "groupher"
      assert find_community.dashboard.seo.og_description == "forum sass provider"
    end

    test "can update layout in community dashboard", ~m(community_attrs)a do
      {:ok, community} = CMS.create_community(community_attrs)

      {:ok, _} =
        CMS.update_dashboard(community.raw, :layout, %{
          post_layout: "upvote_first",
          changelog_layout: "full"
        })

      {:ok, find_community} = ORM.find(Community, community.id, preload: :dashboard)

      assert find_community.dashboard.layout.post_layout == "upvote_first"
      assert find_community.dashboard.layout.changelog_layout == "full"
    end

    test "can update rss in community dashboard", ~m(community_attrs)a do
      {:ok, community} = CMS.create_community(community_attrs)

      {:ok, _} =
        CMS.update_dashboard(community.raw, :rss, %{
          rss_feed_type: "full",
          rss_feed_count: 25
        })

      {:ok, find_community} = ORM.find(Community, community.id, preload: :dashboard)

      assert find_community.dashboard.rss.rss_feed_type == "full"
      assert find_community.dashboard.rss.rss_feed_count == 25
    end

    test "can update alias in community dashboard", ~m(community_attrs)a do
      {:ok, community} = CMS.create_community(community_attrs)

      {:ok, _} =
        CMS.update_dashboard(community.raw, :name_alias, [
          %{
            raw: "raw",
            name: "name",
            original: "original",
            group: "group"
          }
        ])

      {:ok, find_community} = ORM.find(Community, community.id, preload: :dashboard)

      first = find_community.dashboard.name_alias |> Enum.at(0)

      assert first.raw == "raw"
      assert first.name == "name"
      assert first.original == "original"
      assert first.group == "group"
    end

    test "should overwirte all alias in community dashboard everytime", ~m(community_attrs)a do
      {:ok, community} = CMS.create_community(community_attrs)

      {:ok, _} =
        CMS.update_dashboard(community.raw, :name_alias, [
          %{
            raw: "raw",
            name: "name",
            original: "original",
            group: "group"
          },
          %{
            raw: "raw2",
            name: "name2",
            original: "original2",
            group: "group2"
          }
        ])

      {:ok, find_community} = ORM.find(Community, community.id, preload: :dashboard)

      assert find_community.dashboard.name_alias |> length == 2

      first = find_community.dashboard.name_alias |> Enum.at(0)
      second = find_community.dashboard.name_alias |> Enum.at(1)

      assert first.raw == "raw"
      assert second.raw == "raw2"

      {:ok, _} =
        CMS.update_dashboard(community.raw, :name_alias, [
          %{
            raw: "raw3",
            name: "name3",
            original: "original3",
            group: "group3"
          }
        ])

      {:ok, find_community} = ORM.find(Community, community.id, preload: :dashboard)
      assert find_community.dashboard.name_alias |> length == 1

      third = find_community.dashboard.name_alias |> Enum.at(0)
      assert third.raw == "raw3"
    end

    test "can update header links in community dashboard", ~m(community_attrs)a do
      {:ok, community} = CMS.create_community(community_attrs)

      {:ok, _} =
        CMS.update_dashboard(community.raw, :header_links, [
          %{
            title: "title",
            link: "link",
            group: "group",
            group_index: 1,
            index: 1,
            is_hot: false,
            is_new: false
          }
        ])

      {:ok, find_community} = ORM.find(Community, community.id, preload: :dashboard)

      first = find_community.dashboard.header_links |> Enum.at(0)

      assert first.title == "title"
      assert first.link == "link"
      assert first.group == "group"
      assert first.group_index == 1
    end

    test "should overwirte all header links in community dashboard everytime",
         ~m(community_attrs)a do
      {:ok, community} = CMS.create_community(community_attrs)

      {:ok, _} =
        CMS.update_dashboard(community.raw, :header_links, [
          %{
            title: "title",
            link: "link",
            group: "group",
            group_index: 1,
            index: 1,
            is_hot: false,
            is_new: false
          },
          %{
            title: "title2",
            link: "link2",
            group: "group2",
            group_index: 2,
            index: 2,
            is_hot: false,
            is_new: false
          }
        ])

      {:ok, find_community} = ORM.find(Community, community.id, preload: :dashboard)

      assert find_community.dashboard.header_links |> length == 2

      first = find_community.dashboard.header_links |> Enum.at(0)
      second = find_community.dashboard.header_links |> Enum.at(1)

      assert first.title == "title"
      assert first.group_index == 1
      assert second.title == "title2"
      assert second.group_index == 2

      {:ok, _} =
        CMS.update_dashboard(community.raw, :header_links, [
          %{
            title: "title3",
            link: "link3",
            group: "group3",
            index: 1,
            is_hot: false,
            is_new: false
          }
        ])

      {:ok, find_community} = ORM.find(Community, community.id, preload: :dashboard)
      assert find_community.dashboard.header_links |> length == 1

      third = find_community.dashboard.header_links |> Enum.at(0)
      assert third.title == "title3"
    end

    test "can update footer links in community dashboard", ~m(community_attrs)a do
      {:ok, community} = CMS.create_community(community_attrs)

      {:ok, _} =
        CMS.update_dashboard(community.raw, :footer_links, [
          %{
            title: "title",
            link: "link",
            group: "group",
            index: 1,
            is_hot: false,
            is_new: false
          }
        ])

      {:ok, find_community} = ORM.find(Community, community.id, preload: :dashboard)

      first = find_community.dashboard.footer_links |> Enum.at(0)

      assert first.title == "title"
      assert first.link == "link"
      assert first.group == "group"
    end

    test "should overwirte all footer links in community dashboard everytime",
         ~m(community_attrs)a do
      {:ok, community} = CMS.create_community(community_attrs)

      {:ok, _} =
        CMS.update_dashboard(community.raw, :footer_links, [
          %{
            title: "title",
            link: "link",
            group: "group",
            index: 1,
            is_hot: false,
            is_new: false
          },
          %{
            title: "title2",
            link: "link2",
            group: "group2",
            index: 2,
            is_hot: false,
            is_new: false
          }
        ])

      {:ok, find_community} = ORM.find(Community, community.id, preload: :dashboard)

      assert find_community.dashboard.footer_links |> length == 2

      first = find_community.dashboard.footer_links |> Enum.at(0)
      second = find_community.dashboard.footer_links |> Enum.at(1)

      assert first.title == "title"
      assert second.title == "title2"

      {:ok, _} =
        CMS.update_dashboard(community.raw, :footer_links, [
          %{
            title: "title3",
            link: "link3",
            group: "group3",
            group_index: 3,
            index: 1,
            is_hot: false,
            is_new: false
          }
        ])

      {:ok, find_community} = ORM.find(Community, community.id, preload: :dashboard)
      assert find_community.dashboard.footer_links |> length == 1

      third = find_community.dashboard.footer_links |> Enum.at(0)
      assert third.title == "title3"
      assert third.group_index == 3
    end
  end
end
