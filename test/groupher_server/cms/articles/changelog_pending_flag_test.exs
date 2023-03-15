defmodule GroupherServer.Test.CMS.ChangelogPendingFlag do
  use GroupherServer.TestTools

  alias GroupherServer.{Accounts, CMS, Repo}
  alias Accounts.Model.User
  alias CMS.Model.Changelog
  alias Helper.ORM

  @total_count 35

  @audit_legal CMS.Constant.pending(:legal)
  @audit_illegal CMS.Constant.pending(:illegal)

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    {:ok, community2} = db_insert(:community)
    CMS.create_article(community2, :changelog, mock_attrs(:changelog), user)

    changelogs =
      Enum.reduce(1..@total_count, [], fn _, acc ->
        {:ok, value} = CMS.create_article(community, :changelog, mock_attrs(:changelog), user)
        acc ++ [value]
      end)

    changelog_b = changelogs |> List.first()
    changelog_m = changelogs |> Enum.at(div(@total_count, 2))
    changelog_e = changelogs |> List.last()

    guest_conn = simu_conn(:guest)

    {:ok, ~m(guest_conn community user changelog_b changelog_m changelog_e)a}
  end

  describe "[pending changelogs flags]" do
    test "pending changelog can not be read", ~m(changelog_m)a do
      {:ok, _} = CMS.read_article(:changelog, changelog_m.id)

      {:ok, _} =
        CMS.set_article_illegal(:changelog, changelog_m.id, %{
          is_legal: false,
          illegal_reason: ["some-reason"],
          illegal_words: ["some-word"]
        })

      {:ok, changelog_m} = ORM.find(Changelog, changelog_m.id)
      assert changelog_m.pending == @audit_illegal

      {:error, reason} = CMS.read_article(:changelog, changelog_m.id)
      assert reason |> is_error?(:pending)
    end

    test "author can read it's own pending changelog", ~m(community user)a do
      changelog_attrs = mock_attrs(:changelog, %{community_id: community.id})
      {:ok, changelog} = CMS.create_article(community, :changelog, changelog_attrs, user)

      {:ok, _} = CMS.read_article(:changelog, changelog.id)

      {:ok, _} =
        CMS.set_article_illegal(:changelog, changelog.id, %{
          is_legal: false,
          illegal_reason: ["some-reason"],
          illegal_words: ["some-word"]
        })

      {:ok, changelog_read} = CMS.read_article(:changelog, changelog.id, user)
      assert changelog_read.id == changelog.id

      {:ok, user2} = db_insert(:user)
      {:error, reason} = CMS.read_article(:changelog, changelog.id, user2)
      assert reason |> is_error?(:pending)
    end

    test "pending changelog can set/unset pending", ~m(changelog_m)a do
      {:ok, _} = CMS.read_article(:changelog, changelog_m.id)

      {:ok, _} =
        CMS.set_article_illegal(:changelog, changelog_m.id, %{
          is_legal: false,
          illegal_reason: ["some-reason"],
          illegal_words: ["some-word"]
        })

      {:ok, changelog_m} = ORM.find(Changelog, changelog_m.id)
      assert changelog_m.pending == @audit_illegal

      {:ok, _} = CMS.unset_article_illegal(:changelog, changelog_m.id, %{})

      {:ok, changelog_m} = ORM.find(Changelog, changelog_m.id)
      assert changelog_m.pending == @audit_legal

      {:ok, _} = CMS.read_article(:changelog, changelog_m.id)
    end

    test "pending changelog's meta should have info", ~m(changelog_m)a do
      {:ok, _} = CMS.read_article(:changelog, changelog_m.id)

      {:ok, _} =
        CMS.set_article_illegal(:changelog, changelog_m.id, %{
          is_legal: false,
          illegal_reason: ["some-reason"],
          illegal_words: ["some-word"],
          illegal_articles: ["/changelog/#{changelog_m.id}"]
        })

      {:ok, changelog_m} = ORM.find(Changelog, changelog_m.id)
      assert changelog_m.pending == @audit_illegal
      assert not changelog_m.meta.is_legal
      assert changelog_m.meta.illegal_reason == ["some-reason"]
      assert changelog_m.meta.illegal_words == ["some-word"]

      changelog_m = Repo.preload(changelog_m, :author)
      {:ok, user} = ORM.find(User, changelog_m.author.user_id)
      assert user.meta.has_illegal_articles
      assert user.meta.illegal_articles == ["/changelog/#{changelog_m.id}"]

      {:ok, _} =
        CMS.unset_article_illegal(:changelog, changelog_m.id, %{
          is_legal: true,
          illegal_reason: [],
          illegal_words: [],
          illegal_articles: ["/changelog/#{changelog_m.id}"]
        })

      {:ok, changelog_m} = ORM.find(Changelog, changelog_m.id)
      assert changelog_m.pending == @audit_legal
      assert changelog_m.meta.is_legal
      assert changelog_m.meta.illegal_reason == []
      assert changelog_m.meta.illegal_words == []

      changelog_m = Repo.preload(changelog_m, :author)
      {:ok, user} = ORM.find(User, changelog_m.author.user_id)
      assert not user.meta.has_illegal_articles
      assert user.meta.illegal_articles == []
    end
  end

  # alias CMS.Delegate.Hooks

  # test "can audit paged audit failed changelogs", ~m(changelog_m)a do
  #   {:ok, changelog} = ORM.find(Changelog, changelog_m.id)

  #   {:ok, changelog} = CMS.set_article_audit_failed(changelog, %{})

  #   {:ok, result} = CMS.paged_audit_failed_articles(:changelog, %{page: 1, size: 20})
  #   assert result |> is_valid_pagination?(:raw)
  #   assert result.total_count == 1

  #   Enum.map(result.entries, fn changelog ->
  #     Hooks.Audition.handle(changelog)
  #   end)

  #   {:ok, result} = CMS.paged_audit_failed_articles(:changelog, %{page: 1, size: 20})
  #   assert result.total_count == 0
  # end
end
