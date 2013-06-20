# splot

## Well, what do we have here?
splot is a dumb and loose blogging system. It'd make a cracking coquette, alas she aint. She be a bunch of scripts and a cron line that stick content on a few web pages from out of plain text files. The idea is that rather than having a GUI interface and a database we just have a bunch of loose files, so we've all the power of Linux/userspace to connect the dots. The framework is small, hackable and some might say (including myself) silly. It is nothing to write home about.

## What do I need?
 * ruby
 * sinatra (gem)
 * memcached
 * dalli (gem)
 * github-markdown (gem)

## How does it work?
splot is made up of three pieces: the Splot class (Splot.rb), the frontend (web.rb) and one cron job.

### Tell me about the Splot class...
The Splot class is the interface that sits between the filesystem, memcached and the scripts. It effectively dredges articles out of the filesystem (every user's ~/splot dir) and dumps where to find them and how old they are in the cache. This is done in the Splot.populate instance method, which is called every minute by cron. Wow... We can peel articles out of the cache with the Splot.next instance method. This pulls the file from disk and sticks it in the cache and then renders it with github-markdown.

### Frontend, is that like a y'know... front-end? X3 C==8
LOL, no. It's a Sinatra based web app that has a couple of routes, that parse the hashes pumped out by the Splot.next instance method.

### cron?
Unix-speak for 'scheduled shit' - I use the line:

`
	* * * * * ruby -r'~/code/ruby/splot/Splot.rb' -e'Splot.new.populate'
`

which just means 'call populate every fucking minute.'

## Who wrote this?
[This fine sailor.](http://twitter.com/tploe)
