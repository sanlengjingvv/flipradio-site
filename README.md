# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...


`export PGGSSENCMODE=disable`
A workaround for crash on MacOS
>objc[81924]: +[__NSPlaceholderDictionary initialize] may have been in progress in another thread when fork() was called.
objc[81924]: +[__NSPlaceholderDictionary initialize] may have been in progress in another thread when fork() was called. We cannot safely call it or ignore it in the fork() child process. Crashing instead. Set a breakpoint on objc_initializeAfterForkError to debug.

```bash
# Install postgresql extentsions
pig repo add all -ru
pig ext add pg_search
pig ext add zhparser
pig ext add vchord_bm25
pig ext add pgvector
pig ext add vchord

\c flipradio_production
CREATE EXTENSION pg_search;
CREATE EXTENSION zhparser;
CREATE TEXT SEARCH CONFIGURATION testzhcfg (PARSER = zhparser);
ALTER TEXT SEARCH CONFIGURATION testzhcfg ADD MAPPING FOR n,v,a,i,e,l WITH simple;
update flip_items set zhparser_token = (SELECT ARRAY_AGG(token) FROM ts_parse('zhparser', content));
CREATE INDEX search_idx ON flip_items USING bm25 (id, title, zhparser_token) WITH (key_field='id');
```

todo
tailwindcss layout
ruby_llm avtivetive chat
pg_search jieba
vectorchord 
meilisearch
kamal