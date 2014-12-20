##深入了解文本处理流程

用ElasticSearch进行开发时，你可能会被ElasticSearch提供的不同的搜索方式和查询类型所困扰。每种查询类型的运行机制都不尽相同，我们不能浮于表面，比如，比较区间查询和前缀查询之间的不同点。理解query的工作原理并知晓它们之间的区别是至关重要的，特别是基于ElasticSearch进行业务开发时，比如，处理多语言的文本。

###不是所有的输入都会被分析

在探讨查询解析之间，我们先使用如下的命令创建一个索引
```javascript
curl -XPUT localhost:9200/test -d '{
 "mappings" : {
     "test" : {
         "properties" : {
            "title" : { "type" : "string", "analyzer" : "snowball" }
         }
     }
 }
}'
```
可以看到，索引结构相当简单。文档只有一个域，域会用名为snowball的分析器处理。接下来，索引一个简单的文档。运行如下的命令即可：
```javascript
curl -XPUT localhost:9200/test/test/1 -d '{
"title" : "the quick brown fox jumps over the lazy dog"
}'
```
基于这个简单小巧的索引，我们来测试各种查询。仔细观察下面的两条命令：
```javascript
curl localhost:9200/test/_search?pretty -d '{
 "query" : {
     "term" : {
        "title" : "jumps"
     }
 }
}'
curl localhost:9200/test/_search?pretty -d '{
 "query" : {
     "match" : {
        "title" : "jumps"
     }
 }
}'
```
第一个查询命令无法查询到我们添加到索引中的那个文档，但是第二个查询命令却查到了，这就有点让人不明所以了。你可能已经知道或者猜到这种结果与文本的分析过程有关。那么就让我们来把索引中的文本和我们查询命令中的文本进行一个对比吧。我们将用到Analyze API，命令如下：
```javascript
curl 'localhost:9200/test/_analyze?text=the+quick+brown+fox+jumps+over+the+lazy+dog&pretty&analyzer=snowball'
```

通过命令中的`_analyze`端点，用户可以查看输入的文本参数在ElasticSearch的处理结果，该命令也可以指定某个具体的分析器(`analyzer`参数)。
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
想了解Analyze API的其它功能可以参考
http://www.elasticsearch.org/guide/reference/api/admin-indices-analyze/.
</p>
</div>
<div style="width:13px;height:100%;background:black;position:absolute;right:0px;padding:5px 0 5px 0;">
<img src="../notes/rm.png" height="100%" width="13px"/>
</div>
</div>  <!-- end of note structure -->

执行上面的命令，ElasticSearch将返回如下结果：
```javascript
{
    "tokens" : [ {
        "token" : "quick",
        "start_offset" : 4,
        "end_offset" : 9,
        "type" : "<ALPHANUM>",
        "position" : 2
    }, {
        "token" : "brown",
        "start_offset" : 10,
        "end_offset" : 15,
        "type" : "<ALPHANUM>",
        "position" : 3
    }, {
        "token" : "fox",
        "start_offset" : 16,
        "end_offset" : 19,
        "type" : "<ALPHANUM>",
        "position" : 4
    }, {
        "token" : "jump",
        "start_offset" : 20,
        "end_offset" : 25,
        "type" : "<ALPHANUM>",
        "position" : 5
    }, {
        "token" : "over",
        "start_offset" : 26,
        "end_offset" : 30,
        "type" : "<ALPHANUM>",
        "position" : 6
    }, {
        "token" : "lazi",
        "start_offset" : 35,
        "end_offset" : 39,
        "type" : "<ALPHANUM>",
        "position" : 8
    }, {
        "token" : "dog",
        "start_offset" : 40,
        "end_offset" : 43,
        "type" : "<ALPHANUM>",
        "position" : 9
    } ]
}
```
从结果中可以了解到ElasticSearch是如何将输入的文本转变成一个个的Token。可能读者已经从<b>第一章 介绍Apache Lucene</b>的<b>介绍 ElasticSearch</b>一节中了解到每个Token包含关键词在原始文本中的位置信息、关键词的类型(关键词的类型信息在本节没有什么用处，但是可以用到过滤器中)，关键词自身，关键词会存储在索引中，在搜索时与查询词进行对比。上例中的原始文本:`the quick brown fox jumps over the lazy dog`被转变成如下的词:`quick, brown, fox, jump, over, lazi`(这个很有意思),还有`dog`。因此，我们总结名为snowball的分析器(analyzer)对文本的处理方式如下：
* 略过没有意义的词,即停用词(the)
* 将词转变成原型(jump)
* 有时也会做不合理的转变(lazi)

只要能把同样的词转变成同样的形式，分析器的第三点处理方式也没看上去那么差。因为无论如何，词干化的目的达到了。ElasticSearch只会考虑查询词和索引中的词是否匹配，而不管词处于何种形式。 但是在我们的例子中，查询命令只会基于给定的搜索词(jumps)进行搜索，而搜索词在索引中不存在(索引中是jump)。然而在match query的例子中，输入的文本会先传给分析器，分析器会将jumps转换成jump，经过转换后的词才会用于搜索。

我们再看一个例子：
```javascript
curl localhost:9200/test/_search?pretty -d '{
    "query" : {
        "prefix" : {
            "title" : "lazy"
        }
    }
}'
curl localhost:9200/test/_search?pretty -d '{
    "query" : {
        "match_phrase_prefix" : {
            "title" : "lazy"
        }
    }
}'
```
例子中的两个查询相似，但是我们会再一次看到第一个查询命令的结果为空(因为lazy与索引中的lazi不匹配)，而第二个查询命令，查询词会经过分析，返回了索引中的文档。

