/**
 *Submitted for verification at Etherscan.io on 2021-08-27
*/

pragma solidity ^0.4.26;

contract payableTest{
    //通过当前钱包调取支付，支付对象为合约地址
    function pay() payable{
    }
    
    //查询合约地址的资产
    function getBalance() view returns(uint){
        return this.balance;
    }
    
    //查询该合约地址合约号
    function getThis() view returns(address){
        return this;
    }
    
    //输入地址查询里面的资产
    function getrandomBalance(address account) view returns(uint){
        return account.balance;
    }
    
    // 调取账户给定义的地址转账
    // 可以直接输入 account.transfer(msg.value); 就代表给账户转账。
    //如果函数里面注释掉地址和发送数量，但是基于payable属性，那会直接调取转账给合约地址。
    function transfer() payable{
        address account = 0xC5ba7F9959a76f6c6C89e4a7ED67Ba5127F48905;
        account.transfer(msg.value);
    }
    
}