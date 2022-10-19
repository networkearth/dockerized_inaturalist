# Building iNaturalist as a Service

## Building the iNaturalist WebApp

### Building the Base Image
```bash
docker build -t inaturalist_webapp_base/latest -f DockerfileBase .
```

### Starting the Supporting Services
iNaturalist depends on a few other applications for which we'll be making images as well. To get the base images up and running for modification go to the `supporting` directory of `dockerized_inaturalist` and run the following:
```bash
docker-compose build --parallel es memcached redis pg
docker-compose up es memcached redis pg
```

(Note that you'll want these to be fresh so good idea to just run a `docker-compose rm` to check)

You'll need to wait until the services are up and running.

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
elasticsearch: http://host.docker.internal:4000
```

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
rails r tools/load_iconic_taxa.rb
```

You'll get lots of translation warning messages, but no need to worry.

#### Allowing Access to the API
Add the following to the end of `config/environments/development.rb`:
```bash
config.hosts << "host.docker.internal"
```

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

### Commit the Volumes
Most of what we just did to the supporting containers shows up in their respective data volumes. So if we're going to keep those around we need to tar those up and commit them to git. Specifically the volumes are in the `~/inaturalist_volumes` directory. So once you've shut down the services (so nothing's being updated while you tar things up) you can go ahead and run:

```bash
cd ~/
tar -czf inaturalist_volumes.tar.gz inaturalist_volumes
```

Then move the tar into this repository and commit it. 

### Updating the WebApp Image EntryPoint
We've got a container with everything in it, but now we need to build an image that will actuall start our app for us. From within the `webapp` directory of `dockerized_inaturalist` run:

```bash
docker build -t inaturalist_webapp/latest -f DockerfileFinal .
```

You can test the image with:

```bash
docker run -p 3000:3000 inaturalist_webapp/latest
```

## Building the iNaturalist API

### Building the Base Image
From within the `api` directory of `dockerized_inaturalist` run:

```bash
docker build -t inaturalist_api_base/latest -f DockerfileBase .
```

### Setting up the Config

Start up the base container with:

```bash
docker run --name inaturalist_api_base_container -p 4000:4000 -it inaturalist_api_base/latest
```

Update the hosts in `config.js` to point to `host.docker.internal` for all the services and the webapp. Also change the DB password to be `password` and user to be `username`.

### Setting up Node
```bash
nvm install
npm install
```

You can try it out by running:
```bash
node app.js
```

and then navigating to `http://localhost:4000` on your browser.

### Committing the Updated Image
```bash
docker commit inaturalist_api_base_container inaturalist_api_updated/latest
```

### Building the Final Image
```bash
docker build -t inaturalist_api/latest -f DockerfileFinal .
```

You can test the image with:

```bash
docker run -p 4000:4000 inaturalist_api/latest
```

## Pushing the Images to DockerHub

```bash
docker login
```


### Tag the Images
```bash
docker tag inaturalist_webapp/latest mgietzmann/inaturalist_webapp:latest
docker tag inaturalist_api/latest mgietzmann/inaturalist_api:latest
```

### Push the Images
```bash
docker push mgietzmann/inaturalist_webapp:latest
docker push mgietzmann/inaturalist_api:latest
```

## Building the Full Service
Now that we've built all the pieces we can go ahead and tie them together!

Move to `~/` place the `inaturalist_volumes.tar.gz` file there and run (making sure that `inaturalist_volumes` doesn't exist):
```bash
tar -xzvf inaturalist_volumes.tar.gz
```

This will recreate the volumes needed by the databases.

Going back to the `supporting` directory of `dockerized_inaturalist` run:

```bash
docker-compose build --parallel es memcached redis pg
docker-compose up es memcached redis pg
```

Now you can run the app with:
```bash
docker run -p 3000:3000 mgietzmann/inaturalist_webapp:latest
```

And the api with:
```bash
docker run -p 4000:4000 mgietzmann/inaturalist_api:latest
```

## Some Notes

```ruby
opts = {
    :login => 'quire',
    :email => 'quire@example.com',
    :password => 'quire69',
    :password_confirmation => 'quire69'
}
u = User.new(opts)
u.save
u
```

```bash
rails r my_file.rb
```


```ruby
opts = {
    :name => 'my_app',
    :redirect_uri => 'http://localhost:5000'
}
app = OauthApplication.new(opts)
app.save
app
```