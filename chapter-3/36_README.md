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
一旦索引创建时指定了合并策略就不能更改。但是，合并策略中的其它参数可以通过索引更新的API来实时修改。
</p>
</div>
<div style="width:13px;height:100%;background:black;position:absolute;right:0px;padding:5px 0 5px 0;">
<img src="../notes/rm.png" height="100%" width="13px"/>
</div>
</div>  <!-- end of note structure -->

接下来，了解不同合并策略以及每个合并策略提供的功能。此后，我们将论述各个合并策略的相关参数情况。

####分层合并策略
这是ElasticSearch默认使用的合并策略。该策略将大小相似的段放在一起合并，当然段的数量会限制在每层允许的最大数量之中。依据每层允许的段数量的最大值，可以区分出一次合并中段的数量。在索引过程中，该合并策略将会计算索引中允许存在多少个段，这个值称为`budget`。如果索引中段的数量大于计算出的`budget`值，分层合并策略会首先按照段的大小(删除文档也会考虑在内)降序排序。随后会找出开销最小的合并方案，合并的开销计算会优先考虑比较小的段以及删除文档较多的段。


####字节大小对数合并策略

####文档数量对数合并策略


###合并策略配置

####分层合并策略

####字节大小对数合并策略

####文档数量对数合并策略

###合并计划
除了允许用户控制合并策略的行为，ElasticSearch还允许用户在需要进行段合并时规定合并策略的执行计划。ElasticSearch中有两种合并计划，默认的是`ConcurrentMergeScheduler`。
####并行合并计划
该合并计划会使用多线程来执行段的合并。该合并计划将为每个合并行为创建一个新的线程，直到线程数量的允许创建的上限。如果达到了线程数量的上限，但是又需要开启一个新的线程(段合并的需要)，所有的索引操作将会挂起，直到任意一次段合并行为完成。
为了控制允许创建线程的数量，我们可以修改`index.merge.scheduler.max_thread_count`属性。默认情况下，该值由如下的公式创建：
`maximum_value(1, minimum_value(3, available_processors / 2)`
因此，如果我们的系统中有8个可用的处理器，并行合并计划中允许设置的最大线程数为4。
####串行合并计划
这是一个只用一个线程进行段合并任务的简单合并计划。使用该计划会使段合并执行时，同个线程中正在进行的文档处理操作停止，说得明白点就是停止索引操作。
####设置想要的合并计划
为了设置想要的合并计划，用户需要设置index.merge.scheduler.type属性值为concurrent或serial。例如，如果想设置并行合并计划，用户应该设置如下的属性：
index.merge.scheduer.type: concurrent
如果想设置串行合并计划，用户应该设置如下的属性：
index.merge.scheduer.type: serial

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
当谈到段合并策略和合并计划，如果这些配置和过程能够可视化，那就非常直观了。如果有读者想了解Apache Lucene底层的合并过程，建议访问Mike McCandless的博客： http://blog.mikemccandless.com/2011/02/visualizinglucenes-segment-merges.html. 此外，ElasticSearch还有一个展示段合并过程的插件SegmentSpy。请访问下面的URL了解更多的相关信息：
https://github.com/polyfractal/elasticsearch-segmentspy
</p>
</div>
<div style="width:13px;height:100%;background:black;position:absolute;right:0px;padding:5px 0 5px 0;">
<img src="../notes/rm.png" height="100%" width="13px"/>
</div>
</div>  <!-- end of note structure -->
