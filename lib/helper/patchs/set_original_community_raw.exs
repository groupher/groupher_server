import Ecto.Query, warn: false

alias Helper.ORM

alias GroupherServer.Repo
alias GroupherServer.CMS.Model.Post

{:ok, all_posts} =
  Post
  |> where([p], is_nil(p.original_community_raw))
  |> ORM.find_all(%{page: 1, size: 100})

Enum.each(all_posts.entries, fn post ->
  post = Repo.preload(post, :original_community)

  IO.inspect(post.title, label: "post")
  IO.inspect(post.original_community.raw, label: "community")

  case post.original_community_raw do
    nil -> ORM.update(post, %{original_community_raw: post.original_community.raw})
    _ -> {:ok, :pass}
  end

  IO.inspect("---")
end)
