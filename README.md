## Description
debugger2 is a fork of debugger for Ruby 2.0.

It only use only external C-APIs. Not of Ruby core sources.

(and debugger is a fork of ruby-debug(19) that works on 1.9.2 and 1.9.3 and installs easily for rvm/rbenv rubies :)

I want to merge original debugger if it has no problem. So debugger2 may be obsolete.

## Install

    TODO: xxx

## Supported Rubies

Ruby 2.0.0 or later.

## Usage

Wherever you need a debugger, simply:

```ruby
require 'debugger'; debugger
```

To use with bundler, drop in your Gemfile:

    gem 'debugger2'

### Configuration

At initialization time, debugger loads config files, executing their lines
as if they were actual commands a user has typed. config files are loaded
from two locations:

* ~/.rdebugrc (~/rdebug.ini for windows)
* $PWD/.rdebugrc ($PWD/rdebug.ini for windows)

Here's a common configuration (yeah, I should make this the default):

    set autolist
    set autoeval
    set autoreload

To see debugger's current settings, use the `set` command.

### Using Commands

For a list of commands:

    (rdb: 1) help

Most commands are described in rdebug's man page

    $ gem install gem-man
    $ man rdebug

### More documentation

I forked this project from <https://github.com/cldwalker/debugger>.
Maybe it can work same as `debugger'.
However, now don't support `post-motem' mode and `threading'.

Please give us your feedback.

## Reason for Fork

Ruby 2.0.0 has debugger support API. No need to install internal headers.

## Issues
Please report them [on github](http://github.com/ko1/debugger2/issues).

## Credits

All ruby's debugger programmers.

## TODO

* Collect feedback.

