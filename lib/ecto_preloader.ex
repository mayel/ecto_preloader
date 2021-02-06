defmodule Ecto.Preloader do
  @moduledoc """
  `Ecto.Preloader` is a module for preloading associations using joins.

  By default, Ecto preloads associations using a separate query for each association, which can degrade performance.

  You could make it run faster by using a combination of join/preload, but that requires a bit of boilerplate (see example below).

  With `Ecto.Preloader`, you can accomplish this with just one line of code.

  ## Example using just Ecto

  It requires calling `Query.join/4`, `Query.assoc/3` and `Query.preload/2`

  ```
  import Ecto.Query

  Invoice
  |> join(:left, [i], assoc(i, :customer), as: :customer)
  |> join(:left, [i], assoc(i, :lines), as: :lines)
  |> preload([lines: l, customers: c], lines: l, customer: c)
  |> Repo.all()
  ```

  ## Example using Ecto.Preloader

  Just one method call:

  ```
  import Ecto.Query
  import Ecto.Preloader

  Invoice
  |> preload_join(:customer)
  |> preload_join(:lines)
  |> Repo.all()
  ```

  """

  import Ecto, only: [assoc: 2]
  alias Ecto.Query.Builder.{Join, Preload}

  defmacro preload_join(query, association) do

    binding = quote do: [l]
    expr = quote do: assoc(l, unquote(association))

    preload_bindings = quote do: [{unquote(association), x}]
    preload_expr = quote do: [{unquote(association), x}]

    do_preload_join(query, association, binding, expr, preload_bindings, preload_expr, __CALLER__)
  end

  defmacro preload_join(query, via_association, association) do

    binding = quote do: [r, {unquote(via_association), l}]
    expr = quote do: assoc(l, unquote(association))

    preload_bindings = quote do: []
    preload_expr = quote do: [{unquote(via_association), unquote(association)}]

    do_preload_join(query, association, binding, expr, preload_bindings, preload_expr, __CALLER__)
  end

  defmacro preload_join(query, via_association_a, via_association_b, association) do

    binding = quote do: [r, {unquote(via_association_a), a}, {unquote(via_association_b), b}]
    expr = quote do: assoc(b, unquote(association))

    # TODO: use bindings to avoid extra queries for preloads
    preload_bindings = quote do: []
    preload_expr = quote do: [{unquote(via_association_a), [{unquote(via_association_b), [unquote(association)]}]}]

    do_preload_join(query, association, binding, expr, preload_bindings, preload_expr, __CALLER__)
  end

  defp do_preload_join(query, association, binding, expr, preload_bindings, preload_expr, caller) do

    query
    |> Join.build(:left, binding, expr, nil, nil, association, nil, nil, caller)
    |> elem(0)
    |> Preload.build(preload_bindings, preload_expr, caller)
  end
end
