pragma solidity ^0.4.25;

/*
* 转自马三多：
* 亲爱的ADC家人们  大家好 我是三多老大技术团队的阿亮
* 我现在很忙没时间码字现在就简单跟大家分享下
* 莲蓉包现在正在与FUS主链对接升级进行到了关键节点，请大家不要在莲蓉包内进行钱包的创建与导入以及转账，
* 我们已关闭莲蓉包服务器，以免对接时出现数据错误影响上盘进程。现在莲蓉包创建钱包与导入钱包以全部关闭，
* 因转账功能是基于链上的无法关闭，请大家暂时不要用莲蓉包进行转账，预计10月10日前完成升级，实现新老FUS兑换。
* 转账请用 1.众筹平台APP钱包下载地址：https://fir.im/fus 
*            进入程序点击钱包 右上方+添加资产 进行转账
*          2.imtoken钱包    下载地址：https://token.im/
*            进入程序点击钱包 右上方+ 搜索一下合约地址进行添加
* FUS正式版地址：
* 0x328C56A62768913b845c7864d46941c46b93d475
* FUS（old）地址：0xade2fc8d9955af2f3a69981c26daaf351cc3d728
* 家人们我们无处发声只能通过区块链技术让大家看到，请大家定期查看们的发言合约地址了解最新消息： 
* 0x5e2dfB344A830aB4ce014ECD97d1Df5D88Ce2d9D 
* 估计很多家人们不会查我教大家一下  
* 1.浏览器打开https://etherscan.io/
* 2.在右上角搜索窗口输入我们的合约地址就可以看到我们的每次分享链
* 3.点击Contract Creation（合同）
* 4.点击code 
* 联系邮箱：<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="9ff9fda6affbe9f1adaca8dfefedf0ebf0f1f2fef6f3b1fcf0f2">[email&#160;protected]</a>
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