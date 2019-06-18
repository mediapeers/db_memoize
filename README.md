[![Build Status](https://travis-ci.com/mediapeers/db_memoize.svg?branch=master)](https://travis-ci.com/mediapeers/db_memoize)

# db_memoize
A library to cache (memoize) return values of methods in the database.

**Note:** when updating from version 0.1 to 0.2 you need to run a migration on the existing table, see below.

## Usage in ActiveRecord models:

### Example Class:

```
class Letter < ActiveRecord::Base
  include DbMemoize::Model

  def hello(name = 'John')
    "Hello #{name}!"
  end
  db_memoize :hello

  def bye
   	'Best regards'
  end
  db_memoize :bye
end
```

### Get Values

```
record = Letter.first
record.hello
=> 'Hello John!'
record.hello
=> 'Hello John!'
```

will call the original method only once. Consecutive calls will return a cached value.

If the method takes arguments...

    record.hello('Maria')
    record.hello('John')

a cached value will be created for every set of arguments.

### Clear Values

To clear cached values for a single method

    record.unmemoize(:hello)

To clear all cached values of one record

    record.unmemoize

To clear cached values of given records for a single method

    Letter.unmemoize([letter1, letter2], :hello)

To clear all cached values of given records

    Letter.unmemoize([letter1, letter2])

Instead of ActiveRecord instances it's sufficient to pass in the ids of the records, too

    Letter.unmemoize([23,24])

### Gotchas

The cached values themselves are active records (of type `DbMemoize::Value`) and are saved in the database.
They are also registered as an association, so you can access all of the cached values of an object like this:

    record.memoized_values

This means you can also very easily perform eager loading on them:

    Letter.includes(:memoized_values).all

DbMemoize by default will write log output to STDOUT. You can change this by setting another logger like so:

    DbMemoize.logger = your_logger

### Rake Tasks

To _warmup_ your cache, you can pre-generate cached values via a rake task like this (only works for methods that do not take arguments):

    bundle exec rake db_memoize:warmup class=Letter methods=hello,bye

Similarly, you can wipe all cached values for a given class:

    bundle exec rake db_memoize:clear class=Letter

### Setup

To create the required DB tables add a migration like this:

```
class CreateMemoizedValues < ActiveRecord::Migration
  def up
    require 'db_memoize/migrations'
    DbMemoize::Migrations.create_tables(self)
  end

  def down
    drop_table :memoized_values
  end
end
```

### Testing

Note that db_memoize needs Postgres. To set up the database needed to run tests, this is what you can do:

```sh
~/your/path> sudo su postgresql
~/your/path> createuser >>yourusername<
~/your/path> createdb -O >>yourusername<< db_memoize_test
```


### Updating from earlier versions

It is generally impossible to update from earlier versions and keep the cached data.
DbMemoize should always be able to rerun migrations to update database structures to the latest
version - feel free to add in as many migrations as you like :)
