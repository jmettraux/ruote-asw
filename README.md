
# ruote-asw

A ruote storage implementation based on Amazon SWF (and Amazon S3).

The life impulse of each flow execution is provided by SWF while the ruote state is retained in S3.

(This project is still in an early stage, be patient)


## usage

TODO


### running the specs

Running with a memory store (instead of the default S3 store:

    $ RUOTE_ASW_STORE=mem bundle exec rspec

Set debug level to 1 for the http client (ht):

    $ RUOTE_ASW_DLEVEL=ht1 bundle exec rspec


## license

MIT, see LICENSE.txt


## links

* http://ruote.rubyforge.org/
* http://github.com/jmettraux/ruote-asw


## feedback

* mailing list: http://groups.google.com/group/openwferu-users
* issues: http://github.com/jmettraux/ruote-asw/issues
* irc: irc.freenode.net #ruote

