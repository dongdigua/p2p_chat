# p2p_chat
a peer-to-peer (encrypted) chat<br>
use udp hole punching<br>

zhihu: https://zhuanlan.zhihu.com/p/350937199<br>
为什么网上讲到的P2P穿透基本上都是基于UDP协议的穿透？难道TCP不可能穿透？还是TCP穿透难于实现？

假设现在有内网客户端A和内网客户端B，有公网服务端S。
如果A和B想要进行UDP通信，则必须穿透双方的NAT路由。假设为NAT-A和NAT-B。
A发送数据包到公网S,B发送数据包到公网S,则S分别得到了A和B的公网IP，
S也和A B 分别建立了会话，由S发到NAT-A的数据包会被NAT-A直接转发给A，
由S发到NAT-B的数据包会被NAT-B直接转发给B，除了S发出的数据包之外的则会被丢弃。
所以：现在A B 都能分别和S进行全双工通讯了，但是A B之间还不能直接通讯。

解决办法是：
A向B的公网IP发送一个数据包，
则NAT-A能接收来自NAT-B的数据包并转发给A了（即B现在能访问A了）；
再由S命令B向A的公网IP发送一个数据包，则NAT-B能接收来自NAT-A的数据包并转发给B了（即A现在能访问B了）。
以上就是“穿透/打洞”的原理。

为了保证A的路由器有与B的session，A要定时与B做心跳包，
同样，B也要定时与A做心跳，
这样，双方的通信通道都是通的，就可以进行任意的通信了。