###Analyzer的用法示例

上面的测试都很有意思，读者需要记住的是在ElasticSearch中，有些查询会经分析，有些则不会。查询分析或者不分析，关键点在于我们怎么去有意识地优化应用程序中的搜索模块。

假定我们需要搜索书本中的内容，有些人可能会搜索书中角色的名字，或者地名，或者直接引用文本片段。由于应用程序中没有自然语言分析的功能模块，因此我们无法得知用户输入文本所表达的含义。但是，在某种程度上，我们可以认为与用户输入完全匹配的结果肯定是用户最感兴趣的结果。居于次要地位的是，如果文档中的文本与用户输入的文本用的是同一种语言，那么匹配度会高一些。

我们来创建一个只有一个域的简单索引，来演示上面所描述的情况，命令如下：
```javascript
curl -XPUT localhost:9200/test -d '{
    "mappings" : {
        "test" : {
            "properties" : {
                "lang" : { "type" : "string" },
                "title" : {
                "type" : "multi_field",
                "fields" : {
                    "i18n" : { "type" : "string", "index" : "analyzed",
                    analyzer : "english" },
                    "org" : { "type" : "string", "index" : "analyzed",
                    "analyzer" : "standard"}
                    }
                }
            }
        }
    }
}'
```
索引中只有一个域，但是由于是`multi_field`类型，所以采用了两种分析方式：`standard`分析器(域`title.org`)，以及`english`分析器(域`title.i18n`)，通过`english`分析器将输入文本转换成其原形。如果用下面的命令索引一个样例文档：
```javascript
curl -XPUT localhost:9200/test/test/1 -d '{ "title" : "The quick brown fox jumps over the lazy dog." }'
```
那么在`title.org`域中将存在`jumps`关键词，在`title.i18n`域将存在`jump`关键词。接下来，运行如下的查询命令：
```javascript
curl localhost:9200/test/_search?pretty -d '{
    "query" : {
        "multi_match" : {
            "query" : "jumps",
            "fields" : ["title.org^1000", "title.i18n"]
        }
    }
}'
```
由于对`title.org`域进行了加权，加之匹配到了`jumps`关键词，索引中的文档将会获得比较高的得分。由于`title.i18n`中的jump关键词，所以`field.i18n`也对得分有贡献，但是贡献很小，因为我们没有指定加权的数值，所以使用默认值1。

###改变索引过程的分析器
关于多语言数据的处理，另一点值得一提的是在索引过程中动态改变分析器的功能。我们将前面的mappings修改一下，添加`_analyzer`部分：
```javascript
curl -XPUT localhost:9200/test -d '{
    "mappings" : {
        "test" : {
            "_analyzer" : {
                "path" : "lang"
            },
          "properties" : {
            "lang" : { "type" : "string" },
            "title" : {
                "type" : "multi_field",
                    "fields" : {
                        "i18n" : { "type" : "string", "index" : "analyzed"},
                        "org" : { "type" : "string", "index" : "analyzed","analyzer" : "standard"}
                    }
                }
            }
        }
    }
}'
```
我们所做的改变就是让ElasticSearch基于待处理文本的内容选择分析器。`path`参数是文档域的值，其中包含了分析器的名称。第二个改变是删除了`field.i18n`中定义的分析器。接下来就可以用如下的索引命令：
```javascript
curl -XPUT localhost:9200/test/test/1 -d '{ "title" : "The quick brownfox jumps over the lazy dog.", "lang" : "english" }'
```
执行上面的命令，EalsticSearch就会根据`lang`对应的值来选择相应的分析器处理该文档。这一功能在用户希望不同的文档使用不同的分析方式时很有用(比如，有些文档应该除去停用词，有些则该保留)。
###改变搜索过程中的分析器

在查询期间改变分析器也是可以的，通过使用`analyzer`属性即可。比如，看下面的查询命令：
<pre>
curl localhost:9200/test/_search?pretty -d '{
    "query" : {
        "multi_match" : {
            "query" : "jumps",
            "fields" : ["title.org^1000", "title.i18n"],
            <b>"analyzer": "english"</b>
        }
    }
}'
</pre>
正是由于上面的高亮片段，ElasticSearch才会选择在命令中指定的分析器。

###分析器相关的陷阱以及默认分析器
将索引期间和搜索期间给每个文档替换分析器的功能融合到应用中是一个非常强大的功能，但是也会引入难以解释的问题。其中的一个就是如下指定的分析器不存在，在这种情况下，ElasticSearch会使用默认分析器。即便这样，有些问题还是难以解释，因为默认的分析器可以通过相关的插件修改。因此，确定默认分析器很有必要。一般自定义的分析器最好取一个新的名字，与默认分析器区别开。

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
作为备选方案，你可以指定default\_index analyzer和default\_search analyzer，这样在索引和搜索时ElasticSearch就会使用相应的分析器，而不会混淆。
</p>
</div>
<div style="width:13px;height:100%;background:black;position:absolute;right:0px;padding:5px 0 5px 0;">
<img src="../notes/rm.png" height="100%" width="13px"/>
</div>
</div>  <!-- end of note structure -->

