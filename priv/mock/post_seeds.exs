alias GroupherServer.CMS.Delegate.Seeds

alias GroupherServer.CMS
alias CMS.Constant

Enum.reduce(1..10, [], fn _, _ ->
  # {:ok, post} = Seeds.Articles.seed_articles("home", :post)

  # {:ok, _} = CMS.set_post_cat(post, Constant.article_cat().feature)
  # {:ok, _} = CMS.set_post_state(post, Constant.article_state().todo)

  {:ok, doc} = Seeds.Articles.seed_articles("home", :doc)
end)
