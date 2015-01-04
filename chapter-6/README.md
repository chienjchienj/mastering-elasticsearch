# 第6章 应对系统突发状况

在前面的章节中，我们深入讲解了ElasticSearch集群管理相关的内容。我们学习了如何选择合适的Lucene Directory实现类，了解对于某个具体的应用，究竟哪一种选择是正确的。我们也学习了ElasticSearch Discovery模块的工作方式，学习了什么是多播，什么是单播，以及如何应用亚马逊EC3 disvoery模块。此外，我们也了解了什么是Gateway模块，以及如何配置它的恢复机制。我们也用到了一些比较冷门的ElasticSearch API
，同时我们也了解了如何检测索引内部段的构成，以及段数据的可视化。最后，我们还学习了在ElasticSearch中，缓存类型是什么，都可用于哪些地方，如何配置它们，如何使用ElasticSearch API来清空缓存。在本章，读者将了解到：
* 什么是垃圾收集器，它是怎么工作的，以及如何诊断它引发的问题
* 如何使用ElasticSearch来控制I/O操作的数量
* 缓存预热是如何对查询命令加速，并用一个案例来演示
* 什么是hot thread，如何查看hot thread
* 在节点和集群出现问题时，哪些ElasticSearch API可以用来确定问题的所在
