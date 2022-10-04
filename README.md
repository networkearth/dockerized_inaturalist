# dockerized_inaturalist

## Requirements
* Docker
* Docker Compose
* Git

## Instructions
Adapted from on the development setup instructions [here](https://github.com/inaturalist/inaturalist/wiki/Development-Setup-Guide)

### Build the Services
```bash
git clone https://github.com/inaturalist/inaturalist.git
cd inaturalist
make services
```

### Build and Run the Central Image
If you're not using visual studio:
```bash
docker build -t mgietzmann/inaturalist .
docker container run -it -p 3000:3000 mgietzmann/inaturalist /bin/bash
```

If you are using visual studio simply open inaturalist in a container and choose the docker file in this repo. You'll want to port forward port `3000`.

### Setting up iNaturalist Itself
If you're not using visual studio you'll need to first
```bash
cd /inaturalist
```
to get into the inaturalist repository.

#### Setting up the Postgres Database

##### Updating Login Information to Point at Postgresql Service
You'll need to set the default settings for `psql` login:
```
export PGHOST=host.docker.internal
export PGUSER=username
export PGPASSWORD=password
```
Next you'll need to update the login section of `config/database.yml` to look like:
```yml
login: &login
  host: host.docker.internal
  encoding: utf8
  adapter: postgis
  template: template_postgis
  username: username
  password: password

development:
  <<: *login
  database: inaturalist_development

test:
  <<: *login
  database: inaturalist_test

production:
  <<: *login
  database: inaturalist_production
```

##### Setting up the Database
```bash
ruby bin/setup
```
If you see some errors about things already existing, that's fine as the service already has some things setup.

#### Setting up Elasticsearch
Update `config/config.yml` to have
```yml
elasticsearch_host: http://host.docker.internal:9200
```
then run
```
rake es:rebuild
```
to set everything up.

#### Setting up Node
```bash
npm install
npm audit
npm run webpack 
```

#### Seed Data
```bash
rails r "Site.create( name: 'iNaturalist', url: 'http://localhost:3000' )"
rails r tools/load_sources.rb
rails r tools/load_iconic_taxa.rb
rake inaturalist:generate_translations_js
```

### Starting the Application
```bash
rails s -b 127.0.0.1
```

### Setting up iNaturalistAPI
From the base directory:
```bash
git clone https://github.com/inaturalist/iNaturalistAPI.git
cd iNaturalistAPI
git checkout no-maps
cp config_example.js config.js
```

Then 
- update the postgres user and password to reflect what's in the `database.yml` for the iNaturalist app
- update the hosts for redis and postgres to be `host.docker.internal`

```bash
npm install 
node app.js
```
