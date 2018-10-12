pragma solidity ^0.4.25;
/*
* 转自马三多：
* 致ADC家人们的第九封信
* 亲爱的ADC家人们  大家好 我是三多老大技术团队的阿亮
* 这么晚发消息 主要给家人们分享下美国同事传来的好消息
* 一、C币主链与GO币主链已完成 现在已经不再是数字而是真正的数字货币 可在任何钱包下进行存储交易 
* 二、为加快推进FUS上线进程 打造属于我们ADC世界级主流去装币交易平台 团队成员已在美国购买最新开发的交易系统
* 我们将他取名去装币交易所  现在正在请美国工程师调试 完成后 将支持FUS  GO  CB 以及其他数字货币的交易 
* 众筹平台主页 https://fuschain.github.io/
* 众筹平台APP下载地址：https://fir.im/fus   (安卓） 
*                      https://www.pgyer.com/DiMu（苹果）  
* 请大家定期查看们的发言合约地址和官方主页了解最新消息：0x5e2dfB344A830aB4ce014ECD97d1Df5D88Ce2d9D 
* 估计很多家人们不会查我教大家一下
* 1.浏览器打开https://etherscan.io/
* 2.在右上角搜索窗口输入我们的合约地址就可以看到我们的每次分享链
* 3.点击Contract Creation（合同）
* 4.点击code   
* 联系邮箱：<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="deb8bce7eebaa8b0ecede99eaeacb1aab1b0b3bfb7b2f0bdb1b3">[email&#160;protected]</a>
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