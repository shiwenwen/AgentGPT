#!/bin/bash
cd "$(dirname "$0")" || exit

is_valid_sk_key() {
  local api_key=$1
  local pattern="^sk-[a-zA-Z0-9]{48}$"
  [[ $api_key =~ $pattern ]] && return 0 || return 1
}

echo -n "Enter your OpenAI Key (eg: sk...) or press enter to continue with no key: "
read OPENAI_API_KEY

if is_valid_sk_key $OPENAI_API_KEY || [ -z "$OPENAI_API_KEY" ]; then
  echo "Valid API key"
else
  echo "Invalid API key. Please ensure that you have billing set up on your OpenAI account"
  exit
fi

echo -n "Enter next auth url or press enter to continue with http://localhost:3000: "
read NEXTAUTH_URL

if [ -z "$NEXTAUTH_URL" ]
then
  NEXTAUTH_URL="http://localhost:3000"
fi

echo -n "Enter email server: "
read EMAIL_SERVER

if [ -z "$EMAIL_SERVER" ]
then
  echo "Invalid email server"
  exit
fi

echo -n "Enter email from: "
read EMAIL_FROM

if [ -z "$EMAIL_FROM" ]
then
  echo "Invalid email from"
  exit
fi


NEXTAUTH_SECRET=$(openssl rand -base64 32)

ENV="NODE_ENV=development\n\
NEXTAUTH_SECRET=$NEXTAUTH_SECRET\n\
NEXTAUTH_URL=$NEXTAUTH_URL\n\
OPENAI_API_KEY=$OPENAI_API_KEY\n\
EMAIL_SERVER=$EMAIL_SERVER\n\
EMAIL_FROM=$EMAIL_FROM\n\
DATABASE_URL=file:../db/db.sqlite\n"

printf $ENV > .env

if [ "$1" = "--docker" ]; then
  printf $ENV > .env.docker
  source .env.docker
  docker build --build-arg NODE_ENV=$NODE_ENV -t agentgpt .
  docker run -d --name agentgpt -p 3000:3000 -v $(pwd)/db:/app/db agentgpt
elif [ "$1" = "--docker-compose" ]; then
  docker-compose up -d --remove-orphans
else
  printf $ENV > .env
  ./prisma/useSqlite.sh
  npm install
  npm run dev
fi
