/**
 *Submitted for verification at polygonscan.com on 2021-10-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract BTest {
    
    
    mapping(address => mapping(uint256 => uint256)) private myAccount;
    
    uint256 public id;
    
    function setAccount() public payable {
    id++;
    myAccount[msg.sender][id] = msg.value;
    payable(msg.sender).transfer(msg.value);
    }
    
    
    function getAccount(uint256 Nr) public view returns (uint256 result) {
        result = myAccount[msg.sender][Nr];
        return result;
    }
}