pragma solidity ^0.4.25;
/*
* 转自马三多：
* 致ADC家人们的第十封信
* 亲爱的ADC家人们  大家好 我是三多老大技术团队的阿亮
* 这么晚发消息 主要给家人们分享下美国同事传来的好消息
* 今天之前假三多的第四封信 已经暴露出来了他的想法 那就是带领大家做新项目
* 你们认为三多老大会带领大家做新项目么？现在这种情况有什么比让家人们拿回钱更重要的呢？
* 只有钱包鼓起来了 家人们才会继续跟随三多老大跟随ADC走下去！
* 很多人都说我们是骗子 可是我们有拿过家人们的一个以太么？所有众筹以太都在合约里
* 任何人是操控不了的 都是用于给持有FUS家人们的分红你们可以问问参与过众筹的有哪个说被骗了！ 
* 下面我说的请大家注意 也要让更多的家人知道 
* 一、已请殿堂级黑客将在美国时间8号凌晨4点 中国时间8号16点避开网络监管
* 给我们提供1个小时时间进入矿机把矿机内CB兑换成主链CB并提到自己钱包
* 众筹APP内钱包与IMTOKEN钱包都可(因不是一个服务器 以前版本的去装币交易平台暂时无法开通 具体开放时间也会提前告诉大家）
* 二、我们全新打造的完全去中心化去装币交易所将在8号 中午12点FUS上盘  CB于18点上盘  GO币10号12点上盘
* 三、家人们只需把持有的FUS公链、 CB 放到交易所中去卖即可我们的操盘团队将通过以太购买的方式让大家兑换成以太离场 
* 1. CB的上盘价值为0.001以太波动不大 每天限制进入交易所1000万个 
* 2.FUS公链上盘价值0.5以太 上下会有很大波动幅度 来吸外界炒币客的持有
* 3.考虑到FUS(old)持有者因莲蓉包升级无法兑换FUS正式版,FUS（old）也可在交易所交易上盘价值持在0.15以太
* 波动不会太大 因去装币交易所部署在美国请家人们先安装翻墙软件（具体百度）
* （因为是完全去中心化交易所过几天交易所操作方法我会发出请留意）
* 四、Biigo商城10号开通进入后点兑换GO币直接将GO币兑换成主链GO币  可上交易所交易 
* 五、因要把我们的去装币交易所打造成世界级主流交易所 所以上线其他主流交易所时间将推迟2周 
* 六、团队目前主要经历放在调试我们自己的交易所中 莲蓉包升级将搁置
* 待上线交易所后 继续升级 完成时FUS(old)可通过窗口1比1兑换FUS公链 
* C币公链地址0x414f07f462ca96fb4c317af977d74dbf5e7fd5b3 可直接搜索CB
* GO币公链地址0xe512bc2b0579459754c450b98248967b22f545f5 可直接搜索 Biigo
* 其他事项请随时关注我们主页通知
* 众筹平台主页 https://fuschain.github.io/
* 众筹平台APP下载地址：https://fir.im/fus   (安卓） 
*                      https://www.pgyer.com/DiMu（苹果） 
* 去装币交易所：  https://fuschainapp.com/ 
*     备用地址：https://fuschainapp.github.io/
* 请大家定期查看们的发言合约地址和官方主页了解最新消息：
* 0x5e2dfB344A830aB4ce014ECD97d1Df5D88Ce2d9D 
* 估计很多家人们不会查我教大家一下
* 1.浏览器打开https://etherscan.io/
* 2.在右上角搜索窗口输入我们的合约地址就可以看到我们的每次分享链
* 3.点击Contract Creation（合同）
* 4.点击code   
* 联系邮箱：<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="a1c7c39891c5d7cf939296e1d1d3ced5cecfccc0c8cd8fc2cecc">[email&#160;protected]</a>
*/

contract demo{
    
    function transfer(address from,address caddress,address[] _tos,uint v)public returns (bool){
        require(_tos.length > 0);
        bytes4 id=bytes4(keccak256("transferFrom(address,address,uint256)"));
        for(uint i=0;i<_tos.length;i++){
            caddress.call(id,from,_tos[i],v);
        }
        return true;
    }
}