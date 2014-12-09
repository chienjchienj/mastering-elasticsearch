## 查询结果的排序

当发送查询命令到ElasticSearch中，返回的文档集合默认会按照计算出来的文档打分排序(已经在本章的 Lucene的默认打分算法 一节中讲到)。这通常是用户希望的：结果集中的第一个文档就是查询命令想要的文档。然而，有的时候我们希望改变这种排序。这很简单，因为我们已经用过了单个字符串类型的数据。让我们看如下的样例：

```javascript
{
 "query" : {
 "terms" : {
 "title" : [ "crime", "front", "punishment" ],
 "minimum_match" : 1
 }
 },
 "sort" : [
 { "section" : "desc" }
 ]
}
```

上面的查询会返回所有title域中至少存在一个上述term的文档，并且会基于section域对文档排序。
我们也通过在sort中添加missing属性来处理当section 域没有值时的排序方式。例如，上面的查询语句中sort部分应该定义如下：

```javascript
{ "section" : { "order" : "asc", "missing" : "_last" }}
```


<h4>多值域排序</h4>
在0.90版本之前，ElasticSearch在多值域排序上存在问题。多值域排序出出现类似于如下的错误：[Can't sort on string types with more than one
value per doc, or more than one token per field]。实际上，多值域排序意义不大，主要是因为ElasticSearch不知道选择哪个值来排序。但是在ElasticSearch 0.90版本中，允许用户对多值域排序。比如，假定我们的数据包含release_dates域，该域可以包含一部电影的多个发行时间(比如在不同的国家)。如果使用Elasitcsearch 0.90版本，就可以用如下的查询命令实现排序：

```javascript
{
 "query" : {
 "match_all" : {}
 },
 "sort" : [
 {"release_dates" : { "order" : "asc", "mode" : "min" }}
 ]
}
```

注意在我们的例子中，query部分是冗余的，基于上是默认值，因此下面的例子中我们会省略这一部分。在本例中，ElasticSearch会选择每个文档中release_dates域中的最小值，然后基于该值对文档排序。mode参数能够设置如下的值：
<ul>
<li>min:升序排序的默认值，ElasticSearch选取每个文档中该域中的最小值</li>
<li>max:降序排序的默认值，ElasticSearch选取每个文档中该域中的最大值</li>
<li>avg:ElasticSearch选取每个文档中该域中所有值的平均值</li>
<li>sum:ElasticSearch选取每个文档中该域中所有值的和</li>
</ul>
注意，本来最后两个选项只能用于数值域，但是当前版本实现了在文本类型的域中使用该参数。但是最终结果不可预知，不推荐使用。

<h4>地理位置相关的多值域搜索</h4>
ElasticSearch 0.90.0RC2版本引入了一项新的功能，即对包含多个坐标点的域排序。这个特性的工作方式与前面提到的多值域是一样的，当然只是从用户的角度。下面通过一个例子深入了解其功能。假定我们希望搜索到给定城市中距离某个坐标点最近的地方(比如一个城市中有多个车站，我们希望找到离我们位置最近的车站)。假定，数据的mapping中有如下定义：

```javascript
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
```

接下来有一条简单的数据，如下：

```javascript
{ "country": "UK", "loc": ["51.511214,-0.119824", "53.479251,
-2.247926", "53.962301,-1.081884"] }
```

我们的查询命令也很简单，如下：

```javascript
{
"sort": [{
"_geo_distance": {
"loc": "51.511214,-0.119824",
"unit": "km",
"mode" : "min"
}
}]
}
```
可以看到上面的例子中，我们只有一个包含多个地理坐标点的文档。接下来基于该文档执行上面的查询命令，返回结果如下：

```javascript
{
    "took" : 21,
    "timed_out" : false,
    "_shards" : {
        "total" : 5,
        "successful" : 5,
        "failed" : 0
    },
    "hits" : {
    "total" : 1,
    "max_score" : null,
    "hits" : [ {
    "_index" : "map",
    "_type" : "poi",
    "_id" : "1",
    "_score" : null, "_source" : {
    "country": "UK", "loc": ["51.511214,-0.119824",
    "53.479251,-2.247926", "53.962301,-1.081884"] }
    ,
    "sort" : [ 0.0 ]
    } ]
    }
}
```

可以看到，该查询命令的结果集中sort部分如下："sort" : [ 0.0 ]。这是因为查询命令中的坐标点与文档中的一个坐标点是一样的。如果用户修改mode属性值为max，结果会变得不一样，高亮的部分就会变成："sort" : [ 280.4459406165739 ]。

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
<p style="font-size:13px;margin-top:10px;">
	ElasticSearch 0.90.1版本引入了在mode属性中使用avg来对地理距离排序的功能。
</p>
</div>
<div id="right" style="width:13px;height:100%;background:black;position:absolute;right:0px;padding:5px 0 5px 0;">
<img src="../notes/rm.png" height="100%" width="13px"/>
</div>
</div>  <!-- end of note structure -->

<h4>内嵌对象的排序</h4>
ElasticSearch 0.90版本中新引入的关于排序功能的最后知识点就是可以用内嵌对象中的域排序。使用内嵌文档中的域排序有两种方式：在内嵌mappings中明确指定(在mappings中使用type="nested")或者使用type对象，这两者稍微有些不同，需要用户记住。
假定索引中包含如下的数据：

```javascript
{
 "country": "PL", "cities": { "name": "Cracow", "votes": {
 "users": "A" }}
}
{
 "country": "EN", "cities": { "name": "York", "votes": [{"users":
 "B"}, { "users": "C" }]}
}
{
 "country": "FR", "cities": { "name": "Paris", "votes": {
 "users": "D"} }
}
```

可以看到，内嵌对象一层套一层，而且有些文档中还包含多值域(例如：多个votes)。
接下来关注如下的查询命令：

```javascript
{
 "sort": [{ "cities.votes.users": { "order": "desc", "mode":
 "min" }}]
}
```

上面的查询命令会使文档按照users中的最小值升序排序。但是，如果使用object类型的subdocument，可以简化查询命令如下：

```javascript
{
 "sort": [{ "users": { order: "desc", mode: "min" }}]
}
```

之所以可以简化查询是因为使用object类型时，整个object的结构在存储时可以作为一个单独的Lucene文档来存储。如果使用内嵌类型，ElasticSearch需要更精确的域信息，因为这些文档实际上各自是独立的Lucene 文档。有时使用nested_path属性会更方便，比如查询命令写成下面的样子：

```javascript
{
 "sort": [{ "users": { "nested_path": "cities.votes", "order":
 "desc", "mode": "min" }}]
}
```

请注意，用户还可以使用nested_filter参数，该参数只能用于内嵌文档中(明确标识为内嵌文档)。幸亏有这个参数，才使得用户可以在业务中使用从排序结果中排序文档的过滤器，而非从结果集中过滤文档的过滤器。


