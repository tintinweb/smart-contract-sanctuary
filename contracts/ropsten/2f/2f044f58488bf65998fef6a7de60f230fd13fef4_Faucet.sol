// Version of Solidity compiler this program was written for
pragma solidity ^0.4.19;
contract Faucet {
   //函数名为 withdraw，它接收一个无符号整数（uint）名为 withdraw_amount 的参数。它被声明为 public 函数，意味着它可以被其他合约调用。
   function withdraw(uint withdraw_amount) public{
     //withdraw+方法的第一部分设置了取款限制。它使用内置的Solidity函数 +require 来测试前提条件，即 withdraw_amount 小于或等于100000000000000000 wei，它是ether的基本单位（参见 Ether Denominations and Unit Names），等于0.1 ether。如果使用 withdraw_amount 大于该数量调用 withdraw 函数，则此处的 require 函数将导致合约执行停止并失败，并显示_异常_。
     require(withdraw_amount <= 100000000000000000);
     //msg 对象是所有合约可以访问的输入之一。它代表触发执行此合约的交易。属性 sender 是交易的发件人地址。函数 transfer 是一个内置函数，它将ether从合约传递到调用它的地址。从后往前读，表示 transfer 到触发此合约执行的 msg 的 sender。transfer 函数将一个金额作为唯一的参数。我们传递之前声明为 withdraw 方法的参数的 withdraw_amount 值。
     msg.sender.transfer(withdraw_amount);
   }
   //此函数是所谓的_“fallback”_或_default_函数，如果合约的交易没有命名合约中任何已声明的功能或任何功能，或者不包含数据，则触发此函数。合约可以有一个这样的默认功能（没有名字），它通常是接收ether的那个。这就是为什么它被定义为 public 和 payable 函数，这意味着它可以接受合约中的ether。除了大括号中的空白定义 {} 所指示的以外，它不会执行任何操作。如果我们进行一次向这个合约地址发送ether的交易，就好像它是一个钱包一样，该函数将处理它。
   function () public payable {
   }
}