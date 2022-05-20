FROM elixir:1.13.4-alpine
WORKDIR /chat_server
COPY . .
RUN mix compile
CMD ["mix", "run", "--no-halt"]