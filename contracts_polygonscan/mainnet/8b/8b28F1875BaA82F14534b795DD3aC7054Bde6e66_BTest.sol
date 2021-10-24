/**
 *Submitted for verification at polygonscan.com on 2021-10-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract BTest {
    
    mapping(address => mapping(uint256 => uint256)) private myAccount2;
    mapping(address => mapping(uint256 => zooi)) private myAccount;
    
    mapping(address => uint256) public account;
    
    uint256 public id;
    
    
    function setAccount() public payable {
    id++;
    myAccount[msg.sender][id].bal = msg.value;
    myAccount2[msg.sender][id] += 1;
    account[msg.sender] = msg.value;
    payable(msg.sender).transfer(msg.value);
    }
    
    struct zooi{
        uint256 bal;
    }
    
    
    function getAccount(uint256 Nr) public view returns (uint256 result) {
        result = myAccount[msg.sender][Nr].bal;
        return result;
    }
    
    function getAccount2(uint256 Nr) public view returns (uint256 result) {
        result = myAccount2[msg.sender][Nr];
        return result;
    }
}