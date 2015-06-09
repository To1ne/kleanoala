# Kleanoala

Which Koala's turn is it to clean up all the mess?

## Installation

* Set the admin password:

        heroku config:set ADMIN_PASSWORD=the_password

* Add postgres add-on

        heroku addons:create heroku-postgresql:hobby-dev

## Setup

* Set the list of cleaners (see `put.sh`)


## Usage

* Just visit `/now` and it will return the current cleaner

