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
    @update_info_query """
    mutation($community: String!, $homepage: String, $title: String, $slug: String, $desc: String, $introduction: String, $logo: String, $favicon: String, $city: String, $techstack: String) {
      updateDashboardBaseInfo(community: $community, homepage: $homepage, title: $title, slug: $slug, desc: $desc, introduction: $introduction, logo: $logo, favicon: $favicon, city: $city, techstack: $techstack) {
        id
        title

        dashboard {
          baseInfo {
            title
            introduction
          }
        }
      }
    }
    """
    test "update community dashboard base info", ~m(community)a do
      rule_conn = simu_conn(:user, cms: %{"community.update" => true})

      variables = %{
        community: community.slug,
        title: "groupher",
        slug: "groupher",
        homepage: "https://groupher.com",
        desc: "thie community is awesome",
        introduction: """
        I feel very happy writing this post. After reading this post you might feel the same as me.

        So let's know why NASA thanked India and China.

        A new study shows that two countries with the world's largest population are leading the increase in greenery on land.

        Putting photos, NASA said that there is more greenery on the Earth than 20 years ago, which has been credited by India and China.

        In the last 20 years, India and China have planted quite a lot of trees, you can see it in the picture above.

        India is breaking the world record in plantations, with 800,000 Indians planting 50 million trees in just 24 hours.

        The most important conclusion from the data is that the increase in green areas on the planet is almost entirely due to human action.

        But we do not have to stop now, I request everyone to plant some trees.
        """,
        logo: "logo",
        favicon: "favicon",
        city: "chengdu,shanghai",
        techstack: "Javascript,Elixir"
      }

      updated =
        rule_conn
        |> mutation_result(@update_info_query, variables, "updateDashboardBaseInfo")

      {:ok, found} = Community |> ORM.find(updated["id"], preload: :dashboard)

      assert found.dashboard.base_info.introduction |> String.length() == 828
      assert found.dashboard.base_info.title == "groupher"
      assert found.dashboard.base_info.desc == "thie community is awesome"
      assert found.dashboard.base_info.slug == "groupher"

      assert found.dashboard.base_info.city == "chengdu,shanghai"
      assert found.dashboard.base_info.techstack == "Javascript,Elixir"
    end

    @update_seo_query """
    mutation($community: String!, $ogTitle: String, $ogDescription: String, $seoEnable: Boolean) {
      updateDashboardSeo(community: $community, ogTitle: $ogTitle, ogDescription: $ogDescription, seoEnable: $seoEnable) {
        id
        title
        dashboard {
          seo {
            seoEnable
          }
        }
      }
    }
    """
    test "update community dashboard seo info", ~m(community)a do
      rule_conn = simu_conn(:user, cms: %{"community.update" => true})
      variables = %{community: community.slug, ogTitle: "new title", seoEnable: false}

      updated = rule_conn |> mutation_result(@update_seo_query, variables, "updateDashboardSeo")

      assert get_in(updated, ["dashboard", "seo", "seoEnable"]) == false

      {:ok, found} = Community |> ORM.find(updated["id"], preload: :dashboard)

      assert found.dashboard.seo.og_title == "new title"
      assert found.dashboard.seo.seo_enable == false
    end

    @update_wallpaper_query """
    mutation (
      $community: String!
      $wallpaper: String
      $wallpaperType: String
      $direction: String
      $customColorValue: String
      $bgSize: String
      $uploadBgImage: String
      $hasPattern: Boolean
      $hasBlur: Boolean
      $hasShadow: Boolean
      ) {
      updateDashboardWallpaper(
        community: $community
        wallpaper: $wallpaper
        wallpaperType: $wallpaperType
        direction: $direction
        customColorValue: $customColorValue
        bgSize: $bgSize
        uploadBgImage: $uploadBgImage
        hasPattern: $hasPattern
        hasBlur: $hasBlur
        hasShadow: $hasShadow
      ) {
        id
        title
        dashboard {
          wallpaper {
            wallpaperType
            wallpaper
          }
        }
      }
    }
    """
    test "update community dashboard wallpaper", ~m(community)a do
      rule_conn = simu_conn(:user, cms: %{"community.update" => true})
      variables = %{community: community.slug, wallpaper: "orange", wallpaperType: "custom"}

      updated =
        rule_conn
        |> mutation_result(@update_wallpaper_query, variables, "updateDashboardWallpaper")

      assert get_in(updated, ["dashboard", "wallpaper", "wallpaper"]) == "orange"

      {:ok, found} = Community |> ORM.find(updated["id"], preload: :dashboard)

      assert found.dashboard.wallpaper.wallpaper == "orange"
      assert found.dashboard.wallpaper.wallpaper_type == "custom"
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
      variables = %{community: community.slug, post: false, changelog: true}

      updated =
        rule_conn |> mutation_result(@update_enable_query, variables, "updateDashboardEnable")

      {:ok, found} = Community |> ORM.find(updated["id"], preload: :dashboard)

      assert found.dashboard.enable.post == false
      assert found.dashboard.enable.changelog == true
    end

    @update_layout_query """
    mutation($community: Stirng!, $postLayout: String, $kanbanLayout: String, $footerLayout: String, $broadcastEnable: Boolean, $kanbanBgColors: [String], $glowType: String, $glowFixed: Boolean, $glowOpacity: String) {
      updateDashboardLayout(community: $community, postLayout: $postLayout, kanbanLayout: $kanbanLayout, footerLayout: $footerLayout, broadcastEnable: $broadcastEnable, kanbanBgColors: $kanbanBgColors, glowType: $glowType, glowFixed: $glowFixed, glowOpacity: $glowOpacity) {
        id
        title
        dashboard {
          layout {
            footerLayout
            glowType
            glowFixed
            glowOpacity
          }
        }
      }
    }
    """
    test "update community dashboard layout info", ~m(community)a do
      rule_conn = simu_conn(:user, cms: %{"community.update" => true})

      variables = %{
        community: community.slug,
        postLayout: "new layout",
        broadcastEnable: true,
        kanbanLayout: "full",
        footerLayout: "simple",
        kanbanBgColors: ["#111", "#222"],
        glowType: "PINK",
        glowFixed: true,
        glowOpacity: "30"
      }

      updated =
        rule_conn
        |> mutation_result(@update_layout_query, variables, "updateDashboardLayout")

      {:ok, found} = Community |> ORM.find(updated["id"], preload: :dashboard)

      assert found.dashboard.layout.post_layout == "new layout"
      assert found.dashboard.layout.kanban_layout == "full"
      assert found.dashboard.layout.broadcast_enable == true
      assert found.dashboard.layout.kanban_bg_colors == ["#111", "#222"]
      assert found.dashboard.layout.footer_layout == "simple"

      assert found.dashboard.layout.glow_type == "PINK"
      assert found.dashboard.layout.glow_fixed == true
      assert found.dashboard.layout.glow_opacity == "30"
    end

    test "update community dashboard layout should not overwrite existing settings",
         ~m(community)a do
      rule_conn = simu_conn(:user, cms: %{"community.update" => true})

      variables = %{
        community: community.slug,
        postLayout: "new layout"
      }

      updated =
        rule_conn
        |> mutation_result(@update_layout_query, variables, "updateDashboardLayout")

      {:ok, found} = Community |> ORM.find(updated["id"], preload: :dashboard)

      assert found.dashboard.layout.post_layout == "new layout"
      assert found.dashboard.layout.kanban_layout == ""

      variables = %{
        community: community.slug,
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
        community: community.slug,
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

    test "update community dashboard name alias info", ~m(community)a do
      rule_conn = simu_conn(:user, cms: %{"community.update" => true})

      variables = %{
        community: community.slug,
        nameAlias: [
          %{
            slug: "slug",
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

      assert found_alias.slug == "slug"
      assert found_alias.name == "name"
      assert found_alias.group == "group"
    end

    @update_header_links_query """
    mutation($community: String!, $headerLinks: [dashboardLinkMap]) {
      updateDashboardHeaderLinks(community: $community, headerLinks: $headerLinks) {
        id
        title
        dashboard {
          headerLinks {
            groupIndex
          }
        }
      }
    }
    """

    test "update community dashboard header links info", ~m(community)a do
      rule_conn = simu_conn(:user, cms: %{"community.update" => true})

      variables = %{
        community: community.slug,
        headerLinks: [
          %{
            title: "title",
            link: "link",
            group: "group",
            group_index: 1,
            index: 1,
            is_hot: false,
            is_new: false
          }
        ]
      }

      updated =
        rule_conn
        |> mutation_result(@update_header_links_query, variables, "updateDashboardHeaderLinks")

      assert updated["dashboard"]["headerLinks"] |> List.first() |> Map.get("groupIndex") == 1
      {:ok, found} = Community |> ORM.find(updated["id"], preload: :dashboard)

      link = found.dashboard.header_links |> Enum.at(0)

      assert link.title == "title"
      assert link.link == "link"
      assert link.group == "group"
      assert link.group_index == 1
    end

    @update_footer_links_query """
    mutation($community: String!, $footerLinks: [dashboardLinkMap]) {
      updateDashboardFooterLinks(community: $community, footerLinks: $footerLinks) {
        id
        title
        dashboard {
          footerLinks {
            groupIndex
          }
        }
      }
    }
    """
    test "update community dashboard footer links info", ~m(community)a do
      rule_conn = simu_conn(:user, cms: %{"community.update" => true})

      variables = %{
        community: community.slug,
        footerLinks: [
          %{
            title: "title",
            link: "link",
            group: "group",
            group_index: 1,
            index: 1,
            is_hot: false,
            is_new: false
          }
        ]
      }

      updated =
        rule_conn
        |> mutation_result(@update_footer_links_query, variables, "updateDashboardFooterLinks")

      assert updated["dashboard"]["footerLinks"] |> List.first() |> Map.get("groupIndex") == 1

      {:ok, found} = Community |> ORM.find(updated["id"], preload: :dashboard)

      link = found.dashboard.footer_links |> Enum.at(0)

      assert link.title == "title"
      assert link.link == "link"
      assert link.group == "group"
      assert link.group_index == 1
    end

    @update_social_links_query """
    mutation($community: String!, $socialLinks: [dashboardSocialLinkMap]) {
      updateDashboardSocialLinks(community: $community, socialLinks: $socialLinks) {
        id
        title
        dashboard {
          socialLinks {
            type
            link
          }
        }
      }
    }
    """
    test "update community dashboard social links info", ~m(community)a do
      rule_conn = simu_conn(:user, cms: %{"community.update" => true})

      variables = %{
        community: community.slug,
        socialLinks: [
          %{
            type: "twitter",
            link: "link"
          }
        ]
      }

      updated =
        rule_conn
        |> mutation_result(@update_social_links_query, variables, "updateDashboardSocialLinks")

      assert updated["dashboard"]["socialLinks"] |> List.first() |> Map.get("type") == "twitter"

      {:ok, found} = Community |> ORM.find(updated["id"], preload: :dashboard)

      link = found.dashboard.social_links |> Enum.at(0)

      assert link.type == "twitter"
      assert link.link == "link"
    end

    @update_media_reports_query """
    mutation($community: String!, $mediaReports: [dashboardMediaReportMap]) {
      updateDashboardMediaReports(community: $community, mediaReports: $mediaReports) {
        id
        title
        dashboard {
          mediaReports {
            title
            url
          }
        }
      }
    }
    """
    test "update community dashboard media reports info", ~m(community)a do
      rule_conn = simu_conn(:user, cms: %{"community.update" => true})

      variables = %{
        community: community.slug,
        mediaReports: [
          %{
            index: 233_344,
            title: "title",
            url: "url"
          }
        ]
      }

      updated =
        rule_conn
        |> mutation_result(@update_media_reports_query, variables, "updateDashboardMediaReports")

      assert updated["dashboard"]["mediaReports"] |> List.first() |> Map.get("title") == "title"

      {:ok, found} = Community |> ORM.find(updated["id"], preload: :dashboard)
      link = found.dashboard.media_reports |> Enum.at(0)

      assert link.index == 233_344
      assert link.title == "title"
      assert link.url == "url"
    end

    @update_faqs_query """
    mutation($community: String!, $faqs: [dashboardFaqMap]) {
      updateDashboardFaqs(community: $community, faqs: $faqs) {
        id
        title
        dashboard {
          faqs {
            title
            body
            index
          }
        }
      }
    }
    """
    test "update community dashboard faqs info", ~m(community)a do
      rule_conn = simu_conn(:user, cms: %{"community.update" => true})

      variables = %{
        community: community.slug,
        faqs: [
          %{
            title: "title",
            body: "body",
            index: 0
          }
        ]
      }

      updated =
        rule_conn
        |> mutation_result(
          @update_faqs_query,
          variables,
          "updateDashboardFaqs"
        )

      assert updated["dashboard"]["faqs"] |> List.first() |> Map.get("title") == "title"

      {:ok, found} = Community |> ORM.find(updated["id"], preload: :dashboard)

      faq = found.dashboard.faqs |> Enum.at(0)

      assert faq.title == "title"
      assert faq.body == "body"
    end
  end
end
