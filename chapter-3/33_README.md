##使用Codec机制

Apache Lucene 4.0 最大的改变就是可以改变索引文件的写入方式。在Lucene 4.0之前，如果我们想改变索引的写入方式，就不得不以补丁的方式嵌入到Lucene中。自从引入了弹性的索引架构，遇到需要改变倒排表结构的需求就再也不是问题了。

##简单的用例

可能有人会有这样的疑问，我们需要这种机制吗？默认的索引格式已经很好了，我们为什么要修改Lucene索引的写入方式？理由之一就是性能问题。有些域需要进行特殊的处理，像每条记录中唯一主键，如果进行一些特殊的处理，在搜索时就会很快，特别是与有多个不同值的数值域或者文本域的搜索相比。该特性也可以用来调试。使用SimpleTextCodec(
在Apache Lucene中使用，因为ElasticSearch没有开放该类型的codec)调试就可以了解Lucene索引写入的各种细节。

##看看Codec是如何工作的
假定我们为`posts`索引定义如下的mappings(保存在posts.json文件中):
```javascript
{
 "mappings" : {
     "post" : {
         "properties" : {
             "id" : { "type" : "long", "store" : "yes",
             "precision_step" : "0" },
             "name" : { "type" : "string", "store" : "yes", "index" :
             "analyzed" },
             "contents" : { "type" : "string", "store" : "no", "index"
             : "analyzed" }
         }
     }
 }
}
```
codec是以域为单位的。为了配置codec，需要添加一个名为postings_format的属性，属性值为为我们想添加的codec类型，比如，`pulsing`类型。因此引入提到的codec后，mappings文件中关于codec部分的片断如下：
<pre>
{
 "mappings" : {
     "post" : {
         "properties" : {
             <b>"id" : { "type" : "long", "store" : "yes", "precision_step" :
             "0", "postings_format" : "pulsing" },</b>
             "name" : { "type" : "string", "store" : "yes", "index" :
             "analyzed" },
             "contents" : { "type" : "string", "store" : "no", "index"
             : "analyzed" }
         }
     }
 }
}
</pre>

接下来如果执行如下的命令：
```javascript
curl -XGET 'localhost:9200/posts/_mapping?pretty'
```
来检验ElasticSearch中codec是否生效，我们将会看到如下的返回结果：
```javascript
{
 "posts" : {
     "post" : {
         "properties" : {
             "contents" : {
                "type" : "string"
             },
             "id" : {
                 "type" : "long",
                 "store" : true,
                 "postings_format" : "pulsing",
                 "precision_step" : 2147483647
             },
             "name" : {
                 "type" : "string",
                 "store" : true
             }
         }
     }
 }
}
```
可以看到，id域的配置是使用posting_format属性，这正是我们所希望看到的。

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
请记住，由于codec是Apache Lucene 4.0版本引入的，所以ElasticSearch 0.90前的版本不支持该属性。
</p>
</div>
<div style="width:13px;height:100%;background:black;position:absolute;right:0px;padding:5px 0 5px 0;">
<img src="../notes/rm.png" height="100%" width="13px"/>
</div>
</div>  <!-- end of note structure -->

##可用的倒排表格式

如下的倒排表格式可用：

* `default`: 如果没有明确指定使用哪种格式，那么就是它了。它提供了存储域和词向量的快速压缩。如果希望了解压缩相关的知识，可以参考  http://solr.pl/en/2012/11/19/solr-4-1-stored-fields-compression/.
* `plusing`:它将高基数域(数量而非顺序)的倒排表转换到terms数组中。这样在检索一个文档时，就可以避免频繁的定位操作。在高基数域中，使用该类型的Codec能够提高查询的效率。
* `direct`:该codec用于读取大量的terms到数组中，terms都以非压缩状态保存在内存中。对于频繁用到的域，使用该codec可以提升性能，但是需要注意的是，由于terms和倒排表都存储在内存中，很容易出现内存溢出的问题。

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
由于所有的terms都保存在byte数组中，每个段使用的内存可以达到2.1GB。
</p>
</div>
<div style="width:13px;height:100%;background:black;position:absolute;right:0px;padding:5px 0 5px 0;">
<img src="../notes/rm.png" height="100%" width="13px"/>
</div>
</div>  <!-- end of note structure -->

* `memory`:正如它的名字一样，该codec将所有的数据写到硬盘上，但是使用一种叫FST(Finite State Transducers)的数据结构把terms和倒排表读取到内存中。关于FST结构的更多信息，可以参考Mike McCandless 的博客 //blog.mikemccandless.com/2010/12/using-finite-state-transducers-in.html 。由于数据存储在内存中，对于频繁访问的terms，使用该Codec可以提升性能。
* `bloom_defalut`:这是`default`类型Codec的扩展版本，它添加了一个bloom filter(布隆过滤器，功能类似于Hash，但是超级节约内存)的功能。当读取数据时，它会被加载到内存中，用来快速检验某个值是否存在。该Codec对于类似于主键的高基数域非常有用。关于布隆过滤器的更多信息，可以参考：http://en.wikipedia.org/wiki/Bloom_filter 。需要记住，它就是在default类型Codec的基础上添加了bloom filter功能模块。
* `bloom_plusing`:这是`plusing`类型codec的扩展版本。就是在plusing类型Codec的基础上添加了bloom filter功能模块。

##配置codec的行为

