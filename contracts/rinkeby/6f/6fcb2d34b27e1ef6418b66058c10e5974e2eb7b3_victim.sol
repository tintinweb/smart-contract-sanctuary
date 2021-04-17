/**
 *Submitted for verification at Etherscan.io on 2021-04-17
*/

pragma solidity 0.5.9;
// SPDX-License-Identifier: MIT

contract victim{
        mapping(address => uint256) public balance;
        
        function deposit() payable public returns (bool){
            balance[msg.sender]+= msg.value;
        }
        
        function withdraw(uint amount) payable public returns (bool) {
            msg.sender.call.value(amount);
            balance[msg.sender] =0;
        }
        
}