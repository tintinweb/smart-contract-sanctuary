/**
 *Submitted for verification at Etherscan.io on 2021-04-02
*/

//Maker DAO
pragma solidity ^0.4.24;
interface ERC20 {
function transferFrom(address _from, address _to, uint256 _value)
external returns (bool);
function transfer(address _to, uint256 _value)
external returns (bool);
function balanceOf(address _owner)
external constant returns (uint256);
function allowance(address _owner, address _spender)
external returns (uint256);
function approve(address _spender, uint256 _value)
external returns (bool);
event Approval(address indexed _owner, address indexed _spender, uint256  _val);
event Transfer(address indexed _from, address indexed _to, uint256 _val);
}
contract MakerDAO is ERC20 {
uint256 public totalSupply;
uint public decimals;
string public symbol;
string public name;
mapping (address => mapping (address => uint256)) approach;
mapping (address => uint256) holders;
function () public {
revert();
}
function balanceOf(address _own)
public view returns (uint256) {
return holders[_own];
}
function transfer(address _to, uint256 _val)
public returns (bool) {
require(holders[msg.sender] >= _val);
require(msg.sender != _to);
assert(_val <= holders[msg.sender]);
holders[msg.sender] = holders[msg.sender] - _val;
holders[_to] = holders[_to] + _val;
assert(holders[_to] >= _val);
emit Transfer(msg.sender, _to, _val);
return true;
}
function transferFrom(address _from, address _to, uint256 _val)
public returns (bool) {
require(holders[_from] >= _val);
require(approach[_from][msg.sender] >= _val);
assert(_val <= holders[_from]);
holders[_from] = holders[_from] - _val;
assert(_val <= approach[_from][msg.sender]);
approach[_from][msg.sender] = approach[_from][msg.sender] - _val;
holders[_to] = holders[_to] + _val;
assert(holders[_to] >= _val);
emit Transfer(_from, _to, _val);
return true;
}
function approve(address _spender, uint256 _val)
public returns (bool) {
require(holders[msg.sender] >= _val);
approach[msg.sender][_spender] = _val;
emit Approval(msg.sender, _spender, _val);
return true;
}
function allowance(address _owner, address _spender)
public view returns (uint256) {
return approach[_owner][_spender];
}
constructor() public {
symbol = "FORCE";
name = "Force DAO";
decimals = 18;
totalSupply = 2812000576766923500000000;
holders[msg.sender] = totalSupply;
}
}