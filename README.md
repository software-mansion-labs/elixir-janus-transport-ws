# Elixir Janus Transport WS
This package implements transport behaviour of `Janus.Transport` module from [ Elixir Janus package ](https://github.com/software-mansion-labs/elixir-janus).
Transport is implemented via websockets.

## Disclaimer
This package is experimental and is not yet released to hex.

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

## Copyright and License

Copyright 2020, [Software Mansion](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=elixir-janus-transport-ws)

[![Software Mansion](https://logo.swmansion.com/logo?color=white&variant=desktop&width=200&tag=elixir-janus-transport-ws)](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=elixir-janus-transport-ws)

Licensed under the [Apache License, Version 2.0](LICENSE)


