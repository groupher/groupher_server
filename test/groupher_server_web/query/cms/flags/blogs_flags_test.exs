defmodule GroupherServer.Test.Query.Flags.BlogsFlags do
  use GroupherServer.TestTools

  import Helper.Utils, only: [get_config: 2]

  alias GroupherServer.{CMS}
  alias Helper.ORM

  @total_count 35
  @page_size get_config(:general, :page_size)

  @audit_illegal CMS.Constant.pending(:illegal)

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    {:ok, community2} = db_insert(:community)
    CMS.create_article(community2, :blog, mock_attrs(:blog), user)

    blogs =
      Enum.reduce(1..@total_count, [], fn _, acc ->
        {:ok, value} = CMS.create_article(community, :blog, mock_attrs(:blog), user)
        acc ++ [value]
      end)

    blog_b = blogs |> List.first()
    blog_m = blogs |> Enum.at(div(@total_count, 2))
    blog_e = blogs |> List.last()

    guest_conn = simu_conn(:guest)

    {:ok, ~m(guest_conn community user blog_b blog_m blog_e)a}
  end

  describe "[pending blogs flags]" do
    @query """
    query($filter: PagedBlogsFilter!) {
      pagedBlogs(filter: $filter) {
        entries {
          id
          pending
          communities {
            raw
          }
        }
        totalPages
        totalCount
        pageSize
        pageNumber
      }
    }
    """

    test "pending blog should not see in paged query",
         ~m(guest_conn community blog_m)a do
      variables = %{filter: %{community: community.raw}}
      results = guest_conn |> query_result(@query, variables, "pagedBlogs")

      assert results["totalCount"] == @total_count

      {:ok, _} =
        CMS.set_article_illegal(:blog, blog_m.id, %{
          is_legal: false,
          illegal_reason: ["some-reason"],
          illegal_words: ["some-word"]
        })

      {:ok, blog_m} = ORM.find(CMS.Model.Blog, blog_m.id)
      assert blog_m.pending == @audit_illegal

      results = guest_conn |> query_result(@query, variables, "pagedBlogs")
      assert results["totalCount"] == @total_count - 1
    end
  end

  describe "[pinned blogs flags]" do
    @query """
    query($filter: PagedBlogsFilter!) {
      pagedBlogs(filter: $filter) {
        entries {
          id
          isPinned
          communities {
            raw
          }
        }
        totalPages
        totalCount
        pageSize
        pageNumber
      }
    }
    """

    test "if have pinned blogs, the pinned blogs should at the top of entries",
         ~m(guest_conn community blog_m)a do
      variables = %{filter: %{community: community.raw}}

      results = guest_conn |> query_result(@query, variables, "pagedBlogs")

      assert results |> is_valid_pagination?
      assert results["pageSize"] == @page_size
      assert results["totalCount"] == @total_count

      {:ok, _} = CMS.pin_article(:blog, blog_m.id, community.id)

      results = guest_conn |> query_result(@query, variables, "pagedBlogs")
      entries_first = results["entries"] |> List.first()

      assert results["totalCount"] == @total_count
      assert entries_first["id"] == to_string(blog_m.id)
      assert entries_first["isPinned"] == true
    end

    test "pind blogs should not appear when page > 1", ~m(guest_conn community)a do
      variables = %{filter: %{page: 2, size: 20}}
      results = guest_conn |> query_result(@query, variables, "pagedBlogs")
      assert results |> is_valid_pagination?

      random_id = results["entries"] |> Enum.shuffle() |> List.first() |> Map.get("id")

      {:ok, _} = CMS.pin_article(:blog, random_id, community.id)

      results = guest_conn |> query_result(@query, variables, "pagedBlogs")

      assert results["entries"] |> Enum.any?(&(&1["id"] !== random_id))
    end

    test "if have trashed blogs, the mark deleted blogs should not appears in result",
         ~m(guest_conn community)a do
      variables = %{filter: %{community: community.raw}}
      results = guest_conn |> query_result(@query, variables, "pagedBlogs")

      random_id = results["entries"] |> Enum.shuffle() |> List.first() |> Map.get("id")
      {:ok, _} = CMS.mark_delete_article(:blog, random_id)

      results = guest_conn |> query_result(@query, variables, "pagedBlogs")

      assert results["entries"] |> Enum.any?(&(&1["id"] !== random_id))
      assert results["totalCount"] == @total_count - 1
    end
  end
end