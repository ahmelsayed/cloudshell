FROM golang:1.20-alpine AS backend

WORKDIR /go/src/cloudshell

COPY . .
RUN CGO_ENABLED=0 && \
    VERSION_INFO=dev-build && \
    apk add --no-cache make git && \
    # git clone --depth=1 https://github.com/ahmelsayed/cloudshell . && \
    go mod vendor && \
    go build -a -v -ldflags "-s -w -extldflags 'static' -X main.VersionInfo='${VERSION_INFO}'" \
        -o ./bin/cloudshell ./cmd/cloudshell

FROM node:20.0.0-alpine AS frontend

WORKDIR /app
COPY . .
RUN apk add --no-cache git && \
    # git clone --depth=1 https://github.com/ahmelsayed/cloudshell . && \
    npm install

FROM alpine AS final

WORKDIR /app
RUN apk update && \
    apk add --no-cache bash ncurses zsh git vim zsh-autosuggestions zsh-syntax-highlighting bind-tools curl && \
    rm -rf /var/cache/apk/*

COPY --from=backend /go/src/cloudshell/bin/cloudshell /app/cloudshell
COPY --from=frontend /app/node_modules /app/node_modules
COPY --from=frontend /app/public /app/public

RUN ln -s /app/cloudshell /usr/bin/cloudshell

RUN adduser -D -u 1000 user && \
    mkdir -p /home/user && \
    chown user:user /app -R

WORKDIR /
ENV WORKDIR=/app \
    TERM=xterm-256color

RUN sh -c "$(wget https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)" && \
    echo "source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ~/.zshrc && \
    echo "source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" >> ~/.zshrc

CMD ["--command", "/bin/zsh", "--log-level", "info"]
ENTRYPOINT ["/app/cloudshell"]
