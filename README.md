# Lua-Neo4j

Unofficial library for communication with Neo4j database over bolt tcp protocol.

[![Tests with a database](https://github.com/stefanak-michal/lua-neo4j/actions/workflows/main.yml/badge.svg?branch=master)](https://github.com/stefanak-michal/lua-neo4j/actions/workflows/main.yml)
![](https://img.shields.io/github/stars/stefanak-michal/lua-neo4j) 
![](https://img.shields.io/github/v/release/stefanak-michal/lua-neo4j) 
![](https://img.shields.io/github/commits-since/stefanak-michal/lua-neo4j/latest)

## Install

Download this repository and use source code from **src**.

Or you can install it from https://luarocks.org/modules/stefanak-michal/bolt

```
luarocks install bolt
```

## Usage

```lua
local bolt = require('bolt')
bolt.init({scheme = 'basic', principal = 'neo4j', credentials = 'neo4j'})
local result, err = bolt.query('RETURN 1 as num, $str as str', {str = 'Hello'})
```

### Aura

```lua
local bolt = require('bolt')
bolt.setHost('abcxyz.databases.neo4j.io') -- without neo4j+s://
bolt.setSSL({mode = 'client', protocol = 'any', verify = 'none', dane = true})
bolt.init({scheme = 'basic', principal = 'neo4j', credentials = 'password'})
local result, err = bolt.query('RETURN 1 as num, $str as str', {str = 'Hello'})
```

_More options for Luasec (setSSL) described [here](https://github.com/brunoos/luasec/wiki/LuaSec-1.0.x#ssl_newcontext)._

## Methods

| Name | Description | Arguments |
|:---:|:---:|:---:|
| setHost | Set hostname for connection. | string ip = 127.0.0.1 |
| setPort | Set port for connection. | int port = 7687 |
| setSSL | set configuration for secure connection. | table params = nil |
| setVersions | Set requested bolt versions. | number/string ... = 4.4, 4.3 |
| | | |
| init | Connect to database with credentials. | table auth [info](https://7687.org/bolt/bolt-protocol-message-specification-4.html#request-message---44---hello) |
| query | Execute query and get records with associated keys. Shortcut for run and pull. | string cypher, table params, table extra |
| run | Execute query and get meta informations. | string cypher, table params, table extra |
| pull | Pull records from last run. Last record is meta informations. | table extra = {n = -1} |
| discard | Discard records from last run. | table extra = {n = -1} |
| begin | Begin transaction. | table extra = {} |
| commit | Commit transaction. | |
| rollback | Rollback transaction. | |
| reset | Reset connection to initial state. | |
| route | Send route message. | table routing, table bookmarks, string db |

_Check official [documentation](https://7687.org/bolt/bolt-protocol-message-specification-4.html) for more informations._

### Specific Neo4j types

Neo4j support two array data types which are not available in Lua. Lua has only **table** type. You have to specify type with key **neotype** in your table. You can use helper functions to add it. Available types are **list**, **dictionary** and Neo4j [structures](https://github.com/stefanak-michal/lua-neo4j/blob/master/src/structures.lua). Response doesn't contains neotype key for list and dictionary.

```lua
-- List
local result, err = bolt.query('RETURN $list AS list', {
  ['list'] = bolt.list({34, 65})
})
-- Dictionary
local result, err = bolt.query('RETURN $dict AS dict', {
  ['dict'] = bolt.dictionary({['one'] = 1, ['two'] = 2})
})
```

Another issue is with **nil** while Neo4j has **null** type. If you set nil into table value in Lua, key is removed from table while Neo4j expects key _(in query parameters)_ even with null value. If you are looking how to set null we introduce to you another specific type. You can use helper function to generate it.

```lua
local result, err = bolt.query('RETURN $n AS n', {
  ['n'] = bolt.null()
})

-- Response from server is not decoded into table with neotype, because Lua can handle missing key as nil.
-- result: {1 = {}}
```

## Requires

- [Lua](https://www.lua.org/manual/5.3/) >= 5.3
- [Luasocket](https://w3.impa.br/~diego/software/luasocket/)
- [Luasec](https://github.com/brunoos/luasec) - if you need SSL
- [Neo4j](https://neo4j.com/) >= 3
