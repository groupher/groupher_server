alias GroupherServer.CMS.Delegate.Seeds

alias GroupherServer.CMS
alias CMS.Constant

Enum.reduce(1..5, [], fn _, _ ->
  {:ok, post} = Seeds.Posts.seed_posts("home", :post)

  # {:ok, _} = CMS.set_post_cat(post, Constant.article_cat().feature)
  # {:ok, _} = CMS.set_post_state(post, Constant.article_state().todo)

  {:ok, _} = CMS.set_post_cat(post, Constant.article_cat().bug)
  {:ok, _} = CMS.set_post_state(post, Constant.article_state().done)
end)
