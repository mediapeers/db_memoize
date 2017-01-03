# db_memoize
library to cache (memoize) method return values in database

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

```
record.hello('Maria')
record.hello('John')
```

a cached value will be created for every set of arguments.

### Clear Values

To clear cached values for a single method

```
record.unmemoize(:hello)
```

To clear all cached values of one record

```
record.unmemoize
```

To clear cached values of given records for a single method

```
Letter.unmemoize([letter1, letter2], :hello)
```

To clear all cached values of given records

```
Letter.unmemoize([letter1, letter2])
```

Instead of ActiveRecord instances it's sufficient to pass in the ids of the records, too

```
Letter.unmemoize([23,24])
```

### Gotchas

As the cached values themselves are writtten to the database, are ActiveRecord records (of type `DbMemoize::Value`) and are reqistered as an association you can access all of the cached values of an object like this:

```
record.memoized_values
```

This means you can also very easily perform eager loading on them:

```
Letter.includes(:memoized_values).all
```

DbMemoize by default will write log output to STDOUT. You can change this by setting another logger like so:

```
DbMemoize.logger = your_logger
```

To invalidate all cached keys easily you can specify a default custom key to be used internally like this:

```
DbMemoize.default_custom_key = 'e.g. latest git commit hash'
```

### Rake Tasks

To _warmup_ your cache you can pre-generate cached values via a rake task like this (only works for methods not depending on arguments)

```
bundle exec rake db_memoize:warmup class=Letter methods=hello,bye
```

Similarly you can wipe all cached values for a given class

```
bundle exec rake db_memoize:clear class=Letter
```


Have fun!



