# Lua-Neo4j

Unofficial library for communication with Neo4j database over bolt tcp protocol.

WIP

## What works

- Communication with db over bolt
- Packing and unpacking messages
- Actions: init, run, pull, discard, reset, begin, commit, rollback 

## What is missing

- Chunking messages for send
- SSL
- Tests coverage

## Requires

- [Lua](https://www.lua.org/manual/5.3/) >= 5.3
- [Luasocket](https://w3.impa.br/~diego/software/luasocket/)
- [Luasec](https://github.com/brunoos/luasec) - if you need SSL
- [Neo4j](https://neo4j.com/) >= 3
