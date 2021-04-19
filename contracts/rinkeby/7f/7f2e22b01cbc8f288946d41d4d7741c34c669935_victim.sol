/**
 *Submitted for verification at Etherscan.io on 2021-04-19
*/

pragma solidity 0.6.10;
// SPDX-License-Identifier: MIT

contract victim{
        mapping(address => uint256) public balance;
        
        function deposit() public payable {
            balance[msg.sender] += msg.value;
        }
        
        function withdraw(uint amount) public {
            require(balance[msg.sender] >= amount);
            
            (bool sent,) = msg.sender.call{value: amount}("");
            require(sent, "Failed to send Ether");
            balance[msg.sender] -= amount;
        }
        
}