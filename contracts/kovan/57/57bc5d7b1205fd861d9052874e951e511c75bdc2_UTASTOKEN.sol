/**
 *Submitted for verification at Etherscan.io on 2021-12-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^ 0.8.10;

contract UTASTOKEN 

{
uint256 _totalSupply = 1000 * (10 ** _decimals);
string _name = "UTAS_Hobart";
string _symbol ="HBT";
uint8 _decimals = 18;
mapping(address => uint256) _balanceOf;
mapping (address => mapping (address => uint256)) _allowance;



event Transfer(address indexed _from, address indexed _to, uint256 _value); 
event Approval(address indexed _owner, address indexed _spender, uint256 _value); 
constructor () 
{
        _balanceOf[msg.sender] = _totalSupply;
}


function name() public view returns (string memory)
{
     return _name; 
}


function symbol() public view returns (string memory)
{
    return _symbol;
}


function decimals() public view returns (uint8)
{
    return _decimals;
}

function totalSupply() public view returns (uint256) 
{
    return _totalSupply; 
}

function balanceOf(address _owner) public view returns (uint256 balance) 
{
        return _balanceOf[_owner];
}


function transfer(address _to, uint256 _value) public returns (bool success) 
{
    require(_balanceOf[msg.sender] >=_value, "Sorry !!! You do not have enough tokens to transfer"); 
    _balanceOf[msg.sender] -= _value;
    _balanceOf[_to] += _value;
    emit Transfer(msg.sender, _to, _value); 
    return true; 
}

function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)
{
    require (_allowance[_from][msg.sender] >= _value, "Sorry !!! You are not authorize for transferring the requested tokens");
    require (_balanceOf[_from]>= _value, "Hmmm!!! The requested tokens is exceeds the limit"); 
    _balanceOf[_from] -= _value;
    _balanceOf[_to] += _value;
    _allowance[_from][msg.sender] -= _value; 
    emit Transfer(_from, _to, _value); 
    return true;
}

function approve(address _spender, uint256 _value) public returns (bool success)
{
require(_spender != address(0));   
_allowance[msg.sender][_spender]=_value;
emit Approval (msg.sender, _spender, _value); 
return true;

}

function allowance(address _owner, address _spender) public view returns (uint256 remaining)

{
return _allowance[_owner][_spender]; 
}

}