#!/bin/sh
# This script will bootstrap a laravel project
# TODO accept arguments for:
# TODO - Project name
# TODO - React or Vue
# TODO - Authenticate Bootstrap
# TODO - Git init
# TODO - silent
# TODO - config file
clear
echo "Bootstrapping Laravel Project"

# get laravel project name
echo "Name your laravel project"
read LARAVEL_NAME

# run laravel new
laravel new ${LARAVEL_NAME}
cd ${LARAVEL_NAME}

# swap preset
echo "vue, react or none (default: react)?"
read PRESET

case "$PRESET" in
   "react"|"")
        php artisan preset react
        ;;
   "vue")
        echo "vue already installed, skipping"
        ;;
   "none")
        php artisan preset none
        ;;
esac

# install all npm packages
npm install && npm run dev

# generate new key
php artisan key:generate

# bootstrap login system
echo "Auth scaffoling y or n (default: y)?"
read AUTH_ENABLED

case "$AUTH_ENABLED" in
   "y"|"")
        AUTH_ENABLED="y"
        php artisan make:auth
        ;;
   "n")
        echo "skipping auth scaffolding"
        ;;
esac

# only do register question if auth scaffolded
if [ $AUTH_ENABLED == "y" ]
then
    # Turn register page off
    echo "Disable Register y or n (default: y)?"
    read REGISTER_DISABLED

    case "$REGISTER_DISABLED" in
        "y"|"")
            sed -i "s/.*\$this->middleware('guest');.*/        \/\/This will disable register form for both auth and guest\n        \$this->middleware('auth');\n&/" ./app/Http/Controllers/Auth/RegisterController.php
            ;;
        "n")
            echo "register enabled"
            ;;
    esac
fi

# config Database
echo "InnoDB y or n (default: y)?"
read INNODB_CONFIG

case "$INNODB_CONFIG" in
   "y"|"")
        sed -i "/.*'mysql' => \[.*/,/.*'pgsql' => \[.*/s/.*'engine' => '',.*/            'engine' => 'InnoDB ROW_FORMAT=DYNAMIC',/" ./config/database.php
        ;;
   "n")
        echo "skipping innodb config"
        ;;
esac

# Tedit .env file
# TODO ask if want to rename app
sed -i "s/^APP_NAME=.*/APP_NAME=${LARAVEL_NAME}/" .env

# database settings
# TODO default db name
echo "What to name database?"
read $DB_NAME
sed -i "s/^DB_USERNAME=.*/DB_USERNAME=root/" .env
sed -i "s/^DB_DATABASE=.*/DB_DATABASE=${DB_NAME}/" .env

# TODO optionally create database

# TODO fix sass folder
cd resources/sass
mkdir pages/

# create welcome sass file
cat <<EOF >pages/welcome.scss
.content {
  text-align: center;
}

.title {
  font-size: 84px;
}

.links > a {
  color: #636b6f;
  padding: 0 25px;
  font-size: 12px;
  font-weight: 600;
  letter-spacing: .1rem;
  text-decoration: none;
  text-transform: uppercase;
}
EOF

# create helper sass
cat <<EOF >_helpers.scss
.full-height {
  height: calc(100vh - 73px);
}

.flex-center {
  align-items: center;
  display: flex;
  justify-content: center;
}

.position-ref {
  position: relative;
}

.marigin-bottom-md {
  margin-bottom: 30px;
}
EOF

# edit sass variables file
sed -i "s/.*\$body-bg: #f5f8fa;*/\$body-bg: #fff;/" _variables.scss
sed -i "s/.*\$font-family-sans-serif: \"Raleway\", sans-serif;.*/\$font-family-sans-serif: \"Lato\", sans-serif;/" _variables.scss

# TODO edit app sass file

cd -

# TODO fix blade files
cd resources/views

rm welcome.blade.php

cat <<EOF >welcome.blade.php
@extends('layouts.app')

@section('content')
    <div class="flex-center position-ref full-height">
        <div class="content">
            <div class="title marigin-bottom-md">
                {{ config('app.name', 'Laravel') }}
            </div>

            <div class="links">
                <a href="https://laravel.com/docs">Documentation</a>
                <a href="https://laracasts.com">Laracasts</a>
                <a href="https://laravel-news.com">News</a>
                <a href="https://forge.laravel.com">Forge</a>
                <a href="https://github.com/laravel/laravel">GitHub</a>
            </div>
        </div>
    </div>
@endsection
EOF

cd -

# run npm dev
npm run dev

# TODO add to gitignore
#/public/css/app.css
#/public/js/app.js

# TODO commit and push