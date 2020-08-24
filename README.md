# Elixir Janus Transport WS
This package implements transport behaviour from `Janus.Transport` module in [ Elixir Janus package ](https://github.com/software-mansion-labs/elixir-janus).
Transport is implemented via websockets.


**WARNING**

This package is experimental and is not released to hex.

## Adapters
Package has been designed to easily change and update websocket's client providers when needed.
Every client should have its own adapter module.
To create one please go see `Janus.Transport.WS.Adapter` module.

Adapter is compiled only when its client package is added along `elixir_janus_transport_ws` package inside `mix.exs` dependencies.
```elixir
# e.g
defp deps do
  [
    {:elixir_janus_transport_ws, "~> 0.1.0"},
    {:websockex, "~> 0.4.2"} # <- can be replaced with any other implemented adapter's client
  ]
end
```

Currently implemented adapters:
 - `Janus.Transport.WS.Adapters.WebSockex` - uses [WebSockex package](https://github.com/Azolo/websockex)


Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/elixir_janus_transport_ws](https://hexdocs.pm/elixir_janus_transport_ws).

