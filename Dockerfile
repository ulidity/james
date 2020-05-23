FROM elixir:1.10
LABEL maintainer="yauheni@tsiarokhin.me"

ARG API_TOKEN
ENV JAMES_API_TOKEN=$API_TOKEN

ENV APPDIR=/app \
    APPNAME=james \
    MIX_ENV=prod

ADD . $APPDIR
WORKDIR $APPDIR

RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix deps.get
RUN mix compile
RUN mix release

ENTRYPOINT ["_build/prod/rel/james/bin/james", "start"]

EXPOSE 80
