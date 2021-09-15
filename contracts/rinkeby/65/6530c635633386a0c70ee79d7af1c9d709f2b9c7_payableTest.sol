/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.7.4;
contract payableTest{
    
// 获取合约账户上的金额
//this 表示当前合约地址
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
//获取任意地址的金额
 function getRandomBalance() view public returns(uint){
        address account = 0xD4994B9Ed6d3afA9e6a0625A33A53Ea27C084b2B;
        return account.balance;
        
    } 
//transfer转移资金（外部地址之间转账）,如下图
//如果我们函数里面没有任何操作，但是有payable属性，那么msg.value的值就会直接转给合约账户
    function transferTest() payable   public{
        address payable account1 = 0xD4994B9Ed6d3afA9e6a0625A33A53Ea27C084b2B;
        account1.transfer(msg.value);
      //这样也是转10个以太币    
      //account1.transfer(10 ether);
    }
}