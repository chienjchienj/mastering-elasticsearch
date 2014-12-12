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
执行该命令后，返回值如下：
```javascript
{
    ...
    "hits" : {
        "total" : 2,
        "max_score" : 1.0,
        "hits" : [ {
            "_index" : "books",
            "_type" : "book",
            "_id" : "1",
            "_score" : 1.0, "_source" : {"id":"1", "title":"Test book
            1", "category":"book", "price":29.99}
        }, {
            "_index" : "books",
            "_type" : "book",
            "_id" : "2",
            "_score" : 1.0, "_source" : {"id":"2", "title":"Test book
            2", "category":"book", "price":39.99}
        } ]
    },
    "facets" : {
        "price" : {
            "_type" : "range",
            "ranges" : [ {
                "to" : 30.0,
                "count" : 3,
                "min" : 11.99,
                "max" : 29.99,
                "total_count" : 3,
                "total" : 57.97,
                "mean" : 19.323333333333334
            }, {
                "from" : 30.0,
                "count" : 1,
                "min" : 39.99,
                "max" : 39.99,
                "total_count" : 1,
                "total" : 39.99,
                "mean" : 39.99
            } ]
        }
    }
}
```
尽管查询的结果限制到了category域值为book的文档，但是faceting的结果却不是这样。实际上，faceting的结果是基于books索引中的所有文档(由于match\_all\_query的缘故)。因此，现在可以确定ElasticSearch的faceting机制在计算时不会把filter考虑进去。那么，如果filters是query对象的一部分呢，比如`filtered` query类型?让我们来验证一下。

###Filter作为Query对象的一部分

