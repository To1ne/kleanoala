if -z "$PROD"
then
  URL="http://localhost:4567/put"
else
  URL="https://kleanoala.herokuapp.com/cleaners"
fi

curl -H "Content-Type: application/json" -X PUT -d '{"startdate":"2015/06/01","cleaners":["nate", "toon", "reprazent", "pjaspers", "soffe", "gregory", "bram", "lewis", "atog", "buwaro", "tomklaasen"]}' $URL -u admin:$ADMIN_PASSWORD
