FROM alpine:latest AS unzipper
RUN apk update && apk add wget tmux unzip
RUN mkdir /data/
WORKDIR /data
ARG TERRARIA_VERSION=1449
RUN wget https://terraria.org/api/download/pc-dedicated-server/terraria-server-$TERRARIA_VERSION.zip -O terraria.zip
RUN unzip terraria.zip

FROM ubuntu:latest AS terraria
ARG TERRARIA_VERSION=1449
# Labels.
LABEL org.opencontainers.image.authors="maha90"
LABEL org.opencontainers.image.source="https://github.com/maha90/terraria"
LABEL org.opencontainers.image.version=$TERRARIA_VERSION
LABEL org.opencontainers.image.title="Terraria Server"

COPY --from=unzipper "/data/$TERRARIA_VERSION/Linux" /data/server
RUN mkdir /data/worlds
WORKDIR /data/server
RUN chmod +x TerrariaServer.bin.x86*
COPY ./entrypoint.sh /data/server/entrypoint.sh
RUN chmod +x entrypoint.sh
ENTRYPOINT ["./entrypoint.sh"]
