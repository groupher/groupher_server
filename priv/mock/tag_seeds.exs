alias GroupherServer.CMS.Delegate.Seeds

alias GroupherServer.{Accounts, CMS}
alias Helper.ORM

{:ok, community} = ORM.find_by(CMS.Model.Community, raw: "home")
{:ok, user} = ORM.find(Accounts.Model.User, 1)

IO.inspect community.raw, label: "@@ got community"
IO.inspect user.nickname, label: "@@ got user"


article_tag_attrs = %{
  title: "HM",
  raw: "hm",
  thread: "POST",
  color: "YELLOW",
  group: "平台",
  # community: Faker.Pizza.topping(),
  community: community,
  author: user,
  extra: []
  # user_id: 1
}

{:ok, _article_tag} = CMS.create_article_tag(community, :post, article_tag_attrs, user)

# Enum.reduce(1..5, [], fn _, _ ->
#   {:ok, post} = Seeds.Posts.seed_posts("home", :post)

#   {:ok, _} = CMS.set_post_cat(post, Constant.article_cat().bug)
#   {:ok, _} = CMS.set_post_state(post, Constant.article_state().done)
# end)
