## 使用filters优化查询

ElasticSearch支持多种不同类型的查询方式，这一点大家应该都已熟知。但是在选择哪个文档应该匹配成功，哪个文档应该呈现给用户这一需求上，查询并不是唯一的选择。ElasticSearch 查询DSL允许用户使用的绝大多数查询都会有各自的标识，这些查询也以嵌套到如下的查询类型中：
*   `constant_score`
*   `filterd`
*   `custom_filters_score`

那么问题来了，为什么要这么麻烦来使用filtering？在什么场景下可以只使用queries？ 接下来就试着解决上面的问题。


### 过滤器(Filters)和缓存

首先，正如读者所想，filters来做缓存是一个很不错的选择，ElasticSearch也提供了这种特殊的缓存，filter cache来存储filters得到的结果集。此外，缓存filters不需要太多的内存(它只保留一种信息，即哪些文档与filter相匹配)，同时它可以由其它的查询复用，极大地提升了查询的性能。设想你正运行如下的查询命令：
```javascript
{
    "query" : {
        "bool" : {
            "must" : [
            {
                "term" : { "name" : "joe" }
            },
            {
                "term" : { "year" : 1981 }
            }
            ]
        }
    }
}
```
该命令会查询到满足如下条件的文档：`name`域值为`joe`同时`year`域值为`1981`。这是一个很简单的查询，但是如果用于查询足球运动员的相关信息，它可以查询到所有符合指定人名及指定出生年份的运动员。

如果用上面命令的格式构建查询，查询对象会将所有的条件绑定到一起存储到缓存中；因此如果我们查询人名相同但是出生年份不同的运动员，ElasticSearch无法重用上面查询命令中的任何信息。因此，我们来试着优化一下查询。由于一千个人可能会有一千个人名，所以人名不太适合缓存起来；但是年份比较适合(一般`year`域中不会有太多不同的值，对吧？)。因此我们引入一个不同的查询命令，将一个简单的query与一个filter结合起来。
```javascript
{
    "query" : {
        "filtered" : {
            "query" : {
                "term" : { "name" : "joe" }
            },
            "filter" : {
                "term" : { "year" : 1981 }
            }
        }
    }
}
```
我们使用了一个filtered类型的查询对象，查询对象将query元素和filter元素都包含进去了。第一次运行该查询命令后，ElasticSearch就会把filter缓存起来，如果再有查询用到了一样的filter，就会直接用到缓存。就这样，ElasticSearch不必多次加载同样的信息。
###并非所有的filters会被默认缓存起来

缓存很强大，但实际上ElasticSearch在默认情况下并不会缓存所有的filters。这是因为部分filters会用到域数据缓存(field data cache)。该缓存一般用于按域值排序和faceting操作的场景中。默认情况下，如下的filters不会被缓存：

* numeric_range
* script
* geo_bbox
* geo_distance
* geo\_distance_range
* geo_polygon
* geo_shape
* and
* or
* not

尽管上面提到的最后三种filters不会用到域缓存，它们主要用于控制其它的filters，因此它不会被缓存，但是它们控制的filters在用到的时候都已经缓存好了。

###更改ElasticSearch缓存的行为

ElasticSearch允许用户通过使用\_chache和\_cache\_key属性自行开启或关闭filters的缓存功能。回到前面的例子，假定我们将关键词过滤器的结果缓存起来，并给缓存项的key取名为`year_1981_cache`，则查询命令如下：
```javascript
{
    "query" : {
        "filtered" : {
            "query" : {
                "term" : { "name" : "joe" }
            },
            "filter" : {
                "term" : {
                    "year" : 1981,
                    "_cache_key" : "year_1981_cache"
                }
            }
        }
    }
}
```

也可以使用如下的命令关闭该关键词过滤器的缓存：
```javascript
{
    "query" : {
        "filtered" : {
            "query" : {
                "term" : { "name" : "joe" }
            },
            "filter" : {
                "term" : {
                    "year" : 1981,
                    "_cache" : false
                }
            }
        }
    }
}
```

###为什么要这么麻烦地给缓存项的key取名

上面的问题换个说法就是，我有是否有必要如此麻烦地使用\_cache\_key属性，ElasticSearch不能自己实现这个功能吗？当然它可以自己实现，而且在必要的时候控制缓存，但是有时我们需要更多的控制权。比如，有些查询复用的机会不多，我们希望定时清除这些查询的缓存。如果不指定\_cache_key，那就只能清除整个过滤器缓存(filter cache)；反之，只需要执行如下的命令即可清除特定的缓存：
```javascript
curl -XPOST 'localhost:9200/users/_cache/clear?filter_keys=year_1981_cache'
```

###啥时该改变ElasticSearch 过滤器缓存的行为


