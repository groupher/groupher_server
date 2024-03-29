defmodule Helper.QueryBuilder do
  @moduledoc """
  handle common query pices across the project
  """

  import Ecto.Query, warn: false
  alias GroupherServer.CMS

  alias CMS.Constant

  @article_cat Constant.article_cat()
  @article_state Constant.article_state()

  @audit_illegal Constant.pending(:illegal)
  @audit_failed Constant.pending(:audit_failed)

  @doc """
  load inner user field
  """
  def load_inner_users(queryable, filter) do
    queryable
    |> join(:inner, [f], u in assoc(f, :user))
    |> select([f, u], u)
    |> filter_pack(filter)
  end

  @doc """
  inserted in latest x mounth
  """
  def recent_inserted(queryable, months: count) do
    end_of_today = Timex.now() |> Timex.end_of_day()
    x_months_ago = Timex.today() |> Timex.shift(months: -count) |> Timex.to_datetime()

    queryable
    |> where([q], q.inserted_at >= ^x_months_ago)
    |> where([q], q.inserted_at <= ^end_of_today)
  end

  @doc """
  inserted in latest x days
  """
  def recent_inserted(queryable, days: count) do
    end_of_today = Timex.now() |> Timex.end_of_day()
    x_days_ago = Timex.today() |> Timex.shift(days: -count) |> Timex.to_datetime()

    queryable
    |> where([q], q.inserted_at >= ^x_days_ago)
    |> where([q], q.inserted_at <= ^end_of_today)
  end

  # this is strategy will cause
  # defp sort_strategy(:desc_inserted), do: [desc: :inserted_at, desc: :views]
  # defp sort_strategy(:most_views), do: [desc: :views, desc: :inserted_at]
  # defp sort_strategy(:least_views), do: [asc: :views, desc: :inserted_at]
  # defp strategy(:most_stars), do: [desc: :views, desc: :inserted_at]

  defp sort_by_count(queryable, field, direction) do
    queryable
    |> join(:left, [p], s in assoc(p, ^field))
    |> group_by([p], p.id)
    |> select([p], p)
    |> order_by([_, s], {^direction, fragment("count(?)", s.id)})
  end

  defp trans_article_cat(queryable, cat) when is_integer(cat) do
    queryable |> where([p], p.cat == ^cat)
  end

  defp trans_article_cat(queryable, cat) when is_binary(cat) do
    cat_key = cat |> String.downcase() |> String.to_atom()
    cat_value = @article_cat |> Map.get(cat_key)

    case cat_value do
      ## -1 means not exist
      nil -> queryable |> where([p], p.cat == -1)
      _ -> queryable |> where([p], p.cat == ^cat_value)
    end
  end

  defp trans_article_state(queryable, state) when is_integer(state) do
    queryable |> where([p], p.state == ^state)
  end

  defp trans_article_state(queryable, state) when is_binary(state) do
    state_key = state |> String.downcase() |> String.to_atom()
    state_value = @article_state |> Map.get(state_key)

    case state_value do
      ## -1 means not exist
      nil -> queryable |> where([p], p.state == -1)
      _ -> queryable |> where([p], p.state == ^state_value)
    end
  end

  defp trans_articles_order(queryable, "upvotes") do
    queryable |> order_by(desc: :upvotes_count)
  end

  defp trans_articles_order(queryable, "comments") do
    queryable |> order_by(desc: :comments_count)
  end

  defp trans_articles_order(queryable, "views") do
    queryable |> order_by(desc: :views, desc: :inserted_at)
  end

  defp trans_articles_order(queryable, "publish") do
    queryable |> order_by(desc: :inserted_at)
  end

  defp trans_articles_order(queryable, _), do: queryable

  def filter_pack(queryable, filter) when is_map(filter) do
    Enum.reduce(filter, queryable, fn
      {:order, nil}, queryable ->
        queryable

      {:order, key}, queryable ->
        queryable |> trans_articles_order(String.downcase(key))

      # old
      {:sort, :desc_active}, queryable ->
        queryable |> order_by(desc: :active_at)

      {:sort, :desc_inserted}, queryable ->
        # queryable |> order_by(^sort_strategy(:desc_inserted))
        queryable |> order_by(desc: :inserted_at)

      {:sort, :asc_inserted}, queryable ->
        queryable |> order_by(asc: :inserted_at)

      {:sort, :desc_index}, queryable ->
        queryable |> order_by(desc: :index)

      {:sort, :asc_index}, queryable ->
        queryable |> order_by(asc: :index)

      {:sort, :most_views}, queryable ->
        queryable |> order_by(desc: :views, desc: :inserted_at)

      {:sort, :least_views}, queryable ->
        queryable |> order_by(asc: :views, desc: :inserted_at)

      {:sort, :most_stars}, queryable ->
        queryable |> sort_by_count(:stars, :desc)

      {:sort, :least_stars}, queryable ->
        queryable |> sort_by_count(:stars, :asc)

      {:length, :most_words}, queryable ->
        queryable |> order_by(desc: :length)

      {:length, :least_words}, queryable ->
        queryable |> order_by(asc: :length)

      {:when, :today}, queryable ->
        # date = DateTime.utc_now() |> Timex.to_datetime()
        # use timezone info is server is not in the some timezone
        # Timex.now("America/Chicago")
        date = Timex.now()

        queryable
        |> where([p], p.inserted_at >= ^Timex.beginning_of_day(date))
        |> where([p], p.inserted_at <= ^Timex.end_of_day(date))

      {:when, :this_week}, queryable ->
        date = Timex.now()

        queryable
        |> where([p], p.inserted_at >= ^Timex.beginning_of_week(date))
        |> where([p], p.inserted_at <= ^Timex.end_of_week(date))

      {:when, :this_month}, queryable ->
        date = Timex.now()

        queryable
        |> where([p], p.inserted_at >= ^Timex.beginning_of_month(date))
        |> where([p], p.inserted_at <= ^Timex.end_of_month(date))

      {:when, :this_year}, queryable ->
        date = Timex.now()

        queryable
        |> where([p], p.inserted_at >= ^Timex.beginning_of_year(date))
        |> where([p], p.inserted_at <= ^Timex.end_of_year(date))

      {:article_tag, tag_name}, queryable ->
        from(
          q in queryable,
          join: t in assoc(q, :article_tags),
          where: t.slug == ^tag_name
        )

      {:article_tags, tag_name_list}, queryable ->
        from(
          q in queryable,
          join: t in assoc(q, :article_tags),
          where: t.slug in ^tag_name_list,
          distinct: q.id,
          group_by: q.id
        )

      {:category, catetory_slug}, queryable ->
        from(
          q in queryable,
          join: t in assoc(q, :categories),
          where: t.slug == ^catetory_slug
        )

      {:thread, thread}, queryable ->
        thread = thread |> to_string |> String.upcase()
        from(q in queryable, where: q.thread == ^thread)

      {:community_id, community_id}, queryable ->
        from(
          q in queryable,
          join: t in assoc(q, :community),
          where: t.id == ^community_id
        )

      {:original_community_id, original_community_id}, queryable ->
        from(
          q in queryable,
          join: t in assoc(q, :original_community),
          where: t.id == ^original_community_id
        )

      {:cat, nil}, queryable ->
        queryable

      {:state, nil}, queryable ->
        queryable

      {:cat, cat}, queryable ->
        queryable |> trans_article_cat(cat)

      {:state, state}, queryable ->
        queryable |> trans_article_state(state)

      {:community_slug, community_slug}, queryable ->
        from(
          q in queryable,
          join: t in assoc(q, :community),
          where: t.slug == ^community_slug
        )

      {:community, community_slug}, queryable ->
        from(
          q in queryable,
          join: t in assoc(q, :communities),
          where: t.slug == ^community_slug
        )

      {:first, first}, queryable ->
        queryable |> limit(^first)

      {:mark_delete, bool}, queryable ->
        queryable |> where([p], p.mark_delete == ^bool)

      {:pending, :legal}, queryable ->
        queryable |> where([p], p.pending != ^@audit_illegal)

      {:pending, :audit_failed}, queryable ->
        queryable |> where([p], p.pending == ^@audit_failed)

      {_, _}, queryable ->
        queryable
    end)
  end

  @doc """
  handle spec needs for CMS query filter
  """
  def domain_query(queryable, _filter), do: queryable
end
