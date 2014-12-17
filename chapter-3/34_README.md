##近实时搜索，段数据刷新，数据可见性更新和事务日志

理想的搜索解决方案是这样的：新的数据一添加到索引中立马就能搜索到。第一眼看上去，这不正是ElasticSearch的工作方式吗，即使是多服务器环境也是如此。但是真实情况不是这样的(至少现在不是)，后面会讲到为什么它是似是而非。首先，我们往新创建的索引中添加一个新的文档，命令如下：
```javascript
curl -XPOST localhost:9200/test/test/1 -d '{ "title": "test" }'
```
接下来，我们在替换文档的同时查找该文档。我们用如下的链式命令来实现这一点：
```javascript
curl -XPOST localhost:9200/test/test/1 -d '{ "title": "test2" }' ; curl
localhost:9200/test/test/_search?pretty
```
上面命令的结果类似如下：
```javascript
{"ok":true,"_index":"test","_type":"test","_id":"1","_version":2}
{
    "took" : 1,
    "timed_out" : false,
        "_shards" : {
        "total" : 5,
        "successful" : 5,
        "failed" : 0
    },
    "hits" : {
        "total" : 1,
        "max_score" : 1.0,
        "hits" : [ {
            "_index" : "test",
            "_type" : "test",
            "_id" : "1",
            "_score" : 1.0, "_source" : { "title": "test" }
        } ]
    }
}
```
第一行是第一个命令，即索引命令的返回结果。可以看到，数据更新成功。因此，第二个命令，即查询命令查询到的文档title域值应该为test2。但是，可以看到结果并不如人所愿。这背后发生了什么呢？

在揭开前一个问题的答案之前，我们先退一步，来了解底层的Apache Lucene工具包是如何让新添加的文档对搜索可见的。

###更新索引并且将改动提交

从 第1章 介绍ElasticSearch 的 介绍Apache Lucene一节中，我们已经了解到，在索引过程中，新添加的文档都是写入到段(segments)中。每个段都是有着独立的索引结构，这意味着查询与索引两个过程是可以并行存在的，索引过程中，系统会不定期创建新的段。Apache Lucene通过在索引目录中创建新的segments_N文件来标识新的段。段创建的过程就称为索引的提交。Lucene可以一种安全的方式实现索引的提交——我们可以确定段文件要么全部创建成功，要么失败。如果错误发生，我们可以确保索引状态的一致性。

回到我们的例子中，第一条命令添加文档到索引中，但是没有提交。这就是它的工作方式。然而，索引数据的提交也不能保证数据是搜索可见的。Lucene工具包使用一个名为Searcher的抽象类来读取索引。索引提交操作完成后，Searcher对象需要重新打开才能加载到新创建的索引段。这整个过程称为更新。出于性能的考虑，ElasticSearch会将推迟开销巨大的更新操作，默认情况下，单个文档的添加并不会触发搜索器的更新，Searcher对象会每秒更新一次。这个频率已经比较高了，但是在一些应用程序中，需要更频繁的更新。对面这个需求，我们可以考虑使用其它的解决方案或者再次核实我们是否真的需要这样做。如果确实需要，那么可以使用ElasticSearch API强制更新。比如，上面的例子中，我们可以执行如下的命令强制更新：
```javascript
curl –XGET localhost:9200/test/_refresh
```
如果在搜索前执行了上面的命令，那么ElasticSearch就可以搜索到修改后的文档。

###修改Searcher对象默认的更新时间
