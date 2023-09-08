defmodule GroupherServer.Billing do
  @moduledoc false

  alias GroupherServer.Billing.Delegate.CRUD

  defdelegate create_record(user, attrs), to: CRUD
  defdelegate paged_records(user, filter), to: CRUD
  defdelegate update_record_state(record_id, state), to: CRUD
end
