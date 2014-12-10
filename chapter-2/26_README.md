## update API

当往索引中添加新的文档到索引中时，底层的Lucene工具包会分析每个域，生成token流，token流过滤后就得到了倒排索引。在这个过程中，输入文本中一些不必要的信息会丢弃掉。这些不必要的信息可能是一些特殊词的位置(如果没有存储term vectors)，一些停用词或者用同义词代替的词，或者词尾(抽取词干时)。这也是为什么无法对Lucene中的文档进行修改，每次需要修改一个文档时，就必须把文档的所有域添加到索引中。ElasticSearch通过使用\_source这个代理域来存储和检索文档中的真实数据，以绕开前面的问题。当我们想更新文档时，ElasticSearch 会把数据存放在\_source域中，然后做出修改，最后把更新后的文档添加到索引中。当然，前提是_source域的这项特性必须生效。关于update，非常重要的一个限制就是文档更新命令只能更新一个文档，基于查询命令的文档更新还没有正式开放出来。

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

从API的角度来看，在发送请求到某个具体文档并带上\_update端点时，文档更新操作就会触发。比如，`/library/book/1/_update`。接下来看看用这项功能都能做些什么。
<br/>
本节接下来的内容都会使用如下命令索引的文档为例，来演示update的相关特性。文档索引命令如下：
```javascript
curl -XPUT localhost:9200/library/book/1 -d '{
"title": "The Complete Sherlock Holmes","author": "Arthur Conan
Doyle","year": 1936,"characters": ["Sherlock Holmes","Dr.
Watson", "G. Lestrade"],"tags": [],"copies": 0, "available" :
false, "section" : 12
}'
```

##简单的域更新操作

第一个演示案例就是更改选定文档的某个域。例如，看如下的命令：
```javascript
curl -XPOST localhost:9200/library/book/1/_update -d '{
    "doc" : {
        "title" : "The Complete Sherlock Holmes Book",
        "year" : 1935
    }
}'
```
在上面的命令中，我们修改了文档的两个域，`title`域和`year`域。当添加上面的文档到索引中时，ElasticSearch的回复内容如下：
```javascript
{"ok":true,"_index":"library","_type":"book","_id":"1","_version"2}
```
接下来看看文档的域是否更新成功，执行如下的命令：
```javascript
curl -XGET localhost:9200/library/book/1?pretty
```
命令的返回内容如下：
```javascript
{
"_index" : "library",
"_type" : "book",
"_id" : "1",
"_version" : 2,
"exists" : true, "_source" : {"title":"The Complete Sherlock
    Holmes Book","author":"Arthur Conan
    Doyle","year":1935,"characters":["Sherlock Holmes","Dr.
    Watson","G.
    Lestrade"],"tags":[],"copies":0,"available":false,
    "section":12}
}
```
可以看到在`_source`域中，`title`域和`year`域已经被更新了。接下来进入到下一个例子中，该例使用了脚本。

##使用脚本选择性更新域

有时，在修改文档过程中添加一些额外的判断逻辑会很有用，这也是ElasticSearch允许用户在update API中使用脚本的原因。比如，我们可以发送如下的请求：
```javascript
curl localhost:9200/library/book/1/_update -d '{
    "script" : "if(ctx._source.year == start_date)ctx._source.year
        = new_date; else ctx._source.year = alt_date;",
    "params" : {
        "start_date" : 1935,
        "new_date" : 1936,
        "alt_date" : 1934
    }
}'
```
可以看到，`script`域定义了对命令中文档的操作方式。脚本可以按照需求自行定义。用户同样可以引用`ctx`变量来获取文档的域。通常情况下，用户还可以在脚本中定义其它的变量。使用`ctx._source`,用户可更新现有的域，也可以创建新的域(如果用到了不存在的域，ElasticSearch会创建新的域)。域的创建也是实实在在发生在上例`ctx._source.year=new_date`脚本中。用户还可以使用remove()方法删除文档的域，比如：
```javascript
curl localhost:9200/library/book/1/_update -d '{
    "script" : "ctx._source.remove(\"year\");"
}'
```
##使用update API创建和删除文档

Update API不仅可以修改文档的某个域，同时也能用于操纵整个文档。`upsert`特性使得在定位到一个不存在的文档时，它会被创建出来。参考如下的命令：
```javascript
curl localhost:9200/library/book/1/_update -d '{
    "doc" : {
        "year" : 1900
    },
    "upsert" : {
        "title" : "Unknown Book"
    }
}'
```
如果文档(索引`library`中，type为`book`，id为1)存在，该命令将重置`year`域的值；否则文档将会被创建出来，新建的文档包含`upset`中定义的`title`域。当然，上面的命令还可以使用脚本，写成如下格式：
```javascript
curl localhost:9200/library/book/1/_update -d '{
"script" : "ctx._source.year = 1900",
    "upsert" : {
        "title" : "Unknown Book"
    }
}'
```
Update API中最后一点有趣的特性就是允许用户选择性地删除整个文档。该功能可以通过在命令中设置`ctx.op`值为`delete`来实现。比如，下面的命令就实现在从索引中删除文档的功能：
```javascript
curl localhost:9200/library/book/1/_update -d '{
    "script" : "ctx.op = \"delete\""
}'
```
当然，用户还可以使用脚本实现更复杂的逻辑来删除满足条件的文档。
