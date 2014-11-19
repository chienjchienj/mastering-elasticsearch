## 路由功能浅谈

<div style="text-indent:2em">
<p>在本章<i>&nbsp;选择恰当的分片数量和分片副本数量&nbsp;</i>一节中，已经提到使用路由功能可以只在一个分片上执行查询命令，作为提高系统吞吐量的一种解决方案。接下来作者将详细地介绍这一功能。</p>
<h3>分片和分片中数据</h3>
<p>通常情况下，ElasticSearch是如何把数据分发到各个分片中，哪个分片存储哪一类的文档等细节并不重要。因为查询时，将查询命令分发到每个分片就OK了。唯一的关键点在于算法，将数据均等地分配到各个分片的算法。在删除或者更新文档时，情况就会变得有点复杂了。实际上，这也不是什么大问题。只要保证分片算法在处理文档时，对于相同的文档标识生成相同的映射值就可以了。如果我们有这样的分片算法，ElasticSearch就知道在处理文档时，如何定位到正确的分片。但是，在选择文档的存储分片时，采用一个更加智能的办法不就更省事儿了吗？比如，把某一特定类型的书籍存储到特定的分片上去，这样在搜索这一类书籍的时候就可以避免搜索其它的分片，也就避免了多个分片搜索结果的合并。这就是路由功能(routing)的用武之地。路由功能向ElasticSearch提供一种信息来决定哪些分片用于存储和查询。同一个路由值将映射到同一个分片。这基本上就是在说：“通过使用用户提供的路由值，就可以做到定向存储，定向搜索。”</p>

<h3>路由功能的简单应用</h3>

<p>我们将通过一个例子来说明ElasticSearch是如何分配分片，哪些文档会存储在特定的分片上这一过程，为了使细节更清楚，我们借助一个第三方插件。这个插件将帮助我们更生动形象地了解ElasticSearch处理数据的过程。用如下的命令来安装插件：
</p>
<blockquote>
bin/plugin -install karmi/elasticsearch-paramedic</blockquote>
<p>重启ElasticSearch后，用浏览器打开http://localhost:9200/_plugin/paramedic/index.html 我们将能看到显示索引的各种信息的统计结果的页面。例如：最值得关注的信息是集群的状态和每个索引下分片及分片副本的相关信息。</p>
<p>启动两个节点的ElasticSearch集群，用如下的命令创建索引：
<blockquote style="text-indent:0em;">
curl&nbsp;-XPUT&nbsp;localhost:9200/documents&nbsp;-d&nbsp; '{<blockquote>
settings: {<blockquote>number_of_replicas: 0,<br/>
number_of_shards: 2
</blockquote>
}</blockquote>
}'
</blockquote>
<p/>
<p>我们创建了具有2个分片0个分片副本的索引。这意味着该集群最多有两个结点，多余的节点无法存储数据，除非我们增加分片副本的数量(读者可以回顾本章<i>选择恰当的分片数量和分片副本数量</i>一节内容了解相关知识)。创建索引后，下一步的操作就是添加数据了。我们用如下的命令来进行数据添加：
<blockquote style="text-indent:0em;">
curl&nbsp;-XPUT&nbsp; localhost:9200/documents/doc/1&nbsp;-d&nbsp;'{ "title" : "Document No.
1" }'<br/>
curl&nbsp;-XPUT&nbsp; localhost:9200/documents/doc/2&nbsp;-d&nbsp;'{ "title" : "Document No.
2" }'<br/>
curl&nbsp;-XPUT&nbsp; localhost:9200/documents/doc/3&nbsp;-d&nbsp;'{ "title" : "Document No.
3" }'<br/>
curl&nbsp;-XPUT&nbsp; localhost:9200/documents/doc/3&nbsp;-d&nbsp;'{ "title" : "Document No.
4" }'<br/>
</blockquote>
</p>
<p>添加数据完成后，Paramedic插件显示集群中存在两个分片，截图如下：
<img src="../42_paramedic_1.png"/>
</p>
<p>在节点所呈现的信息中，我们一样能够找到值得关注的信息。集群中的每个节点都存储着两个文档，这让我们容易得出如下的结论：分片算法完美地完成了数据分片的任务；集群中有一个由两个分片构建成的索引，索引对每个分片中文档的数量进行了均等分配。</p>
<p>现在我们做一些破坏，关闭一个节点。用Paramedic插件，我们将看到类似下图的截图：
<img src="../42_paramedic_2.png"/>
</p>
<p>我们关注的第一条信息是集群的状态已经变成了红色状态。这意味着至少有一个主分片已经丢失，这就表明有一部分数据已经失效，同时有一部分索引也失效了。尽管如此，在ElasticSearch集群上仍然可以进行查询操作。ElasticSearch集群把决定权交给了开发者：决定返回给用户不完整的数据还是阻塞用户查询。先看看查询命令的返回结果吧：
<blockquote style="text-indent:0em;">
{<blockquote>
"took" : 30,<br/>
"timed_out" : false,<br/>
"_shards" : {<br/>
"total" : 2,<br/>
"successful" : 1,<br/>
"failed" : 1,<br/>
"failures" : [ {<blockquote>
"index" : "documents",<br/>
"shard" : 1,<br/>
"status" : 500,<br/>
"reason" : "No active shards"</blockquote>
} ]</blockquote>
},
"hits" : {<blockquote>
"total" : 2,<br/>
"max_score" : 1.0,<br/>
"hits" : [ {<blockquote>
"_index" : "documents",<br/>
"_type" : "doc",<br/>
"_id" : "1",<br/>
"_score" : 1.0, "_source" : { "title" : "Document No. 1" }</blockquote>
}, {<blockquote>
"_index" : "documents",<br/>
"_type" : "doc",<br/>
"_id" : "3",<br/>
"_score" : 1.0, "_source" : { "title" : "Document No. 3" }</blockquote>
} ]</blockquote>
}
}
</blockquote>
</p>

