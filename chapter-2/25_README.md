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
<li>min:</li>
<li>max:</li>
<li>avg:</li>
<li>sum:</li>
</ul>

</p>
</div>
