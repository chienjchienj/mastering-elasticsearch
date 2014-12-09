## 查询结果的重打分

<p>有些应用场景中，对查询语句的结果文档进行重新打分是很有必要的。重新打分的原因可能会各不相同。其中的一个原因可能是出于性能的考虑，比如，对整个有序的结果集进行重排序开销会很大，通常就会只对结果集的子集进行处理。可以想象重打分在业务中应用会相当广泛。接下来了解一下这项功能，学习如何将它应用在业务中。 </p>
<h4>理解重打分</h4>
<p>在ElasticSearch中，重打分是一个对限定数目的查询结果进行再次打分的一个过程。这意味着ElasticSearch会根据新的打分规则对查询结果的前N个文档重新进行一次排序。</p>
<h4>样例数据</h4>

<p>样例数据存储在documents.json文件中(随书附带)，可以通过如下的命令索引到ElasticSearch中：
</p>

```javascript
curl -XPOST localhost:9200/_bulk?pretty --data-binary @documents.json
```

<h4>查询</h4>
首先，运行如下的查询命令：

```javascript
{
 "fields" : ["title", "available"],
 "query" : {
 "match_all" : {}
 }
}
```

该命令的返回了索引中的所有文档。由于查询命令的类型是match\_all类型，所以查询命令返回的每个文档得分都是1.0分。这将足够展示recore对结果集影响。关于查询命令，还有一点就是我们指定了结果集中每个文档只返回"title"域和"available"域的内容。


<h4>rescore query的结构</h4>
附带recore功能的查询命令样例如下：

```javascript
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
```

在前面的json样例中，rescore对象中包含着一个query对象。作者写这本书的时候，query是唯一的一个选项，但是在后续的版本中我们将期待开发出更多的影响结果集打分的功能。在本例中，我们的rescore只是使用了一个返回所有文档集的简单查询对象，然后限定每个文档的得分值与year域的值相同(拜托不要问我这个查询在业务场景中能用到哪儿)。
如果我们把查询语句保存到query.json文件中，执行命令 curl localhost:9200/library/book/_search?pretty -d @query.json，我们就可以看到如下的文档(我们省略了response的结构)

```javascript
"_score" : 1962.0,
"title" : "Catch-22",
"available" : false
"_score" : 1937.0,
"title" : "The Complete Sherlock Holmes",
"available" : false
"_score" : 1930.0,
"title" : "All Quiet on the Western Front",
"available" : true
"_score" : 1887.0,
"title" : "Crime and Punishment",
"available" : true
```

通过结果可以看到，ElasticSearch查询到了原始查询语句返回的所有文档。接下来看看文档的得分。ElasticSearch截取了结果集靠前的N个文档，然后用第二个查询对象重新查询这些文档集。结果是这些文档的得分变成第一个查询对象得分和第二个查询对象得分的和。

出于性能的考虑，有时间会需要执行一些脚本；比如本例中的第二个查询对象。试想，如果我们最开始的match_all查询返回了成千上万上的文档，对这些文档进行重打分会影响到查询的性能。重打分提供了一个只对top N文档重新排序的功能，通过这种方式来降低对查询性能的影响。
接下来看看如何驯化rescore功能，它有哪些参数可供用户使用。

<h4>重打分的参数</h4>
<p>在查询语句的rescore对象中，用户还可以添加如下的参数：
<ul>
<li>window\_size(默认是from和size参数的和):该参数提供了与上文提到的N个文档相关的信息。window\_size参数指定了每个分片上用于重打分的文档的个数。</li>
<li>query\_weight(默认值为1):原查询的打分会先乘以该值，然后再与rescore的得分相加。 </li>
<li>rescore\_query\_weight(默认值为1):rescore的打分会先乘以该值，然后再与原查询的得分相加。</li>
<li>rescore_mode(默认值是tatal):该参数在ElasticSearch 0.90.3版本中引入(在ElasticSearch 0.90.3版本前，该参数类似的功能模块设置值为tatal),它用来指定重打分文档的打分方式。可选值为total,max,min,avg和multiply。当设置该值为total时文档最终得分为原查询得分和rescore得分的和；当设置该值为max时，文档最终得分为原查询得分和rescore得分的最大值；与max类似，当设置该值为min时，文档最终得分为原查询得分和rescore得分的最小值。以此类推，当选择avg时，文档的最终得分为原查询得分和rescore得分的平均值，如果设置为multiply,两种查询的得分将会相乘。</li>
</ul>
例如，设置rescore\_mode参数值为total，文档的最终得分是：
</p>


```javascript
original_query_score * query_weight + rescore_query_score *
rescore_query_weight
 ```

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
请记住ElasticSearch 0.90.3之前的版本不支持rescore\_mode参数，在ElasticSearch 0.90.3 版本之前，rescore机制实际上就是参数值只能为total。
</p>
</div>
<div id="right" style="width:13px;height:100%;background:black;position:absolute;right:0px;padding:5px 0 5px 0;">
<img src="../notes/rm.png" height="100%" width="13px"/>
</div>
</div>  <!-- end of note structure -->

<h4>本节小结</h4>
<p>有时，我们可能需要根据一些规则对页面中前几个文档进行排序。但是不幸的是，rescore机制并不能满足这一需求。也许第一个想到的是设置window\_size参数，但是该参数实际上关联的并不是结果集中的前几个文档，而是每个分片上的前几个文档。此外，window\_size参数值不能小于页面大小。(如果小于页面大小，则ElasticSearch会自动使用页面大小取代原来的window_size值)。而且非常重要的一点是重排序不能与排序结合使用，因为排序必须在重排序改变文档得分之前完成，而且文档排序并不会将新计算的得分考虑到内。上面提到的参数限制以及几种不同重排序功能的缺失(比如，对前3个文档使用一种规则进行排序，对随后的5个文档用另一种规则进行排序)限制了rescore功能的应用场景，在使用rescore功能前需要记住这一点。 </p>

