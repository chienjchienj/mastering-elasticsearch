##相似度模型的配置

既然已经了解了如何为索引的每个域设置相似度模型，接下来就了解如何根据需要来配置相似度模型的参数，不用担心，操作非常简单。我们所需要做的就是在索引settgings中添加similarity对象。例如，如下的配置文本(该样例已经保存在posts_custom_similarity.json文件中):
```javascript
{
    "settings" : {
        "index" : {
            "similarity" : {
                "mastering_similarity" : {
                    "type" : "default",
                    "discount_overlaps" : false
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
                "analyzed", "similarity" : "mastering_similarity" },
                "contents" : { "type" : "string", "store" : "no", "index"
                : "analyzed" }
            }
        }
    }
}
```

我们可以在索引中配置多个相似度模型，然而还是先把注意力集中到上面只配置一个模型的例子中。在例子中，我们定义了一个新的相似度模型，命名为`mastering_similarity`，当然它是基于默认的TF/IDF模型。我们同时设置了模型的`discount_overlaps`参数值为false。我们将该模型用于name域中。本节稍后将论述哪些属性可以用于不同的模型，先了解如何替换ElasticSearch的默认相似度模型。

###选择默认的相似度模型

为了替换系统默认的相似度模型，我们需要用到一个名为`default`的配置参数。例如，如果我们希望将上面设置的`mastering_similarity`模型设置为系统的默认相似度模型，就需要将前面的配置改为如下(整个样例配置保存在posts\_default_similarity.json文件中)：
```javascript
{
    "settings" : {
        "index" : {
            "similarity" : {
                "default" : {
                    "type" : "default",
                    "discount_overlaps" : false
                }
            }
        }
    },
    ...
}
```

由于`query norm`和`coord`因子(两个因子的作用在<b>第2章 强大的用户查询语言 DSL</b>的<b>Lucene默认的打分算法 </b>有解析说明)在打分模型中是全局的，而且是从`default`类型的相似度模型中取得，ElasticSearch允许用户按需自行修改。

为了能够修改这两个因子，我们需要定义另一个相似度模型参数，命名为`base`。除了名字与`default`参数不一样外，其用法并无二致。样例配置如下(整个样例保存在posts_base_similarity.json文件中)：
<pre>
{
     "settings" : {
         "index" : {
             "similarity" : {
                 "<b>base</b>" : {
                     "type" : "default",
                     "discount_overlaps" : false
                 }
             }
         }
     },
     ...
}
</pre>
如果`base`相似度参数出现在配置中，ElasticSearch就会使用它配置的相似度模型来计算`query norm`和`coord`两个因子，而文档得分则可用其它的相似度模型来计算。

###配置选定的相似度模型

每个新添加的相似度模型可以根据需求来配置。ElasticSearch 允许用户不作任何配置使用`default`和BM25相似度模型，因为他们是预先在系统中配置好的。如果是DFR和IB模型，我们需要配置才能使用他们。接下来来了解一下ElasticSearch提供了哪些相似度模型相关的参数。

###配置TF/IDF相似度模型

###配置Okapi BM25相似度模型

###配置DFR相似度模型

###配置IB相似度模型


