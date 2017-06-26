# db_memoize
library to cache (memoize) method return values in database

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

If the method takes arguments..

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

As the cached values themselves are writtten to the database, are ActiveRecord records (of type `DbMemoize::Value`) and are reqistered as an association you can access all of the cached values of an object like this:

    record.memoized_values

This means you can also very easily perform eager loading on them:

    Letter.includes(:memoized_values).all

DbMemoize by default will write log output to STDOUT. You can change this by setting another logger like so:

    DbMemoize.logger = your_logger

### Rake Tasks

To _warmup_ your cache you can pre-generate cached values via a rake task like this (only works for methods not depending on arguments)

    bundle exec rake db_memoize:warmup class=Letter methods=hello,bye

Similarly you can wipe all cached values for a given class

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

    # sudo su postgresql
    # createuser >>yourusername<<
    # createdb -O >>yourusername<< db_memoize_test


### Updating fropm 0.1 -> 0.2

You need to run a migration, like the following: 

```
class FixDbMemoizeTable < ActiveRecord::Migration
  def up
    execute <<-SQL
    ALTER TABLE memoized_values
      ALTER COLUMN entity_table_name SET NOT NULL,
      ALTER COLUMN entity_id SET NOT NULL,
      ALTER COLUMN method_name SET NOT NULL,
      ALTER COLUMN created_at SET NOT NULL;

      DROP INDEX index_memoized_values_on_entity_table_name_and_entity_id;

      CREATE INDEX memoized_attributes_idx ON memoized_values USING btree (((arguments_hash IS NULL)))
    SQL
  end

  def down
    execute <<-SQL
      DROP INDEX memoized_attributes_idx
    SQL
  end
end
```

Have fun!



