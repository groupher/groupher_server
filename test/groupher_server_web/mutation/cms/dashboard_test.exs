defmodule GroupherServer.Test.Mutation.CMS.Dashboard do
  @moduledoc false

  use GroupherServer.TestTools

  alias GroupherServer.{Accounts, CMS}

  alias Accounts.Model.User
  alias CMS.Model.{Category, Community, CommunityEditor, Passport}

  alias Helper.ORM
  alias CMS.Constant

  @community_normal Constant.pending(:normal)
  @community_applying Constant.pending(:applying)

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
    @tag :wip
    test "update community dashboard seo info", ~m(community)a do
      rule_conn = simu_conn(:user, cms: %{"community.update" => true})
      variables = %{id: community.id, ogTitle: "new title"}

      updated = rule_conn |> mutation_result(@update_seo_query, variables, "updateDashboardSeo")

      {:ok, found} = Community |> ORM.find(updated["id"], preload: :dashboard)

      assert found.dashboard.seo.og_title == "new title"
    end

    @update_layout_query """
    mutation($id: ID!, $postLayout: String, $broadcastEnable: Boolean, $kanbanBgColors: [String]) {
      updateDashboardLayout(id: $id, postLayout: $postLayout, broadcastEnable: $broadcastEnable, kanbanBgColors: $kanbanBgColors) {
        id
        title
      }
    }
    """
    @tag :wip
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
  end
end
