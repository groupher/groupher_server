defmodule GroupherServer.Test.CMS.Comments.ChangelogPendingFlag do
  use GroupherServer.TestTools

  alias GroupherServer.{Accounts, CMS}
  alias Accounts.Model.User
  alias CMS.Model.Comment
  alias CMS.Constant

  alias Helper.ORM

  @audit_legal Constant.pending(:legal)
  @audit_illegal Constant.pending(:illegal)

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    {:ok, changelog} = db_insert(:changelog)
    guest_conn = simu_conn(:guest)

    {:ok, ~m(guest_conn community user changelog)a}
  end

  describe "[pending changelog comemnt flags]" do
    test "pending changelog comment can set/unset pending", ~m(changelog user)a do
      {:ok, comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)

      {:ok, _} =
        CMS.set_comment_illegal(comment.id, %{
          is_legal: false,
          illegal_reason: ["some-reason"],
          illegal_words: ["some-word"]
        })

      {:ok, comment} = ORM.find(Comment, comment.id)
      assert comment.pending == @audit_illegal

      {:ok, _} =
        CMS.unset_comment_illegal(comment.id, %{
          is_legal: true,
          illegal_reason: [],
          illegal_words: []
        })

      {:ok, comment} = ORM.find(Comment, comment.id)
      assert comment.pending == @audit_legal
    end

    test "pending changelog-comment's meta should have info", ~m(changelog user)a do
      {:ok, comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)

      {:ok, _} =
        CMS.set_comment_illegal(comment.id, %{
          is_legal: false,
          illegal_reason: ["some-reason"],
          illegal_words: ["some-word"],
          illegal_comments: ["/changelog/#{changelog.id}/comment/#{comment.id}"]
        })

      {:ok, comment} = ORM.find(Comment, comment.id)
      assert comment.pending == @audit_illegal
      assert not comment.meta.is_legal
      assert comment.meta.illegal_reason == ["some-reason"]
      assert comment.meta.illegal_words == ["some-word"]

      {:ok, user} = ORM.find(User, comment.author_id)
      assert user.meta.has_illegal_comments
      assert user.meta.illegal_comments == ["/changelog/#{changelog.id}/comment/#{comment.id}"]

      {:ok, _} =
        CMS.unset_comment_illegal(comment.id, %{
          is_legal: true,
          illegal_reason: [],
          illegal_words: [],
          illegal_comments: ["/changelog/#{changelog.id}/comment/#{comment.id}"]
        })

      {:ok, comment} = ORM.find(Comment, comment.id)
      assert comment.pending == @audit_legal
      assert comment.meta.is_legal
      assert comment.meta.illegal_reason == []
      assert comment.meta.illegal_words == []

      {:ok, user} = ORM.find(User, comment.author_id)
      assert not user.meta.has_illegal_comments
      assert user.meta.illegal_comments == []
    end
  end
end
