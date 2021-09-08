/**
 *Submitted for verification at polygonscan.com on 2021-09-08
*/

pragma solidity ^0.5.16;


contract BankTest1 {
    mapping(address => uint256) public balances;


    function deposit(uint256 newBalance) public   {
           balances[msg.sender] = newBalance;
    }
   

 
}