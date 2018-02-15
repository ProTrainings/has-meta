###0.9.0
* Add support for storing datetimes
* Return duck-typed values (strings to dates and times)
* Allow manually setting data type via `:as` option: `#meta_set :key, value, as: :type`

###0.9.1
* Don't try to set meta attributes until parent object is persisted
* Update meta_set! method to accept options hash

###0.9.2
* Force out of range integers to be stored as text based on integer column limit
