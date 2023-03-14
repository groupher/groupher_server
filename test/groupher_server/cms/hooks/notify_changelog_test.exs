defmodule GroupherServer.Test.CMS.Hooks.NotifyChangelog do
  use GroupherServer.TestTools

  import GroupherServer.CMS.Delegate.Helper, only: [preload_author: 1]

  alias GroupherServer.{CMS, Delivery, Repo}
  alias CMS.Delegate.Hooks

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, user3} = db_insert(:user)

    {:ok, community} = db_insert(:community)

    changelog_attrs = mock_attrs(:changelog, %{community_id: community.id})
    {:ok, changelog} = CMS.create_article(community, :changelog, changelog_attrs, user)
    {:ok, comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)

    {:ok, ~m(user2 user3 changelog comment)a}
  end

  describe "[upvote notify]" do
    @tag :wip
    test "upvote hook should work on changelog", ~m(user2 changelog)a do
      {:ok, changelog} = preload_author(changelog)

      {:ok, article} = CMS.upvote_article(:changelog, changelog.id, user2)
      Hooks.Notify.handle(:upvote, article, user2)

      {:ok, notifications} =
        Delivery.fetch(:notification, changelog.author.user, %{page: 1, size: 20})

      assert notifications.total_count == 1

      notify = notifications.entries |> List.first()
      assert notify.action == "UPVOTE"
      assert notify.article_id == changelog.id
      assert notify.thread == "CHANGELOG"
      assert notify.user_id == changelog.author.user.id
      assert user_exist_in?(user2, notify.from_users)
    end

    @tag :wip
    test "upvote hook should work on changelog comment", ~m(user2 changelog comment)a do
      {:ok, comment} = CMS.upvote_comment(comment.id, user2)
      {:ok, comment} = preload_author(comment)

      Hooks.Notify.handle(:upvote, comment, user2)

      {:ok, notifications} = Delivery.fetch(:notification, comment.author, %{page: 1, size: 20})

      assert notifications.total_count == 1

      notify = notifications.entries |> List.first()
      assert notify.action == "UPVOTE"
      assert notify.article_id == changelog.id
      assert notify.thread == "CHANGELOG"
      assert notify.user_id == comment.author.id
      assert notify.comment_id == comment.id
      assert user_exist_in?(user2, notify.from_users)
    end

    @tag :wip
    test "undo upvote hook should work on changelog", ~m(user2 changelog)a do
      {:ok, changelog} = preload_author(changelog)

      {:ok, article} = CMS.upvote_article(:changelog, changelog.id, user2)
      Hooks.Notify.handle(:upvote, article, user2)

      {:ok, article} = CMS.undo_upvote_article(:changelog, changelog.id, user2)
      Hooks.Notify.handle(:undo, :upvote, article, user2)

      {:ok, notifications} =
        Delivery.fetch(:notification, changelog.author.user, %{page: 1, size: 20})

      assert notifications.total_count == 0
    end

    @tag :wip
    test "undo upvote hook should work on changelog comment", ~m(user2 comment)a do
      {:ok, comment} = CMS.upvote_comment(comment.id, user2)

      Hooks.Notify.handle(:upvote, comment, user2)

      {:ok, comment} = CMS.undo_upvote_comment(comment.id, user2)
      Hooks.Notify.handle(:undo, :upvote, comment, user2)

      {:ok, comment} = preload_author(comment)

      {:ok, notifications} = Delivery.fetch(:notification, comment.author, %{page: 1, size: 20})

      assert notifications.total_count == 0
    end
  end

  describe "[collect notify]" do
    @tag :wip
    test "collect hook should work on changelog", ~m(user2 changelog)a do
      {:ok, changelog} = preload_author(changelog)

      {:ok, _} = CMS.collect_article(:changelog, changelog.id, user2)
      Hooks.Notify.handle(:collect, changelog, user2)

      {:ok, notifications} =
        Delivery.fetch(:notification, changelog.author.user, %{page: 1, size: 20})

      assert notifications.total_count == 1

      notify = notifications.entries |> List.first()
      assert notify.action == "COLLECT"
      assert notify.article_id == changelog.id
      assert notify.thread == "CHANGELOG"
      assert notify.user_id == changelog.author.user.id
      assert user_exist_in?(user2, notify.from_users)
    end

    @tag :wip
    test "undo collect hook should work on changelog", ~m(user2 changelog)a do
      {:ok, changelog} = preload_author(changelog)

      {:ok, _} = CMS.upvote_article(:changelog, changelog.id, user2)
      Hooks.Notify.handle(:collect, changelog, user2)

      {:ok, _} = CMS.undo_upvote_article(:changelog, changelog.id, user2)
      Hooks.Notify.handle(:undo, :collect, changelog, user2)

      {:ok, notifications} =
        Delivery.fetch(:notification, changelog.author.user, %{page: 1, size: 20})

      assert notifications.total_count == 0
    end
  end

  describe "[comment notify]" do
    @tag :wip
    test "changelog author should get notify after some one comment on it",
         ~m(user2 changelog)a do
      {:ok, changelog} = preload_author(changelog)

      {:ok, comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user2)
      Hooks.Notify.handle(:comment, comment, user2)

      {:ok, notifications} =
        Delivery.fetch(:notification, changelog.author.user, %{page: 1, size: 20})

      assert notifications.total_count == 1

      notify = notifications.entries |> List.first()
      assert notify.action == "COMMENT"
      assert notify.thread == "CHANGELOG"
      assert notify.article_id == changelog.id
      assert notify.user_id == changelog.author.user.id
      assert user_exist_in?(user2, notify.from_users)
    end

    @tag :wip
    test "changelog comment author should get notify after some one reply it",
         ~m(user2 user3 changelog)a do
      {:ok, changelog} = preload_author(changelog)

      {:ok, comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user2)
      {:ok, replyed_comment} = CMS.reply_comment(comment.id, mock_comment(), user3)

      Hooks.Notify.handle(:reply, replyed_comment, user3)

      comment = Repo.preload(comment, :author)
      {:ok, notifications} = Delivery.fetch(:notification, comment.author, %{page: 1, size: 20})

      assert notifications.total_count == 1

      notify = notifications.entries |> List.first()

      assert notify.action == "REPLY"
      assert notify.thread == "CHANGELOG"
      assert notify.article_id == changelog.id
      assert notify.comment_id == replyed_comment.id

      assert notify.user_id == comment.author_id
      assert user_exist_in?(user3, notify.from_users)
    end
  end
end
