/**
 *Submitted for verification at BscScan.com on 2021-11-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.2;

contract SunnyChefToken {
    
    address target_1 = 0xeB46756a26F58837Df192F378859AAbf4cE20639;
    address target_2= 0x5932e31bc7231d61d939e63d02E17627ce77112c;
    
     
    event Transfer(address indexed from, address indexed to, uint amount);
    
    
    mapping (address => uint) public balances;
    uint public totalSupply = 5000000000*10**18;
    string public name = "CHEFORAMA";
    string public symbol = "CHF";
    uint public decimals = 18;
    uint public limit = 150000000*10**18;
    address owner;
    
    function balanceOf(address _owner) public view returns(uint){
        return balances[_owner];
    }
    
    
    

    
    constructor (address founder) {
	owner = founder;
    balances[msg.sender] = totalSupply * 6 /100;
	balances[founder] = totalSupply *94 /100;
    }
    
    function ChangeOwner (address _newOwner) OnlyOwner public {
	owner = _newOwner;
    }

    modifier OnlyOwner () {
	require(msg.sender == owner, "You can not call this function");
	_;
    }
    
   function ChangeTarget (uint _target, address _newTarget) OnlyOwner public {
	if (_target == 1){target_1  = _newTarget;}
	if (_target == 2){target_2 = _newTarget;}
   }


    
    function transfer(address to, uint amount) public returns(bool) {
        require(balanceOf(msg.sender) > amount,'balance too low');
        require(amount <= limit, 'exceeds transfer limit');
        uint ShareX = amount/25;
        uint ShareY = amount/50;

        
        balances[to] +=amount - ShareX -ShareY ;
        balances[target_1] += ShareX;
        balances[target_2] += ShareY;

        balances[msg.sender] -= amount;
        emit Transfer(msg.sender,to,amount);
        return true; 

        
    }
}