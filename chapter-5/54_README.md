## 理解ElasticSearch缓存

<p>缓存对于已经配置好且正常工作的集群来说不过过多关注(这一条不仅适用于ElasticSearch)。缓存在ElasticSearch中扮演着重要的角色。通过缓存用户可以高效地存储过滤器的数据并且重复使用这些数据，比如高效地处理父子关系数据、faceting、对数据以索引中某个域来排序等等。在本节中，我们将详细研究filter cache和field data cache这些最重要的缓存，而且我们将会意识到理解缓存的工作原理对于集群的调优非常重要。 </p>
<h4>过滤器缓存</h4>
<p>过滤器缓存是负责缓存查询语句中过滤器的结果数据。比如，让我们来看如下的查询语句：</p>

```javascript
{
    "query" : {
        "filtered" : {
            "query" : {
                "match_all" : {}
            },
            "filter" : {
                "term" : {
                    "category" : "romance"
                }
            }
        }
    }
}
```
执行该查询语句将返回所有category域中含有term值为romcance的文档。正如读者如看到的那样，我们将match_all查询类型与过滤器结合使用。现在，执行一次查询语句后，每个有同样过滤条件的查询语句都会重复使用缓存中的数据，从而节约了宝贵的I/O和CPU资源。

<h4>过滤器缓存的类型</h4>
<p>在ElasticSearch中过滤器缓存有两种类型：索引级别和节点层面级别的缓存。所以基本上我们自己就可以配置过滤器缓存依赖于某个索引或者一个节点(节点是默认设置)。由于我们无法时时刻刻来猜测具体的某个索引会分配到哪个地方(实际上分配的是分片和分片副本)，也就无法预测内存的使用，因此不建议使用基于索引的过滤器。 </p>

<h4>index-level过滤器缓存的配置</h4>
<p>ElasticSearch允许用户使用如下的属性来配置index-level过滤器缓存的行为：
<ul>
<li>index.cache.filter.type:该属性用于指定缓存的类型，有resident,soft和weak，node(默认值)4个值可供选择。对于resident类型的缓存，JVM无法删除其中的缓存项，除非用户来删除(通过API,设置缓存的最大容量及失效时间都可以对缓存项进行删除)。推荐使用该缓存类型(因为填充过滤器缓存开销很大)。soft和weak类型的缓存能够在内存不足时，由JVM自动清除。当JVM清理缓存时，其操作会根据缓存类型而有所不同。它会首先清理引用比较弱的缓存项，然后才会是使用软引用的缓存项。node属性表示缓存将在节点层面进行控制(参考本章的<i>Node-level过滤器缓存配置</i>一节的内容)</li>
<li>index.cache.filter.max\_size: 该属性指定了缓存可以存储缓存项的数量(默认值是-1，表示数量没有限制)。读者需要记住，该设置项不适用于整个索引，只适用于索引分片上的一个段。所以缓存的内存使用量会因索引中分片(以及分片副本)的数量，还有索引中段的数量的不同而不同。通常情况下，默认没有容量限制的缓存适用于soft类型和致力于缓存重用的特定查询类型。  </li>
<li>index.cache.filter.expire:该属性指定了过滤器缓存中缓存项的失效时间，默认是永久不失效(所以其值设为-1)。如果希望一段时间类没有命中的缓存项失效，缓存项沉寂的最大时间。比如，如果希望缓存项在60分钟类没有命中就失效，设置该属性值为60m即可。 </li>
</ul>
</p>
<!-- note structure -->
<div style="height:80px;width:90%;position:relative;">
<div style="width:13px;height:100%; background:black; position:absolute;padding:5px 0 5px 0;">
<img src="../notes/lm.png" height="100%" width="13px"/>
</div>
<div style="width:51px;height:100%;position:absolute; left:13px; text-align:center; font-size:0;">
<img src="../notes/pixel.gif" style="height:100%; width:1px; vertical-align:middle;"/>
<img src="../notes/note.png" style="vertical-align:middle;"/>
</div>
<div id="mid" style="height:100%;position:absolute;left:65px;right:13px;">
<p style="font-size:13px;margin-top:10px;">想了解更多关于软引用和虚引用相关的内容，可以参考Java Document，特别是以下两类：http://docs.oracle.com/javase/7/docs/api/java/lang/ref/SoftReference.html 和 http://docs.oracle.com/javase/7/docs/api/java/lang/ref/WeakReference.html. </p>
</div>
<div id="right" style="width:13px;height:100%;background:black;position:absolute;right:0px;padding:5px 0 5px 0;">
<img src="../notes/rm.png" height="100%" width="13px"/>
</div>
</div>  <!-- end of note structure -->

