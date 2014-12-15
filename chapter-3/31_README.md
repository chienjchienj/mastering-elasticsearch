##改变Lucene的打分模型

随着Apache Lucene 4.0版本在2012年的发布，这款伟大的全文检索工具包终于允许用户修改默认的基于TF/IDF原理的打分算法。Lucene API变得更加容易修改和扩展打分公式。但是，对于文档的打分计算，Lucene并只是允许用户在打分公式上修修补补，Lucene 4.0推出了更多的打分模型，从根本上改变了文档的打分公式，允许用户使用不同的打分公式来计算文档的得分。在本节，我们将深入了解Lucene 4.0的新特性，以及这些特性如何融入ElasticSearch。

###可用的相似度模型

前面已经提到，除了Apache Lucene 4.0以前版本中原来支持的默认相似度模型，TF/IDF模型同样支持。该模型在 <b>第2章 强大的用户查询语言DSL</b> 的 <b>Lucene 默认打分算法</b>一节中已经详细论述了。

新引入了三种相似度模型：

* Okapi BM25:这是一种基于概率模型的相似度模型，对于给定的查询语句，该模型会估计每个文档与查询语句匹配的概率。为了在ElasticSearch中使用该相似度模型，用户需要使用模型的名称，BM25。据说，Okapi BM25相似度模型最适合处理短文本，即关键词的重复次数对整个文档得分影响比较大的文本。
* Divergence from randomness:这是一种基于同名概率模型的相似度模型。想要在ElasticSearch使用该模型，就要用到名称，DFR。据说该相似度模型适用于自然语言类的文本。
* Information based:这是最后一个新引入的相似度模型，它与Diveragence from randomness模型非常相似。想要在ElasticSearch使用该模型，就要用到名称，IB。与DFR相似度模型类似，据说该模型也适用于自然语言类的文本。

<!-- note structure -->
<div style="height:90px;width:90%;position:relative;">
<div style="width:13px;height:100%; background:black; position:absolute;padding:5px 0 5px 0;">
<img src="../notes/lm.png" height="100%" width="13px"/>
</div>
<div style="width:51px;height:100%;position:absolute; left:13px; text-align:center; font-size:0;">
<img src="../notes/pixel.gif" style="height:100%; width:1px; vertical-align:middle;"/>
<img src="../notes/note.png" style="vertical-align:middle;"/>
</div>
<div style="height:100%;position:absolute;left:65px;right:13px;">
<p style="font-size:13px;margin-top:10px;">
上面提到的模型都需要相关的数据基础才能完全理解模型的原理，这些知识已经远远超出了本书的知识范围。如果希望了解这些模型的相关知识，请参考网页 http://en.wikipedia.org/wiki/Okapi\_BM25 了解关于 Okapi BM25相似度模型， 参考 http://terrier.org/docs/v3.5/dfr_description.html 了解DFR相似度模型。
</p>
</div>
<div style="width:13px;height:100%;background:black;position:absolute;right:0px;padding:5px 0 5px 0;">
<img src="../notes/rm.png" height="100%" width="13px"/>
</div>
</div>  <!-- end of note structure -->

###配置每个域的相似度模型

在ElasticSearch 0.90版本以后，用户就可以在mappings中为每个域设置不同的相似度模型。例如，假定我们用如下的简单的mapping来存储博客的帖子(mapping保存在posts_no_similarity.json文件中)：
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
我们希望将BM25相似度模型用于`name`域和`contents`域。为了实现这一点，我们扩展域的定义，将similarity属性以及选定的相似度模型的名称添加到mapping中。修改后的mappings(保存在posts_similarity.json文件中)如下：
```javascript
{
    "mappings" : {
        "post" : {
            "properties" : {
                "id" : { "type" : "long", "store" : "yes",
                "precision_step" : "0" },
                "name" : { "type" : "string", "store" : "yes", "index" :
                "analyzed", "similarity" : "BM25" },
                "contents" : { "type" : "string", "store" : "no", "index"
                : "analyzed", "similarity" : "BM25" }
            }
        }
    }
}
```
经过这样简单的设置就可以实现更换打分模型的目标了，简单就是这么任性。经过前面的修改后，Apache Lucene就会使用BM25相似度模型为文档的`name`域和`content`域打分了。

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
对于DFR模型和IB模型的配置，还需要一些额外的参数。如何设置将在本节下面部分的内容中呈现。
</p>
</div>
<div style="width:13px;height:100%;background:black;position:absolute;right:0px;padding:5px 0 5px 0;">
<img src="../notes/rm.png" height="100%" width="13px"/>
</div>
</div>  <!-- end of note structure -->
