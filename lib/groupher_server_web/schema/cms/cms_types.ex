defmodule GroupherServerWeb.Schema.CMS.Types do
  @moduledoc """
  cms types used in queries & mutations
  """
  use Helper.GqlSchemaSuite

  import GroupherServerWeb.Schema.Helper.Fields
  import GroupherServerWeb.Schema.Helper.Objects

  import Ecto.Query, warn: false
  import Absinthe.Resolution.Helpers, only: [dataloader: 2]

  alias GroupherServer.CMS
  alias GroupherServerWeb.Schema

  import_types(Schema.CMS.Metrics)

  object :check_state do
    field(:exist, :boolean)
  end

  object :done_state do
    field(:done, :boolean)
  end

  ######
  # common stands for minimal info of the type
  # usually used in abuse_report, feeds, etc ..
  object :common_user do
    field(:login, :string)
    field(:avatar, :string)
    field(:nickname, :string)
    field(:avatar, :string)
    field(:bio, :string)
    field(:shortbio, :string)
  end

  object :common_article do
    field(:thread, :string)
    field(:id, :id)
    # field(:body_html, :string)
    field(:title, :string)
    field(:author, :common_user)
  end

  object :common_comment do
    field(:id, :id)
    field(:body_html, :string)
    field(:upvotes_count, :integer)
    field(:author, :common_user)
    field(:article, :common_article)
  end

  ######

  object :idlike do
    field(:id, :id)
  end

  object :thread_document do
    field(:body, :string)
    field(:body_html, :string)
  end

  object :post do
    meta(:cache, max_age: 30)
    interface(:article)

    general_article_fields()
    comments_fields()

    field(:cat, :string)
    field(:state, :string)

    timestamp_fields(:article)
  end

  object :changelog do
    meta(:cache, max_age: 30)
    interface(:article)

    general_article_fields()
    comments_fields()

    timestamp_fields(:article)
  end

  object :doc do
    meta(:cache, max_age: 30)
    interface(:article)

    general_article_fields()
    comments_fields()

    timestamp_fields(:article)
  end

  object :blog do
    meta(:cache, max_age: 30)
    interface(:article)

    general_article_fields()
    comments_fields()

    timestamp_fields(:article)
  end

  object :thread_item do
    field(:id, :id)
    field(:title, :string)
    field(:slug, :string)
    field(:index, :integer)
  end

  object :contribute do
    meta(:cache, max_age: 30)
    field(:date, :date)
    field(:count, :integer)
  end

  object :contribute_map do
    meta(:cache, max_age: 30)
    field(:start_date, :date)
    field(:end_date, :date)
    field(:total_count, :integer)
    field(:records, list_of(:contribute))
  end

  object(:dasbboard_rss, do: dashboard_gq_fields(:rss))
  object(:dasbboard_seo, do: dashboard_gq_fields(:seo))

  object :dasbboard_layout do
    dashboard_gq_fields(:layout)
    field(:kanban_bg_colors, list_of(:string))
  end

  object(:dasbboard_enable, do: dashboard_gq_fields(:enable))
  object(:dasbboard_base_info, do: dashboard_gq_fields(:base_info))
  object(:dasbboard_name_alias, do: dashboard_gq_fields(:name_alias))
  object(:dasbboard_link, do: dashboard_gq_fields(:header_link))
  object(:dasbboard_social_link, do: dashboard_gq_fields(:social_link))
  object(:dasbboard_faq_section, do: dashboard_gq_fields(:faq_section))

  object :dashboard do
    field(:seo, :dasbboard_seo)
    field(:layout, :dasbboard_layout)
    field(:enable, :dasbboard_enable)
    field(:base_info, :dasbboard_base_info)
    field(:rss, :dasbboard_rss)
    field(:name_alias, list_of(:dasbboard_name_alias))
    field(:header_links, list_of(:dasbboard_link))
    field(:footer_links, list_of(:dasbboard_link))
    field(:social_links, list_of(:dasbboard_social_link))
    field(:faqs, list_of(:dasbboard_faq_section))
  end

  object :community_admins do
    field(:root, :common_user)
    field(:moderators, list_of(:common_user))
  end

  object :community do
    meta(:cache, max_age: 30)
    field(:id, :id)
    field(:title, :string)
    field(:desc, :string)
    field(:slug, :string)
    field(:index, :integer)
    field(:logo, :string)
    field(:author, :user, resolve: dataloader(CMS, :author))
    field(:threads, list_of(:thread_item), resolve: dataloader(CMS, :threads))
    field(:categories, list_of(:category), resolve: dataloader(CMS, :categories))
    field(:dashboard, :dashboard, resolve: dataloader(CMS, :dashboard))
    field(:root_user, :user, resolve: dataloader(CMS, :root_user))

    # field(:admins, :community_admins, resolve: dataloader(CMS, :admins))
    field(:admins, :community_admins)

    field(:meta, :community_meta)
    field(:views, :integer)
    field(:contributes_digest, list_of(:integer))

    field(:articles_count, :integer)
    field(:subscribers_count, :integer)
    field(:editors_count, :integer)
    field(:article_tags_count, :integer)

    field(:viewer_has_subscribed, :boolean)
    field(:viewer_is_editor, :boolean)

    field(:pending, :integer)

    # TODO: remove
    field :threads_count, :integer do
      resolve(&R.CMS.threads_count/3)
    end

    timestamp_fields()
  end

  object :category do
    field(:id, :id)
    field(:title, :string)
    field(:slug, :string)
    field(:index, :integer)
    field(:author, :user, resolve: dataloader(CMS, :author))
    field(:communities, list_of(:community), resolve: dataloader(CMS, :communities))

    timestamp_fields()
  end

  object :article_tag do
    field(:id, :id)
    field(:title, :string)
    field(:desc, :string)
    field(:layout, :string)
    field(:slug, :string)
    field(:color, :string)
    field(:thread, :string)
    field(:group, :string)
    field(:extra, list_of(:string))
    field(:icon, :string)
    field(:index, :integer)

    field(:author, :user, resolve: dataloader(CMS, :author))
    field(:community, :community, resolve: dataloader(CMS, :community))

    timestamp_fields()
  end

  object :comment_emotions do
    emotion_fields(:comment)
  end

  object :article_emotions do
    emotion_fields()
  end

  object :comment_meta do
    field(:is_article_author_upvoted, :boolean)
    field(:is_reply_to_others, :boolean)

    # audit states
    field(:is_legal, :boolean)
    field(:illegal_reason, list_of(:string))
    field(:illegal_words, list_of(:string))
    # field(:report_count, :boolean)
    # field(:is_solution, :boolean)
  end

  object :comment_reply do
    comment_general_fields()
  end

  object :comment do
    comment_general_fields()

    field(:replies, list_of(:comment_reply))
    field(:article, :common_article)

    field(:is_for_question, :boolean)
    field(:is_solution, :boolean)
  end

  object :comments_list_state do
    field(:total_count, :integer)
    field(:participants_count, :integer)
    field(:participants, list_of(:common_user))
    field(:is_viewer_joined, :boolean)
  end

  ####### reports
  object :abuse_report_case do
    field(:reason, :string)
    field(:attr, :string)
    field(:user, :common_user)
  end

  object :abuse_report do
    field(:id, :id)
    field(:article, :common_article)
    field(:comment, :common_comment)
    field(:account, :common_user)
    field(:report_cases_count, :integer)
    field(:deal_with, :string)
    field(:operate_user, :user)
    field(:report_cases, list_of(:abuse_report_case))

    timestamp_fields()
  end

  object :citing do
    field(:id, :id)
    field(:thread, :string)
    field(:title, :string)
    field(:block_linker, list_of(:string))
    field(:comment_id, :id)
    field(:user, :common_user)

    timestamp_fields()
  end

  object :blog_feed do
    field(:title, :string)
    field(:digest, :string)
    field(:link_addr, :string)
    field(:content, :string)
    field(:published, :string)
    field(:updated, :string)
  end

  object :blog_author do
    field(:name, :string)
    field(:intro, :string)
    field(:github, :string)
    field(:twitter, :string)
  end

  paged_article_objects()

  object :grouped_posts do
    field(:todo, :paged_posts)
    field(:wip, :paged_posts)
    field(:done, :paged_posts)
  end

  object :paged_reports do
    field(:entries, list_of(:abuse_report))
    pagination_fields()
  end

  object :paged_citings do
    field(:entries, list_of(:citing))
    pagination_fields()
  end

  object :paged_categories do
    field(:entries, list_of(:category))
    pagination_fields()
  end

  object :paged_comments do
    field(:entries, list_of(:comment))
    pagination_fields()
  end

  object :paged_comment_replies do
    field(:entries, list_of(:comment_reply))
    pagination_fields()
  end

  object :paged_communities do
    field(:entries, list_of(:community))
    pagination_fields()
  end

  object :paged_article_tags do
    field(:entries, list_of(:article_tag))
    pagination_fields()
  end

  object :paged_threads do
    field(:entries, list_of(:thread_item))
    pagination_fields()
  end

  object :paged_articles do
    field(:entries, list_of(:common_article))
    pagination_fields()
  end

  @desc "article meta info"
  object :article_meta do
    field(:thread, :string)
    field(:is_edited, :boolean)
    field(:is_comment_locked, :boolean)
    field(:last_active_at, :datetime)
    field(:citing_count, :integer)
    field(:latest_upvoted_users, list_of(:common_user))
    # audit states
    field(:is_legal, :boolean)
    field(:illegal_reason, list_of(:string))
    field(:illegal_words, list_of(:string))
  end

  object :community_meta do
    threads_count_fields()
    field(:apply_msg, :string)
    field(:apply_category, :string)
  end

  # dashboard types

  ## seo info
  object :dashboard_seo do
    field(:og_title, :string)
    field(:og_description, :string)
  end
end