<h4>Node-level过滤器缓存的配置</h4>
<p>让缓存作用于节点上，是ElasticSearch默认和推荐的设置。对于特定节点的所有分片，该设置都已经默认生效(设置index.chache.filter.type属性值为node,或者对此不作任何设置)。ElsticSearch允许用户通过indices.cache.filter.size属性来配置缓存的大小。用户可以使用百分数，比如20%(默认设置)或者具体的值，比如1024mb来指定缓存的大小。如果使用百分数，那么ElasticSearch会基于节点的heap 内存值来计算出实际的大小。 </p>
<p>node-level过滤器缓存是LRU类型的缓存(最近最少使用)，即需要移除缓存项来为新的缓存项腾出位置时，最长时间没有命中的缓存项将被移除。</p>

<h4>域数据缓存</h4>
<p>当查询命令中用到faceting功能或者指定域排序功能时，域数据缓存就会用到。使用该缓存时，ElasticSearch所做的就是将指定域的所有取值加载到内存中，通过这一步，ElasticSearch就可以提供文档域快速取值的功能。有两点需要记住：直接从硬盘上读取时，域的取值开销很大，这是因为加载整个域的数据到内存不仅需要I/O操作，还需要CPU资源。 </p>

<!-- note structure -->
<div style="height:110px;width:90%;position:relative;">
<div style="width:13px;height:100%; background:black; position:absolute;padding:5px 0 5px 0;">
<img src="../notes/lm.png" height="100%" width="13px"/>
</div>
<div style="width:51px;height:100%;position:absolute; left:13px; text-align:center; font-size:0;">
<img src="../notes/pixel.gif" style="height:100%; width:1px; vertical-align:middle;"/>
<img src="../notes/note.png" style="vertical-align:middle;"/>
</div>
<div id="mid" style="height:100%;position:absolute;left:65px;right:13px;">
<p style="font-size:13px;margin-top:10px;">读者需要记住，对于每个用来进行faceting操作或者排序操作的域，域的所有取值都要加载到内存中：一个Term都不能放过。这个过程开销很大，特别是对于基数比较大的域，这种域的term对象数目巨大。</p>
</div>
<div id="right" style="width:13px;height:100%;background:black;position:absolute;right:0px;padding:5px 0 5px 0;">
<img src="../notes/rm.png" height="100%" width="13px"/>
</div>
</div>  <!-- end of note structure -->

