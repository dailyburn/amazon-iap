# Amazon::Iap

This gem is a simple implementation of the Amazon Receipt Verfication Service. It supports both V1 and V2 APIs.

[V1 spec](https://developer.amazon.com/sdk/in-app-purchasing/documentation/rvs.html)

[V2 spec](https://developer.amazon.com/public/apis/earn/in-app-purchasing/docs-v2/verifying-receipts-in-iap-2.0)

## Installation

Add this line to your application's Gemfile:

    gem 'amazon-iap'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install amazon-iap

## Usage

**NOTE:** Amazon does not deploy a sandbox environment for testing purposes.  Rather,
they give you access to a deployable WAR file.  You can use this WAR file to easily deploy your
own sandbox environment on Heroku.  See [here](https://devcenter.heroku.com/articles/war-deployment#command-line)
for more details.

Initialize a client, passing in the developer secret and (optionally) the host.  If a host is not
passed, it will use Amazon's production endpoint.

```ruby
client = Amazon::Iap::Client.new 'my_developer_secret', 'http://iap-staging.domain.com' # staging server
client = Amazon::Iap::Client.new 'my_developer_secret' # production server
```

From there, you can call either `verify_v1` or `verify_v2` on the client and pass in the user id and purchase token:

```ruby
result = client.verify_v1 'some-user-id', 'some-purchase-token'
result = client.verify_v2 'some-user-id', 'some-purchase-token'
```
Both methods will return the same fields in the same place, while the v2 one will supply some additional data. Mapping is done internally to provide a uniform interface between versions.

For compatibility purposes, the `verify` method is an alias for `verify_v1`.

By default, the `verify_v1` method will automatically try to renew expired tokens, and will recall `verify_v1`
against the new token returned.  If you do not want this behavior, simply pass in `false` as the third
attribute to the `verify` method:

```ruby
result = client.verify_v1 'some-user-id', 'some-purchase-token', false
```

You can also manually renew a token with

```ruby
result = client.renew 'some-user-id', 'some-purchase-token'
```

## Returned Values

An instance of Amazon::Iap::Result is returned from both methods, the attributes being the underscored versions
of the hash keys returned in the JSON object.  For convenience, we also add `start_time` and `end_time` attributes
which are `Time` representations of the milliseconds returned in `start_date` and `end_date` respectively.  E.g.,

```ruby
result = client.verify_v2 'some-user-id', 'some-purchase-token'

result.class.name     # "Amazon::Iap::Result"
result.item_type      # "SUBSCRIPTION"
result.sku            # "some-sku"
result.start_date     # 1378751554943
result.start_time     # 2013-09-09 14:32:34 -0400 
result.end_date       # nil
result.end_time       # nil
result.purchase_token # "some-purchase-token"
```

<!-- -->

```ruby
result = client.renew 'some-user-id', 'some-purchase-token'

result.class.name     # "Amazon::Iap::Result"
result.purchase_token # "some-new-purchase-token"
```

## Exception Handling

Any non-200 status code will raise an exception.  For convenience in internal controls, each status code raises
a distinct exception.  Take a look at the [Amazon::Iap::Result class](lib/amazon/iap/result.rb) for specifics.

Example exception handling:

```ruby
begin
  result = client.verify 'some-user-id', 'some-purchase-token'
rescue Amazon::Iap::Exceptions::InternalError => e
  # enqueue to try again later
end
```

For convenience, all exceptions inherit from `Amazon::Iap::Exceptions::Exception` so you can rescue from
any exception (or as a default):

```ruby
begin
  result = client.verify 'some-user-id', 'some-purchase-token'
rescue Amazon::Iap::Exceptions::InternalError => e
  # enqueue to try again later
rescue Amazon::Iap::Exceptions::Exception => e
  # log the exception
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b some-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin some-new-feature`)
5. Create new Pull Request
