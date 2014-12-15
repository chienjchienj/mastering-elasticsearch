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
