/**
 *Submitted for verification at Etherscan.io on 2020-08-05
*/

/**
 *Submitted for verification at Etherscan.io on 2018-06-12
*/
pragma solidity ^0.4.24;
//**************************** INTERFACE ***************************************
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
//***************************** CONTRACT ***************************************
contract T5GCoinToken is ERC20 {
uint256 public totalSupply;
uint public decimals;
string public symbol;
string public name;
mapping (address => mapping (address => uint256)) approach;
mapping (address => uint256) holders;
//***************************** REVERT IF ETHEREUM SEND ************************
function () public {
revert();
}
//***************************** CHECK BALANCE **********************************
function balanceOf(address _own)
public view returns (uint256) {
return holders[_own];
}
//***************************** TRANSFER TOKENS FROM YOUR ACCOUNT **************
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
//**************************** TRANSFER TOKENS FROM ANOTHER ACCOUNT ************
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
//***************************** APPROVE TOKENS TO SEND *************************
function approve(address _spender, uint256 _val)
public returns (bool) {
require(holders[msg.sender] >= _val);
approach[msg.sender][_spender] = _val;
emit Approval(msg.sender, _spender, _val);
return true;
}
//***************************** CHECK APPROVE **********************************
function allowance(address _owner, address _spender)
public view returns (uint256) {
return approach[_owner][_spender];
}
//***************************** CONSTRUCTOR CONTRACT ***************************
constructor() public {
symbol = "5G";
name = "5G Coin";
decimals = 18;
totalSupply = 10000000* 1000000000000000000;
holders[msg.sender] = totalSupply;
}
}