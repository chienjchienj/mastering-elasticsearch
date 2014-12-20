##段合并的底层控制
读者应该已经了解每个ElasticSearch索引都由一个或多个分片加上零个或者多个分片副本组成(已经在<b>第一章 介绍ElasticSearch</b>论述过)。而且每个分片和分片副本实际上是Apache Lucene的索引，由多个段(至少一个段)组成。读者应该还记得，段数据都是一次写入，多次读取，当然保存删除文档的文件除外，该文件可以随机改变。经过一段时间，当条件满足时，多个小的段中的内容会被复制到一个大的段中，原来的那些小段就会丢弃，然后从硬盘上删除。这个过程称为<b>段合并(segment merging)</b>。

读者可能会嘀咕，为什么要这么麻烦进行段合并？有以下几个原因：首先，索引中存在的段越多，搜索响应速度就会越慢，内存占用也会越大。此外，段文件是无法改动的，因此段数据信息不会删除。如果恰好删除了索引中的很多文档，在索引合并之前，这些文档只是标记删除，并非物理删除。因此，当段合并时，标记删除的文档不会写入到新的段中，通过这种方式实现真正的删除，并缩减了段数据的大小。

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
索引中微小的改变也会导致大量碎片段的产生，大量碎片段会导致大量文件的打开，系统持有太多文件的句柄就会出现问题。我们应该时刻准备着应对这种情况，比如，将限制文件打开数量设置为一个恰当的值。
</p>
</div>
<div style="width:13px;height:100%;background:black;position:absolute;right:0px;padding:5px 0 5px 0;">
<img src="../notes/rm.png" height="100%" width="13px"/>
</div>
</div>  <!-- end of note structure -->

因此，快速总结如下，从用户的角度，段合并将产生以下两种影响：
* 当几个段合并成一个段时，通过减少段的数量提升了搜索的性能。
* 段合并完成后，索引大小会由于标记删除转成物理删除而有所缩减。

但是，要记住段合并也是有开销的：段合并引起的I/O操作可能会使系统变慢从而影响性能。因此，ElasticSearch允许用户自己设定合并策略和存储层面I/O限制。关于段合并策略相关的内容将在下节介绍，同时存储层面I/O限制相关的内容将在<b>第6章 对应突发事件</b>的<b>I/O阻塞解决方案</b>一节中介绍。

###选择正确的合并策略

尽管段合并是Apache Lucene分内的事儿，ElasticSearch还是开放了相关的配置参数，允许用户选择合并策略。目前有三种策略可供选择：
* `tiered`(默认选项)
* `log_byte_size`
* `log_doc`

上面提到的合并策略都还有各自的参数，这些参数可以覆盖默认值用来调整其行为(可以参考相关的章节来查看各个合并策略都有哪些参数可用)。

为了告诉ElasticSearch我们想用哪种合并策略，应该设置`index.merge.policy.type`值为我们希望设定的策略名称，例如：
`index.merge.policy.type:tiered`
