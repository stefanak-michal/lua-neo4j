# Lua-Neo4j

Unofficial library for communication with Neo4j database over bolt tcp protocol.

## Usage

```lua
local bolt = require('bolt')
bolt.init({scheme = 'basic', principal = 'neo4j', credentials = 'neo4j'})
local result, err = bolt.query('RETURN 1 as num, $str as str', {str = 'Hello'})
```

_Check test.lua for more examples._

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

### Table - List and Dictionary

Neo4j support two array data types which are not available in Lua. Lua has only **table** type. You have to specify type with key **neotype** in your table. Available types are **list**, **dictionary** and Neo4j [structures](https://github.com/stefanak-michal/lua-neo4j/blob/master/src/structures.lua).

```lua
local result, err = bolt.query('RETURN $list AS list', {
  ['list'] = {['neotype'] = 'list', 34, 65}
})
-- OR
local result, err = bolt.query('RETURN $dict AS dict', {
  ['dict'] = {['neotype'] = 'dictionary', ['one'] = 1, ['two'] = 2}
})
```

## What is missing

- Tests coverage

## Requires

- [Lua](https://www.lua.org/manual/5.3/) >= 5.3
- [Luasocket](https://w3.impa.br/~diego/software/luasocket/)
- [Luasec](https://github.com/brunoos/luasec) - if you need SSL
- [Neo4j](https://neo4j.com/) >= 3
