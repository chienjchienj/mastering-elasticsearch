## 总体架构
<div style="text-indent:2em;">
<p>尽管我希望直奔主题，介绍Lucene的架构，但是首先必须理解一些概念才能更好地理解Lucene的架构，这些概念是：</p>
<hr>
<ul>
<li><b>Document</b>:&nbsp;&nbsp;它是在索引和搜索过程中数据的主要表现形式，或者称“载体”，承载着我们索引和搜索的数据,它由一个或者多个域(Field)组成。 </li>
<li><b>Field</b>:&nbsp;&nbsp; 它是Document的组成部分，由两部分组成，名称(name)和值(value)。</li>
<li><b>Term</b>:&nbsp;&nbsp;它是搜索的基本单位，其表现形式为文本中的一个词。</li>
<li><b>Token</b>:&nbsp;&nbsp;它是单个Term在所属Field中文本的呈现形式，包含了Term内容、Term类型、Term在文本中的起始及偏移位置。</li>
</ul>
<hr>
<p>Apache Lucene把所有的信息都写入到一个称为**倒排索引**的数据结构中。这种数据结构把索引中的每个Term与相应的Document映射起来，这与关系型数据库存储数据的方式有很大的不同。读者可以把倒排索引想象成这样的一种数据结构：数据以Term为导向，而不是以Document为导向。下面看看一个简单的倒排索引是什么样的，假定我们的Document只有title域(Field)被编入索引，Document如下：</p>

*  ElasticSearch Servier (document 1)
*  Mastering ElasticSearch (document 2)
*  Apache Solr 4 Cookbook (document 3)


所以索引(以一种直观的形式)展现如下：

| Term | count | Docs |
| -- | -- | -- |
| 4 | 1 | <3> |
|Apache | 1 | <3>  |
| Cookbook | 1 | <3>  |
| ElasticSearch | 2 | <1> <2>  |
| Mastering | 1 | <1> |
| Server | 1 | <1> |
| Solr | 1 | <3> |

<br/><br/>
<p>正如所看到的那样，每个词都指向它所在的文档号(Document Number/Document ID)。这样的存储方式使得高效的信息检索成为可能，比如基于词的检索(term-based query)。此外，每个词映射着一个数值(Count)，它代表着Term在文档集中出现的频繁程度。
</p>
<br/>
<p>当然，Lucene创建的真实索引远比上文复杂和先进。这是因为在Lucene中，<b>词向量</b>(由单独的一个Field形成的小型倒排索引，通过它能够获取这个特殊Field的所有Token信息)可以存储；所有Field的原始信息可以存储；删除Document的标记信息可以存储……。核心在于了解数据的组织方式，而非存储细节。</p>
<br/>
<p>每个索引被分成了多个段(Segment)，段具有一次写入，多次读取的特点。只要形成了，段就无法被修改。例如：被删除文档的信息被存储到一个单独的文件，但是其它的段文件并没有被修改。</p><br/>
<p>需要注意的是，多个段是可以合并的，这个合并的过程称为<b>segments merge</b>。经过强制合并或者Lucene的合并策略触发的合并操作后，原来的多个段就会被Lucene创建的更大的一个段所代替了。很显然，段合并的过程是一个I/O密集型的任务。这个过程会清理一些信息，比如会删除.del文件。除了精减文件数量，段合并还能够提高搜索的效率，毕竟同样的信息，在一个段中读取会比在多个段中读取要快得多。但是，由于段合并是I/O密集型任务，建议不好强制合并，小心地配置好合并策略就可以了。<p>

<!--note structure -->
<div style="height:110px;width:650px;text-indent:0em;">
<div style="float:left;width:13px;height:100%; background:black;">
  <img src="../lm.png" height="100px" width="13px" style="margin-top:5px;"/>
</div>
<div style="float:left;width:50px;height:100%;position:relative;">
	<img src="../note.png" style="position:absolute; top:30%; "/>
</div>
<div style="float:left; width:550px;height:100%;">
	<p style="font-size:13px;margin-top:5px;">如果想了解段由哪些文件组成，想了解每个文件中存储了什么信息，可以参考Apache Lucene documentation ,访问地址：http://lucene.apache.org/core/4_5_0/core/org/apache/lucene/codecs/lucene45/package-summary.html.</p>
</div>
<div style="float:left;width:13px;height:100%;background:black;">
  <img src="../rm.png" height="100px" width="13px" style="margin-top:5px;"/>
</div>
</div> <!-- end of note structure -->
</div>

