defmodule GroupherServer.Test.CMS.DocPendingFlag do
  use GroupherServer.TestTools

  alias GroupherServer.{Accounts, CMS, Repo}
  alias Accounts.Model.User
  alias CMS.Model.Doc
  alias Helper.ORM

  @total_count 35

  @audit_legal CMS.Constant.pending(:legal)
  @audit_illegal CMS.Constant.pending(:illegal)

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    {:ok, community2} = db_insert(:community)
    CMS.create_article(community2, :doc, mock_attrs(:doc), user)

    docs =
      Enum.reduce(1..@total_count, [], fn _, acc ->
        {:ok, value} = CMS.create_article(community, :doc, mock_attrs(:doc), user)
        acc ++ [value]
      end)

    docs_b = docs |> List.first()
    docs_m = docs |> Enum.at(div(@total_count, 2))
    docs_e = docs |> List.last()

    guest_conn = simu_conn(:guest)

    {:ok, ~m(guest_conn community user docs_b docs_m docs_e)a}
  end

  describe "[pending docs flags]" do
    test "pending doc can not be read", ~m(docs_m)a do
      {:ok, _} = CMS.read_article(docs_m.original_community_raw, :doc, docs_m.inner_id)

      {:ok, _} =
        CMS.set_article_illegal(:doc, docs_m.id, %{
          is_legal: false,
          illegal_reason: ["some-reason"],
          illegal_words: ["some-word"]
        })

      {:ok, docs_m} = ORM.find(Doc, docs_m.id)
      assert docs_m.pending == @audit_illegal

      {:error, reason} = CMS.read_article(docs_m.original_community_raw, :doc, docs_m.inner_id)
      assert reason |> is_error?(:pending)
    end

    test "author can read it's own pending doc", ~m(community user)a do
      docs_attrs = mock_attrs(:doc, %{community_id: community.id})
      {:ok, doc} = CMS.create_article(community, :doc, docs_attrs, user)

      {:ok, _} = CMS.read_article(doc.original_community_raw, :doc, doc.inner_id)

      {:ok, _} =
        CMS.set_article_illegal(:doc, doc.id, %{
          is_legal: false,
          illegal_reason: ["some-reason"],
          illegal_words: ["some-word"]
        })

      {:ok, docs_read} = CMS.read_article(doc.original_community_raw, :doc, doc.inner_id, user)
      assert docs_read.id == doc.id

      {:ok, user2} = db_insert(:user)
      {:error, reason} = CMS.read_article(doc.original_community_raw, :doc, doc.inner_id, user2)
      assert reason |> is_error?(:pending)
    end

    test "pending doc can set/unset pending", ~m(docs_m)a do
      {:ok, _} = CMS.read_article(docs_m.original_community_raw, :doc, docs_m.inner_id)

      {:ok, _} =
        CMS.set_article_illegal(:doc, docs_m.id, %{
          is_legal: false,
          illegal_reason: ["some-reason"],
          illegal_words: ["some-word"]
        })

      {:ok, docs_m} = ORM.find(Doc, docs_m.id)
      assert docs_m.pending == @audit_illegal

      {:ok, _} = CMS.unset_article_illegal(:doc, docs_m.id, %{})

      {:ok, docs_m} = ORM.find(Doc, docs_m.id)
      assert docs_m.pending == @audit_legal

      {:ok, _} = CMS.read_article(docs_m.original_community_raw, :doc, docs_m.inner_id)
    end

    test "pending doc's meta should have info", ~m(docs_m)a do
      {:ok, _} = CMS.read_article(docs_m.original_community_raw, :doc, docs_m.inner_id)

      {:ok, _} =
        CMS.set_article_illegal(:doc, docs_m.id, %{
          is_legal: false,
          illegal_reason: ["some-reason"],
          illegal_words: ["some-word"],
          illegal_articles: ["/doc/#{docs_m.id}"]
        })

      {:ok, docs_m} = ORM.find(Doc, docs_m.id)
      assert docs_m.pending == @audit_illegal
      assert not docs_m.meta.is_legal
      assert docs_m.meta.illegal_reason == ["some-reason"]
      assert docs_m.meta.illegal_words == ["some-word"]

      docs_m = Repo.preload(docs_m, :author)
      {:ok, user} = ORM.find(User, docs_m.author.user_id)
      assert user.meta.has_illegal_articles
      assert user.meta.illegal_articles == ["/doc/#{docs_m.id}"]

      {:ok, _} =
        CMS.unset_article_illegal(:doc, docs_m.id, %{
          is_legal: true,
          illegal_reason: [],
          illegal_words: [],
          illegal_articles: ["/doc/#{docs_m.id}"]
        })

      {:ok, docs_m} = ORM.find(Doc, docs_m.id)
      assert docs_m.pending == @audit_legal
      assert docs_m.meta.is_legal
      assert docs_m.meta.illegal_reason == []
      assert docs_m.meta.illegal_words == []

      docs_m = Repo.preload(docs_m, :author)
      {:ok, user} = ORM.find(User, docs_m.author.user_id)
      assert not user.meta.has_illegal_articles
      assert user.meta.illegal_articles == []
    end
  end

  # alias CMS.Delegate.Hooks

  # test "can audit paged audit failed docs", ~m(docs_m)a do
  #   {:ok, doc} = ORM.find(Doc, docs_m.id)

  #   {:ok, doc} = CMS.set_article_audit_failed(doc, %{})

  #   {:ok, result} = CMS.paged_audit_failed_articles(:doc, %{page: 1, size: 20})
  #   assert result |> is_valid_pagination?(:raw)
  #   assert result.total_count == 1

  #   Enum.map(result.entries, fn doc ->
  #     Hooks.Audition.handle(doc)
  #   end)

  #   {:ok, result} = CMS.paged_audit_failed_articles(:doc, %{page: 1, size: 20})
  #   assert result.total_count == 0
  # end
end