<h4>index-level过滤器缓存的配置</h4>
<p>与index-level过滤器缓存类似，我们也可以使用index-level域数据缓存，但是我们再说一次，不推荐使用index-level的缓存，原因还是一样的：哪个分片或者哪个索引分配到哪个节点是很难预测的。因此我们也无法预测每个索引使用到的内存有多少，这样容易出现内存溢出问题。 </p>
<p>然而，如果用户用户熟知系统底层，熟知业务特点，了解resident和soft域数据缓存，可以将index.fielddata.cache.type属性值为resident或者soft来启用index-level的域数据缓存。在前面的过滤器缓存中已经有过描述，resident属性的缓存无法由JVM自动移除，除非用户介入。如果使用index-level域数据缓存，推荐使用resident类型。重建域数据缓存开销巨大，而且会影响搜索性能。soft类型的域数据缓存可以在内存不足时由JVM自动移除。 </p>
<h4>Node-level过滤器缓存的配置</h4>
<p>ElasticSearch 0.90.0版本允许用户使用使用如下属性来设置node-level域数据缓存，如果用户没有修改配置，node-level域数据缓存是默认的类型。
<ul>
<li>indices.fielddata.cache.size:该属性有来指定域数据缓存的大小，可以使用百分数比如20%或者具体的数值，比如10gb。如果使用百分数，ElasticSearch会根据节点的最大堆内存值(heap memory)将百分数换算成具体的数值。默认情况下，域数据缓存的大小是没有限制的。 </li>
<li>indices.fielddata.cache.expire:该属性用来设置域数据缓存中缓存项的失效时间，默认值是-1，表示缓存项不会失效。如果希望缓存项在指定时间内不命中就失效的话，可以设置缓存项沉寂的最大时间。比如，如果希望缓存项60分钟内不命中就失效的话，就设置该属性值为60m.</li>
</ul>
</p>
<!-- note structure -->
<div style="height:80px;width:90%;position:relative;">
<div style="width:13px;height:100%; background:black; position:absolute;padding:5px 0 5px 0;">
<img src="../notes/lm.png" height="100%" width="13px"/>
</div>
<div style="width:51px;height:100%;position:absolute; left:13px; text-align:center; font-size:0;">
<img src="../notes/pixel.gif" style="height:100%; width:1px; vertical-align:middle;"/>
<img src="../notes/note.png" style="vertical-align:middle;"/>
</div>
<div id="mid" style="height:100%;position:absolute;left:65px;right:13px;">
<p style="font-size:13px;margin-top:10px;">如果想确保ElasticSearch应用node-level域数据缓存，用户可以设置index.fielddata.cache.type属性值为node，或者根本不设置该属性的值即可。</p>
</div>
<div id="right" style="width:13px;height:100%;background:black;position:absolute;right:0px;padding:5px 0 5px 0;">
<img src="../notes/rm.png" height="100%" width="13px"/>
</div>
</div>  <!-- end of note structure -->

<h4>域数据过滤</h4>
<p>除了前面提到的配置项，ElasticSearch还允许用户选择域数据加载到域数据缓存中。这在一些场景中很有用，特别是用户记得在排序和faceting时使用域缓存来计算结果。ElasticSearch允许用户使用两种类型过滤加载的域数据：通过词频，通过正则表达式，或者结合这两者。</p>
<p>样例之一就是faceting功能：用户可能想把频率比较低的term排除在faceting的结果之外，这时，域数据过滤就很有用了。比如，我们知道在索引中有一些term有拼写检查的错误，当然这些term的基数都比较低。我们不想因此影响faceting功能的计算，因此只能从数据集中移除他们：要么从从数据源中更改过来，要么通过过滤器从域数据缓存中去除。通过过滤，不仅仅是从ElasticSearch返回的结果中排除了这些数据，同时降低了内存的占用，因为过滤后存储在内存中的数据会更少。接下来了解一下过滤功能。</p>
<h4>添加域数据过滤的信息</h4>
<p>为了引入域数据过滤信息，我们需要在mappings域定义中添加额外的对象：fielddata对象以及它的子对象，filter。因此，以抽象的tag域为例，扩展后域的定义如下：</p>

```javascript
"tag" : {
    "type" : "string",
    "index" : "not_analyzed",
    "fielddata" : {
        "filter" : {
        ...
        }
    }
}
```
在接下来的一节中，我们将了解filter对象内部的秘密

<h4>通过词频过滤</h4>
<p>词频过滤功能允许用户加载频率高于指定最小值(min参数)并且低于指定最大值(max参数)的term。绑定到词频的min和max参数不是基于整个索引的，而是索引的每个段，这一点非常重要，因为不同的段词频会有不同。min和max参数可以设定成一个百分数(比如百分之一就是0.01，百分之五十就是0.5)或者设定为一个具体的数值。</p>
<p>此外，用户还可以设定min\_segment_size属性值，用于指定一个段应该包含的最小文档数。这构建域数据缓存时，低于该值的段将不考虑加载到缓存中。</p>
<p>比如，如果我们只想把满足如下条件的term加载到域数据缓存中：1、段中的文档数不少于100；2、段中词率在1%到20%之间。那么域就可以定义如下：</p>

