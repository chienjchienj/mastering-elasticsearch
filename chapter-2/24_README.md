## 批处理

<p>本书展示的几个例子中，ElasticSearch提供了高效的批量索引数据的功能，用户只需按批量索引的格式组织数据即可。同时，ElasticSearch也为获取数据和搜索数据提供了批处理功能。值得一提的是，该功能使用方式与批量索引类似，只需把多个请求组合到一起，每个请求可以独立指定索引及索引类型。接下来了解这些功能。</p>
<h4>MultiGet</h4>
MultiGet操作允许用户通过_mget端点在单个请求命令中获取多个文档。与RealTime Get功能相似，文档的获取也是近实时的 。MultiGet会获取所有添加到索引的文档，不会考虑这些文档是否已经能够用于搜索或者是否查询可见。看看样例命令吧：

```javascript
curl localhost:9200/library/book/_mget?fields=title -d '{
 "ids" : [1,3]
}'
```
该命令获取了URL中限定索引和type中ids参数指定的两个文档。在前面的样例中，我们也设置了文档需要返回哪些域(使用fields 请求参数)。ElasticSearch将返回如下格式的文档集:

```javascript
{
 "docs" : [ {
     "_index" : "library",
     "_type" : "book",
     "_id" : "1",
     "_version" : 1,
     "exists" : true,
     "fields" : {
     "title" : "All Quiet on the Western Front"
 }
 }, {
     "_index" : "library",
     "_type" : "book",
     "_id" : "3",
     "_version" : 1,
     "exists" : true,
     "fields" : {
     "title" : "The Complete Sherlock Holmes"
 }
 } ]
}
```

前面的请求命令也可以写成如下的紧凑格式：

```javascript
curl localhost:9200/library/book/_mget?fields=title -d '{
 "docs" : [{ "_id" : 1}, { "_id" : 3}]
}'
```

下面的格式在从多个索引和type中获取文档或者不同的文档需要返回不同的域时会很方便。在本例中，URL地址中包含的信息会被当作默认值看待。例如，参考如下的查询命令：

```javascript
curl localhost:9200/library/book/_mget?fields=title -d '{
 "docs" : [
 { "_index": "library_backup", "_id" : 1, "fields": ["otitle"]},
 { "_id" : 3}
 ]
}'
```
该命令会返回两个id值为1和3的文档，但是第一个文档从library_backup索引中返回，第二个文档从library索引中返回(因为library索引是定义在URL中，当作默认值看待的)。此外，在第一个文档中，我们限定只返回域名为otitle的文档。

<!-- note structure -->
<div style="height:110px;width:90%;position:relative;">
<div style="width:13px;height:100%; background:black; position:absolute;padding:5px 0 5px 0;">
<img src="../notes/lm.png" height="100%" width="13px"/>
</div>
<div style="width:51px;height:100%;position:absolute; left:13px; text-align:center; font-size:0;">
<img src="../notes/pixel.gif" style="height:100%; width:1px; vertical-align:middle;"/>
<img src="../notes/note.png" style="vertical-align:middle;"/>
</div>
<div id="mid" style="height:100%;position:absolute;left:65px;right:13px;">
<p style="font-size:13px;margin-top:10px;">
	在ElasticSearch 1.0版本中，MultiGet API会允许用户指定操作的文档版本。如果文档版本与请求命令中的不一致，ElasticSearch将不会执行MultiGet操作。这个新增的参数是version，允许用户传递感兴趣的参数；第二个参数是version_type，支持两种选项：internal和external。
</p>
</div>
<div id="right" style="width:13px;height:100%;background:black;position:absolute;right:0px;padding:5px 0 5px 0;">
<img src="../notes/rm.png" height="100%" width="13px"/>
</div>
</div>  <!-- end of note structure -->

<h4>MultiSearch</h4>
与MultiGet类似，MultiSearch功能允许用户将多个查询请求打包。但是，这种打包会稍微有点不同，看起来与批量索引的命令格式类似。ElasticSearch会按行来解析输入文本，每两行文本为一组，包含了查询的附带参数的目标索引和一个查询对象。参考如下的样例：


```javascript
curl localhost:9200/library/books/_msearch?pretty --data-binary '
{ "type" : "book" }
{ "filter" : { "term" : { "year" : 1936} }}
{ "search_type": "count" }
{ "query" : { "match_all" : {} }}
{ "index" : "library-backup", "type" : "book" }
{ "sort" : ["year"] }
```

正如例子所示，用户请求发送到\_msearch端点。路径中的索引和type是可选的，作为奇数行，即查询命令目标索引和type的默认值。例子中的文本可以包含搜索类型(search\_type)和路由或者查询的执行提示信息(preference)。由于这些参数都不是必须的，在有些情况下，一行可以只有有一个空的对象({})或者甚至是一个空行。真正的查询对象的描述由请求命令中的偶数行负责。接下来，看看上面请求命令的执行结果：
<blockquote>
{
 "responses" : [ {
 "took" : 2,
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
 ...
 } ]
 }
 },
 ...
 {
 "took" : 2,
 "timed_out" : false,
 "_shards" : {
 "total" : 5,
 "successful" : 5,
 "failed" : 0
 },
 "hits" : {
 "total" : 4,
 "max_score" : null,
 "hits" : [ {
 ...
 } ]
 }
 } ]
}
</blockquote>
返回的JSON对象包一个数组，用来存储批量查询中每个查询语句的查询结果。前面已经提到，MultiSearch允许用户将多个独立的查询命令聚集在一起，因此每个查询返回的文档集会根据索引的不同而结构不同。


<!-- note structure -->
<div style="height:110px;width:90%;position:relative;">
<div style="width:13px;height:100%; background:black; position:absolute;padding:5px 0 5px 0;">
<img src="../notes/lm.png" height="100%" width="13px"/>
</div>
<div style="width:51px;height:100%;position:absolute; left:13px; text-align:center; font-size:0;">
<img src="../notes/pixel.gif" style="height:100%; width:1px; vertical-align:middle;"/>
<img src="../notes/note.png" style="vertical-align:middle;"/>
</div>
<div id="mid" style="height:100%;position:absolute;left:65px;right:13px;">
<p style="font-size:13px;margin-top:10px;">
注意，就象批量索引一样，批量请求不需要额外的缩进。每行的作用都很清晰：限制信息或者查询对象。因此要确保每行的换行符号存在，并且发送查询命令的工具不会改变命令的内容。这就是为什么在curl命令中，我们需要使用--data-binary替代-d，-d不会保存换行符号。
</p>
</div>
<div id="right" style="width:13px;height:100%;background:black;position:absolute;right:0px;padding:5px 0 5px 0;">
<img src="../notes/rm.png" height="100%" width="13px"/>
</div>
</div>  <!-- end of note structure -->





