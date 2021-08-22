/**
 *Submitted for verification at Etherscan.io on 2021-08-22
*/

pragma solidity ^0.8.0;

contract CamCoin {
   //Events
   event Transfer(address indexed _from, address indexed _to, uint256 _value);
   event Approval(address indexed _owner, address indexed _spender,uint256 _value);
   //Mappings
   mapping(address => uint256) public balance;
   mapping(address => mapping(address => uint256)) public allowed;
   //Variable Declarations
   uint256 public _totalSupply;
   uint8 public decimals;
   string public name;
   string public symbol;
   //Constructor
   constructor() public {
     name = "CamCoin";
     symbol = "XCAM";
     decimals = 18;
     _totalSupply = 100000000000000000000000000;
   }
   //ERC20 Standard Functions
   function totalSupply() external view returns (uint256) {
     return _totalSupply;
   }

   function balanceOf(address account) external view returns (uint256) {
     return balance[account];
   }

   function allowance(address owner, address spender) external view returns (uint256) {
     return allowed[owner][spender];
   }

   function transfer(address recipient, uint256 amount) external returns (bool) {
     require(balance[msg.sender] >= amount);
     balance[recipient] += amount;
     balance[msg.sender] -= amount;
     emit Transfer(msg.sender, recipient, amount);
     return true;
   }

   function approve(address delegate, uint256 amount) external returns (bool) {
     allowed[msg.sender][delegate];
     emit Approval(msg.sender, delegate, amount);
     return true;
   }

   function transferFrom(address owner, address recipient, uint256 amount) external returns (bool) {
     require(balance[owner] >= amount);
     require(allowed[owner][msg.sender] >= amount);

     balance[recipient] += amount;
     balance[owner] -= amount;
     allowed[owner][msg.sender] -= amount;
     emit Transfer(owner, recipient, amount);
     return true;
   }
}

// SPDX-License-Identifier: GPL-1.0-or-later