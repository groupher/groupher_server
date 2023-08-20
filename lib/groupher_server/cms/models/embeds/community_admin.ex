defmodule GroupherServer.CMS.Model.Embeds.CommunityAdmin do
  @moduledoc """
  general community meta
  """
  use Ecto.Schema
  use Accessible

  alias GroupherServer.Accounts.Model.User

  embedded_schema do
    embeds_one(:root, User, on_replace: :update)
    embeds_many(:moderators, User)
  end
end