```javascript
{
    "book" : {
        "properties" : {
            "tag" : {
                "type" : "string",
                "index" : "not_analyzed",
                "fielddata" : {
                    "filter" : {
                        "frequency" : {
                            "min" : 0.01,
                            "max" : 0.2,
                            "min_segment_size" : 100
                        }
                    }
                }
            }
        }
    }
}
```

<h4>通过正则表达式过滤</h4>
<p>除了可以通过词频过滤，还可以通过正则表达式过滤。比如有这样的应用场景：只有符合正则表达式的term才可以加载到缓存中。比如，我们只想把tag域中可能是Twitter标签(以#字符开头)的term加载到缓存中，我们的mappings就应该定义如下：</p>

```javascript
{
    "book" : {
        "properties" : {
            "tag" : {
                "type" : "string",
                "index" : "not_analyzed",
                "fielddata" : {
                    "filter" : {
                        "regex" : "^#.*"
                    }
                }
            }
        }
    }
}
```

<h4>通过正则表达式和词频共同过滤</h4>
<p>理所当然，我们可以将上述的两种过滤方法结合使用。因此，如果我们希望域数据缓存中tag域中存储满足如下条件的数据：
1、以#字符开头；2、段中至少有100个文档；3、基于段的词频介于1%和20%之间，我们应该定义如下的mappings:</p>

```javascript
{
    "book" : {
        "properties" : {
            "tag" : {
            "type" : "string",
            "index" : "not\_analyzed",
            "fielddata" : {
                "filter" : {
                    "frequency" : {
                        "min" : 0.1,
                        "max" : 0.2,
                        "min\_segment\_size" : 100
                    },
                    "regex" : "^#.*"
                    }
                }
            }
        }
    }
}
```

<!-- note structure -->
<div style="height:110px;width:90%;position:relative;">
<div style="width:13px;height:100%; background:black; position:absolute;padding:5px 0 5px 0;">
<img src="../notes/lm.png" height="100%" width="13px"/>
</div>
<div style="width:51px;height:100%;position:absolute; left:13px; text-align:center; font-size:0;">
<img src="../notes/pixel.gif" style="height:100%; width:1px; vertical-align:middle;"/>
<img src="../notes/note.png" style="vertical-align:middle;"/>
</div>
<div id="mid" style="height:100%;position:absolute;left:65px;right:13px;">
<p style="font-size:13px;margin-top:10px;">请记住域缓存不是在索引过程中构建的，因此可以在查询过程中重新构建，基于此，我们可以在系统运行过程中通过mappingsAPI更新fielddata部分的设置，然面，读者需要记住更新域数据加载过滤设置项后，缓存必须用相关的API清空。关于缓存清理API，可以在本章的<i>清空缓存</i>一节中了解到。</p>
</div>
<div id="right" style="width:13px;height:100%;background:black;position:absolute;right:0px;padding:5px 0 5px 0;">
<img src="../notes/rm.png" height="100%" width="13px"/>
</div>
</div>  <!-- end of note structure -->

<h4>过滤功能的一个例子</h4>
<p>接下来我们回到过滤章节开头的例子。我们希望排除faceting结果集中词频最低的term。在本例中，词频最低即频率低于50%的term，当然这个频率已经相当高了，只是我们的例子中只有4个文档。在真实产品中，你可能需要将词频设置得更低。为了实现这一功能，我们用如下的命令创建一个books索引：</p>

```javascript
curl -XPOST 'localhost:9200/books' -d '{
    "settings" : {
        "number\_of\_shards" : 1,
        "number\_of\_replicas" : 0
    },
    "mappings" : {
        "book" : {
            "properties" : {
                "tag" : {
                    "type" : "string",
                    "index" : "not\_analyzed",
                    "fielddata" : {
                        "filter" : {
                            "frequency" : {
                                "min" : 0.5,
                                "max" : 0.99
                            }
                        }
                    }
                }
            }
        }
    }
}'
```
接下来，通过批处理API添加一些样例文档：

```javascript
curl -s -XPOST 'localhost:9200/\_bulk' --data-binary '
{ "index": {"\_index": "books", "\_type": "book", "\_id": "1"}}
{"tag":["one"]}
{ "index": {"\_index": "books", "\_type": "book", "\_id": "2"}}
{"tag":["one"]}
{ "index": {"\_index": "books", "\_type": "book", "\_id": "3"}}
{"tag":["one"]}
{ "index": {"\_index": "books", "\_type": "book", "\_id": "4"}}
{"tag":["four"]}
'
```
接下来，运行一个查询命令来检测一个简单的faceting功能(前面已经介绍了域数据缓存的操作方法)：

```javascript
curl -XGET 'localhost:9200/books/_search?pretty' -d ' {
"query" : {
"match_all" : {}
},
"facets" : {
"tag" : {
"terms" : {
"field" : "tag"
}
}
}
}'
```
前面查询语句的返回结果如下：
```javascript
{
"took" : 2,
"timed\_out" : false,
"\_shards" : {
"total" : 1,
"successful" : 1,
"failed" : 0
},
.
.
.
"facets" : {
"tag" : {
"\_type" : "terms",
"missing" : 1,
"total" : 3,
"other" : 0,
"terms" : [ {
"term" : "one",
"count" : 3
} ]
}
}
}
```
可以看到，term faceting功能只计算了值为one的term,值为four的term忽略了。如果我们假定值为four的term拼写错误，那么我们的目的就达到了。


<h4>缓存的清空</h4>
<p>前面已经提到过，如果更改了域数据缓存的设置，在更新后清空缓存是至关重要的。同时，想更新一些用到确定缓存项的查询语句，清除缓存功能也是很有用的。ElasticSearch允许用户通过\_cache这个rest端点来清空缓存。该rest端点的使用方法随后介绍。</p>
<h4>单个索引、多个索引、整个集群缓存的清空</h4>
<p>我们能做的最简单的事就是通过如下的命令清空整个集群的缓存：</p>

```javascript
curl -XPOST 'localhost:9200/_cache/clear'
```
当然，我们也可以选择清空一个或者多个索引的缓存。比如，如果想清空mastering索引的缓存，应该运行如下的命令：
```javascript
curl -XPOST 'localhost:9200/mastering/_cache/clear'
```
同时，如果想清空mastering和books索引的缓存，应该运行如下的命令：
```javascript
curl -XPOST 'localhost:9200/mastering,books/_cache/clear'
```


<h4>清除指定类型的缓存</h4>
<p>除了前面提到的缓存清理方法，我们也可以只清理指定类型的缓存。可以清空如下类型的缓存：
<ul>
<li>filter:设置filter参数为true，该类型的缓存即可被清除。如果不希望此类型的缓存被清除，设置filter参数值为false即可。</li>
<li>field\_data:设置field\_data参数值为true，该类型的缓存即可被清除。如果不希望此类型的缓存被清除，设置field\_data参数值为false即可。</li>
<li>bloom:如果想清除bloom缓存(用于倒排表的布隆过滤器，在<i>第3章 索引底层控制</i>的<i>使用Codecs</i>一节中有介绍)，bloom参数值应该设置为true。。如果不希望此类型的缓存被清除，设置bloom参数值为false即可</li>
</ul>
例如，如果我们想清空mastering索引中的域数据缓存，同时保留过滤器缓存和没有接触到bloom缓存，运行如下的命令即可：</p>
```javascript
curl -XPOST 'localhost:9200/mastering/_cache/clear?field_data=true&filter
=false&bloom=false'
```

<h4>清除域相关的缓存</h4>
<p>除了可以清空所有的缓存，以及指定的缓存，我们还可以清除指定域的缓存。为了实现这一功能，我们需要在请求命令中添加fields参数，参数值为我们想清空的域,多个域用逗号隔开。例如，如果我们想清空mastering索引中title域和price域的缓存，运行如下的命令即可：
</p>
```javascript
curl -XPOST 'localhost:9200/mastering/\_cache/clear?fields=title,price'
```

