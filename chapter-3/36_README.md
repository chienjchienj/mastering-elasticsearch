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
这是ElasticSearch默认使用的合并策略。该策略将大小相似的段放在一起合并，当然段的数量会限制在每层允许的最大数量之中。依据每层允许的段数量的最大值，可以区分出一次合并中段的数量。在索引过程中，该合并策略将会计算索引中允许存在多少个段，这个值称为预算。如果索引中段的数量大于预算值，分层合并策略会首先按照段的大小(删除文档也会考虑在内)降序排序。随后会找出开销最小的合并方案，合并的开销计算会优先考虑比较小的段以及删除文档较多的段。
如果合并产生的段比`index.merge.policy.max_merged_segment`属性值更大，该合并策略将减少合并段的数量，以保持新段的大小在预算之下。这意味着，如果`index.merge.policy.max_merged_segment`属性值比较低，那么索引中段的数量就会比较多，查询的性能也就会比较低。用户应该根据应该程序的数量量，来监测并调整合并策略来满足业务需求。

####字节大小对数合并策略
这合并策略将创建由多个大小处于对数运算后大小在指定范围索引组成的索引。索引中存在数量较少的大段，同时也会有数量低于合并因子数(默认是10)的小段。读者可以想象较少的段处于同一个数量级，段的数量低于合并因子。当一个新段产生并且其大小与其它段不在一个数量级时，所有处于该数量级的段就会合并。索引中段的数量与经对数运算后新段字节大小成比例。该合并策略通常能够在使段合并开销最少的情况下将索引中段的数量保持在一个比较低的水平。
(译者注：由于每个段的大小区别比较大，对数计算即将比较大的数映射到小的区间中)。
####文档数量对数合并策略
该合并策略与`log_byte_size`合并策略类似，只是将以段的字节大小来计算的方式换成了文档数量。该合并策略适用于索引中文档大小差别不大或者用户希望每个段中文档的数量相近的场景。

###合并策略配置
现在我们已经了解合并策略的工作原理了，但是缺少配置相关的知识。因此接下来，我们来探讨一下每个合并策略中开放给用户的配置参数。请记住每个参数的默认值对绝大多数应用来说都是Ok的，只有在必要的时候才需要修改。
####分层合并策略
在`tiered`合并策略中，用户可以更改如下的配置项：
* `index.merge.policy.expunge_default_allowed`:默认值为10，该参数指定了段中删除文档的比例。当执行expungeDeletes方法(已经废弃)时，删除文档超过设定比例的段将被合并。
* `index.merge.policy.floor_segment`:该属性用于阻止碎片段的频繁刷新。小于或者等于该设定值的段将考虑被合并。默认值为2M。
* `index.merge.policy.max_merge_at_once`:该属性指定了索引过程中同一时刻用于合并的段的最大数量，默认为10。如果将值设置得更大，一次合并操作将合并更多的段，同时合并过程也需要更多的I/O资源。
* `index.merge.policy.max_merge_at_once_explicit`:该属性指定了在对索引进行optimize操作或者expungeDelete操作时一次合并的段的最大数量。默认值为30。该值不影响索引过程段的合并操作中段的最大数量。
* `index.merge.policy.max_merged_segment`:默认值为5GB，该属性指定了索引过程中单个段的最大容量。这个值是一个近似值，因为合并操作中，段的大小等于待合并段的总大小减去各个段中删除文档的大小。
* `index.merge.policy.segments_per_tier`:该属性指定了每层段的数量。较小的值带来较少的段。这意味着更多的合并操作，和更低索引性能。默认值为10，其值应该不低于`index.merge.policy.max_merge_at_once`属性值，否则就会使合并次数过多，引起性能问题。
* `index.reclaim_deletes_weight`:默认值为2.0，该属性指定了删除文档在合并操作中的重要程度。如果属性值设置为0，删除文档对合并段的选择没有影响。其值越高，表示删除文档在对待合并段的选择影响越大。(译者注：光从字面上无法理解其属性，看TieredMergePolicy源码中reclaimDeletesWeight成员变量更容易理解)
* `index.compund_format`:该属性值为Boolean类型，指定索引是否应该存储为压缩格式。默认情况下为false。如果设置为true,Lucene将会将将整个索引存储到一个文件中。该属性可用于系统出现文件句柄数量太多错误时使用，但是会降低搜索和索引的性能。
* `index.merge.async`:该属性值为Boolean类型，指定合并操作是否异步进行，默认值为true。
* `index.merge.async_interval`:当`index.merge.asnyc`值为true时(合并会异步进行)，该属性指定了两次合并操作的间隔。默认值为1s。请注意该属性值要尽量设置得低一点，以便于尽快实施合并操作，减少索引中段的数量。

