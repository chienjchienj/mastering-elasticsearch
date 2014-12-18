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

Searcher对象的默认更新时间可以通过使用`index.refresh_interval`参数来修改，该参数无论是添加到ElasticSearch的配置文件中或者使用update settings API都可以生效。例如：
```javascript
curl -XPUT localhost:9200/test/_settings -d '{
    "index" : {
        "refresh_interval" : "5m"
    }
}'
```
上面的命令将使Searcher每5秒钟自动更新一次。请记住在更新两个时间点之间添加到索引的数据对查询是不可见的。


<!-- note structure -->
<div style="height:80px;width:90%;position:relative;">
<div style="width:13px;height:100%; background:black; position:absolute;padding:5px 0 5px 0;">
<img src="../notes/lm.png" height="100%" width="13px"/>
</div>
<div style="width:51px;height:100%;position:absolute; left:13px; text-align:center; font-size:0;">
<img src="../notes/pixel.gif" style="height:100%; width:1px; vertical-align:middle;"/>
<img src="../notes/note.png" style="vertical-align:middle;"/>
</div>
<div style="height:100%;position:absolute;left:65px;right:13px;">
<p style="font-size:13px;margin-top:10px;">
我们已经提到，更新操作的时间开销和内存开销都很大。更新的时间段设置越长，索引速度越快。如果在整个索引过程中数据都不必对搜索可见，那么可以考虑关闭更新操作来换取高效的索引过程，设置index.refresh_interval 参数值为-1即可，记得在索引完成后改回原来的值。
</p>
</div>
<div style="width:13px;height:100%;background:black;position:absolute;right:0px;padding:5px 0 5px 0;">
<img src="../notes/rm.png" height="100%" width="13px"/>
</div>
</div>  <!-- end of note structure -->

###事务日志的配置

如果事务日志的默认配置无法满足业务需求，ElasticSearch允许用户在事务日志的处理上自己配置参数。如下的参数可以控制系统的事务日志行为，参数可以设置在elasticsearch.yml文件中，也可以用索引设置更新API来设置：
* `index.translog.flush_threshold_period`:默认值为30秒(30m)。该属性用于控制自动刷新的时间，即使期间没有数据写入，也会强制刷新。
* `index.translog.flush_threshold_ops`:用来指定刷新操作执行的最多事务次数。默认值是5000。
* `index.translog.flush_threshold_size`:用来指定事务日志的最大容量。如果事务日志的大小等于或者超过参数值，就会执行刷新操作。默认值是200M.
* `index.translog.disable_flush`:该属性用来关闭自动刷新。默认情况下日志的自动刷新是开启的，但是有时需要暂时关闭日志的自动刷新。比如需要添加大量数据到集群中时，关闭日志的自动刷新有助于系统性能的提升。

<!-- note structure -->
<div style="height:50px;width:90%;position:relative;">
<div style="width:13px;height:100%; background:black; position:absolute;padding:5px 0 5px 0;">
<img src="../notes/lm.png" height="100%" width="13px"/>
</div>
<div style="width:51px;height:100%;position:absolute; left:13px; text-align:center; font-size:0;">
<img src="../notes/pixel.gif" style="height:100%; width:1px; vertical-align:middle;"/>
<img src="../notes/note.png" style="vertical-align:middle;"/>
</div>
<div style="height:100%;position:absolute;left:65px;right:13px;">
<p style="font-size:13px;margin-top:10px;">
上面的所有参数都定义于某个索引，但是作用于索引的每个分片上。
</p>
</div>
<div style="width:13px;height:100%;background:black;position:absolute;right:0px;padding:5px 0 5px 0;">
<img src="../notes/rm.png" height="100%" width="13px"/>
</div>
</div>  <!-- end of note structure -->

当然，除了预先在elasticsearch.yml文件中设置这些参数外，它们还可以用Settings Update API来设置,比如：
```javascript
curl -XPUT localhost:9200/test/_settings -d '{
    "index" : {
        "translog.disable_flush" : true
    }
}'
```
上面的命令一般用于导入大量数据到索引前执行，这样会提升索引阶段的性能。但是要记住，数据索引完毕后要开启事务日志的自动刷新。

###近实时GET

事务日志带来的副产品就是实时GET操作，即提供了返回早期版本文档，包括未提交文档的功能。实时GET操作从索引中获取数据，但事先会从事务日志中查看是否有更新的版本。如果存在没有刷新的文档，索引中的数据就会被忽略，返回更新版本的文档——事务日志中的文档。想弄清楚该如何使用该功能，可以用户如下的命令代替搜索操作：
```javascript
curl -XGET localhost:9200/test/test/1?pretty
```
ElasticSearch返回的结果如下：
```javascript
{
    "_index" : "test",
    "_type" : "test",
    "_id" : "1",
    "_version" : 2,
    "exists" : true, "_source" : { "title": "test2" }
}
```
如果看到结果，你肯定会再多看一眼，因为返回的文档就是最新的。不需要Searcher的更新也得到想要的结果。
