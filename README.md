# Has-Meta

A key/value store solution for Rails apps with bloated tables

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'has-meta'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install has-meta
    
Then, install migrations: 

```ruby
rake has_meta_engine:install:migrations
```

Finally, review the migrations and migrate:

```ruby
rails db:migrate
```

## Usage

### Declaring Meta Attributes

Suppose we have a model `Part` and only a minority of our parts records have the attribute `catalog_number` populated.  We want to move `catalog_number` to our key/value store.

To create a new meta attribute on an Active Record model, add this line to your model:

```ruby
has_meta :catalog_number
```

Or specify multiple meta attributes on the model:

```ruby
has_meta :catalog_number, :other_attribute
```

You may also choose to migrate existing data from a table:

    $ rake "has_meta_engine:data_mover[parts, catalog_number, integer, catalog_number]"
    
Once that data is moved generate a migration to remove the column and run the migration:

    $ rake generate migration RevmoveCatalogNumberFromParts catalog_number:integer
    $ rake db:migrate
    
And finally, declare the meta attribute in the model

```ruby
has_meta :catalog_number
```

### Getting and Setting Meta Attributes

Now, we can use normal getters and setters to access the attribute:

```ruby
new_part = Part.create name: 'Fancy new part'  
new_part.catalog_number = 12345  
new_part.save

new_part.catalog_number  
# => 12345
```

You can update the attribute any way you would with other attributes managed by Active Record:

```ruby
new_part.update catalog_number: 67890  
new_part.catalog_number # => 67890  

new_part.attributes = {catalog_number: 12345}  
new_part.catalog_number # => 12345  
```

**NB**: _Declaring a meta attribute on a model creates a polymorphic relationship between the model and the MetaData model. Therefore, the parent model must be saved before assigning meta attributes._

Meta attributes may also represent an Active Record model. Perhaps some of our parts may conform to a uniform standard represented by class `Standard`.  Just declare the meta attribute `:standard` and `has-meta` will treat the meta attribute as a one-to-one relation if the attribute corresponds to an Active Record model in your app.

```ruby
has_meta :catalog_number, :standard
```

Now you can get or set the attribute using either object or the object id as you would with any other attribute:

```ruby
new_standard = Standard.create name: 'Some great standard'  
new_part.standard = new_standard  
new_part.standard # => #<Standard id: 1, name: "Some great standard">  
new_part.standard_id # => 1  

newer_standard = Standard.create name 'An even better standard'  
new_part.standard.id = newer_standard.id  
new_part.standard # => #<Standard id: 2, name: "An even better standard">  
new_part.standard_id # => 2  
```

### Finding by meta attributes

`find_by_attribute_name` methods are provided for meta attributes.  For attributes representing an Active Record model, use `find_by_attribute_id`:

```ruby
Part.find_by_catalog_number 12345  
# => #<Part id: 1, name: "Fancy new part">
    
Part.find_by_standard_id 2  
# => #<Part id: 1, name: "Fancy new part">
```

You may also use `with_meta` method to return a scope of parts with correspoding meta attribute values:

```ruby
another_part = Part.create name: 'Another fancy new part'
another_part.update standard: new_standard

Part.with_meta standard: new_standard
# => #<ActiveRecord::Relation [#<Part id: 1, name: "Fancy new part">, 
    #<Part id: 2, name: "Another fancy new part">]>
```

`with_meta` accepts the `any: true` option to match any condition provided:

```ruby
yet_another_part = Part.create name: 'Yet another fancy new part'
yet_another_part.update catalog_number: 12345


Part.with_meta({standard: new_standard, catalog_number: 12345}, any: true)
# => #<ActiveRecord::Relation [#<Part id: 1, name: "Fancy new part">, 
  #<Part id: 2, name: "Another fancy new part">, 
  #<Part id: 3, name: "Yet another fancy new part">]>
```

Calling `excluding_meta` will return all records not meeting the criteria:

```ruby
Part.excluding_meta catalog_number: 12345
# => #<ActiveRecord::Relation [#<Part id: 2, name: "Another fancy new part">]>
```
  
## TODO/Known Issues
`has-meta` was developed for Active Record 4.2+ and MySQL 5.5.  PRs for supporting earlier versions of Active Record and/or PostgreSQL are welcome!

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/protrainings/has-meta.

## License

Has-Meta is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## About ProTrainings
Has-Meta was written by [Dan Drust](https://www.github.com/dandrust).  It is maintained and funded by Protrainings, LLC. Has-Meta, names, and logos are copyright ProTrainings, LLC. 