####字节大小对数合并策略
在`log_byte_size`合并策略中，用户可以更改如下的配置项:
* `merge_factor`:指定了索引过程中段合并的频繁程度。`merge_factor`值越小，搜索就越快，内存使用也越小，但是会使索引的速度变慢。相反，其值越大，索引的速度就是越快(因为更少的合并操作)，但是搜索就会变慢，内存使用就会增多。建议在批量索引中使用较大的值，在普通索引操作中使用较小的值。
* `min_merge_size`:该属性定义了合并段的最小容量(整个段文件的字节数总和)。如果段的容量低于指定值，但是满足`merge_factor`的要求，该段就会被合并。默认值为1.6MB，且该属性对减少碎片段很有用。但是，如果属性值设置过高，会增加合并的开销。
* `max_merge_size`:该属性定义了合并段的最大容量(整个段文件的字节数总和)。默认情况下没有设置值。因此对段的最大容量没有限制。
* `maxMergeDocs`:该属性定义了合并段的最大文档数。默认情况下没有设置值。因此对段的最大文档数没有限制。
* `calibrate_size_by_deletes`:该属性值为Boolean类型，默认值为true，指定了标记删除文档的容量在计算段容量时应该予以考虑。
* `index.compund_format`:该属性值为Boolean类型，指定索引是否应该存储为压缩格式。默认情况下为false。其用法请参考`tiered`合并策略对此属性的解释。

上面提到的属性，都应该加上`index.merge.policy`前缀。因此，如果我们想设置`min_merge_docs`属性值，就应该使用`index.merge.policy.min_merge_docs`属性。
####文档数量对数合并策略
在`log_doc`合并策略中，用户可以更改如下的配置项
* `merge_factor`:与`log_byte_size`合并策略中的属性一样，请考虑该合并策略中对属性的解释。
* `min_merge_docs`:该属性定义了最小段的最小文档数。如果段的文档数低于该值，但是满足`merge_factor`属性条件，则段会被合并。属性的默认值为1000,且该属性对减少碎片段很有用。但是，如果属性值设置过高，会增加合并的开销。
* `max_merge_docs`:该属性定义了待合并段的最大文档数。默认情况下没有设置，因此对一个段中允许拥有的最大文档数量没有限制。
* `calibrate_size_by_deletes`:该属性值为Boolean类型，默认值为true，指定了标记删除文档的容量在计算段容量时应该予以考虑。
* `index.compund_format`:该属性值为Boolean类型，指定索引是否应该存储为压缩格式。默认情况下为false。其用法请参考`tiered`合并策略对此属性的解释。

与前面的合并策略类似，上面提到的属性，都应该加上`index.merge.policy`前缀。因此，如果我们想设置`min_merge_docs`属性值，就应该使用`index.merge.policy.min_merge_docs`属性。
此外，`log_doc`合并策略支持`index.merge.async`属性和`index.merge.async_interval`，用法与`tiered`合并策略一样。
###合并scheduler
除了允许用户控制合并策略的行为，ElasticSearch还允许用户在需要进行段合并时规定合并策略的执行计划。ElasticSearch中有两种合并scheduler，默认的是`ConcurrentMergeScheduler`。
####并行合并scheduler
该合并scheduler会使用多线程来执行段的合并。该合并scheduler将为每个合并行为创建一个新的线程，直到线程数量的允许创建的上限。如果达到了线程数量的上限，但是又需要开启一个新的线程(段合并的需要)，所有的索引操作将会挂起，直到任意一次段合并行为完成。
为了控制允许创建线程的数量，我们可以修改`index.merge.scheduler.max_thread_count`属性。默认情况下，该值由如下的公式创建：
`maximum_value(1, minimum_value(3, available_processors / 2)`
因此，如果我们的系统中有8个可用的处理器，并行合并scheduler中允许设置的最大线程数为4。
####串行合并scheduler
这是一个只用一个线程进行段合并任务的简单合并scheduler。使用该计划会使段合并执行时，同个线程中正在进行的文档处理操作停止，说得明白点就是停止索引操作。
####设置想要的合并scheduler
为了设置想要的合并scheduler，用户需要设置index.merge.scheduler.type属性值为concurrent或serial。例如，如果想设置并行合并scheduler，用户应该设置如下的属性：
index.merge.scheduer.type: concurrent
如果想设置串行合并scheduler，用户应该设置如下的属性：
index.merge.scheduer.type: serial

<!-- note structure -->
<div style="height:100px;width:90%;position:relative;">
<div style="width:13px;height:100%; background:black; position:absolute;padding:5px 0 5px 0;">
<img src="../notes/lm.png" height="100%" width="13px"/>
</div>
<div style="width:51px;height:100%;position:absolute; left:13px; text-align:center; font-size:0;">
<img src="../notes/pixel.gif" style="height:100%; width:1px; vertical-align:middle;"/>
<img src="../notes/note.png" style="vertical-align:middle;"/>
</div>
<div style="height:100%;position:absolute;left:65px;right:13px;">
<p style="font-size:13px;margin-top:10px;">
当谈到段合并策略和合并scheduler，如果这些配置和过程能够可视化，那就非常直观了。如果有读者想了解Apache Lucene底层的合并过程，建议访问Mike McCandless的博客： http://blog.mikemccandless.com/2011/02/visualizinglucenes-segment-merges.html. 此外，ElasticSearch还有一个展示段合并过程的插件SegmentSpy。请访问下面的URL了解更多的相关信息：
https://github.com/polyfractal/elasticsearch-segmentspy
</p>
</div>
<div style="width:13px;height:100%;background:black;position:absolute;right:0px;padding:5px 0 5px 0;">
<img src="../notes/rm.png" height="100%" width="13px"/>
</div>
</div>  <!-- end of note structure -->
