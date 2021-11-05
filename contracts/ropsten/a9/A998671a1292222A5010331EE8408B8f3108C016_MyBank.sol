/**
 *Submitted for verification at Etherscan.io on 2021-11-05
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract MyBank {
    mapping(address => uint) balance;
    address owner;
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    function deposit() public payable returns(uint){
        balance[msg.sender] += msg.value;
        return balance[msg.sender];
    }
    
    function getBalance() public view returns(uint) {
        return balance[msg.sender];
    }
    
    function transfer(address _recipient, uint _amount) public {
        require(balance[msg.sender] >= _amount, "Balance is low");
        require(msg.sender != _recipient, "Can't transfer funds to yourself");
        _transfer(msg.sender, _recipient, _amount);
    }
    
    function _transfer(address _from, address _to, uint _amount) private {
        balance[_from] -= _amount;
        balance[_to] += _amount;
    }
}