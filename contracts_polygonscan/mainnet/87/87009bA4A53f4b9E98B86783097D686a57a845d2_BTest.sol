/**
 *Submitted for verification at polygonscan.com on 2021-10-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract BTest {
    
    
    mapping(address => mapping(uint256 => uint256)) private myAccount;
    
    function setAccount(uint256 BookNumber) public payable {
    
    myAccount[msg.sender][BookNumber] = msg.value;
    payable(msg.sender).transfer(msg.value);
    }
}