<p>正如你所看见的那样，ElasticSearch返回了分片失效的信息。我们看到分片1失效。在返回的结果集中，我们只看到了ID为1和3的文档。至少在主分片1重新连接到集群之前，其它的文档丢失。如果重新启动第二个节点，经过一段时间(取决于网络情况和gateway模块的参数设置)，集群将返回绿色状态，而且整个索引中的文档都可用。接下来，我们将用路由功能(routing)来做与上面一样的事情，并观察两者在集群中的不同点。</p>

<h4 style="text-indent:0em;">启用路由功能(routing)索引数据</h4>

<p>通过路由功能，用户能够控制ElasticSearch用哪个分片来存储文档。路由的参数值是无关紧要的，可以由用户随意给出。关键点在于相同的参数值应该用来把不同的文档导向同一个分片。</p>
<p>将路由参数信息写入到ElasticSearch中有多种方式，最简单的一种是在索引文档的时候提供一个<span style="font-size:13">routing</span>URL 参数。比如：
<blockquote style="text-indent:0em;">curl&nbsp;-XPUT&nbsp; localhost:9200/documents/doc/1?routing=A&nbsp;-d&nbsp;'{ "title":"Document" }'</blockquote>
</p>
<p>另外一种方式就是在创建文档时把_routing域放进去：
<blockquote style="text-indent:0em;">curl&nbsp;-XPUT&nbsp; localhost:9200/documents/doc/1&nbsp;-d&nbsp;'{ "title":"Document","_routing":"A" }'</blockquote>
</p>
<p>然而这种方式只有在mapping中定义了_routing域才会生效。例如：
<blockquote style="text-indent:0em;">
"mappings": {<blockquote>
 "doc": {<blockquote>
 "_routing": {<blockquote>"required": true,<br/>
 "path": "_routing"</blockquote>
 },
 "properties": {<blockquote>
 "title" : {"type": "string" }</blockquote>
 }</blockquote>
 }</blockquote>
 }
</blockquote>
</p>
<p>让我们在这里停留一下。在本例中，我们用到了_routing域。值得一提的是path参数可以指向文档中任何not-analyzed域。这是一个非常强大的特性。例举routing特性的一个主要的优点：比如我们在文档中定义了library_id域，用来表示书籍所在的藏书室编号。当我们基于library_id域来实现路由功能，基于该藏书室检索相关图书将使检索过程更高效，这样做也是合乎逻辑的。</p>
<p>现在，我们回过头来继续讨论routing值的定义方式。最后一个办法是使用批处理索引。在下面的例子中，routing被放置到每个文档的头部信息块中。例如：
<blockquote style="text-indent:0em;">
curl&nbsp;-XPUT&nbsp;localhost:9200/_bulk&nbsp;--data-binary&nbsp;
'{<blockquote>"index" : {<blockquote>"_index" : "documents", "_type" : "doc", "_routing" : "A"
</blockquote>}</blockquote>}
{ "title" : "Document No. 1" }
'
</blockquote>
既然已经了解routing是如何工作的，那么就回到例子中。
</p>

<h3 style="text-indent:0em;">启用路由功能(routing)索引数据</h3>

<p>现在，我们对照前面的例子，依样画葫芦，除了一点不一样，那就是使用路由功能(routing)。第一件事就是删除所有旧的文档。如果不清空索引数据，添加id相同的文档到索引中时，routing会把文档定位到其它的分片上。因此，运行如下的命令清空索引数据：
<blockquote style="text-indent:0em;">
curl&nbsp;-XDELETE&nbsp;localhost:9200/documents/_query?q=*:*
</blockquote>
</p>
<p>经过这一步，我们重新索引数据。但是这次要添加上routing信息。因此索引数据的命令如下：
<blockquote style="text-indent:0em;">curl&nbsp;-XPUT&nbsp;localhost:9200/documents/doc/1?routing=A &nbsp;-d&nbsp;'{ "title" :
"Document No. 1" }'<br/>
curl&nbsp;-XPUT&nbsp;localhost:9200/documents/doc/2?routing=B &nbsp;-d&nbsp;'{ "title" :
"Document No. 2" }'<br/>
curl&nbsp;-XPUT&nbsp;localhost:9200/documents/doc/3?routing=A &nbsp;-d&nbsp;'{ "title" :
"Document No. 3" }'<br/>
curl&nbsp;-XPUT&nbsp;localhost:9200/documents/doc/4?routing=A &nbsp;-d&nbsp;'{ "title" :
"Document No. 4" }'<br/>
</blockquote>
</p>
</div>
