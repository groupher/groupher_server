defmodule GroupherServer.Test.Mutation.CMS.Dashboard do
  @moduledoc false

  use GroupherServer.TestTools

  alias GroupherServer.CMS

  alias CMS.Model.Community

  alias Helper.ORM
  # alias CMS.Constant

  # @community_normal Constant.pending(:normal)
  # @community_applying Constant.pending(:applying)

  setup do
    {:ok, category} = db_insert(:category)
    {:ok, community} = db_insert(:community)
    {:ok, thread} = db_insert(:thread)
    {:ok, user} = db_insert(:user)

    user_conn = simu_conn(:user)
    guest_conn = simu_conn(:guest)

    {:ok, ~m(user_conn guest_conn community thread category user)a}
  end

  describe "[mutation cms community]" do
    @update_seo_query """
    mutation($community: String!, $ogTitle: String, $ogDescription: String) {
      updateDashboardSeo(community: $community, ogTitle: $ogTitle, ogDescription: $ogDescription) {
        id
        title
      }
    }
    """

    test "update community dashboard seo info", ~m(community)a do
      rule_conn = simu_conn(:user, cms: %{"community.update" => true})
      variables = %{community: community.raw, ogTitle: "new title"}

      updated = rule_conn |> mutation_result(@update_seo_query, variables, "updateDashboardSeo")

      {:ok, found} = Community |> ORM.find(updated["id"], preload: :dashboard)

      assert found.dashboard.seo.og_title == "new title"
    end

    @update_enable_query """
    mutation($community: String!, $post: Boolean, $changelog: Boolean) {
      updateDashboardEnable(community: $community, post: $post, changelog: $changelog) {
        id
      }
    }
    """

    test "update community dashboard enable info", ~m(community)a do
      rule_conn = simu_conn(:user, cms: %{"community.update" => true})
      variables = %{community: community.raw, post: false, changelog: true}

      updated =
        rule_conn |> mutation_result(@update_enable_query, variables, "updateDashboardEnable")

      {:ok, found} = Community |> ORM.find(updated["id"], preload: :dashboard)

      assert found.dashboard.enable.post == false
      assert found.dashboard.enable.changelog == true
    end

    @update_layout_query """
    mutation($community: Stirng!, $postLayout: String, $kanbanLayout: String, $broadcastEnable: Boolean, $kanbanBgColors: [String]) {
      updateDashboardLayout(community: $community, postLayout: $postLayout, kanbanLayout: $kanbanLayout, broadcastEnable: $broadcastEnable, kanbanBgColors: $kanbanBgColors) {
        id
        title
      }
    }
    """
    test "update community dashboard layout info", ~m(community)a do
      rule_conn = simu_conn(:user, cms: %{"community.update" => true})

      variables = %{
        community: community.raw,
        postLayout: "new layout",
        broadcastEnable: true,
        kanbanLayout: "full",
        kanbanBgColors: ["#111", "#222"]
      }

      updated =
        rule_conn
        |> mutation_result(@update_layout_query, variables, "updateDashboardLayout")

      {:ok, found} = Community |> ORM.find(updated["id"], preload: :dashboard)

      assert found.dashboard.layout.post_layout == "new layout"
      assert found.dashboard.layout.kanban_layout == "full"
      assert found.dashboard.layout.broadcast_enable == true
      assert found.dashboard.layout.kanban_bg_colors == ["#111", "#222"]
    end

    test "update community dashboard layout should not overwrite existing settings",
         ~m(community)a do
      rule_conn = simu_conn(:user, cms: %{"community.update" => true})

      variables = %{
        community: community.raw,
        postLayout: "new layout"
      }

      updated =
        rule_conn
        |> mutation_result(@update_layout_query, variables, "updateDashboardLayout")

      {:ok, found} = Community |> ORM.find(updated["id"], preload: :dashboard)

      assert found.dashboard.layout.post_layout == "new layout"
      assert found.dashboard.layout.kanban_layout == ""

      variables = %{
        community: community.raw,
        kanbanLayout: "full"
      }

      updated =
        rule_conn
        |> mutation_result(@update_layout_query, variables, "updateDashboardLayout")

      {:ok, found} = Community |> ORM.find(updated["id"], preload: :dashboard)

      assert found.dashboard.layout.post_layout == "new layout"
      assert found.dashboard.layout.kanban_layout == "full"
    end

    @update_seo_query """
    mutation($community: String!, $rssFeedType: String, $rssFeedCount: Int) {
      updateDashboardRss(community: $community, rssFeedType: $rssFeedType, rssFeedCount: $rssFeedCount) {
        id
        title
      }
    }
    """

    test "update community dashboard rss info", ~m(community)a do
      rule_conn = simu_conn(:user, cms: %{"community.update" => true})

      variables = %{
        community: community.raw,
        rssFeedType: "digest",
        rssFeedCount: 22
      }

      updated =
        rule_conn
        |> mutation_result(@update_seo_query, variables, "updateDashboardRss")

      {:ok, found} = Community |> ORM.find(updated["id"], preload: :dashboard)

      assert found.dashboard.rss.rss_feed_type == "digest"
      assert found.dashboard.rss.rss_feed_count == 22
    end

    @update_alias_query """
    mutation($community: String!, $nameAlias: [dashboardAliasMap]) {
      updateDashboardNameAlias(community: $community, nameAlias: $nameAlias) {
        id
        title
      }
    }
    """
    @tag :wip
    test "update community dashboard name alias info", ~m(community)a do
      rule_conn = simu_conn(:user, cms: %{"community.update" => true})

      variables = %{
        community: community.raw,
        nameAlias: [
          %{
            raw: "raw",
            name: "name",
            original: "original",
            group: "group"
          }
        ]
      }

      updated =
        rule_conn
        |> mutation_result(@update_alias_query, variables, "updateDashboardNameAlias")

      {:ok, found} = Community |> ORM.find(updated["id"], preload: :dashboard)

      found_alias = found.dashboard.name_alias |> Enum.at(0)

      assert found_alias.raw == "raw"
      assert found_alias.name == "name"
      assert found_alias.group == "group"
    end

    @update_header_links_query """
    mutation($community: String!, $headerLinks: [dashboardLinkMap]) {
      updateDashboardHeaderLinks(community: $community, headerLinks: $headerLinks) {
        id
        title
      }
    }
    """
    @tag :wip
    test "update community dashboard header links info", ~m(community)a do
      rule_conn = simu_conn(:user, cms: %{"community.update" => true})

      variables = %{
        community: community.raw,
        headerLinks: [
          %{
            title: "title",
            link: "link",
            group: "group",
            index: 1,
            is_hot: false,
            is_new: false
          }
        ]
      }

      updated =
        rule_conn
        |> mutation_result(@update_header_links_query, variables, "updateDashboardHeaderLinks")

      {:ok, found} = Community |> ORM.find(updated["id"], preload: :dashboard)

      link = found.dashboard.header_links |> Enum.at(0)

      assert link.title == "title"
      assert link.link == "link"
      assert link.group == "group"
    end

    @update_footer_links_query """
    mutation($community: String!, $footerLinks: [dashboardLinkMap]) {
      updateDashboardFooterLinks(community: $community, footerLinks: $footerLinks) {
        id
        title
      }
    }
    """
    @tag :wip
    test "update community dashboard footer links info", ~m(community)a do
      rule_conn = simu_conn(:user, cms: %{"community.update" => true})

      variables = %{
        community: community.raw,
        footerLinks: [
          %{
            title: "title",
            link: "link",
            group: "group",
            index: 1,
            is_hot: false,
            is_new: false
          }
        ]
      }

      updated =
        rule_conn
        |> mutation_result(@update_footer_links_query, variables, "updateDashboardFooterLinks")

      {:ok, found} = Community |> ORM.find(updated["id"], preload: :dashboard)

      link = found.dashboard.footer_links |> Enum.at(0)

      assert link.title == "title"
      assert link.link == "link"
      assert link.group == "group"
    end
  end
end
