# IMPORTANT

These are test Certificates and Keys only!

Do NOT use them outside of a closed development environment.

DO NOT commit them to the git repository.

## Generating new certificates

A helper script exists at the project root and takes a list of names for the certificate.

For example:

```
./createcerts.sh webserver webserver.container.docker.internal
```

Each argument is used as a subject alternative name for the certificate.
