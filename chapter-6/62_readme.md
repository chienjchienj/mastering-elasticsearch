# I/O过载的应对方法——I/O限流

在第5章 管理ElasticSearch的 选择正确的directory实现类——存储模块 一节中讲到了存储类型，即用户可以根据业务需求来配置存储模块。但是我们并没有介绍存储模块的每一个知识点——至少没有介绍I/O限流的相关知识。

##控制I/O流量
