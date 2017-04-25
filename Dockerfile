FROM 522104923602.dkr.ecr.eu-west-1.amazonaws.com/sageone/ruby:2.3.1-alpine-3.4

RUN apk add --update --no-cache ruby-dev build-base

# Create application directory and set it as the WORKDIR.
ENV APP_HOME /dynamodb_framework
RUN mkdir -p $APP_HOME
WORKDIR $APP_HOME

COPY . $APP_HOME

RUN bundle install --system --binstubs

CMD ./container_loop.sh