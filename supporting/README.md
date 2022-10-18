# Building the Supporting Services

```bash
docker-compose build --parallel es memcached redis pg
docker-compose up es memcached redis pg
```