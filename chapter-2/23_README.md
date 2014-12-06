## 重排序

<div style="text-indent:2em;">
<p>有些应用场景中，对查询语句的结果文档进行重排序是很有必要的。重排序的原因可能会各不相同。其中的一个原因可能是出于性能的考虑，比如，对整个有序的结果集进行重排序开销会很大，通常就会只对结果集的子集进行处理。可以想象重排序在业务中应用会相当广泛。接下来了解一下这项功能，学习如何将它应用在业务中。 </p>
<h4>理解重排序</h4>
<p>在ElasticSearch中，重排序是一个对限定数目的查询结果进行重新打分的一个过程。这意味着ElasticSearch会根据重排序的打分规则对查询结果的前N个文档进行再次打分。</p>
<h4>样例数据</h4>
<<<<<<< HEAD
<p>样例数据存储在documents.json文件中(随书附带)，可以通过如下的命令索引到ElasticSearch中：
<blockquote>
curl -XPOST localhost:9200/_bulk?pretty --data-binary @documents.json
</blockquote>
</p>
<h4>查询</h4>
<p>首先，运行如下的查询命令：
<blockqoute>
{
 "fields" : ["title", "available"],
 "query" : {
 "match_all" : {}
 }
}
</blockquote>
该命令的返回了索引中的所有文档。由于查询命令的类型是match\_all类型，所以查询命令返回的每个文档得分都是1.0分。这将足够展示recore对结果集影响。关于查询命令，还有一点就是我们指定了结果集中每个文档只返回"title"域和"available"域的内容。
</p>
<h4>rescore query的结构</h4>
<p>附带recore功能的查询命令样例如下：
<blockquote>
{
 "fields" : ["title", "available"],
 "query" : {
 "match_all" : {}
 },
 "rescore" : {
 "query" : {
 "rescore_query" : {
 "custom_score" : {
 "query" : {
 "match_all" : {}
 },
 "script" : "doc['year'].value"
 }
 }
 }
 }
}
</blockquote>
</p>

=======
<p>我们的样例数据存储在documents.json文件中(随书附带) </p>
>>>>>>> 4576cee0646a01b7650cf2366311e7207c50d813
</div>
