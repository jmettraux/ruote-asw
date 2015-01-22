
# ruote-asw

A ruote storage implementation based on Amazon SWF (and Amazon S3).

The life impulse of each flow execution is provided by SWF while the ruote state is retained in S3.

(This project is still in an early stage, be patient)

(Update: this project is as dead as [ruote](http://ruote.io) is)


## usage

(supposes you're familiar with ruote's concepts)

Since SWF distinguishes between "decisions" (episodes of workflow execution) and "activities" (actual handout of work), ruote-asw specializes the ruote workers into Ruote::Asw::DecisionWorker and ::ActivityWorker.

To start a combo decision + activity worker:

```ruby
@dboard =
  Ruote::Dashboard.new(
    Ruote::Asw::DecisionWorker.new(
    Ruote::Asw::ActivityWorker.new(
      Ruote::Asw::Storage.new(
        aws_access_key_id, asw_secret_access_key, region, domain, {}))))
```

(same indentation for the decision and the activity worker, to indicate there is no dependence from one to the other)

Of course, one can start decision and activity workers in their own decicated Ruby processes. The initialization above is mostly a compact setup used for testing/spec'ing.

(to be continued)


### running the specs

Running with a memory store (instead of the default S3 store:

    $ RUOTE_ASW_STORE=mem bundle exec rspec

Set debug level to 1 for the http client (ht):

    $ RUOTE_ASW_DLEVEL=ht1 bundle exec rspec

Set debug level to 1 for the http client and 2 for the SWF client (sw)

    $ RUOTE_ASW_DLEVEL=ht1,sw2 bundle exec rspec

"ht" spans from 0 to 2, "sw" spans from 0 to 4.


## troubleshooting

### "RequestExpiredException"

Your computer's clock is way too out of sync. Resynchronize it (`sudo service ntp restart`).


## license

MIT, see LICENSE.txt


## links

* http://ruote.rubyforge.org/
* http://github.com/jmettraux/ruote-asw


## feedback

* mailing list: http://groups.google.com/group/openwferu-users
* issues: http://github.com/jmettraux/ruote-asw/issues
* irc: irc.freenode.net #ruote

