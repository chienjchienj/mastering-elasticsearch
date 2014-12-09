## Lucene查询语言
<hr>
<p>ElasticSearch提供的一些查询方式(query types)能够被Lucene的查询解析器(query parser)语法所支持。由于这个原因，我们来深入学习Lucene查询语言，了解其庐山真面目吧。</p>

<h3>基础语法</h3>
<p>用户使用Lucene进行查询操作时，输入的查询语句会被分解成一个或者多个Term以及逻辑运算符号。一个Term，在Lucene中可以是一个词，也可以是一个短语(用双引号括引来的多个词)。如果事先设定规则：解析查询语句，那么指定的analyzer就会用来处理查询语句的每个term形成Query对象。</p>
<br/>
<p>一个Query对象中会存在多个布尔运算符，这些布尔运算符将多个Term关联起来形成查询子句。布尔运算符号有如下类型：
<hr style="height:4px;"/>
<ul>
    <li><span style="font-family:COURIER;">AND(与)</span>:给定两个Term(左运算对象和右运算对象)，形成一个查询表达式。只有两个Term都匹配成功，查询子句才匹配成功。比如：查询语句"apache AND lucene"的意思是匹配含apache且含lucene的文档。</li>
    <li><span style="font-family:COURIER;">OR(或)</span>:给定的多个Term，只要其中一个匹配成功，其形成的查询表达式就匹配成功。比如查询表达式"apache OR lucene"能够匹配包含“apache”的文档，也能匹配包含"lucene"的文档，还能匹配同时包含这两个Term的文档。</li>
    <li><span style="font-family:COURIER;">NOT(非)</span>: 这意味着对于与查询语句匹配的文档，NOT运算符后面的Term就不能在文档中出现的。例如：查询表达式“lucene NOT elasticsearch”就只能匹配包含lucene但是不含elasticsearch的文档。</li>
</ul>
<br/>
此外，我们也许会用到如下的运算符：
<ul>
    <li><b>+</b>这个符号表明：如果想要查询语句与文档匹配，那么给定的Term必须出现在文档中。例如：希望搜索到包含关键词lucene,最好能包含关键词apache的文档，可以用如下的查询表达式："+lucene apache"。</li>
    <li><b>-</b>这个符号表明：如果想要查询语句与文档匹配，那么给定的Term不能出现在文档中。例如：希望搜索到包含关键词lucene,但是不含关键词elasticsearch的文档，可以用如下的查询表达式："+lucene -elasticsearch"。</li>
</ul>
如果在Term前没有指定运算符，那么默认使用OR运算符。<br/>
此外，也是最后一点：查询表达式可以用小括号组合起来，形成复杂的查询表达式。比如：
    <center><span style="color:gray;font-family:COURIER;background-color:#F7F7F7;">elasticsearch AND (mastering OR book)</span></center>
</p>

<h3>多域查询</h3>
<p>当然，跟ElasticSearch一样，Lucene中的所有数据都是存储在一个个的Field中，多个Field形成一个Document。如果希望查询指定的Field,就需要在查询表达式中指定Field Name(此域名非彼域名)，后面接一个冒号，紧接着一个查询表达式。例如：查询title域中包含关键词elasticsearch的文档，查询表达式如下：
  <center><span style="color:gray;font-family:COURIER;background-color:#F7F7F7;">title:elasticsearch</span></center>
也可以把多个查询表达式用于一个域中。例如：查询title域中含关键词elasticsearch并且含短语“mastering book”的文档，查询表达式如下：
 <center><span style="color:gray;font-family:COURIER;background-color:#F7F7F7;">title:(+elasticsearch +"mastering book")</span></center>
 当然，也可以换一种写法，作用是一样的：
  <center><span style="color:gray;font-family:COURIER;background-color:#F7F7F7;">+title:elasticsearch +title:"mastering book")</span></center>

</p>

<h3>词语修饰符</h3>

<p>除了可以应用简单的关键词和查询表达式实现标准的域查询，Lucene还支持往查询表达式中传入修饰符使关键词具有变形能力。最常用的修饰符，也是大家都熟知的，就是通配符。Lucene支持?和\*两种通配符。?可以匹配任意单个字符，而\*能够匹配多个字符。
</p>


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
请注意出于性能考虑，默认的通配符不能是关键词的首字母。
</p>
</div>
<div style="width:13px;height:100%;background:black;position:absolute;right:0px;padding:5px 0 5px 0;">
<img src="../notes/rm.png" height="100%" width="13px"/>
</div>
</div>  <!-- end of note structure -->

<p>此外，Lucene支持模糊查询(fuzzy query)和邻近查询(proximity query)。语法规则是查询表达式后面接一个~符号，后面紧跟一个整数。如果查询表达式是单独一个Term，这表示我们的搜索关键词可以由Term变形(替换一个字符，添加一个字符，删除一个字符)而来，即与Term是相似的。这种搜索方式称为模糊搜索(fuzzy search)。在~符号后面的整数表示最大编辑距离。例如：执行查询表达式 "writer~2"能够搜索到含writer和writers的文档。</p>
<p>当~符号用于一个短语时，~后面的整数表示短语中可接收的最大的词编辑距离(短语中替换一个词，添加一个词，删除一个词)。举个例子,查询表达式title:"mastering elasticsearch"只能匹配title域中含"mastering elasticsearch"的文档，而无法匹配含"mastering book elasticsearch"的文档。但是如果查询表达式变成title:"mastering elasticsearch"~2,那么两种文档就都能够成功匹配了。</p></br>
<p>此外，我们还可以使用加权(boosting)机制来改变关键词的重要程度。加权机制的语法是一个^符号后面接一个浮点数表示权重。如果权重小于1，就会降低关键词的重要程度。同理，如果权重大于1就会增加关键词的重要程度。默认的加权值为1。可以参考<span style="font-style:oblique">&nbsp;第2章 活用用户查询语言&nbsp;</span>的<span style="font-style:oblique">&nbsp;Lucene默认打分规则详解&nbsp;</span>章节部分的内容来了解更多关于加权(boosting)是如何影响打分排序的。</p>

<p>除了上述的功能外，Lucene还支持区间查询(range searching),其语法是用中括号或者}表示区间。例如：如果我们查询一个数值域(numeric field)，可以用如下查询表达式：</p>
<p style="color:gray;font-family:COURIER;">price:[10.00 TO 15.00]</p>
<p>这条查询表达式能查询到price域的值在10.00到15.00之间的所有文档。</p>
<p>对于string类型的field，区间查询也同样适用。例如：</p>
<p style="color:gray;font-family:COURIER;">name:[Adam TO Adria]</p>
<p>这条查询表达式能查询到name域中含关键词Adam到关键词Adria之间关键词(字符串升序，且闭区间)的文档。</p>
<p>如果希望区间的边界值不会被搜索到，那么就需要用大括号替换原来的中括号。例如，查询price域中价格在10.00(10.00要能够被搜索到)到15.00(15.00不能被搜索到)之间的文档，就需要用如下的查询表达式：</p>

<p style="color:gray;font-family:COURIER;">price:[10.00 TO 15.00}</p>

<h3>处理特殊字符</h3>
<p>如果在搜索关键词中出现了如下字符集合中的任意一个字符，就需要用反斜杠(\\)进行转义。字符集合如下： +, -, &&, || , ! , (,) , { } , [ ] , ^, " , ~, *, ?, : , \, / 。例如，查询关键词 abc"efg 就需要转义成 abc\"efg。
</p>
