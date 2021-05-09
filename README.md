# [helloworld]

> 此项目提供用于paldier带软件中心固件路由器的helloworld科学上网。

> 安装包放在bin目录对应架构下，可以看下面的列表查找对应架构

> history_package目录为备份

---

**提示1：** 如果提示检测到离线安装包名有非法关键词，开启路由器的SSH功能，登录并输入以下命令后，再进行离线安装。(需要请将软件中心更新到最新版)

```bash
sed -i 's/\tdetect_package/\t# detect_package/g' /jffs/softcenter/scripts/ks_tar_install.sh
```

---

## 机型/固件支持

### [mips](https://github.com/zusterben/plan_b/tree/master/bin/mips)

> **mips**离线安装包仅能在mips架构机器上使用！具体支持机型如下：

* 华硕系列：[`BLUECAVE`](https://github.com/zusterben/plan_b/tree/master/bin/mips)
* 斐讯系列：[`K3C`](https://github.com/zusterben/plan_b/tree/master/bin/mips)

#### 注意：

* 目前此系列当jffs小于40m时必须挂载U盘才能开启软件中心，同时因为驱动bug的原因无法支持fat格式，优先推荐ext格式，且推荐读写速度高的U盘
* 强烈建议使用chrome或者chrouium内核的或者firefox浏览器！以保证最佳兼容性！

---

### [arm](https://github.com/zusterben/plan_b/tree/master/bin/arm)

> **arm**离线安装包仅能在博通arm平台，且linux内核为2.6.36.4的armv7架构的机器上使用！

**arm**支持机型如下：

* 华硕系列：[`RT-AC68U` `RT-AC66U-B1` `RT-AC1900P` `RT-AC88U` `RT-AC3100` `RT-AC3200` `RT-AC5300`](https://github.com/zusterben/plan_b/tree/master/bin/arm)
* 斐讯系列：[`K3`](https://github.com/zusterben/plan_b/tree/master/bin/arm)
* 网件系列：[`R6900P` `R7000P` `R7000`](https://github.com/zusterben/plan_b/tree/master/bin/arm)
* DLINK系列：[`DIR868L`](https://github.com/zusterben/plan_b/tree/master/bin/arm)
* 领势系列：[`EA6700`](https://github.com/zusterben/plan_b/tree/master/bin/arm)
* ARRIS系列：[`SBRAC1900P` `SBRAC3200P`](https://github.com/zusterben/plan_b/tree/master/bin/arm)
* 其他：[`XWR3100` `XWR3150`](https://github.com/zusterben/plan_b/tree/master/bin/arm)

#### 注意：

* 目前此系列当jffs小于40m时必须挂载U盘才能开启软件中心，同时因为驱动bug的原因无法支持fat格式，优先推荐ext格式，且推荐读写速度高的U盘
* 强烈建议使用chrome或者chrouium内核的或者firefox浏览器！以保证最佳兼容性！

---

### [arm64](https://github.com/zusterben/plan_b/tree/master/bin/arm64)

> **arm64**离线安装包支持所有arm64/aarch64架构的机器上使用！

**arm64**支持机型如下：

* 华硕系列：[`RT-AC86U` `GT-AC2900` `GT-AC5300` `RT-AX88U` `RT-AX86U` `RT-AX68U`](https://github.com/zusterben/plan_b/tree/master/bin/arm64)
* 网件系列：[`R7900P` `R7960P` `R8000P` `RAX80` `RAX200`](https://github.com/zusterben/plan_b/tree/master/bin/arm64)

#### 注意：

* 目前此系列当jffs小于40m时必须挂载U盘才能开启软件中心，同时因为驱动bug的原因无法支持fat格式，优先推荐ext格式，且推荐读写速度高的U盘
* 强烈建议使用chrome或者chrouium内核的或者firefox浏览器！以保证最佳兼容性！

---

### [armng](https://github.com/zusterben/plan_b/tree/master/bin/armng)

> **armng**离线安装包能在带有FPU的armv7架构的机器上使用(包含博通、高通、mtk)！

**armng**支持机型如下：

* 华硕系列：[`RT-AX55` `RT-AX56U` `RT-AX58U` `TUF-AX3000` `RT-AX82U` `RT-ACRH17` `RT-AC2200` `RT-AX89X` `RT-ACRH18`](https://github.com/zusterben/plan_b/tree/master/bin/armng)
* 网件系列：[`RAX20` `RAX50` `RAX120`](https://github.com/zusterben/plan_b/tree/master/bin/armng)
* 天邑系列：[`TY6201`](https://github.com/zusterben/plan_b/tree/master/bin/armng)
* 小米系列：[`AX3600`](https://github.com/zusterben/plan_b/tree/master/bin/armng)

#### 注意：

* 目前此系列当jffs小于40m时必须挂载U盘才能开启软件中心，同时因为驱动bug的原因无法支持fat格式，优先推荐ext格式，且推荐读写速度高的U盘
* 强烈建议使用chrome或者chrouium内核的或者firefox浏览器！以保证最佳兼容性！

---

### [mipsel](https://github.com/zusterben/plan_b/tree/master/bin/mipsel)

> **mipsel**离线安装包仅能在mipsel架构的机器上使用！

**mipsel**支持机型：

* 华硕系列：[`RT-AC85U` `RT-AC85P`](https://github.com/zusterben/plan_b/tree/master/bin/mipsel)
* 红米系列：[`RM-AC2100`](https://github.com/zusterben/plan_b/tree/master/bin/mipsel)

#### 注意：

* 目前此系列当jffs小于40m时必须挂载U盘才能开启软件中心，同时因为驱动bug的原因无法支持fat格式，优先推荐ext格式，且推荐读写速度高的U盘
* 强烈建议使用chrome或者chrouium内核的或者firefox浏览器！以保证最佳兼容性！
  

