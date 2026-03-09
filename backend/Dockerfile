FROM dart:stable

WORKDIR /app

ENV PATH="/root/.pub-cache/bin:${PATH}"

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    openssh-client \
  && rm -rf /var/lib/apt/lists/* \
  && dart pub global activate dart_frog_cli

COPY pubspec.yaml pubspec.lock ./
RUN dart pub get

COPY . .

RUN dart_frog build

EXPOSE 8080

CMD ["dart", "run", "build/bin/server.dart"]
