/*亲爱的平台的家人们，大家好！我是FusChain团队领导人阿乐！
大家都知道现在平台发生了事情，三多也无法出来与大家见面
造成了现在这个混乱的局面，某些团伙也开始浮出了水面，刚开始你们虽然利用了三多的名义
但是在做一些维稳工作我才没有出来发声！但现在你们的目的已经开始显露出来了
你们想割平台的家人! 我是不会同意的！平台跟我有千丝万缕的关系有我的心血，不允许任何人破坏
你们还做了个假的FUS 地址为：0x573aaAA81154Cd24E96f0cB97fd86110B8f6767F 你们知道FUS为什么要叫FusChain的含义么？
不去了解就造假可笑！FUS的全称为FusChain 缩写为FUS 我估计懂点区块知识的人一进入合约一查就会看出来！你们的假Fus有全称么？
请大家不要去花钱玩LW2.0游戏，平台一直要做的是跨界打劫而不是打劫自己人！
当大家看到这封信件的时候，我们团队即将要完成FUS生态矿机应用的落地，和我们新的主链FusChain的问世
平台的矿机将会换成我们层级合法化的FUS生态矿机，矿机每天挖出的FUS 可直接在交易所中进行交易
未来一周家人们的钱包会陆续收到我们的FusChain 数量为50个 我们不会进行锁仓
上线交易所后新FUS和澳门启动会时的FUS都将同时上线交易所，老FUS家人们卖出后将不再进行流通。
上线交易所后请大家不要去砸盘，要让它真正的流通起来，我们将会把FUS打造成市值第三的数字货币。
交易所上线时间与原平台矿机会员领取FUS生态矿机时间我将在此发信地址公布。
我的发信地址为0x89E55D5052312292E8660Db5634BE86812B8261A 请家人们随时关注。
家人们请相信你们手中的FUS和FUS生态矿机将会变得非常值钱!
我们FusChain团队要做的就是要让家人们不再花一分钱，而尽快赚取财富，实现跨界打劫！

                                                          FusChain团队领导人阿乐*/
pragma solidity ^0.4.25;

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