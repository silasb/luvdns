# LuvDNS

Easy way to update your PowerDNS records via Git and a Sinatra server.

### This will delete all PowerDNS records when you sync

# Description

PowerDNS has this cool feature that allows you to host your DNS domains and
records in a SQL (any many other) datastores.

My idea is that I would rather work with my CLI tools and have revision control
on my DNS records than logging into a web interface and changing my records.

The essential idea is that you will be hosting an simple Sinatra application
that will be talking to the PowerDNS database.  There is a Github repo that has
a post-commit hooking point to an web server.

When you update your `domains` repo and push to `github` the post-commit hook
on `github` will send a HTTP request to our server. The application will
download a recent copy of the `domains` repo and then run a the `luvdns` utility
If it finds a zone file the `luvdns` binary will send a HTTP POST request to 
server to update the PowerDNS records.

Soon after the database records have changed PowerDNS will become aware and
start serving those out.

# Prereqs

Have a recent version of Ruby installed ( >= 1.9.3 ).
Have a recent version of LuaJIT installed.
Have a Github repo that holds your domains with a post commit hook point to the
new application.

# Zone format

The format that I have is based on ideas from `luadns`.

# Setup

First I'm going to assume you are a savvy person if you are running your own
DNS.

Two methods to deploying that I find really easy.  First deploy to Heroku, this
would mean that you host your PowerDNS database on Heroku which might add some
latency for each record requested, you might be able to get around this with
some caching methods in PowerDNS config.  The second method is via hosting it
on your own server, which is what I do.

Use my domains repo as an example.

http://github.com/silasb/domains

First is to get the server installed on a public facing internet machine.
I typically use `rbenv` and `ruby-build` to setup everything on the server.

    git clone https://github.com/silas/luvdns.git

    cd luvdns

    bundle

After you have setup Ruby site, now you need to setup the Lua side.  This is
a little more difficult.

Dependences you need for Lua are:

* lua-filesystem (lfs)
* lua-socket
* lua-lib
* lua-find-bin

Find these and stick them into a `LUA_PATH` that you have access to.
`luarocks` will likely help you with this.

Change the settings (`config/settings.yml`) to point to your PowerDNS database.

    `bundle exec foreman start`

Look at the testing section to see how you can simulate Github sending a post
commit hook, or even just to populate the initial database.

For deploying
For production you will want to either deploy to Heroku or create an `.env`
file in the application directory:

    RACK_ENV=production

Then setup a proxy server to forward requests to your application.


# Security

We only allow `127.0.0.1` on `/update`

# TODO

Security, make sure you only accept requests on `/` from Github (or maybe not)

# Testing

Testing the post commit hook from Github.  Note this is only a subset of what
Github will send when it sends it's payload.

curl -d 'payload={"repository": {"url": "https://github.com/silasb/domains.git", "name": "domains"}}' -i -X POST "http://localhost:9292/post-commit-hook"

