# 第2章 强大的户查询语言DSL

在前面 的章节里，我们介绍了什么是Apache Lucene以及它的架构是怎样的，还有文件分析步骤的处理方式。此外，我们也明白了是Lucene查询语言是什么以及如何应用。我们也论述了ElasticSearch、它的架构和核心概念。在本章，我们将深入入探究ElasticSearch的Query DSL相关内容。在学习高级查询之前还是先了解一下Lucene的打分公式。通过本章内容的学习，我们将学习到：
<ul>
<li>Apache Lucene的打分公式是如何工作的</li>
<li>查询重写机制是什么</li>
<li>查询的重排序是如何工作的</li>
<li>在一个请求中如何发送多个近实时数据获取命令</li>
<li>在一个请求中如何发送多条查询语句</li>
<li>结果集中有内嵌文档和多值域文档时如何进行排序</li>
<li>如何更新已经添加到索引中的文档</li>
<li>如何使用filter机制优化我们的查询</li>
<li>如何在ElasticSearch的faceting功能中使用filters和scopes</li>
</ul>

