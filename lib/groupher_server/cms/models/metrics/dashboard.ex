defmodule GroupherServer.CMS.Model.Metrics.Dashboard do
  @moduledoc """
  KTV(key, type, value(default)) for dashbaord macro/schema/type etc
  define once, we can get embed_schema fields/default_values/cast_values and GraphQL endpont arg ready

  only general key/value like string/boolean are supported
  int/array of type are not supported, cuz it's hard to leverage between GraphQL/Schama/Types ..
  those cases need to manually add
  """

  def macro_schema(:base_info) do
    [
      [:favicon, :string, ""],
      [:title, :string, ""],
      [:logo, :string, ""],
      [:homepage, :string, ""],
      [:city, :string, ""],
      [:techstack, :string, ""]
    ]
  end

  # note: write kanban_bg_colors rules by itsef
  def macro_schema(:layout) do
    # manually add this:
    # [:kanban_bg_colors, {:array, :string}, []],

    [
      [:primary_color, :string, ""],
      [:post_layout, :string, ""],
      [:kanban_layout, :string, ""],
      [:help_layout, :string, ""],
      [:help_faq_layout, :string, ""],
      [:avatar_layout, :string, ""],
      [:brand_layout, :string, ""],
      [:banner_layout, :string, ""],
      [:topbar_layout, :string, ""],
      [:topbar_bg, :string, ""],
      [:broadcast_layout, :string, ""],
      [:broadcast_bg, :string, ""],
      [:broadcast_enable, :boolean, false],
      [:broadcast_article_layout, :string, ""],
      [:broadcast_article_bg, :string, ""],
      [:broadcast_article_enable, :boolean, false],
      [:changelog_layout, :string, ""],
      [:footer_layout, :string, ""]
    ]
  end

  def macro_schema(:seo) do
    [
      [:og_site_name, :string, ""],
      [:og_title, :string, ""],
      [:og_description, :string, ""],
      [:og_url, :string, ""],
      [:og_image, :string, ""],
      [:og_locale, :string, ""],
      [:og_publisher, :string, ""],
      # twitter
      [:tw_title, :string, ""],
      [:tw_description, :string, ""],
      [:tw_url, :string, ""],
      [:tw_card, :string, ""],
      [:tw_site, :string, ""],
      [:tw_image, :string, ""],
      [:tw_image_width, :string, ""],
      [:tw_image_height, :string, ""]
    ]
  end
end
