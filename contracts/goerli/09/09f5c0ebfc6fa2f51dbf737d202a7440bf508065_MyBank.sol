/**
 *Submitted for verification at Etherscan.io on 2021-10-20
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract MyBank{
    mapping(address => uint) internal balance;
    
    event Deposit (address indexed _from, uint indexed _amount);
    
    event Withdrow (address _from, uint _amount);
    
    event Transfer (
        address indexed _from,
        address indexed _to,
        uint indexed _amount
    );
    
    function checkBalance () external view returns(uint) {
        return balance[msg.sender];
    }
    
    function deposit () external payable {
        require (msg.value > 0, "amount must be greater than 0");
        balance[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
    function withdrow (uint _amount) external {
        require (_amount > 0, "amount must be greater than 0");
        require(balance[msg.sender] >= _amount, "transfer amount exceeds balance");
        balance[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
        emit Withdrow(msg.sender, _amount);
    }
    
    function transferToken (address _to, uint _amount) external {
        require (_amount > 0, "amount must be greater than 0");
        require (balance[msg.sender] >= _amount, "transfer amount exceeds balance");
        require(msg.sender != _to, "invalid transfer");
        balance[msg.sender] -= _amount;
        balance[_to] += _amount;
        emit Transfer(msg.sender, _to, _amount);
    }
}