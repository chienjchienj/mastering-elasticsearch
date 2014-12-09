## 节点发现模块的配置
<div style="text-indent:2em;">
<p>我们已经多次提到，ElasticSearch创建的目的就是对应集群工作环境。这是跟与ElasticSearch功能类似的其它开源解决方案(比如solr)主要的不同点。其它解决方案也许同样能或难或易地应用于多节点的分布式环境，但是对对于ElasticSearch来说，工作在分布式环境就是它每天的生活。由于节点发现机制，它最大程度简化了集群的 安装和配置。</p>
<p>该发现机制主要基于以下假设：
集群由cluster.name设置项相同的节点自动连接而成。这就允许了同一个网段中存在多个独立的集群。自动发现机制的缺点在于：如果有人忘记改变cluster.name的设置项，无意中连接到其它的某个集群。在这种情况下，ElasticSearch可能出于重新平衡集群状态的考虑，将一些数据移动到了新加入的节点。当该节点被关闭，节点所在的集群中会有部分数据像出现魔法一样凭空消失。 </p>

<h4>Zen 发现机制</h4>
<p>Zen 发现机制是ElasticSearch中默认的用来发现新节点的功能模块，而且集群启动后默认生效。Zen发现机制默认配置是用多播来寻找其它的节点。对于用户而言，这是一极其省事的解决方案：只需启动新的ElasticSearch节点即可，如果各个模块工作正常，该节点就会自动添加到与节点中集群名字(cluster.name)一样的集群，同时其它的节点都能感知到新节点的加入。如果节点添加不进去，你就应该检查节点的publish_host属性或者host属性的设置，来确保ElasticSearch在监听合适的网络端口。 </p>
<p>
有时由于某些原因，多播无法使用或者由于前面提到的一些原因，你不想使用它。在比较大的集群中，多播发现机制可能会产生太多不必要的流量开销，这是不使用多播的一个充分理由。在这种情况下，Zen发现机制引入了第二种发现节点的方法：单播模式。让我们在这个知识点上停留一段时间，了解这些模式的配置相关知识。
</p>
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
<p style="font-size:13px;margin-top:10px;">如果想知道关于单播和多播ping方法更多的不同点，请参考:http://en.wikipedia.org/wiki/Multicastand http://en.wikipedia.org/wiki/Unicast. </p>
</div>
<div id="right" style="width:13px;height:100%;background:black;position:absolute;right:0px;padding:5px 0 5px 0;">
<img src="../notes/rm.png" height="100%" width="13px"/>
</div>
</div>  <!-- end of note structure -->

<h4>多播</h4>
<p>前面已经提到，这是默认的网络传输模式。当节点并非集群的一部分时(比如节点只是刚刚启动或者重启 )，它会发送一个多播的ping请求到网段中，该请求只是用来通知所有能连接到节点和集群它已经准备好加入到集群中。关于多播发送，Zen发现模块暴露出如下的设置项：
<ul>
<li>discovery.zen.ping.multicast.address(默认是所有的网络接口):属性值是接口的地址或者名称。</li>
<li>discovery.zen.ping.multicast.port(默认是54328):端口用于网络通信。</li>
<li>discovery.zen.ping.multicast.group(默认是:224.2.2.4):代表多播通信的消息接收地。</li>
<li>discovery.zen.ping.multicast.buffer\_size(默认是:2048byte):</li>
<li>discovery.zen.ping.multicast.ttl(默认是3):它代表多播信息的生存时间。只要数据包通过的路由，TTL值就废弃了。通过该参数可以限制信息接收的区域。注意路由器可以指定一个类似于TTL值的阈值来确保TTL值并非唯一可以限制数据包可以跳过路由器的因素。</li>
<li>discovery.zen.ping.multicast.enabled(默认值为true):设置该属性值的值为false就关闭了多播传输。如果计划使用单播传输，就应该关闭多播传输。 </li>
</ul>
</p>

<h4>单播</h4>
<p>当像前面描述的那样关闭多播，就可以安全地使用单播。当节点不是集群的一部分时(比如节点重启，启动或者由于某些错误从集群中断开)，节点会发送一个ping请求到事先设置好的地址中，来通知集群它已经准备好加入到集群中了。相关的配置项很简单，如下：
<ul>
<li>discovery.zen.ping.unicats.hosts:该配置项代表集群中初始结点的主机列表。每个主机由名字(或者IP地址)加端口或者端口范围组成。比如，该属性值可以是如下的写法：["master1","master2:8181", "master3[80000-81000]"] ，因此用于单播节点发现的主机列表基本上不必是集群中的所有节点，因为一个节点一旦连接到集群中的一个节点，这个连接信息就会发送集群中其它所有的节点。 </li>
<li> discovery.zen.ping.unicats.concurrent\_connects(默认值: 10):该属性指定节点发现模块能够开启的单播最大并发连接数。</li>
</ul>
</p>

<h4>主节点候选节点个数的最小化</h4>
<p>对于节点发现模块来说，discovery.zen.minimum\_master\_nodes无疑是最重要的一个属性。该属性允许用户设置集群选举时主节点的候选节点数，该数值是组建集群所必须的。该属性存在的意义就是解决集群的裂脑现象。由于某些故障(比如网络故障)，网络中原来的集群分成了多个部分，每个部分的集群名字都相同，这种现象就是集群的裂脑现象。你可以想象两个同名的集群(本应该是一个)索引着不同的数据，很容易就会出现问题。因此，专家建议使用discovery.zen.minimum\_master\_nodes属性，并且该属性值的下限是集群节点总数的50%+1。比如，如果你们集群有9个节点，所有的节点都可以作为主结点，我们就需要设置discovery.zen.minimum\_master\_nodes属性值为5。即集群中至少要有5个符合选举条件的节点，才能够选择出一个主节点。 </p>

<h4>Zen发现机制的故障检测</h4>
<p>ElasticSearch运行时会启动两个探测进程。一个进程用于从主节点向集群中其它节点发送ping请求来检测节点是否正常可用。另一个进程的工作反过来了，其它的节点向主节点发送ping请求来验证主节点是否正常且忠于职守。但是，如果我们的网络很慢或者节点分布在不同的主机，默认的配置可能显得力不从心。因此，ElasticSearch的节点发现模块开放出了如下的属性：
<ul>
<li>discovery.zen.fd.ping_interval:该属性的默认值是1s,指定了本节点隔多久向目标结点发送一次ping请求。</li>
<li>discovery.zen.fd.ping_timeout:该属性的默认值是30s,指定了节点等待ping请求的回复时间。如果节点百分百可用或者网络比较慢，可能就需要增加该属性值。</li>
<li>discovery.zen.fd.ping_retries:该属性值默认为3，指定了在目标节点被认定不可用之前ping请求重试的次数。用户可以在网络丢包比较严重的网络状况下增加该属性值(或者修复网络状况)。</li>
</ul>
</p>

<h4>Amazon EC2 discovery</h4>
<blockquote>
    关于Amazon EC2 discovery相关内容暂时不翻译
</blockquote>

<h4>本地Gateway</h4>
<p>随着ElasticSearch 0.20版本发布(有些在0.19版本中)，除默认的local类型外，其它所有的gateway类型，都将废弃并且不建议用户使用，因为在未来的ElasticSearch版本中，这些类型将被移除。如果想避免出现整个数据集重新索引的情况，用户应该只使用local类型的gateway，这也是我们为什么不探讨所有其它类型gateway的原因。
local类型的gateway使用本机硬盘存储节点上的元数据、mappings数据、索引数据。为了能够使用这种gateway类型，需要服务器的硬盘有足够的空间在不使用内存缓存的情况下存储所有数据。local类型的gateway持久化数据的方式与其它gateway有所不同，为了确保在写数据的过程中，数据不丢失，它采用同步的方式来完成写数据的功能。
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
<div id="mid" style="height:100%;position:absolute;left:65px;right:13px;">
<p style="font-size:13px;margin-top:10px;">如果想设置集群使用的gateway类型，用户需要使用gateway.type属性，默认情况下该属性值为local
</p>
</div>
<div id="right" style="width:13px;height:100%;background:black;position:absolute;right:0px;padding:5px 0 5px 0;">
<img src="../notes/rm.png" height="100%" width="13px"/>
</div>
</div>  <!-- end of note structure -->

<h4>local类型gateway的备份</h4>
<p>ElasticSearch直到0.90.5版本(包括该版本)都不支持存储在local类型gateway中数据的自动备份。然而，做数据备份是至关重要的，比如，如果想把集群升级到一个比较新的版本，如果升级出现了一些问题，就需要回滚操作了。为了完成上述的操作，需要执行如下的步骤：
<ul>
<li>停止发生在ElasticSearch集群中的数据索引操作(这可能意味着停止rivers或者任何向ElasticSearch集群发送数据的应用)</li>
<li>用Flush API刷新所有还没有提交的数据。</li>
<li>为集群中的每一个分片至少创建一个拷贝，万一出现问题，也能找回数据。当然，如果希望尽可能简单地解决问题，也可以复制整个集群中每个节点的所有数据作为备用集群。</li>
</ul>
</p>
<h4>恢复机制的配置</h4>
<p>我们已经提到可以使用gateway来配置ElasticSearch恢复过程的行为,但是除外之外，ElasticSearch还允许用户自己配置恢复过程。在第4章 分布式索引构架 的 改变分片的默认分配方式一节中，我们已经提到一些恢复功能的配置，但是，我们认为在gateway和recovery相关的章节中讨论这些用到的属性是最合适的。 </p>

<h4>cluster-level 恢复机制的配置</h4>
<p>绝大多数恢复机制都是定义在集群层面的，用户通过为恢复模块设置通用的规则来控制恢复模块的工作。这些设置项如下：
<ul>
<li>indices.recovery.concurrent\_streams:该属性的默认值为3，表明从数据源恢复分片数据时，允许同时打开的数据流通道。该值越大，网络层的压力也就越大，同时恢复的速度也就越快，当然恢复速度与网络使用量和总的吞吐量也有关系。  <li>
<li>indices.recovery.max\_bytes\_per\_sec:该属性默认设置为20MB，表示分片在恢复过程中每秒传输的最大数据量。要想关闭传输量的限制，用户需要设置该属性值为0。与并发流的功能相似，该属性允许用户在恢复过程中控制网络的流量。设置该属性一个比较大的值会导致网络变得繁忙，当然恢复过程也会加快。<li>
<li>indices.recovery.compress:该属性值默认为true，允许用户自行决定在恢复过程是否对数据进行压缩。设置该属性值为false可以降低CPU的压力，与此同时，会导致网络需要传输更多的数据。 <li>
<li>indices.recovery.file\_chunk\_size:该属性值指定了用于从源数据复制到分片时，每次复制的数据块的大小。默认值是512KB,同时如果indices.recovery.compress属性设置为true，数据会被压缩。 <li>
<li>indices.recovery.translog\_ops:该属性值默认为1000，指定了在恢复过程中，单个请求中分片间传输的事务日志的行数。<li>
<li>indices.recovery.translog\_size: 该属性指定了从源数据分片复制事务日志数据时每次处理的数据块的大小。默认值为512KB，同时如果如果indices.recovery.compress属性设置为true，数据会被压缩。 <li>
</ul>
</p>
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
在ElasticSearch 0.90.0版本前，曾用到indices.recovery.max\_size\_per\_sec属性，但是在随后的版本中，该属性值被废弃了，由indices.recovery.max\_bytes\_per\_sec属性替代。然而，如果使用0.90.0版本前的ElasticSearch，还是有必要记住这个属性。
</p>
</div>
<div id="right" style="width:13px;height:100%;background:black;position:absolute;right:0px;padding:5px 0 5px 0;">
<img src="../notes/rm.png" height="100%" width="13px"/>
</div>
</div>  <!-- end of note structure -->
<p>上述的所有属性都可以通过集群的update API或者elasticsearch.yml来设置生效。</p>

<h4>index-level 恢复机制的配置</h4>
<p>除了前面提到的属性，还有一个可以作用于单个索引的属性。该属性可以在elasticsearch.yml文件中设置，也可以用索引更新的API来设置，它是index.recovery.initial\_shards。通常情况下，当集群中还存在着不低于quorum数量的分片，并且这些分片都可进行分配时，ElasticSearch只会恢复一个特殊的分片。quorum数量是指总的分片数量加一。通过使用index.recovery.initial\_shards属性时，用户可以改变ElasticSearch中quorum的实际分片数量。该属性可设置如下值：
<ul>
<li>quorum: 该值意味着集群中至少有(分片总数的50%+1)个分片存在并且可分配。</li>
<li>quorum-1:该值意味着集群中至少有(分片总数的50%-1)个分片存在并且可分配。</li>
<li>full:该值意味着集群中所有的分片都必须存在并且可分配。</li>
<li>full-1:该值意味着集群中至少有(分片总数-1)个分片必须存在并且可分配。</li>
<li>整数值:表示可设置为任意的整数值，比如1,2或者5，表示至少需要存在且可分配的分片数。比如，属性值为2，表示最少需要2个分片存在，同时ElasticSearch中至少需要2个分片可分配。</li>
</ul>
了解该属性值的作用总会有用上的一天，尽管在绝大多数场景中使用默认值就足够了。
</p>
</div>

