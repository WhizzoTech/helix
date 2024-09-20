FROM lamho/centos7 AS build
ARG TARGET=x86_64-unknown-linux-gnu
ARG GIT_SSL_NO_VERIFY=true
ARG DEBIAN_FRONTEND=noninteractive

RUN yum update && \
    yum install centos-release-scl && \
    yum install devtoolset-8-gcc* && \
    scl enable devtoolset-8 bash && \
    sh -c "$(curl -sSLfk https://sh.rustup.rs)" -- -y --no-modify-path --target "$TARGET"

COPY src /app
WORKDIR /app

RUN mkdir -p /root/.cargo && \
    echo "[profile.release]" > /root/.cargo/config.toml && \
    echo "strip = true" >> /root/.cargo/config.toml && \
    /root/.cargo/bin/cargo run --package=helix-loader --bin=hx-loader && \
    /root/.cargo/bin/cargo build --release --locked --target "$TARGET" && \
    cp "target/$TARGET/release/hx" /usr/local/bin/hx && \
    rm -rf runtime/grammars/sources

FROM scratch
COPY --from=build /usr/local/bin/hx /hx
COPY --from=build /app/runtime /runtime
COPY --from=build /app/contrib/completion /contrib/completion
