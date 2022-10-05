# Building the iNaturalist WebApp

### Building the Base Image
```bash
docker build -t inaturalist_webapp_base/latest  -f DockerfileBase .
```

### Setting up iNaturalist on the Base Container
Note that as iNaturalist gets setup it also sets up the database and elasticsearch, so you'll need to set these things up concurrently.

```bash
docker run --name inaturalist_webapp_base_container -p 3000:3000 -it inaturalist_webapp_base/latest
```

(This'll take a five or so minutes)

#### Setting up the Database

Write the following to `config/database.yml`

```yaml
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

Export the following environment variables so you can connect to the database with `psql`:
```bash
export PGHOST=host.docker.internal
export PGUSER=username
export PGPASSWORD=password
```

Setup the database with:
```bash
ruby bin/setup
```

If you see some errors about things already existing, that's fine as the service already has some things setup.

```bash
== Creating Template Database ==
createdb: error: database creation failed: ERROR:  database "template_postgis" already exists
bin/setup:37:in `system': Command failed with exit 1: createdb (RuntimeError)
        from bin/setup:37:in `block in <main>'
        from /root/.rbenv/versions/3.0.4/lib/ruby/3.0.0/fileutils.rb:139:in `chdir'
        from /root/.rbenv/versions/3.0.4/lib/ruby/3.0.0/fileutils.rb:139:in `cd'
        from bin/setup:10:in `<main>'
```

Then using `psql` run the following:
```psql
CREATE database inaturalist_development; 
CREATE database inaturalist_test;
```

Back in `bash` execute the following to setup the schemas:
```bash
rake db:schema:load
```

#### Setting up ElasticSearch
Update `config/config.yml` to have
```yml
elasticsearch_host: http://host.docker.internal:9200
```

and

```yml
node_api_url: http://host.docker.internal:4000/v1
```

then run
```bash
rake es:rebuild
```

#### Setting up Node

```bash
nvm install 
npm install
npm run webpack 
```

#### Seeding the Site
```bash
rails r "Site.create( name: 'iNaturalist', url: 'http://localhost:3000' )"
rake inaturalist:generate_translations_js
```

You'll get lots of translation warning messages, but no need to worry.

#### Testing it Out

Run the following:
```bash
rails s -b 0.0.0.0
```
and then navigate to `http://localhost:3000` in your browser!

### Commit the Updated Container to an Image
```bash
docker commit inaturalist_webapp_base_container inaturalist_webapp_updated/latest
```