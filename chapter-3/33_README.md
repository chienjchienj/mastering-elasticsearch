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
* `plusing`:它将高基数域(数量而非顺序)的倒排表转换到terms数组中。这样在检索一个文档时，就可以避免频繁定位操作。在高基数域中，能够提高查询的效率。
* `direct`:

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

* `memory`:
* `bloom_defalut`:
* `bloom_plusing`:

