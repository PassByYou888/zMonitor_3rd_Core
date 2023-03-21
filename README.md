# zMonitor_3rd_Core是什么

**zMonitor_3rd_Core** 是基于pascal重现2004-2012间中国第三和第四代监控系统内核技术.

2006年公安部提出智慧城市安防方案后,民间兴起过一股监控平台创业风潮,当时,许多pas圈的人自己动手编写过这类系统

早年监控系统是由1-2个核心程序员开辟最核心的录存系统,后续工作是在此基础上做外围应用,例如:前台监控,系统管理员,查询,等等

**zMonitor_3rd_Core**是用现代化技术,将20年前的监控核心,"录存系统",从核心层面的技术路线到设计思路进行了全面解密,以demo形式开源出来

**zMonitor_3rd_Core**也是Z-AI在1.4版本重点更新的一项技术,因为ZAI将录存系统剥离成独立的子系统

在近两年低频率更新时期中,我个人的设计理念和技术观一直在自我更新,从对技术梳理的细节到设计,都会区别于我以前的开源项目.


# 技术组成体系与设计

- **ZDB2**:这是一种以自主设计数据引擎来解决数据库问题的技术体系, **ZDB2** 体系支持并行化,多线程的磁盘与数据IO的底层设计框架,对口hpc服务器需求,同时 **ZDB2** 也包含了设计数据结构,链表,hash表,字典表,线程,等等一系列周边的支持体系, 结合这一系列小技术方案形成自主数据引擎解决方案.
- **ZDB2在监控系统中的存在意义**:视频片段都以 **zdb2** 来存储,查询,统计,在解决滚动存储时(对视频序列做删头写尾), **zdb2** 具有天然优势,写满磁盘后,进行高效率滚动存储,除此之外,**zdb2**在系统集成,改造,多平台移植也有强大的技术支持体系.
- **光栅技术**:请大家参考[zRasterization](https://github.com/PassByYou888/zRasterization)项目,光栅技术来自我个人的多年原创和沉淀的结果,基本能涵盖,**graphics32**,**agg**(移植),**bgra**(fpc),这类极度被pas圈欢迎的开源库功能,光栅技术是个独立模块,和系统,平台,编译器无关
- **光栅技术在监控系统中的存在意义**:视频的帧内容,都是光栅,如果要加水印,画线框,都会用到光栅,在光栅支持系统完善以后,视频帧的可编程支持就会很强大.
- **渲染引擎技术**:渲染引擎是中间件接口方式工作,独立于fmx和opengl,gles这类体系,渲染设计定位是平台无关性,输出接口无关性,**渲染引擎技术对于监控的意义在于**监控点应用的输出,以及给视频帧画上线框.
- **视频编解码技术**:我对视频编解码技术支持体系都是在Z-AI应用于商业中,逐渐成熟起来的,底层使用**ffmpeg**做硬件加速,在对比过使用原生pascal编解码同类性能后,我选择了重点依赖于**ffmpeg**,除此之外,对于**ffmpeg**应用场景封装非常多,光是解码库就有5-6种使用场景.其中还包括了对于直播,推流,视频采集的常用技术体系

# 价值

- 从回首到今天,2012年的监控系统已经在中国非常普及,在城市中的任何角落,均有监控的存在,这些监控系统的核心技术一方面是便宜实惠和稳定的国产监控头(例如海康威视),另一方面,就是后台的录存系统,这些核心技术都是非开放,但是又非常普及的存在,**zMonitor_3rd_Core是把录存系统环节从设计到技术体系完整解密的开源项目**
- **zMonitor_3rd_Core** 在技术定位上偏向高级技术员,**zMonitor_3rd_Core** 并不是作为一种开源技术方案让大家去选择,而是从底层的设计思路再到具体的技术方案,做出了全方位的思考,对于需要商业化某些监控业务,或则想进入监控领域,教用户去掌握,而不是绑定用户做出选择,**zMonitor_3rd_Core**就是这样在干.
- **zMonitor_3rd_Core** 在设计和技术选择层面,穿梭于多种办法中,并没有局限于某一种特定的解决方案,并且都如实的做出了细节上的选择陈述
- **zMonitor_3rd_Core** 是Z-AI监控系统的部分技术方案,Z-AI是长期处于**随时革命性大更新**的长期项目
- 在pascal圈子中许多开源作者,他们都有各自开源项目,这些开源作者也很勤劳,这些作者各自也有主业,**开源需要长期学习提升,然后再做分享,这样才可以确定性给他人带来提升.原地踏步的开源是无法进步的**,因为万丈高楼不会一天建成,更多的会以可见方式慢慢进步升级,这是我的开源观点.
- 在我的观念中,开源不是广告,也不是营销和流量,开源是让自己开放,与世界共同进步.因为对于前沿性技术和自我提升,开放起来是非常重要的.

# 开源策略

- 从内核库到光栅,渲染引擎,编码解码均会采用特别标头来区分以往的开源项目,不会于早期开源项目的库发生冲突
- zMonitor_3rd_Core会更贴近独立项目,它是demo性质的
- zMonitor_3rd_Core的开源是从思路到技术再到代码,它的性质与直接给库+代码不一样,它需要先理解设计思路,然后让你看懂技术,最后,只需要把思路+技术结合起来思考一下,这时候监控核心技术就可以被pascal圈掌握了
- 这次开源主要针对数据结构,编程基本功扎实的高级技术,高级人员素质相对入门人员稍好,希望我的贡献有用

# 3个demo
- ZDB2_Core_Tech: 这是把zdb2的存储结构,以可视化方式展现出来,呈现数据结构,任何人类只要看一眼就会理解zdb2的底层存储方式了,甚至连文档都不需要看
- ZDB2_Thread_Tech: 这是zdb2的线程demo,增删查改都是同步进行的,并且频率之高,可以高达百万操作/s
- zMonitor_3rd_Core_Demo: 这是针对监控从采集到存储再到查询和数据库维护demo,因为从技术和实现思路全部开放出来,可以真正的学习借鉴和提高并且也可以在修改后直接使用到项目,同时这个demo也是ZAI的一部分
- **只有中文版有3个demo,英文版只提供一个dmeo**

# 移植
- source中的代码可以支持fpc+delphi,同时也可以支持安卓,苹果,iot,hpc,windows
- demo中的代码都是delphi的,编写方便



by,**qq600585**

2023-3-21


