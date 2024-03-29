#!/bin/sh
# This script will bootstrap a laravel project
echo "Bootstrapping Laravel Project"

## Prompts
# get laravel project name
read -p "Name your laravel project: " LARAVEL_NAME

# get preset
read -p "vue, react or none (default: react)? " PRESET

# get Auth scaffolding option
read -p "Auth scaffolding y or n (default: y)? " AUTH_ENABLED

# only do register question if auth scaffolded
if [ "$AUTH_ENABLED" != "n" ]; then
    # Turn register page off
    read -p "Disable Register y or n (default: y)? " REGISTER_DISABLED
fi

# get Innodb option
read -p "InnoDB y or n (default: y)? " INNODB_CONFIG

# get database name
read -p "What to name database? " DB_NAME

## Processes
# run laravel new
laravel new ${LARAVEL_NAME}
cd ${LARAVEL_NAME}


# swap preset
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
case "$AUTH_ENABLED" in
   "y"|"")
        php artisan make:auth
        ;;
   "n")
        echo "skipping auth scaffolding"
        ;;
esac

# only do register question if auth scaffolded
if [ "$AUTH_ENABLED" != "n" ]; then
    # Turn register page off
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
case "$INNODB_CONFIG" in
   "y"|"")
        sed -i "/.*'mysql' => \[.*/,/.*'pgsql' => \[.*/s/.*'engine' =>.*/            'engine' => 'InnoDB ROW_FORMAT=DYNAMIC',/" ./config/database.php
        ;;
   "n")
        echo "skipping innodb config"
        ;;
esac

# Tedit .env file
sed -i "s/^APP_NAME=.*/APP_NAME=${LARAVEL_NAME}/" .env

# database settings
sed -i "s/^DB_USERNAME=.*/DB_USERNAME=root/" .env
sed -i "s/^DB_DATABASE=.*/DB_DATABASE=${DB_NAME}/" .env

# fix sass folder
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
sed -i "s/.*\$body-bg:.*/\$body-bg: #fff;/" _variables.scss
sed -i "s/.*\$font-family-sans-serif:.*/\$font-family-sans-serif: \"Lato\", sans-serif;/" _variables.scss

cd -

# fix blade files
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