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
    mutation($id: ID!, $ogTitle: String, $ogDescription: String) {
      updateDashboardSeo(id: $id, ogTitle: $ogTitle, ogDescription: $ogDescription) {
        id
        title
      }
    }
    """
    test "update community dashboard seo info", ~m(community)a do
      rule_conn = simu_conn(:user, cms: %{"community.update" => true})
      variables = %{id: community.id, ogTitle: "new title"}

      updated = rule_conn |> mutation_result(@update_seo_query, variables, "updateDashboardSeo")

      {:ok, found} = Community |> ORM.find(updated["id"], preload: :dashboard)

      assert found.dashboard.seo.og_title == "new title"
    end

    @update_enable_query """
    mutation($id: ID!, $post: Boolean, $changelog: Boolean) {
      updateDashboardEnable(id: $id, post: $post, changelog: $changelog) {
        id
      }
    }
    """
    @tag :wip
    test "update community dashboard enable info", ~m(community)a do
      rule_conn = simu_conn(:user, cms: %{"community.update" => true})
      variables = %{id: community.id, post: false, changelog: true}

      updated =
        rule_conn |> mutation_result(@update_enable_query, variables, "updateDashboardEnable")

      {:ok, found} = Community |> ORM.find(updated["id"], preload: :dashboard)

      assert found.dashboard.enable.post == false
      assert found.dashboard.enable.changelog == true
    end

    @update_layout_query """
    mutation($id: ID!, $postLayout: String, $broadcastEnable: Boolean, $kanbanBgColors: [String]) {
      updateDashboardLayout(id: $id, postLayout: $postLayout, broadcastEnable: $broadcastEnable, kanbanBgColors: $kanbanBgColors) {
        id
        title
      }
    }
    """
    test "update community dashboard layout info", ~m(community)a do
      rule_conn = simu_conn(:user, cms: %{"community.update" => true})

      variables = %{
        id: community.id,
        postLayout: "new layout",
        broadcastEnable: true,
        kanbanBgColors: ["#111", "#222"]
      }

      updated =
        rule_conn
        |> mutation_result(@update_layout_query, variables, "updateDashboardLayout")

      {:ok, found} = Community |> ORM.find(updated["id"], preload: :dashboard)

      assert found.dashboard.layout.post_layout == "new layout"
      assert found.dashboard.layout.broadcast_enable == true
      assert found.dashboard.layout.kanban_bg_colors == ["#111", "#222"]
    end

    @update_seo_query """
    mutation($id: ID!, $rssFeedType: String, $rssFeedCount: Int) {
      updateDashboardRss(id: $id, rssFeedType: $rssFeedType, rssFeedCount: $rssFeedCount) {
        id
        title
      }
    }
    """
    test "update community dashboard rss info", ~m(community)a do
      rule_conn = simu_conn(:user, cms: %{"community.update" => true})

      variables = %{
        id: community.id,
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
    mutation($id: ID!, $nameAlias: [dashboardAliasMap]) {
      updateDashboardNameAlias(id: $id, nameAlias: $nameAlias) {
        id
        title
      }
    }
    """
    test "update community dashboard name alias info", ~m(community)a do
      rule_conn = simu_conn(:user, cms: %{"community.update" => true})

      variables = %{
        id: community.id,
        nameAlias: [
          %{
            raw: "raw1",
            name: "name",
            original: "original",
            group: "group1"
          }
        ]
      }

      updated =
        rule_conn
        |> mutation_result(@update_alias_query, variables, "updateDashboardNameAlias")

      {:ok, found} = Community |> ORM.find(updated["id"], preload: :dashboard)

      found_alias = found.dashboard.name_alias |> Enum.at(0)

      assert found_alias.raw == "raw1"
      assert found_alias.name == "name"
      assert found_alias.group == "group1"
    end
  end
end
