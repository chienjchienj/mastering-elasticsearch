## update API

当往索引中添加新的文档到索引中时，底层的Lucene工具包会分析每个域，生成token流，token流过滤后就得到了倒排索引。在这个过程中，输入文本中一些不必要的信息会丢弃掉。这些不必要的信息可能是一些特殊词的位置(如果没有存储term vectors)，一些停用词或者用同义词代替的词，或者词尾(抽取词干时)。这也是为什么无法对Lucene中的文档进行修改，每次需要修改一个文档时，就必须把文档的所有域添加到索引中。ElasticSearch通过使用\_source这个代理域来存储和检索文档中的真实数据，以绕开前面的问题。当我们想更新文档时，ElasticSearch 会把数据存放在\_source域中，然后做出修改，最后把更新后的文档添加到索引中。当然，前提是_source域的这项特性必须生效。非常重要的一个限制就是文档更新命令只能更新一个文档，基于查询命令的文档更新还没有正式支持。

<!-- note structure -->
<div style="height:110px;width:90%;position:relative;">
<div style="width:13px;height:100%; background:black; position:absolute;padding:5px 0 5px 0;">
<img src="../notes/lm.png" height="100%" width="13px"/>
</div>
<div style="width:51px;height:100%;position:absolute; left:13px; text-align:center; font-size:0;">
<img src="../notes/pixel.gif" style="height:100%; width:1px; vertical-align:middle;"/>
<img src="../notes/note.png" style="vertical-align:middle;"/>
</div>
<div style="height:100%;position:absolute;left:65px;right:13px;">
<p style="font-size:13px;margin-top:10px;">
如果读者对Apache Lucene 分析器的工作原理或者上面提到的术语不熟悉，请参考 <b>第1章 ElasticSearch简介</b> 的  <b>认识Apache Lucene</b> 一节的内容。
</p>
</div>
<div style="width:13px;height:100%;background:black;position:absolute;right:0px;padding:5px 0 5px 0;">
<img src="../notes/rm.png" height="100%" width="13px"/>
</div>
</div>  <!-- end of note structure -->

从API的角度来看，
