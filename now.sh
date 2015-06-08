if -z "$PROD"
then
  URL="http://localhost:4567/put"
else
  URL="https://kleanoala.herokuapp.com/cleaners"
fi

curl -H "Content-Type: application/json" $URL
