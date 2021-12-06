/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

contract KashifFirstToken {

uint256 constant MAXSUPPLY= 1000000;
uint256 constant TRANSFERFEE=1;
uint256 supply = 50000;

address public minter;

event Transfer(address indexed _from, address indexed _to, uint256 _value);

event Approval(address indexed _owner, address indexed _spender, uint256 _value);

event MintershipTransfer(address indexed previousMinter, address indexed newMinter);

mapping(address =>uint) public balances;

mapping (address => mapping(address => uint)) public allowances;

constructor() 
{
balances[msg.sender]=supply;
minter=msg.sender;
}

function totalSupply() public view returns (uint256) 
{
return supply;
}

function balanceOf(address _owner) public view returns (uint256) 
{
return balances[_owner];
}

function mint(address receiver, uint256 amount) public returns (bool) 
{
require(msg.sender==minter);
require((supply+amount)<=MAXSUPPLY);
supply+=amount;
balances[receiver]+=amount;
emit Transfer(address(0),receiver,amount);
return true;
}

function burn(uint256 amount) public returns (bool) 
{
require(amount<=balances[msg.sender]);
supply-=amount;
balances[msg.sender]-=amount;
emit Transfer(msg.sender,address(0),amount);
return true;
}

function transferMintership(address newMinter) public returns (bool) 
{
require(msg.sender==minter,"Error, Only Minter can transfer mintership privileges");
minter=newMinter;
emit MintershipTransfer(msg.sender,newMinter);
return true;
}

function transfer(address _to, uint256 _value) public returns (bool) 
{
require(_value<=balances[msg.sender],"Insufficient Balance");
require(TRANSFERFEE<=_value);
balances[msg.sender]-=_value;
balances[_to]+=(_value-TRANSFERFEE);
balances[minter]+=TRANSFERFEE;
emit Transfer(msg.sender,_to, _value);
return true;
}

function transferFrom(address _from, address _to, uint256 _value) public returns (bool) 
{
require(_value<=balances[_from],"Not sufficient tokens");
require(allowances[_from][msg.sender]>=_value, "Insufficient Allowances");
require(TRANSFERFEE<=_value);
balances[_from]-=_value;
balances[_to]+=(_value-TRANSFERFEE);
balances[minter]+=TRANSFERFEE;
allowances[_from][msg.sender]-=_value;
emit Transfer(_from,_to,_value);
return true;
}

function approve(address _spender, uint256 _value) public returns (bool) 
{
allowances[msg.sender][_spender]=_value;
emit Approval(msg.sender, _spender, _value);
return true;
}

function allowance(address _owner, address _spender) public view returns (uint256 remaining)
{
return allowances[_owner][_spender];
}
}