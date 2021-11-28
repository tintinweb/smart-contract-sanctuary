/**
 *Submitted for verification at Etherscan.io on 2021-11-28
*/

pragma solidity ^0.4.16;
//用contract声明一个合约,现在我们声明了一个Coin合约
contract Coin {
    //声明了一个minter的地址类型的变量,public表示可以被外部访问
    address public minter;

    //声明了一个二维数组变量balances 
    //比如初始化的时候 我给地址A的balance设置为100,B的balance设置为200
    //可以这样些 balances[a] = 100; balances[b] = 200;
    mapping (address => uint) public balances;

    //声明一个转账的事件
    event Sent(address from, address to, uint amount);
    
    //这个构造函数的代码仅仅只在合约创建的时候被运行。
    function Coin() public{
        minter = msg.sender;
    }
    
    //挖矿的方法,就是可以给某个人的账户增加余额
    function mint(address receiver, uint amount) public{
        if (msg.sender != minter) return;
        balances[receiver] += amount;
    }
    
    //发送方法 比如A发送金额给B
    function send(address receiver, uint amount) public {
        if (balances[msg.sender] < amount) return;
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        Sent(msg.sender, receiver, amount);
    }
}