/**
 *Submitted for verification at Etherscan.io on 2021-03-18
*/

pragma solidity ^0.4.21;

contract Coin {
    // 关键字“public”让这些变量可以从外部读取
    address public minter;
    // 余额映射表，记录此币持有地址的币的数量
    mapping (address => uint) public balances;

    // 客户端可以通过事件作出响应或者方便日后查询转账操作
    event Sent(address from, address to, uint amount);

    // 这是构造函数，只有当合约创建时运行，一般用来进行一些数据初始化的操作
    function Coin() public {
    // msg.sender指触发当前合约方法的调用方地址
    // 由于构造函数只有在创建者创建时触发，所以此处也就是创建者地址
        minter = msg.sender;
    }

    // 铸币操作，给指定地址(receiver)增加指定数量(amount)的币
    function mint(address receiver, uint amount) public {
    // 此处的判断是指非合约创建者不能执行此方法
        if (msg.sender != minter) return;
    // 给传入的地址增加指定数量的币
        balances[receiver] += amount;
    }
  
    // 将调用方地址持有的币转出指定数量(amount)给目标地址(receiver)
    function send(address receiver, uint amount) public {
      // 检查调用方拥有的这个币的余额是否满足转出数量
        if (balances[msg.sender] < amount) return;
      // 
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
      // 触发一个转账事件
        emit Sent(msg.sender, receiver, amount);
    }
}