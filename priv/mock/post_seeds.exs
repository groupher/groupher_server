alias GroupherServer.CMS.Delegate.Seeds

alias GroupherServer.CMS
alias CMS.Model.{Post, ArticleTag}
alias CMS.Constant
alias Helper.ORM

# Enum.reduce(1..10, [], fn _, _ ->
  # {:ok, post} = Seeds.Articles.seed_articles("home", :post)

  # {:ok, _} = CMS.set_post_cat(post, Constant.article_cat().feature)
  # {:ok, _} = CMS.set_post_state(post, Constant.article_state().todo)

  # {:ok, doc} = Seeds.Articles.seed_articles("home", :doc)
# end)

{:ok, post} = ORM.find(Post, 8)
{:ok, tag} = ORM.find(ArticleTag, 4)
{:ok, tag2} = ORM.find(ArticleTag, 5)

IO.inspect post, label: "find post"
IO.inspect tag, label: "find tag"
IO.inspect tag2, label: "find tag2"

# {:ok, post} = CMS.set_article_tag(:post, post.id, tag.id)
# {:ok, post} = CMS.set_article_tag(:post, post.id, tag2.id)
