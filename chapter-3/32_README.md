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

