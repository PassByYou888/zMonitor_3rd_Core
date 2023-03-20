# What is zMonitor_3rd_Core

**zMonitor_3rd_Core** is based on Pascal to reproduce the core technology of China's third and fourth generation monitoring systems from 2004 to 2012.

After the Ministry of Public Security proposed the smart city security plan in 2006, there was a trend of monitoring platform entrepreneurship among the people. At that time, many PAS circle people wrote such systems by themselves.

Early monitoring system is a core recording system developed by 1-2 core programmers. Follow-up work is to do peripheral applications on this basis, such as foreground monitoring, system administrators, queries, and so on.

**zMonitor_3rd_Core** is a modern technology that completely decrypts the monitoring core, "Recording System" 20 years ago from the core level to the design idea, and opens the source as demo.

**zMonitor_3rd_Core** is also a key Z-AI update in version 1.4 because ZAI strips the recording system off to a separate subsystem, known as zMonitor_3rd_Core

During the last two years of low-frequency updates, my personal design concepts and technical concepts have been self-renewing, ranging from the details of technology combing to design, to my previous open source projects.


# Technical Composition System and Design

- **ZDB2**: This is a technology system that solves database problems by designing data engine independently. **ZDB2** supports parallelism, the underlying design framework of multi-threaded disk and data IO, and the requirements of peer-to-peer HPC servers. At the same time**ZDB2** also contains a series of peripheral support systems for designing data structures, chain tables, hash tables, dictionary tables, threads, etc. Combining this series of small technical solutions to form an autonomous data engine solution.
- **The significance of ZDB2 in the monitoring system**: Video fragments are stored in **zdb2**, queries, statistics, when solving scrolling storage (delete the beginning and end of the video sequence), **zdb2** has a natural advantage, full disk, efficient scrolling storage, in addition, **zdb2** has a strong technical support system in system integration, transformation, multi-platform porting.
- **Raster technology**: Please refer to [zRasterization](https://github.com/PassByYou888/zRasterization) Project, raster technology is the result of many years of personal originality and precipitation, basically covering, **graphics 32**, **agg**, **bgra**(fpc). This kind of open source library function is extremely popular with PAS ring. Raster technology is an independent module, independent of system, platform, compiler
- **Significance of raster technology in monitoring system**: Video frame content is raster. If you want to add watermarks and draw wireframes, raster will be used. After the raster support system is improved, the programmable support of video frames will be strong.
- **Rendering Engine Technology**: Rendering Engine works as a middleware interface, independent of systems such as FMX and OpenGL and gles. Rendering design positioning is platform independent, output interface independent, ** Rendering Engine Technology is meaningful for monitoring ** The output of monitoring point applications and wireframe video frames.
- **Video Codec Technology**: My technical support system for video codec is mature in Z-AI application in business. The underlying layer uses **ffmpeg** for hardware acceleration. After comparing the same performance with native Pascal codec, I chose to rely on **ffmpeg**. In addition, there are many encapsulations for **ffmpeg** application scenarios, there are 5-6 scenarios in the decoding library alone. These include live broadcasting, push streaming, and so on. Common Technological Systems for Video Acquisition


# Investability

- From now on, the monitoring system in 2012 has been very popular in China. There is monitoring in any corner of the city. The core technology of these monitoring systems is on the one hand inexpensive and stable home-made monitoring heads (such as Haikangwei), on the other hand, the background recording system. These core technologies are not open, but very popular,**zMonitor_3rd_Core is an open source project for the complete decryption of the recording system from design to technology**
- **zMonitor_3rd_Core** Skewed to Senior Technician in Technical Positioning, **zMonitor_3rd_Core** is not an open source technology solution for everyone to choose, but from the underlying design ideas to specific technology solutions, has made a full range of thinking about the need to commercialize some monitoring business, or want to enter the monitoring field, to teach users to master, rather than binding users to make choices,**zMonitor_ 3rd_ That's what Core** is doing.
- **zMonitor_3rd_Core** travels through multiple approaches at the design and technology level, not limited to a particular solution, and makes a truthful choice statement in detail
- **zMonitor_3rd_Core** is part of the technical solution of the Z-AI monitoring system. Z-AI is a long-term project that has been in ** with revolutionary updates at any time**
-Many open source authors in the Pascal circle have their own open source projects, and these open source authors are also diligent. These authors also have their own major industries,**Open Source needs long-term learning and improvement before sharing so that they can be sure to bring improvement to others.
- In my view, open source is not advertising, marketing and traffic. Open source is opening itself up and making progress with the world. Because opening up is very important for cutting-edge technology and self-improvement.

# Policy

- From kernel libraries to rasters, rendering engines, encoding and decoding will all use special headers to distinguish between previous open source projects, without conflicts between libraries of earlier open source projects
- zMonitor_3rd_Core is closer to a stand-alone project and demo-like



By,**q600585**


2023-3-21