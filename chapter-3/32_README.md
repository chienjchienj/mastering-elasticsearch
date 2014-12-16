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

使用TF/IDF相似度模型时，对用户开放的只有`discount_overlaps`一个属性，属性默认值为true。默认情况下，tokens的位置增量值为0(即它们都是重叠在一起的)，在计算文档得分时位置增量不会算在其中。如果我们希望位置增量用于文档得分，则需要配置`discount_overlaps`属性值为true。 注：可以参考DefaultSimilarity.lengthNorm()方法的源码。

###配置Okapi BM25相似度模型

使用Okapi BM25相似度模型时，有如下的参数可以配置：
* k1 参数(控制<b>饱和度(saturation)</b>，非线性的词频归一化参数),是一个浮点数。
* b 参数(控制词频影响文档长度的方式),是一个浮点数。
* discount_overlaps属性，用法与TF/IDF相似度模型一样。

###配置DFR相似度模型
使用DFR相似度模型时，有如下的参数可以配置：
* basic_model参数(取值范围为: be,d,g,if,in和ine)
* after_effect参数(取值范围为:no,b和l)
* normalization参数(聚会范围为:no,h1,h2,h3或z)

如果我们配置归一化参数值为除no外的其它值，我们需要设置归一化因子。归一化因子取决与我们选择的归一化方式。对于 h1 归一化方法，我们需要使用normalization.h1.c参数(float类型)。
对于 h2 归一化方法，我们需要使用normalization.h2.c参数(float类型)。对于 h3 归一化方法，我们需要使用normalization.h3.c参数(float类型)。对于 z 归一化方法，我们需要使用normalization.z.z参数(float类型)。下面的一段代码展示了相似度模型的配置样例：
```javascript
"similarity" : {
    "esserverbook_dfr_similarity" : {
        "type" : "DFR",
        "basic_model" : "g",
        "after_effect" : "l",
        "normalization" : "h2",
        "normalization.h2.c" : "2.0"
    }
}
```

###配置IB相似度模型

使用IB相似度模型，我们可以配置如下的参数：
* distribution属性(取值范围为ll或者spl)
* lambda属性(取值范围为df或者 tff)

此外，我们还可以选择DFR相似度模型中使用的归一化因子，这里就不再赘述。下面的一段代码展示了相似度模型的配置样例：
```javascript
"similarity" : {
    "esserverbook_ib_similarity" : {
        "type" : "IB",
        "distribution" : "ll",
        "lambda" : "df",
        "normalization" : "z",
        "normalization.z.z" : "0.25"
    }
}
```

