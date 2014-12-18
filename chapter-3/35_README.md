##深入了解文本处理流程

用ElasticSearch进行开发时，你可能会被ElasticSearch提供的不同的搜索方式和查询类型所困扰。每种查询类型的运行机制都不尽相同，我们不能浮于表面，比如，比较区间查询和前缀查询之间的不同点。理解query的工作原理并知晓它们之间的区别是至关重要的，特别是基于ElasticSearch进行业务开发时，比如，处理多语言的文本。

###输入的文本并不是都会进行分析

在探讨查询解析之间，我们先使用如下的命令创建一个索引
```javascript
curl -XPUT localhost:9200/test -d '{
 "mappings" : {
     "test" : {
         "properties" : {
            "title" : { "type" : "string", "analyzer" : "snowball" }
         }
     }
 }
}'
```
可以看到，索引结构相当简单。文档只有一个域，域会用名为snowball的分析器处理。接下来，索引一个简单的文档。运行如下的命令即可：
```javascript
curl -XPUT localhost:9200/test/test/1 -d '{
"title" : "the quick brown fox jumps over the lazy dog"
}'
```
基于这个简单小巧的索引，我们来测试各种查询。仔细观察下面的两条命令：
```javascript
curl localhost:9200/test/_search?pretty -d '{
 "query" : {
     "term" : {
        "title" : "jumps"
     }
 }
}'
curl localhost:9200/test/_search?pretty -d '{
 "query" : {
     "match" : {
        "title" : "jumps"
     }
 }
}'
```
