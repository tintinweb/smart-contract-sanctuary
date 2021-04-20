/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract TestTest {
    
    event StringChanged(string oldString, string newString);
    event NewElementAddedToArray(uint256 newArrayLength, uint256 newElement);
    
    event Deposit(address user, uint256 amount);
    event Withdraw(address user, uint256 amount);
    
    uint256[] public myArr;
    string public myStr;
    
    mapping(address => uint256) balances;
    
    function changeString(string memory str) public {
        emit StringChanged(myStr, str);
        myStr = str;
    }
    
    function addElement(uint256 el) public {
        myArr.push(el);
        emit NewElementAddedToArray(myArr.length, el);
    }
    
    function deposit() public payable {
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
    function withdraw() public payable {
        uint256 amount = balances[msg.sender];
        balances[msg.sender] -= amount;
        emit Withdraw(msg.sender, amount);
    }
    
}