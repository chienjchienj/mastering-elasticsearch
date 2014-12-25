# 了解垃圾收集器
由于ElasticSearch是基于Java语言的应用，所以它必须运行在Java虚拟机上。任何Java程序都被编译成字节码，然后才能运行在JVM上。用最常规的方式思考，可以想象JVM只是执行其它的程序，并且控制程序的行为。但是除非你是在为ElasticSearch开发新的插件(这部分的内容将在第9章 开发ElasticSearch插件中论述)，否则这不是你关注的重点。你需要关注的重点是垃圾收集器，JVM中负责内存管理的那部分。当一个对象不再被程序用到时，用垃圾收集器可以将对象从内存中删除，当内存不足时，垃圾收集器就开始工作。在本章，我们将学习如何配置垃圾收集器，如果避免内存交换，如何记录垃圾收集器的工作日志，如何利用垃圾收集器诊断程序的问题，最后将会学习几种Java工具的使用。

<!-- note structure -->
<div style="height:70px;width:90%;position:relative;">
<div style="width:13px;height:100%; background:black; position:absolute;padding:5px 0 5px 0;">
<img src="../notes/lm.png" height="100%" width="13px"/>
</div>
<div style="width:51px;height:100%;position:absolute; left:13px; text-align:center; font-size:0;">
<img src="../notes/pixel.gif" style="height:100%; width:1px; vertical-align:middle;"/>
<img src="../notes/note.png" style="vertical-align:middle;"/>
</div>
<div id="mid" style="height:100%;position:absolute;left:65px;right:13px;">
<p style="font-size:13px;margin-top:10px;">
读者可以从互联网上了解关于Java虚拟机架构的更多信息，比如，在维基百科: http://en.wikipedia.org/wiki/Java\_virtual\_machine
</p>
</div>
<div id="right" style="width:13px;height:100%;background:black;position:absolute;right:0px;padding:5px 0 5px 0;">
<img src="../notes/rm.png" height="100%" width="13px"/>
</div>
</div>  <!-- end of note structure -->

##Java内存模型

当我们用`Xms`和`Xmx`参数(或者`ES_MIN_MEN`和`ES_MAX_MEM`属性)来设定内存的容量时，实际上就是指定了Java虚拟机堆内存的最大值和最小值。堆内存是为Java程序预留的空间，所谓的Java程序在本文中即ElasticSearch节点。一个Java程序能够使用的堆内存绝对不会超过`Xmx`属性(或者`ES_MAX_MEM`属性)中设定的内存值。当程序新创建一个java对象，这个对象就存储在了堆内存中。如果长时间该对象没有被引用，垃圾收集器就会从堆内存中删除该对象，回收内存空间，给后来的对象使用。可以设想，如果没有足够的堆内存空间给java应用程序来生成对象，程序运行就会出问题，比如JVM就会抛出OutOfMemory异常，这个异常表明程序的内存使用出错了，原因可能是堆内存空间不足，或者程序出现内存溢出，没有释放无用的对象。
JVM的内存被划分成如下的区域：
* **Eden区域**：堆内存的一部分，JVM启动时，绝大多数的对象都分配到该区域。
* **Survivor区域**：堆内存的一部分，存储Eden区经过垃圾收集器扫描后幸存的对象。Survivor区分成0号survivor区和1号survivor区两个部分
* **tenured geneneration**：堆内存的一部分，存储在survivor区幸存一段时间的对象。
* **Permanent generation**：非堆内存区域，存储虚拟机自己的数据，比如生成对象的类和方法。
* **代码缓存区**：非堆内存区域，在HotSpot JVM中用于编译和存储本地方法。

上面的分类方法比较简单。eden区域和survivor区域又称为年轻代堆内存空间。tenured geneneration又称为老年代。

##java对象的生存周期和垃圾回收过程
