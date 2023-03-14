defmodule GroupherServer.Test.CMS.Comments.ChangelogComment do
  @moduledoc false

  use GroupherServer.TestTools
  import Helper.Utils, only: [get_config: 2]

  alias Helper.ORM
  alias GroupherServer.{Accounts, CMS}
  alias Accounts.Model.User
  alias CMS.Model.{Comment, PinnedComment, Embeds, Changelog}

  @active_period get_config(:article, :active_period_days)

  @delete_hint Comment.delete_hint()
  @report_threshold_for_fold Comment.report_threshold_for_fold()
  @default_comment_meta Embeds.CommentMeta.default_meta()
  @pinned_comment_limit Comment.pinned_comment_limit()

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, user3} = db_insert(:user)
    {:ok, changelog} = db_insert(:changelog)
    {:ok, community} = db_insert(:community)

    {:ok, ~m(community user user2 user3 changelog)a}
  end

  describe "[comments state]" do
    @tag :wip
    test "can get basic state", ~m(user changelog)a do
      {:ok, _} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)
      {:ok, _} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)

      {:ok, state} = CMS.comments_state(:changelog, changelog.id)

      assert state.participants_count == 1
      assert state.total_count == 2

      assert state.participants |> length == 1
      assert not state.is_viewer_joined
    end

    @tag :wip
    test "can get viewer joined state", ~m(user changelog)a do
      {:ok, _} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)
      {:ok, _} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)

      {:ok, state} = CMS.comments_state(:changelog, changelog.id, user)

      assert state.participants_count == 1
      assert state.total_count == 2
      assert state.participants |> length == 1
      assert state.is_viewer_joined
    end

    @tag :wip
    test "can get viewer joined state 2", ~m(user user2 user3 changelog)a do
      {:ok, _} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user2)
      {:ok, _} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user3)

      {:ok, state} = CMS.comments_state(:changelog, changelog.id, user)

      assert state.participants_count == 2
      assert state.total_count == 2
      assert state.participants |> length == 2
      assert not state.is_viewer_joined
    end
  end

  describe "[basic article comment]" do
    @tag :wip
    test "changelog are supported by article comment.", ~m(user changelog)a do
      {:ok, changelog_comment_1} =
        CMS.create_comment(:changelog, changelog.id, mock_comment(), user)

      {:ok, changelog_comment_2} =
        CMS.create_comment(:changelog, changelog.id, mock_comment(), user)

      {:ok, changelog} = ORM.find(Changelog, changelog.id, preload: :comments)

      assert exist_in?(changelog_comment_1, changelog.comments)
      assert exist_in?(changelog_comment_2, changelog.comments)
    end

    @tag :wip
    test "comment should have default meta after create", ~m(user changelog)a do
      {:ok, comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)
      assert comment.meta |> Map.from_struct() |> Map.delete(:id) == @default_comment_meta
    end

    @tag :wip
    test "create comment should update active timestamp of changelog", ~m(user changelog)a do
      Process.sleep(1000)
      {:ok, _comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)
      {:ok, changelog} = ORM.find(Changelog, changelog.id, preload: :comments)

      assert not is_nil(changelog.active_at)
      assert changelog.active_at > changelog.inserted_at
    end

    @tag :wip
    test "changelog author create comment will not update active timestamp",
         ~m(community user)a do
      changelog_attrs = mock_attrs(:changelog, %{community_id: community.id})
      {:ok, changelog} = CMS.create_article(community, :changelog, changelog_attrs, user)
      {:ok, changelog} = ORM.find(Changelog, changelog.id, preload: [author: :user])

      Process.sleep(1000)

      {:ok, _comment} =
        CMS.create_comment(:changelog, changelog.id, mock_comment(), changelog.author.user)

      {:ok, changelog} = ORM.find(Changelog, changelog.id, preload: :comments)

      assert not is_nil(changelog.active_at)
      assert changelog.active_at == changelog.inserted_at
    end

    @tag :wip
    test "old changelog will not update active after comment created", ~m(user)a do
      active_period_days = @active_period[:changelog] || @active_period[:default]

      inserted_at =
        Timex.shift(Timex.now(), days: -(active_period_days - 1)) |> Timex.to_datetime()

      {:ok, changelog} = db_insert(:changelog, %{inserted_at: inserted_at})
      Process.sleep(1000)
      {:ok, _comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)
      {:ok, changelog} = ORM.find(Changelog, changelog.id)

      assert changelog.active_at |> DateTime.to_date() == DateTime.utc_now() |> DateTime.to_date()

      #####
      inserted_at =
        Timex.shift(Timex.now(), days: -(active_period_days + 1)) |> Timex.to_datetime()

      {:ok, changelog} = db_insert(:changelog, %{inserted_at: inserted_at})
      Process.sleep(3000)
      {:ok, _comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)
      {:ok, changelog} = ORM.find(Changelog, changelog.id)

      assert changelog.active_at |> DateTime.to_unix() !==
               DateTime.utc_now() |> DateTime.to_unix()
    end

    @tag :wip
    test "comment can be updated", ~m(changelog user)a do
      {:ok, comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)

      {:ok, updated_comment} = CMS.update_comment(comment, mock_comment("updated content"))

      assert updated_comment.body_html |> String.contains?(~s(updated content</p>))
    end
  end

  describe "[article comment floor]" do
    @tag :wip
    test "comment will have a floor number after created", ~m(user changelog)a do
      {:ok, changelog_comment} =
        CMS.create_comment(:changelog, changelog.id, mock_comment(), user)

      {:ok, changelog_comment2} =
        CMS.create_comment(:changelog, changelog.id, mock_comment(), user)

      {:ok, changelog_comment} = ORM.find(Comment, changelog_comment.id)
      {:ok, changelog_comment2} = ORM.find(Comment, changelog_comment2.id)

      assert changelog_comment.floor == 1
      assert changelog_comment2.floor == 2
    end
  end

  describe "[article comment participator for changelog]" do
    @tag :wip
    test "changelog will have participator after comment created", ~m(user changelog)a do
      {:ok, _} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)

      {:ok, changelog} = ORM.find(Changelog, changelog.id)

      participator = List.first(changelog.comments_participants)
      assert participator.id == user.id
    end

    @tag :wip
    test "psot participator will not contains same user", ~m(user changelog)a do
      {:ok, _} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)
      {:ok, _} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)

      {:ok, changelog} = ORM.find(Changelog, changelog.id)

      assert 1 == length(changelog.comments_participants)
    end

    @tag :wip
    test "recent comment user should appear at first of the psot participants",
         ~m(user user2 changelog)a do
      {:ok, _} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)
      {:ok, _} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user2)

      {:ok, changelog} = ORM.find(Changelog, changelog.id)

      participator = List.first(changelog.comments_participants)

      assert participator.id == user2.id
    end
  end

  describe "[article comment upvotes]" do
    @tag :wip
    test "user can upvote a changelog comment", ~m(user changelog)a do
      {:ok, comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)

      CMS.upvote_comment(comment.id, user)

      {:ok, comment} = ORM.find(Comment, comment.id, preload: :upvotes)

      assert 1 == length(comment.upvotes)
      assert List.first(comment.upvotes).user_id == user.id
    end

    @tag :wip
    test "user can upvote a changelog comment twice is fine", ~m(user changelog)a do
      {:ok, comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)

      {:ok, _} = CMS.upvote_comment(comment.id, user)
      {:error, _} = CMS.upvote_comment(comment.id, user)

      {:ok, comment} = ORM.find(Comment, comment.id, preload: :upvotes)
      assert 1 == length(comment.upvotes)
    end

    @tag :wip
    test "article author upvote changelog comment will have flag", ~m(changelog user)a do
      {:ok, comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)
      {:ok, author_user} = ORM.find(User, changelog.author.user.id)

      CMS.upvote_comment(comment.id, author_user)

      {:ok, comment} = ORM.find(Comment, comment.id, preload: :upvotes)
      assert comment.meta.is_article_author_upvoted
    end

    @tag :wip
    test "user upvote changelog comment will add id to upvoted_user_ids", ~m(changelog user)a do
      {:ok, comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)
      {:ok, comment} = CMS.upvote_comment(comment.id, user)

      assert user.id in comment.meta.upvoted_user_ids
    end

    @tag :wip
    test "user undo upvote changelog comment will remove id from upvoted_user_ids",
         ~m(changelog user user2)a do
      {:ok, comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)
      {:ok, _comment} = CMS.upvote_comment(comment.id, user)
      {:ok, comment} = CMS.upvote_comment(comment.id, user2)

      assert user2.id in comment.meta.upvoted_user_ids
      assert user.id in comment.meta.upvoted_user_ids

      {:ok, comment} = CMS.undo_upvote_comment(comment.id, user2)

      assert user.id in comment.meta.upvoted_user_ids
      assert user2.id not in comment.meta.upvoted_user_ids
    end

    @tag :wip
    test "user upvote a already-upvoted comment fails", ~m(user changelog)a do
      {:ok, comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)

      CMS.upvote_comment(comment.id, user)
      {:error, _} = CMS.upvote_comment(comment.id, user)
    end

    @tag :wip
    test "upvote comment should inc the comment's upvotes_count", ~m(user user2 changelog)a do
      {:ok, comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)
      {:ok, comment} = ORM.find(Comment, comment.id)
      assert comment.upvotes_count == 0

      {:ok, _} = CMS.upvote_comment(comment.id, user)
      {:ok, _} = CMS.upvote_comment(comment.id, user2)

      {:ok, comment} = ORM.find(Comment, comment.id)
      assert comment.upvotes_count == 2
    end

    @tag :wip
    test "user can undo upvote a changelog comment", ~m(user changelog)a do
      {:ok, comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)
      CMS.upvote_comment(comment.id, user)

      {:ok, comment} = ORM.find(Comment, comment.id, preload: :upvotes)
      assert 1 == length(comment.upvotes)

      {:ok, comment} = CMS.undo_upvote_comment(comment.id, user)
      assert 0 == comment.upvotes_count
    end

    @tag :wip
    test "user can undo upvote a changelog comment with no upvote", ~m(user changelog)a do
      {:ok, comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)
      {:ok, comment} = CMS.undo_upvote_comment(comment.id, user)
      assert 0 == comment.upvotes_count

      {:ok, comment} = CMS.undo_upvote_comment(comment.id, user)
      assert 0 == comment.upvotes_count
    end

    @tag :wip
    test "upvote comment should update embeded replies too", ~m(user user2 user3 changelog)a do
      {:ok, parent_comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)
      {:ok, replied_comment} = CMS.reply_comment(parent_comment.id, mock_comment(), user)

      {:ok, _} = CMS.upvote_comment(parent_comment.id, user)
      {:ok, _} = CMS.upvote_comment(replied_comment.id, user)
      {:ok, _} = CMS.upvote_comment(replied_comment.id, user2)
      {:ok, _} = CMS.upvote_comment(replied_comment.id, user3)

      filter = %{page: 1, size: 20}
      {:ok, paged_comments} = CMS.paged_comments(:changelog, changelog.id, filter, :replies)

      parent = paged_comments.entries |> List.first()
      reply = parent |> Map.get(:replies) |> List.first()
      assert parent.upvotes_count == 1
      assert reply.upvotes_count == 3

      {:ok, _} = CMS.undo_upvote_comment(replied_comment.id, user2)
      {:ok, paged_comments} = CMS.paged_comments(:changelog, changelog.id, filter, :replies)

      parent = paged_comments.entries |> List.first()
      reply = parent |> Map.get(:replies) |> List.first()
      assert parent.upvotes_count == 1
      assert reply.upvotes_count == 2
    end
  end

  describe "[article comment fold/unfold]" do
    @tag :wip
    test "user can fold a comment", ~m(user changelog)a do
      {:ok, comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)
      {:ok, comment} = ORM.find(Comment, comment.id)

      assert not comment.is_folded

      {:ok, comment} = CMS.fold_comment(comment.id, user)
      {:ok, comment} = ORM.find(Comment, comment.id)
      assert comment.is_folded

      {:ok, changelog} = ORM.find(Changelog, changelog.id)
      assert changelog.meta.folded_comment_count == 1
    end

    @tag :wip
    test "user can unfold a comment", ~m(user changelog)a do
      {:ok, comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)
      {:ok, _comment} = CMS.fold_comment(comment.id, user)
      {:ok, comment} = ORM.find(Comment, comment.id)

      assert comment.is_folded

      {:ok, _comment} = CMS.unfold_comment(comment.id, user)
      {:ok, comment} = ORM.find(Comment, comment.id)
      assert not comment.is_folded

      {:ok, changelog} = ORM.find(Changelog, changelog.id)
      assert changelog.meta.folded_comment_count == 0
    end
  end

  describe "[article comment pin/unpin]" do
    @tag :wip
    test "user can pin a comment", ~m(user changelog)a do
      {:ok, comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)
      {:ok, comment} = ORM.find(Comment, comment.id)

      assert not comment.is_pinned

      {:ok, comment} = CMS.pin_comment(comment.id)
      {:ok, comment} = ORM.find(Comment, comment.id)

      assert comment.is_pinned

      {:ok, pined_record} = PinnedComment |> ORM.find_by(%{changelog_id: changelog.id})
      assert pined_record.changelog_id == changelog.id
    end

    @tag :wip
    test "user can unpin a comment", ~m(user changelog)a do
      {:ok, comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)

      {:ok, _comment} = CMS.pin_comment(comment.id)
      {:ok, comment} = CMS.undo_pin_comment(comment.id)

      assert not comment.is_pinned
      assert {:error, _} = PinnedComment |> ORM.find_by(%{comment_id: comment.id})
    end

    @tag :wip
    test "pinned comments has a limit for each article", ~m(user changelog)a do
      {:ok, comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)

      Enum.reduce(0..(@pinned_comment_limit - 1), [], fn _, _acc ->
        {:ok, _comment} = CMS.pin_comment(comment.id)
      end)

      assert {:error, _} = CMS.pin_comment(comment.id)
    end
  end

  describe "[article comment report/unreport]" do
    #
    # test "user can report a comment", ~m(user changelog)a do
    #   {:ok, comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)
    #   {:ok, comment} = ORM.find(Comment, comment.id)

    #   {:ok, comment} = CMS.report_comment(comment.id, mock_comment(), "attr", user)
    #   {:ok, comment} = ORM.find(Comment, comment.id)
    # end

    #
    # test "user can unreport a comment", ~m(user changelog)a do
    #   {:ok, comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)
    #   {:ok, _comment} = CMS.report_comment(comment.id, mock_comment(), "attr", user)
    #   {:ok, comment} = ORM.find(Comment, comment.id)

    #   {:ok, _comment} = CMS.undo_report_comment(comment.id, user)
    #   {:ok, comment} = ORM.find(Comment, comment.id)
    # end

    @tag :wip
    test "can undo a report with other user report it too", ~m(user user2 changelog)a do
      {:ok, comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)

      {:ok, _comment} = CMS.report_comment(comment.id, mock_comment(), "attr", user)
      {:ok, _comment} = CMS.report_comment(comment.id, mock_comment(), "attr", user2)

      filter = %{content_type: :comment, content_id: comment.id, page: 1, size: 20}
      {:ok, all_reports} = CMS.paged_reports(filter)
      assert all_reports.total_count == 1

      report = all_reports.entries |> List.first()
      assert report.report_cases |> length == 2
      assert Enum.any?(report.report_cases, &(&1.user.login == user.login))
      assert Enum.any?(report.report_cases, &(&1.user.login == user2.login))

      {:ok, _report} = CMS.undo_report_article(:comment, comment.id, user)

      filter = %{content_type: :comment, content_id: comment.id, page: 1, size: 20}
      {:ok, all_reports} = CMS.paged_reports(filter)

      assert all_reports.total_count == 1

      report = all_reports.entries |> List.first()
      assert report.report_cases |> length == 1
      assert Enum.any?(report.report_cases, &(&1.user.login == user2.login))
    end

    @tag :wip
    test "report user < @report_threshold_for_fold will not fold comment", ~m(user changelog)a do
      {:ok, comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)

      assert not comment.is_folded

      Enum.reduce(1..(@report_threshold_for_fold - 1), [], fn _, _acc ->
        {:ok, user} = db_insert(:user)
        {:ok, _comment} = CMS.report_comment(comment.id, mock_comment(), "attr", user)
      end)

      {:ok, comment} = ORM.find(Comment, comment.id)
      assert not comment.is_folded
    end

    @tag :wip
    test "report user > @report_threshold_for_fold will cause comment fold",
         ~m(user changelog)a do
      {:ok, comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)

      assert not comment.is_folded

      Enum.reduce(1..(@report_threshold_for_fold + 1), [], fn _, _acc ->
        {:ok, user} = db_insert(:user)
        {:ok, _comment} = CMS.report_comment(comment.id, mock_comment(), "attr", user)
      end)

      {:ok, comment} = ORM.find(Comment, comment.id)
      assert comment.is_folded
    end
  end

  describe "paged article comments" do
    @tag :wip
    test "can load paged comments participants of a article", ~m(user changelog)a do
      total_count = 30
      page_size = 10
      thread = :changelog

      Enum.reduce(1..total_count, [], fn _, acc ->
        {:ok, new_user} = db_insert(:user)
        {:ok, comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), new_user)

        acc ++ [comment]
      end)

      {:ok, _comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)
      {:ok, _comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)

      {:ok, results} =
        CMS.paged_comments_participants(thread, changelog.id, %{page: 1, size: page_size})

      assert results |> is_valid_pagination?(:raw)
      assert results.total_count == total_count + 1
    end

    @tag :wip
    test "paged article comments folded flag should be false", ~m(user changelog)a do
      total_count = 30
      page_number = 1
      page_size = 35

      all_comments =
        Enum.reduce(1..total_count, [], fn _, acc ->
          {:ok, comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)

          acc ++ [comment]
        end)

      {:ok, paged_comments} =
        CMS.paged_comments(
          :changelog,
          changelog.id,
          %{page: page_number, size: page_size},
          :replies
        )

      random_comment = all_comments |> Enum.at(Enum.random(0..(total_count - 1)))

      assert not random_comment.is_folded

      assert page_number == paged_comments.page_number
      assert page_size == paged_comments.page_size
      assert total_count == paged_comments.total_count
    end

    @tag :wip
    test "paged article comments should contains pinned comments at top position",
         ~m(user changelog)a do
      total_count = 20
      page_number = 1
      page_size = 5

      Enum.reduce(1..total_count, [], fn _, acc ->
        {:ok, comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)

        acc ++ [comment]
      end)

      {:ok, random_comment_1} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)
      {:ok, random_comment_2} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)

      {:ok, pined_comment_1} = CMS.pin_comment(random_comment_1.id)
      {:ok, pined_comment_2} = CMS.pin_comment(random_comment_2.id)

      {:ok, paged_comments} =
        CMS.paged_comments(
          :changelog,
          changelog.id,
          %{page: page_number, size: page_size},
          :replies
        )

      assert pined_comment_1.id == List.first(paged_comments.entries) |> Map.get(:id)
      assert pined_comment_2.id == Enum.at(paged_comments.entries, 1) |> Map.get(:id)

      assert paged_comments.total_count == total_count + 2
    end

    @tag :wip
    test "only page 1 have pinned coments",
         ~m(user changelog)a do
      total_count = 20
      page_number = 2
      page_size = 5

      Enum.reduce(1..total_count, [], fn _, acc ->
        {:ok, comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)

        acc ++ [comment]
      end)

      {:ok, random_comment_1} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)
      {:ok, random_comment_2} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)

      {:ok, pined_comment_1} = CMS.pin_comment(random_comment_1.id)
      {:ok, pined_comment_2} = CMS.pin_comment(random_comment_2.id)

      {:ok, paged_comments} =
        CMS.paged_comments(
          :changelog,
          changelog.id,
          %{page: page_number, size: page_size},
          :replies
        )

      assert not exist_in?(pined_comment_1, paged_comments.entries)
      assert not exist_in?(pined_comment_2, paged_comments.entries)

      assert paged_comments.total_count == total_count
    end

    @tag :wip
    test "paged article comments should not contains folded and repoted comments",
         ~m(user changelog)a do
      total_count = 15
      page_number = 1
      page_size = 20

      all_comments =
        Enum.reduce(1..total_count, [], fn _, acc ->
          {:ok, comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)

          acc ++ [comment]
        end)

      random_comment_1 = all_comments |> Enum.at(0)
      random_comment_2 = all_comments |> Enum.at(1)
      random_comment_3 = all_comments |> Enum.at(3)

      {:ok, _comment} = CMS.fold_comment(random_comment_1.id, user)
      {:ok, _comment} = CMS.fold_comment(random_comment_2.id, user)
      {:ok, _comment} = CMS.fold_comment(random_comment_3.id, user)

      {:ok, paged_comments} =
        CMS.paged_comments(
          :changelog,
          changelog.id,
          %{page: page_number, size: page_size},
          :replies
        )

      assert not exist_in?(random_comment_1, paged_comments.entries)
      assert not exist_in?(random_comment_2, paged_comments.entries)
      assert not exist_in?(random_comment_3, paged_comments.entries)

      assert page_number == paged_comments.page_number
      assert page_size == paged_comments.page_size
      assert total_count - 3 == paged_comments.total_count
    end

    @tag :wip
    test "can loaded paged folded comment", ~m(user changelog)a do
      total_count = 10
      page_number = 1
      page_size = 20

      all_folded_comments =
        Enum.reduce(1..total_count, [], fn _, acc ->
          {:ok, comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)
          CMS.fold_comment(comment.id, user)

          acc ++ [comment]
        end)

      random_comment_1 = all_folded_comments |> Enum.at(1)
      random_comment_2 = all_folded_comments |> Enum.at(3)
      random_comment_3 = all_folded_comments |> Enum.at(5)

      {:ok, paged_comments} =
        CMS.paged_folded_comments(:changelog, changelog.id, %{page: page_number, size: page_size})

      assert exist_in?(random_comment_1, paged_comments.entries)
      assert exist_in?(random_comment_2, paged_comments.entries)
      assert exist_in?(random_comment_3, paged_comments.entries)

      assert page_number == paged_comments.page_number
      assert page_size == paged_comments.page_size
      assert total_count == paged_comments.total_count
    end
  end

  describe "[article comment delete]" do
    @tag :wip
    test "delete comment still exsit in paged list and content is gone", ~m(user changelog)a do
      total_count = 10
      page_number = 1
      page_size = 20

      all_comments =
        Enum.reduce(1..total_count, [], fn _, acc ->
          {:ok, comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)

          acc ++ [comment]
        end)

      random_comment = all_comments |> Enum.at(1)

      {:ok, deleted_comment} = CMS.delete_comment(random_comment)

      {:ok, paged_comments} =
        CMS.paged_comments(
          :changelog,
          changelog.id,
          %{page: page_number, size: page_size},
          :replies
        )

      assert exist_in?(deleted_comment, paged_comments.entries)
      assert deleted_comment.is_deleted
      assert deleted_comment.body_html == @delete_hint
    end

    @tag :wip
    test "delete comment still update article's comments_count field", ~m(user changelog)a do
      {:ok, _comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)
      {:ok, _comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)
      {:ok, comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)
      {:ok, _comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)
      {:ok, _comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)

      {:ok, changelog} = ORM.find(Changelog, changelog.id)

      assert changelog.comments_count == 5

      {:ok, _} = CMS.delete_comment(comment)

      {:ok, changelog} = ORM.find(Changelog, changelog.id)
      assert changelog.comments_count == 4
    end

    @tag :wip
    test "delete comment still delete pinned record if needed", ~m(user changelog)a do
      total_count = 10

      all_comments =
        Enum.reduce(1..total_count, [], fn _, acc ->
          {:ok, comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)

          acc ++ [comment]
        end)

      random_comment = all_comments |> Enum.at(1)

      {:ok, _comment} = CMS.pin_comment(random_comment.id)
      {:ok, _comment} = ORM.find(Comment, random_comment.id)

      {:ok, _} = CMS.delete_comment(random_comment)
      assert {:error, _comment} = ORM.find(PinnedComment, random_comment.id)
    end
  end

  describe "[article comment info]" do
    @tag :wip
    test "author of the article comment a comment should have flag", ~m(user changelog)a do
      {:ok, comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)
      assert not comment.is_article_author

      author_user = changelog.author.user
      {:ok, comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), author_user)
      assert comment.is_article_author
    end
  end

  describe "[lock/unlock changelog comment]" do
    @tag :wip
    test "locked changelog can not be comment", ~m(user changelog)a do
      {:ok, _} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)
      {:ok, _} = CMS.lock_article_comments(:changelog, changelog.id)

      {:error, reason} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)
      assert reason |> is_error?(:article_comments_locked)

      {:ok, _} = CMS.undo_lock_article_comments(:changelog, changelog.id)
      {:ok, _} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)
    end

    test "locked changelog can not by reply", ~m(user changelog)a do
      {:ok, parent_comment} = CMS.create_comment(:changelog, changelog.id, mock_comment(), user)
      {:ok, _} = CMS.reply_comment(parent_comment.id, mock_comment(), user)

      {:ok, _} = CMS.lock_article_comments(:changelog, changelog.id)

      {:error, reason} = CMS.reply_comment(parent_comment.id, mock_comment(), user)
      assert reason |> is_error?(:article_comments_locked)

      {:ok, _} = CMS.undo_lock_article_comments(:changelog, changelog.id)
      {:ok, _} = CMS.reply_comment(parent_comment.id, mock_comment(), user)
    end
  end

  describe "[update user info in comments_participants]" do
    @tag :wip
    test "basic find", ~m(user community)a do
      changelog_attrs = mock_attrs(:changelog, %{community_id: community.id, is_question: true})
      {:ok, changelog} = CMS.create_article(community, :changelog, changelog_attrs, user)

      {:ok, _comment} =
        CMS.create_comment(:changelog, changelog.id, mock_comment("solution"), user)

      CMS.update_user_in_comments_participants(user)
    end
  end
end
