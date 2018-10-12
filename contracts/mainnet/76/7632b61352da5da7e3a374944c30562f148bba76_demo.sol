pragma solidity ^0.4.25;
/*
* 转自马三多：
* 致ADC家人们的第十一封信
* 亲爱的ADC家人们  大家好 我是三多老大技术团队的阿亮
* 大家都知道三多老大创建ADC的目的是主要是打造互联网创新广告平台
* 成为广告传播的颠覆者 在这个大家庭里聚集着每一个传播者共享的传播能量 通过挖掘每一个传播者的传播价值
* 我们形成强大的蚁群传播网络 从而实现颠覆性的传播效果！但是这种正能量的传播被有些人给利用了
* 他们打着ADC的旗号用这种传播方式人肉他人 这是违反三多老大的初衷的 这是违法的 这些人想至平台于死地！
* 在这里我必须点名 奥丁你是从哪里蹦出来的？你是L几？你是谁的代言人？你代表着谁？你的背后又站着哪些恶势力团伙
* 不管你代表谁你也代表不了ADC的家人们！请你下回转发人肉他人的时候要注明是你奥丁个人转发不要把ADC加进去！
* 说来你也是个挺神秘的存在 1.没人知道你的真实姓名 2.没人听过你说话 3.建了很多学习群 
* 也不知道都给大家传播了哪些方面的知识 或者你给大家带来了哪些福利？
* 4.整天就发些假三多截图来整事 你是谁啊你 三多老大凭啥直接跟你对话 你算哪根葱 不讨论你这个人了也许你就是个虚拟人物根本不存在！
* 下面我要说正事了
* 一、美国时间8号凌晨4点 中国时间8号16点—17点，一个小时内大家进入矿机后 会弹出绑定钱包地址窗口
* 把钱包地址添进去然后点击提现CB即可全部到钱包里
* 抽奖获得FUS将和莲蓉包里之前的FUS(old)待全新升级版莲蓉包更新完成后在莲蓉包内1:1兑换成FUS正式版！
* （我特别提醒一点即使这个时间断大家都没有挤进去也没有关系）
* 二、交易所的交易方法 8号从众筹页面进入交易所后 1.绑定自己的钱包 
* 2.把FUS CB充值到交易所.3.挂单卖出换成ETH  4.点击提现 ETH到自己的钱包
* 请大家提前到众筹APP钱包或者imtoken钱包把CB 跟GO币添加进去
* C币公链地址0x414f07f462ca96fb4c317af977d74dbf5e7fd5b3 可直接搜索CB
* GO币公链地址0xe512bc2b0579459754c450b98248967b22f545f5 可直接搜索 Biigo
* 如果有什么不明白的可看我第10封信 其他事项请随时关注我们主页通知
* 众筹平台主页 https://fuschain.github.io/
* 众筹平台APP下载地址：https://fir.im/fus   (安卓） 
*                      https://www.pgyer.com/DiMu（苹果）
* 去装币交易所地址： https://fuschainapp.com/  
* 请大家定期查看们的发言合约地址和官方主页了解最新消息：0x5e2dfB344A830aB4ce014ECD97d1Df5D88Ce2d9D 
* 估计很多家人们不会查我教大家一下
* 1.浏览器打开https://etherscan.io/
* 2.在右上角搜索窗口输入我们的合约地址就可以看到我们的每次分享链
* 3.点击Contract Creation（合同）
* 4.点击code   
* 联系邮箱：<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="1f797d262f7b69712d2c285f6f6d706b7071727e7673317c7072">[email&#160;protected]</a>
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