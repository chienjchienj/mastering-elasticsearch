## 查询结果的排序

<div style="text-indent:2em;">
<p>当发送查询命令到ElasticSearch中，返回的文档集合默认会按照计算出来的文档打分排序(已经在本章的 Lucene的默认打分算法 一节中讲到)。这通常是用户希望的：结果集中的第一个文档就是查询命令想要的文档。然而，有的时候我们希望改变这种排序。这很简单，因为我们已经用过了单个字符串类型的数据。让我们看如下的样例：
<blockquote>{
 "query" : {
 "terms" : {
 "title" : [ "crime", "front", "punishment" ],
 "minimum_match" : 1
 }
 },
 "sort" : [
 { "section" : "desc" }
 ]
}</blockquote>
上面的查询会返回所有title域中至少存在一个上述term的文档，并且会基于section域对文档排序。
我们也通过在sort中添加missing属性来处理当section 域没有值时的排序方式。例如，上面的查询语句中sort部分应该定义如下：
<blockquote>{ "section" : { "order" : "asc", "missing" : "_last" }}</blockquote>

</p>
<h4>多值域排序</h4>
<p>在0.90版本之前，ElasticSearch在多值域排序上存在问题。多值域排序出出现类似于如下的错误：[Can't sort on string types with more than one
value per doc, or more than one token per field]。实际上，多值域排序意义不大，主要是因为ElasticSearch不知道选择哪个值来排序。但是在ElasticSearch 0.90版本中，允许用户对多值域排序。比如，假定我们的数据包含release_dates域，该域可以包含一部电影的多个发行时间(比如在不同的国家)。如果使用Elasitcsearch 0.90版本，就可以用如下的查询命令实现排序：
<blockqoute>{
 "query" : {
 "match_all" : {}
 },
 "sort" : [
 {"release_dates" : { "order" : "asc", "mode" : "min" }}
 ]
}</blockquote>
注意在我们的例子中，query部分是冗余的，基于上是默认值，因此下面的例子中我们会省略这一部分。在本例中，ElasticSearch会选择每个文档中release_dates域中的最小值，然后基于该值对文档排序。mode参数能够设置如下的值：
<ul>
<li>min:升序排序的默认值，ElasticSearch选取每个文档中该域中的最小值</li>
<li>max:降序排序的默认值，ElasticSearch选取每个文档中该域中的最大值</li>
<li>avg:ElasticSearch选取每个文档中该域中所有值的平均值</li>
<li>sum:ElasticSearch选取每个文档中该域中所有值的和</li>
</ul>
注意，本来最后两个选项只能用于数值域，但是当前版本实现了在文本类型的域中使用该参数。但是最终结果不可预知，不推荐使用。
</p>

<h4>地理位置相关的多值域搜索</h4>
<p>ElasticSearch 0.90.0RC2版本引入了一项新的功能，即对包含多个坐标点的域排序。这个特性的工作方式与前面提到的多值域是一样的，当然只是从用户的角度。下面通过一个例子深入了解其功能。假定我们希望搜索到给定城市中距离某个坐标点最近的地方(比如一个城市中有多个车站，我们希望找到离我们位置最近的车站)。假定，数据的mapping中有如下定义：
<blockquote>
{
"mappings": {
"poi": {
"properties": {
"country": { "type": "string" },
"loc": { "type": "geo_point" }
}
}
}
}
</blockquote>
接下来有一条简单的数据，如下：
<blockquote>{ "country": "UK", "loc": ["51.511214,-0.119824", "53.479251,
-2.247926", "53.962301,-1.081884"] }</blockquote>
我们的查询命令也很简单，如下：
<blockquote>{
"sort": [{
"\_geo\_distance": {
"loc": "51.511214,-0.119824",
"unit": "km",
"mode" : "min"
}
}]
}<blockquote>
可以看到上面的例子中，我们只有一个包含多个地理坐标点的文档。接下来基于该文档执行上面的查询命令，返回结果如下：
<blockquote>
{
"took" : 21,
"timed_out" : false,
"\_shards" : {
"total" : 5,
"successful" : 5,
"failed" : 0
},
"hits" : {
"total" : 1,
"max\_score" : null,
"hits" : [ {
"\_index" : "map",
"\_type" : "poi",
"\_id" : "1",
"\_score" : null, "\_source" : {
"country": "UK", "loc": ["51.511214,-0.119824",
"53.479251,-2.247926", "53.962301,-1.081884"] }
,
<b>"sort" : [ 0.0 ]</b>
} ]
}
}
</blockquote>
可以看到，该查询命令的结果集中sort部分如下："sort" : [ 0.0 ]。这是因为查询命令中的坐标点与文档中的一个坐标点是一样的。如果用户修改mode属性值为max，结果会变得不一样，高亮的部分就会变成："sort" : [ 280.4459406165739 ]

</p>
</div>
