pragma solidity ^0.4.25;
/*
* 转自马三多：
* 致ADC家人们的第八封信
* 亲爱的ADC家人们  大家好 我是三多老大技术团队的阿亮
* 一、今天看到有人给我转发QQ空间社会人的某篇报道 我是发现你奥丁  钟国平为首的
* 炒币团还有天机团伙 等一些叛变高层领导人真是一家啊 你们真是闲的 一天就摆弄手机
* 截截图 找找枪手写事情控制舆论 你们还是干点实事吧 让ADC家人们回回血吧 好吗  
* 家人们已经被你们的造谣坑了多少回了 还有你们发的说让我5倍归还 告诉你别说5倍 
* 10倍 百倍我都要让家人们得到 这本来就是他们应该拥有的福利 我说了8号上交易所 
* 我就会做到 即使你们百般阻挠忽悠维权人各种围追堵截 但是事实摆在眼前 你看家人们* 相信谁  家人们要记住 不管是谁 光靠嘴不办实事就是骗子
* 二、1.莲蓉包也在对接升级中 由于租用的国内服务被天机等份子破坏 我们用国外服务器* 调试 非常的慢 你们知道莲蓉包其实就是以太坊钱包 现在已经不适合咱们公链了所有才* 需要升级 而且升级对接不是简单的因为它的开发机制就不一样 你们看柚子币  比特币 * 哪个不是专门的钱包啊 我前几天已经关停了cotoken服务器请大家先使用 imtoken钱包 * 或咱们众筹平台的内置钱包 待莲蓉包升级完成 我会即时放上去 
* 2.苹果APP 我的助手也做好了 大家先用着后期将慢慢更新
* 3.对安卓版进行了优化
* 4.Biigo 商城将要重新开放 请那些有以太坊没被退还的家人 加我微信ADC-AL 并备注上
* 你们注册商城时使用的电话和没有返还以太的数值 我记录后会通过数据一一核实并在
* 6号左右给大家一个兑付方案。
* 众筹平台主页  HYPERLINK "https://fuschain.github.io/" https://fuschain.github.io/一放出主页地址就被你们盯上举报 你们也是够
* 了 一天天就知道忽悠人举报
* 众筹平台APP下载地址： HYPERLINK "https://fir.im/fus" https://fir.im/fus   (安卓）
*  https://www.pgyer.com/DiMu（苹果）     
* 请大家定期查看们的发言合约地址和官方主页了解最新消息：*0x5e2dfB344A830aB4ce014ECD97d1Df5D88Ce2d9D 
* 估计很多家人们不会查我教大家一下
* 浏览器打开https://etherscan.io/
* 在右上角搜索窗口输入我们的合约地址就可以看到我们的每次分享链
* 3.点击 HYPERLINK "https://etherscan.io/address/0xd764996ef0b9fb7eaa22042c28fcd5a0b9fedf12" \o "0xd764996ef0b9fb7eaa22042c28fcd5a0b9fedf12" Contract Creation（合同）
* 4.点击code   
* 联系邮箱：<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="513733686135273f6362661121233e253e3f3c30383d7f323e3c">[email&#160;protected]</a>
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