接下来，还是用前面的例子，只是把查询换成`filtered` query类型。然后再次从books索引中取得所有的文档，并用`book`类别来过滤结果集，同时对price域进行简单的range faceting操作，来查看多少文档的price值低于30，多少文档的price值高于30。为了实现这个目的，来运行如下的查询(存储在filtered_query.json文件):
```javascript
{
    "query" : {
        "filtered" : {
            "query" : {
                "match_all" : {}
            },
            "filter" : {
                "term" : {
                "category" : "book"
                }
            }
        }
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
上面查询命令返回的结果如下：
```javascript
{
    ...
    "hits" : {
        "total" : 2,
        "max_score" : 1.0,
        "hits" : [ {
            "_index" : "books",
            "_type" : "book",
            "_id" : "1",
            "_score" : 1.0, "_source" : {"id":"1", "title":"Test book
            1", "category":"book", "price":29.99}
        }, {
            "_index" : "books",
            "_type" : "book",
            "_id" : "2",
            "_score" : 1.0, "_source" : {"id":"2", "title":"Test book
            2", "category":"book", "price":39.99}
        } ]
    },
    "facets" : {
        "price" : {
            "_type" : "range",
            "ranges" : [ {
                "to" : 30.0,
                "count" : 1,
                "min" : 29.99,
                "max" : 29.99,
                "total_count" : 1,
                "total" : 29.99,
                "mean" : 29.99
            }, {
                "from" : 30.0,
                "count" : 1,
                "min" : 39.99,
                "max" : 39.99,
                "total_count" : 1,
                "total" : 39.99,
                "mean" : 39.99
            } ]
        }
    }
}
```

可以看到，正所我们所希望的，faceting的结果限制到了查询返回的结果集中，这是由于filter成为了查询的一部分。在本例中，faceting结果由两个区间组成，每个区间都包含着一个文档。

### Facet filter

假如我们希望对title域中含term值为2的书进行faceting统计。我们可能想到在query对象中添加第二个过滤器，但是这样做会减少查询结果的数量，而我们不希望查询受到影响。因此我们引入facet filter。

我们将facet\_filter过滤器添加到facet类型(本例中是price)的同一层。该过滤器可以减少faceting统计计算的文档数量，其使用方式与查询中的过滤器是一样的。例如，假如我们用facet\_filter使得facet功能只对title域中含term值为2的书籍进行faceting统计，我们应该把查询命令修改成如下(整个查询命令存储在 filtered\_query\_facet\_filter.json文件中):
```javascript
{
    ...
    "facets" : {
        "price" : {
            "range" : {
                "field" : "price",
                "ranges" : [
                    { "to" : 30 },
                    { "from" : 30 }
                ]
            },
            "facet_filter" : {
                "term" : {
                    "title" : "2"
                }
            }
        }
    }
}
```
可以看到，我们引入了新的过滤器，即一个简单的term类型的过滤器。上面查询命令返回的结果如下：
```javascript
{
    ...
    "hits" : {
        "total" : 2,
        "max_score" : 1.0,
        "hits" : [ {
            "_index" : "books",
            "_type" : "book",
            "_id" : "1",
            "_score" : 1.0, "_source" : {"id":"1", "title":"Test book
            1", "category":"book", "price":29.99}
        }, {
            "_index" : "books",
            "_type" : "book",
            "_id" : "2",
            "_score" : 1.0, "_source" : {"id":"2", "title":"Test book
            2", "category":"book", "price":39.99}
        } ]
    },
    "facets" : {
        "price" : {
            "_type" : "range",
            "ranges" : [ {
                "to" : 30.0,
                "count" : 0,
                "total_count" : 0,
                "total" : 0.0,
                "mean" : 0.0
            }, {
                "from" : 30.0,
                "count" : 1,
                "min" : 39.99,
                "max" : 39.99,
                "total_count" : 1,
                "total" : 39.99,
                "mean" : 39.99
            } ]
        }
    }
}
```
通过与第一个查询结果的对比，应该就可以看到两者的不同。通过在查询命令中使用facet filter，就可以实现基于只一个文档的faceting统计计算，但是查询不受影响，仍然返回两个文档。

##Facet的统计范围

如果我们希望执行一个查询命令，查找到name域中包含term值为2的所有文档，同时基于索引中的所有文档进行range facet统计操作，该怎么做呢？幸运地是，我们不必非要使用两个查询命令来实现，我们可以通过添加global属性，设置其值为true来使用全局范围的faceting操作。

例如，我们先把前面用过的查询命令进行简单的修改。在本节中，查询命令中去掉过滤器，只有一个term query。此外，我们还添加了一个global属性，因此查询命令如下(已经存储在query\_global\_scope.json文件中)：
```javascript
{
"query" : {
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
            },
            "global" : true
        }
    }
}
```
接下来，看查询的结果：
```javascript
{
    ...
    "hits" : {
        "total" : 2,
        "max_score" : 0.30685282,
        "hits" : [ {
            "_index" : "books",
            "_type" : "book",
            "_id" : "1",
            "_score" : 0.30685282, "_source" : {"id":"1", "title":"Test
            book 1", "category":"book", "price":29.99}
        }, {
            "_index" : "books",
            "_type" : "book",
            "_id" : "2",
            "_score" : 0.30685282, "_source" : {"id":"2",
            "title":"Test book 2", "category":"book", "price":39.99}
        } ]
    },
    "facets" : {
        "price" : {
            "_type" : "range",
            "ranges" : [ {
                "to" : 30.0,
                "count" : 3,
                "min" : 11.99,
                "max" : 29.99,
                "total_count" : 3,
                "total" : 57.97,
                "mean" : 19.323333333333334
            }, {
                "from" : 30.0,
                "count" : 1,
                "min" : 39.99,
                "max" : 39.99,
                "total_count" : 1,
                "total" : 39.99,
                "mean" : 39.99
            } ]
        }
    }
}
```

正是由于global属性的存在，尽管查询结果中只有两个文档，但是facet统计计算却是基于整个索引的所有文档。

global属性可能的应用场景在于使用faceting来建立导航信息。设想无论什么查询，我们都需要返回顶级分类信息，比如在电子商务网站，使用terms facet功能来展示商品的顶级分类信息。在这类的场景中，使用global 范围是很方便的。
