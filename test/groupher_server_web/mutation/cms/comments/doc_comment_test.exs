defmodule GroupherServer.Test.Mutation.Comments.DocComment do
  use GroupherServer.TestTools

  alias GroupherServer.CMS
  alias CMS.Model.Doc

  alias Helper.ORM

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)
    {:ok, doc} = CMS.create_article(community, :doc, mock_attrs(:doc), user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn user guest_conn owner_conn community doc)a}
  end

  describe "[article comment CRUD]" do
    @write_comment_query """
    mutation($thread: Thread!, $id: ID!, $body: String!) {
      createComment(thread: $thread,id: $id, body: $body) {
        id
        bodyHtml
      }
    }
    """

    test "write article comment to a exsit doc", ~m(doc user_conn)a do
      variables = %{thread: "DOC", id: doc.id, body: mock_comment()}

      result = user_conn |> mutation_result(@write_comment_query, variables, "createComment")

      assert result["bodyHtml"] |> String.contains?(~s(<p id=))
      assert result["bodyHtml"] |> String.contains?(~s(comment</p>))
    end

    @reply_comment_query """
    mutation($id: ID!, $body: String!) {
      replyComment(id: $id, body: $body) {
        id
        bodyHtml
      }
    }
    """

    test "login user can reply to a comment", ~m(doc user user_conn)a do
      {:ok, comment} = CMS.create_comment(:doc, doc.id, mock_comment(), user)
      variables = %{id: comment.id, body: mock_comment("reply comment")}

      result = user_conn |> mutation_result(@reply_comment_query, variables, "replyComment")

      assert result["bodyHtml"] |> String.contains?(~s(<p id=))
      assert result["bodyHtml"] |> String.contains?(~s(reply comment</p>))
    end

    @update_comment_query """
    mutation($id: ID!, $body: String!) {
      updateComment(id: $id, body: $body) {
        id
        bodyHtml
      }
    }
    """

    test "only owner can update a exsit comment",
         ~m(doc user guest_conn user_conn owner_conn)a do
      {:ok, comment} = CMS.create_comment(:doc, doc.id, mock_comment(), user)
      variables = %{id: comment.id, body: mock_comment("updated comment")}

      assert user_conn |> mutation_get_error?(@update_comment_query, variables, ecode(:passport))

      assert guest_conn
             |> mutation_get_error?(@update_comment_query, variables, ecode(:account_login))

      result = owner_conn |> mutation_result(@update_comment_query, variables, "updateComment")

      assert result["bodyHtml"] |> String.contains?(~s(<p id=))
      assert result["bodyHtml"] |> String.contains?(~s(updated comment</p>))
    end

    @delete_comment_query """
    mutation($id: ID!) {
      deleteComment(id: $id) {
        id
        isDeleted
      }
    }
    """

    test "only owner can delete a exsit comment",
         ~m(doc user guest_conn user_conn owner_conn)a do
      {:ok, comment} = CMS.create_comment(:doc, doc.id, mock_comment(), user)
      variables = %{id: comment.id}

      assert user_conn |> mutation_get_error?(@delete_comment_query, variables, ecode(:passport))

      assert guest_conn
             |> mutation_get_error?(@delete_comment_query, variables, ecode(:account_login))

      deleted = owner_conn |> mutation_result(@delete_comment_query, variables, "deleteComment")

      assert deleted["id"] == to_string(comment.id)
      assert deleted["isDeleted"]
    end
  end

  describe "[article comment upvote]" do
    @upvote_comment_query """
    mutation($id: ID!) {
      upvoteComment(id: $id) {
        id
        upvotesCount
        viewerHasUpvoted
      }
    }
    """

    test "login user can upvote a exsit doc comment",
         ~m(doc user guest_conn user_conn)a do
      {:ok, comment} = CMS.create_comment(:doc, doc.id, mock_comment(), user)
      variables = %{id: comment.id}

      assert guest_conn
             |> mutation_get_error?(@upvote_comment_query, variables, ecode(:account_login))

      result = user_conn |> mutation_result(@upvote_comment_query, variables, "upvoteComment")

      assert result["id"] == to_string(comment.id)
      assert result["upvotesCount"] == 1
      assert result["viewerHasUpvoted"]
    end

    @undo_upvote_comment_query """
    mutation($id: ID!) {
      undoUpvoteComment(id: $id) {
        id
        upvotesCount
        viewerHasUpvoted
      }
    }
    """

    test "login user can undo upvote a exsit doc comment",
         ~m(doc user guest_conn user_conn)a do
      {:ok, comment} = CMS.create_comment(:doc, doc.id, mock_comment(), user)
      variables = %{id: comment.id}
      user_conn |> mutation_result(@upvote_comment_query, variables, "upvoteComment")

      assert guest_conn
             |> mutation_get_error?(@undo_upvote_comment_query, variables, ecode(:account_login))

      result =
        user_conn
        |> mutation_result(@undo_upvote_comment_query, variables, "undoUpvoteComment")

      assert result["upvotesCount"] == 0
      assert not result["viewerHasUpvoted"]
    end
  end

  describe "[article comment emotion]" do
    @emotion_comment_query """
    mutation($id: ID!, $emotion: CommentEmotion!) {
      emotionToComment(id: $id, emotion: $emotion) {
        id
        emotions {
          beerCount
          viewerHasBeered
          latestBeerUsers {
            login
            nickname
          }
        }
      }
    }
    """

    test "login user can emotion to a comment", ~m(doc user user_conn)a do
      {:ok, comment} = CMS.create_comment(:doc, doc.id, mock_comment(), user)
      variables = %{id: comment.id, emotion: "BEER"}

      comment =
        user_conn |> mutation_result(@emotion_comment_query, variables, "emotionToComment")

      assert comment |> get_in(["emotions", "beerCount"]) == 1
      assert get_in(comment, ["emotions", "viewerHasBeered"])
    end

    @emotion_comment_query """
    mutation($id: ID!, $emotion: CommentEmotion!) {
      undoEmotionToComment(id: $id, emotion: $emotion) {
        id
        emotions {
          beerCount
          viewerHasBeered
          latestBeerUsers {
            login
            nickname
          }
        }
      }
    }
    """

    test "login user can undo emotion to a comment", ~m(doc user owner_conn)a do
      {:ok, comment} = CMS.create_comment(:doc, doc.id, mock_comment(), user)
      {:ok, _} = CMS.emotion_to_comment(comment.id, :beer, user)

      variables = %{id: comment.id, emotion: "BEER"}

      comment =
        owner_conn |> mutation_result(@emotion_comment_query, variables, "undoEmotionToComment")

      assert comment |> get_in(["emotions", "beerCount"]) == 0
      assert not get_in(comment, ["emotions", "viewerHasBeered"])
    end
  end

  describe "[article comment lock/unlock]" do
    @query """
    mutation($id: ID!, $communityId: ID!){
      lockDocComment(id: $id, communityId: $communityId) {
        id
        title
      }
    }
    """

    test "can lock a doc's comment", ~m(community doc)a do
      variables = %{id: doc.id, communityId: community.id}
      passport_rules = %{community.slug => %{"doc.lock_comment" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      result = rule_conn |> mutation_result(@query, variables, "lockDocComment")
      assert result["id"] == to_string(doc.id)

      {:ok, doc} = ORM.find(Doc, doc.id)
      assert doc.meta.is_comment_locked
    end

    test "unauth user  fails", ~m(guest_conn community doc)a do
      variables = %{id: doc.id, communityId: community.id}

      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end

    @query """
    mutation($id: ID!, $communityId: ID!){
      undoLockDocComment(id: $id, communityId: $communityId) {
        id
      }
    }
    """

    test "can undo lock a doc's comment", ~m(community doc)a do
      {:ok, _} = CMS.lock_article_comments(:doc, doc.id)
      {:ok, doc} = ORM.find(Doc, doc.id)
      assert doc.meta.is_comment_locked

      variables = %{id: doc.id, communityId: community.id}
      passport_rules = %{community.slug => %{"doc.undo_lock_comment" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      result = rule_conn |> mutation_result(@query, variables, "undoLockDocComment")
      assert result["id"] == to_string(doc.id)

      {:ok, doc} = ORM.find(Doc, doc.id)
      assert not doc.meta.is_comment_locked
    end

    test "unauth user undo fails", ~m(guest_conn community doc)a do
      variables = %{id: doc.id, communityId: community.id}

      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end
  end

  describe "[article comment pin/unPin]" do
    @query """
    mutation($id: ID!){
      pinComment(id: $id) {
        id
        isPinned
      }
    }
    """

    test "can pin a doc's comment", ~m(owner_conn doc user)a do
      {:ok, comment} = CMS.create_comment(:doc, doc.id, mock_comment(), user)

      variables = %{id: comment.id}
      result = owner_conn |> mutation_result(@query, variables, "pinComment")

      assert result["id"] == to_string(comment.id)
      assert result["isPinned"]
    end

    test "unauth user fails.", ~m(guest_conn doc user)a do
      {:ok, comment} = CMS.create_comment(:doc, doc.id, mock_comment(), user)
      variables = %{id: comment.id}

      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end

    @query """
    mutation($id: ID!){
      undoPinComment(id: $id) {
        id
        isPinned
      }
    }
    """

    test "can undo pin a doc's comment", ~m(owner_conn doc user)a do
      {:ok, comment} = CMS.create_comment(:doc, doc.id, mock_comment(), user)
      {:ok, _} = CMS.pin_comment(comment.id)

      variables = %{id: comment.id}
      result = owner_conn |> mutation_result(@query, variables, "undoPinComment")

      assert result["id"] == to_string(comment.id)
      assert not result["isPinned"]
    end

    test "unauth user undo fails.", ~m(guest_conn doc user)a do
      {:ok, comment} = CMS.create_comment(:doc, doc.id, mock_comment(), user)
      {:ok, _} = CMS.pin_comment(comment.id)
      variables = %{id: comment.id}

      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end
  end
end
