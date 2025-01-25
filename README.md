# Jaiminho

<p style="float:right" ><img src="https://media1.tenor.com/m/nnP-RFH4OOsAAAAd/televisa-distrito-comedia.gif" height="140" alt="jaiminho" /></p>

Jaiminho is a parcel management API designed to handle the logistics of parcel tracking, from creation to delivery. It supports key features such as parcel state transitions (e.g., shipped, delivered), movement tracking across locations, and validation to ensure data consistency and integrity.

## Features

- Create and manage parcels with descriptions, source, and destination locations.
- Track parcel movements between locations, including support for complex paths.
- Monitor parcel states, including whether they are shipped or delivered.

## Prerequisites

The application requires:
- Erlang/OTP 1.18.1
- Elixir 27.2
- PostgreSQL 15.2

The application uses `asdf` for version management. Make sure you have `asdf` installed and run:

```bash
asdf install
```

## Running the Application

To start the server:

```bash
# Start the Phoenix server
mix phx.server

# Or run it inside IEx (Interactive Elixir)
iex -S mix phx.server
```

The server will be available at [`localhost:4000`](http://localhost:4000).