对于绝大多数应用场景而言，各种倒排表结构的默认设置项中心满足业务需求了，但还是避免不了一些特殊情况，这时就需要改变默认的设置项以满足业务需求。ElasticSearch允许用户通过索引设置相关的API来配置codec。比如，如果想配置`default`类型的codec，命名为`custom_default`，就可以定义如下的mappings(保存在posts\_codec_custom.json文件中):
```javascript
{
    "settings" : {
        "index" : {
            "codec" : {
                "postings_format" : {
                    "custom_default" : {
                        "type" : "default",
                        "min_block_size" : "20",
                        "max_block_size" : "60"
                    }
                }
            }
        }
    },
    "mappings" : {
        "post" : {
            "properties" : {
                "id" : { "type" : "long", "store" : "yes",
                "precision_step" : "0" },
                "name" : { "type" : "string", "store" : "yes", "index" :
                "analyzed", "postings_format" : "custom_default" },
                "contents" : { "type" : "string", "store" : "no", "index"
                : "analyzed" }
            }
        }
    }
}
```
可以看到，我们改变了`default`类型的codec的`min_block_size`和`max_block_size`属性，同时我们也给新配置的codec命名为`custom_default`。然后，我们将它应用于`name`域数据的索引。

###Default类型codec的属性
当使用Defaults类型的codec时，可以使用如下的属性：
* `min_block_size`:它用来指定Lucene词典在编码数据块时，数据块的最小容量，默认值是25。
* `max_block_size`:它用来指定Lucene词典在编码数据块时，数据块的最大容量，默认值是48。
译者注：可以参考DefaultPostingsFormatProvider类的源码了解内部实现。

###Direct类型codec的属性
direct类型的codec允许用户配置如下的属性：
* `min_skip_count`:该属性指定了terms在写入跳跃表时共享前缀的最小值，默认为8。
* `low_freq_cutoff`:direct类型的codec将使用单个数组对象来存储文档频率低于本属性值的倒排索引和位置信息。默认值是32。
译者注：可以参考DirectPostingsFormatProvider类的源码了解内部实现。

###Memory类型codec的属性

使用`memory`类型的codec，可以修改如下的属性值：
* `pack_fst`:这是一个布尔类型的选项，默认值是false。指明存储倒排索引的内存结构是否要压缩到FST中。压缩到FST可以减少内存的消耗。
* `acceptable_overhead_ratio`:内部数据结构(FST)用到的压缩率，是一个float类型值，默认为0.2(在es-1.3.4版本中是0.25)。如果其值为0，导致的结果就是没有额外的内存开销，但是执行时间就会慢一些。如果其值为0.5，导致的结果就是有50%的额外内存开销，但是执行时间就会快一些。高于1的值系统也会接受，但是会导致比较高的额外内存使用。
译者注：可以参考MemoryPostingsFormatProvider类的源码了解内部实现。

###Pulsing类型codec的属性
如果使用`plusing`类型的codec，除了`default`类型允许配置的参数外，还可以配置一个：
* `freq_cut_off`:默认值为1。文档频率会决定倒排表是否写入到词典中。文档的频繁等于或者低于`freq_cut_off`时，文档将会被特殊处理。
译者注：由于涉及到Lucene的底层，故稍微有点复杂。这里应该是一种数据压缩的策略，针对大量长尾词。可参考PulsingPostingsFormatProvider类的源码了解内部实现。

###基于布隆过滤器codec的属性
如果希望用基于布隆过滤器的codec，则需要用到`bloom_filter`类型，并且可以设置如下的值：

* `delegate`:它指定了被布隆过滤器装饰的codec的名称。
* `ffp`:它的值区间为0和1.0。用来指定误报的概率(如果对BloomFilter的原理有了解，就能理解误报这一概念)。系统允许用户基于Lucene的索引段的文档数设定多个概率值。比如，默认值是 `10k=0.01,1m=0.03`，表明当每个段的文档数大于10.000时，创建的布隆过滤器误报率为0.01，当每个段的文档数量大于1.000.000时，创建的布隆过滤器误报率为0.03。


例如，我们可以像下面代码所示的那样，配置布隆过滤器基于`direct`类型的倒排表结构(代码保存在posts\_bloom_custom.json文件中):
```javascript
{
    "settings" : {
        "index" : {
            "codec" : {
                "postings_format" : {
                    "custom_bloom" : {
                        "type" : "bloom_filter",
                        "delegate" : "direct",
                        "ffp" : "10k=0.03,1m=0.05"
                    }
                }
            }
        }
    },
    "mappings" : {
        "post" : {
            "properties" : {
                "id" : { "type" : "long", "store" : "yes",
                "precision_step" : "0" },
                "name" : { "type" : "string", "store" : "yes", "index" :
                "analyzed", "postings_format" : "custom_bloom" },
                "contents" : { "type" : "string", "store" : "no", "index"
                : "analyzed" }
            }
        }
    }
}
```

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
我们已经提到，更新操作的时间开销和内存开销都很大。更新的时间段设置越长，索引速度越快。如果在整个索引过程中数据都不必对搜索可见，那么可以考虑关闭更新操作来换取高效的索引过程，设置index.refresh_interval 参数值为-1即可，记得在索引完成后改回原来的值。
</p>
</div>
<div style="width:13px;height:100%;background:black;position:absolute;right:0px;padding:5px 0 5px 0;">
<img src="../notes/rm.png" height="100%" width="13px"/>
</div>
</div>  <!-- end of note structure -->

###事务日志的配置

如果事务日志的默认配置无法满足业务需求，ElasticSearch允许用户在事务日志的处理上自己配置参数。如下的参数可以控制系统的事务日志行为，参数可以设置在elasticsearch.yml文件中，也可以用索引设置更新API来设置：
* `index.translog.flush_threshold_period`:
* `index.translog.flush_threshold_ops`:
* `index.translog.flush_threshold_size`:
* `index.translog.disable_flush`:


