defmodule GroupherServer.CMS.Constant do
  @moduledoc """
  constant used for CMS

  NOTE: DO NOT modify, unless you know what you are doing
  """

  @artiment_legal 0
  @artiment_illegal 1
  @artiment_audit_failed 2

  @community_normal 0
  @community_applying 1

  @apply_public "PUBLIC"

  def pending(:legal), do: @artiment_legal
  def pending(:illegal), do: @artiment_illegal
  def pending(:audit_failed), do: @artiment_audit_failed

  def pending(:normal), do: @community_normal
  def pending(:applying), do: @community_applying

  def apply_category(:public), do: @apply_public

  def article_cat do
    %{
      feature: 1,
      bug: 2,
      question: 3,
      other: 4
    }
  end

  def article_state do
    %{
      default: 1,
      todo: 2,
      wip: 3,
      done: 4,
      resolve: 5,
      reject_dup: 6,
      reject_no_plan: 7,
      reject_no_fix: 8,
      reject_repro: 9,
      reject_stale: 10
    }
  end
end
