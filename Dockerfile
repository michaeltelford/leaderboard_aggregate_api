FROM ruby:3.3.6-slim-bullseye

WORKDIR /app

RUN apt update
RUN apt install -y build-essential

COPY Gemfile ./
COPY Gemfile.lock ./

RUN bundle install --without development test

COPY . .

CMD ["sh", "-c", "bundle exec rackup -s Puma -p ${PORT}"]
