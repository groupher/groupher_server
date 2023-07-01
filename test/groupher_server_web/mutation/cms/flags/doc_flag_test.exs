defmodule GroupherServer.Test.Mutation.Flags.DocFlag do
  use GroupherServer.TestTools

  alias GroupherServer.CMS
  alias CMS.Model.Community

  alias Helper.ORM

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    {:ok, doc} = CMS.create_article(community, :doc, mock_attrs(:doc), user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn guest_conn owner_conn community user doc)a}
  end

  describe "[mutation doc flag curd]" do
    @query """
    mutation($id: ID!){
      markDeleteDoc(id: $id) {
        id
        markDelete
      }
    }
    """

    test "auth user can markDelete doc", ~m(doc)a do
      variables = %{id: doc.id}

      passport_rules = %{"doc.mark_delete" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      updated = rule_conn |> mutation_result(@query, variables, "markDeleteDoc")

      assert updated["id"] == to_string(doc.id)
      assert updated["markDelete"] == true
    end

    test "mark delete doc should update doc's communities meta count", ~m(user)a do
      community_attrs = mock_attrs(:community) |> Map.merge(%{user_id: user.id})
      {:ok, community} = CMS.create_community(community_attrs)
      {:ok, doc} = CMS.create_article(community, :doc, mock_attrs(:doc), user)

      {:ok, community} = ORM.find(Community, community.id)
      assert community.meta.docs_count == 1

      variables = %{id: doc.id}
      passport_rules = %{"doc.mark_delete" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      rule_conn |> mutation_result(@query, variables, "markDeleteDoc")

      {:ok, community} = ORM.find(Community, community.id)
      assert community.meta.docs_count == 0
    end

    test "unauth user markDelete doc fails", ~m(user_conn guest_conn doc)a do
      variables = %{id: doc.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!){
      undoMarkDeleteDoc(id: $id) {
        id
        markDelete
      }
    }
    """

    test "auth user can undo markDelete doc", ~m(doc)a do
      variables = %{id: doc.id}

      {:ok, _} = CMS.mark_delete_article(:doc, doc.id)

      passport_rules = %{"doc.undo_mark_delete" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)

      updated = rule_conn |> mutation_result(@query, variables, "undoMarkDeleteDoc")

      assert updated["id"] == to_string(doc.id)
      assert updated["markDelete"] == false
    end

    test "undo mark delete doc should update doc's communities meta count",
         ~m(user)a do
      community_attrs = mock_attrs(:community) |> Map.merge(%{user_id: user.id})
      {:ok, community} = CMS.create_community(community_attrs)
      {:ok, doc} = CMS.create_article(community, :doc, mock_attrs(:doc), user)

      {:ok, _} = CMS.mark_delete_article(:doc, doc.id)

      {:ok, community} = ORM.find(Community, community.id)
      assert community.meta.docs_count == 0

      variables = %{id: doc.id}
      passport_rules = %{"doc.undo_mark_delete" => true}
      rule_conn = simu_conn(:user, cms: passport_rules)
      rule_conn |> mutation_result(@query, variables, "undoMarkDeleteDoc")

      {:ok, community} = ORM.find(Community, community.id)
      assert community.meta.docs_count == 1
    end

    test "unauth user undo markDelete doc fails", ~m(user_conn guest_conn doc)a do
      variables = %{id: doc.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!, $communityId: ID!){
      pinDoc(id: $id, communityId: $communityId) {
        id
      }
    }
    """

    test "auth user can pin doc", ~m(community doc)a do
      variables = %{id: doc.id, communityId: community.id}

      passport_rules = %{community.slug => %{"doc.pin" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      updated = rule_conn |> mutation_result(@query, variables, "pinDoc")

      assert updated["id"] == to_string(doc.id)
    end

    test "unauth user pin doc fails", ~m(user_conn guest_conn community doc)a do
      variables = %{id: doc.id, communityId: community.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end

    @query """
    mutation($id: ID!, $communityId: ID!){
      undoPinDoc(id: $id, communityId: $communityId) {
        id
        isPinned
      }
    }
    """

    test "auth user can undo pin doc", ~m(community doc)a do
      variables = %{id: doc.id, communityId: community.id}

      passport_rules = %{community.slug => %{"doc.undo_pin" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      CMS.pin_article(:doc, doc.id, community.id)
      updated = rule_conn |> mutation_result(@query, variables, "undoPinDoc")

      assert updated["id"] == to_string(doc.id)
    end

    test "unauth user undo pin doc fails", ~m(user_conn guest_conn community doc)a do
      variables = %{id: doc.id, communityId: community.id}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:passport))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
      assert rule_conn |> mutation_get_error?(@query, variables, ecode(:passport))
    end
  end
end
