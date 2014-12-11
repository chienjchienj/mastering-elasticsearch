## filters和scope在ElasticSearch Faceting模块的应用

使用ElasticSearch的Facet功能时，有一些关键点需要记住。首先，faceting的结果只会基于查询结果。如果用户在查询命令中使用了filters，那么filters不会对Facet用来的统计计算的文档产生影响。另一个关键点就是scope属性，该属性可以扩展Facet用来统计计算的文档范围。接下来直接看样例。

###样例数据

在回忆queries,filters,facets工作原理的同时，我们来开始新内容的学习。首先往books索引中添加一些文档，命令如下：
```javascript
curl -XPUT 'localhost:9200/books/book/1' -d '{
    "id":"1", "title":"Test book 1", "category":"book",
"price":29.99
}'
curl -XPUT 'localhost:9200/books/book/2' -d '{
"id":"2", "title":"Test book 2", "category":"book",
"price":39.99
}'
curl -XPUT 'localhost:9200/books/book/3' -d '{
"id":"3", "title":"Test comic 1", "category":"comic",
"price":11.99
}'
curl -XPUT 'localhost:9200/books/book/4' -d '{
"id":"4", "title":"Test comic 2", "category":"comic",
"price":15.99
}'
```

###Faceting和filtering

接下来验证queries结合filters时，facetings是如何工作的。我们会运行一个简单的查询命令，该查询会返回books索引中所有的文档；同时，我们也添加了一个filter来缩减查询只返回category域值为book的文档；此外，我们还为price域添加了一个简单的range faceting统计，来看看有多少文档的price域值低于30，多少文档的price域值高于30。整个查询命令如下(存储于query\_with_filter.json文件):
```javascript
{
    "query" : {
        "match_all" : {}
    },
    "filter" : {
        "term" : { "category" : "book" }
    },
    "facets" : {
        "price" : {
            "range" : {
            "field" : "price",
            "ranges" : [
                    { "to" : 30 },
                    { "from" : 30 }
                ]
            }
        }
    }
}
```
