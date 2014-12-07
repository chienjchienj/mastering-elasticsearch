## 批处理

<div style="text-indent:2em;">
<p>本书展示的几个例子中，ElasticSearch提供了高效的批量索引数据的功能，用户只需按批量索引的格式组织数据即可。同时，ElasticSearch也为获取数据和搜索数据提供了批处理功能。值得一提的是，该功能使用方式与批量索引类似，只需把多个请求组合到一起，每个请求可以独立指定索引及索引类型。接下来了解这些功能。</p>
<h4>MultiGet</h4>
<p>MultiGet操作允许用户通过_mget端点在单个请求命令中获取多个文档。与RealTime Get功能相似，文档的获取也是近实时的 。MultiGet会获取所有添加到索引的文档，不会考虑这些文档是否已经能够用于搜索或者是否查询可见。看看样例命令吧：
<blockquote>curl localhost:9200/library/book/_mget?fields=title -d '{
 "ids" : [1,3]
}'</blockquote>
该命令获取了URL中限定索引和索引类型中ids参数指定的两个文档。在前面的样例中，我们也设置了文档需要返回哪些域(使用fields 请求参数)。ElasticSearch将返回如下格式的文档集:
<blockquote>{
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
}</blockquote>
前面的请求命令也可以写成如下的紧凑格式：
<blockquote>curl localhost:9200/library/book/\_mget?fields=title -d '{
 "docs" : [{ "\_id" : 1}, { "\_id" : 3}]
}'</blockquote>
</p>

</div>



