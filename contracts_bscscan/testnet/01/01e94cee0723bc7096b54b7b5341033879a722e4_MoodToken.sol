/**
 *Submitted for verification at BscScan.com on 2021-09-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract MoodToken {

string public constant _name = "MoodToken";
string public constant _symbol = "MOO";
uint8 public constant _decimals = 18;
uint256 public constant _totalSupply = 22000000000000000000000000;
address _minter = msg.sender;

mapping (address => uint256) public _balanceOf;
mapping (address => mapping (address => uint256)) public allowed;

event Transfer(address indexed _from, address indexed _to, uint256 _value);
event Approval(address indexed _owner, address indexed _spender, uint256 _value);

constructor() {
    _balanceOf[_minter] = 10000000000000000000000000; 
}

modifier balanceCheck(uint256 value) {
    require(_balanceOf[msg.sender] >= value,"Not enough Token.");
    _;
}

modifier _balanceCheck(address _from, address _to, uint256 value) {
    require(_balanceOf[_from] >= value,"Not enough Token.");
    require(allowed[_from][msg.sender] >= value,"Not allowed to do this.");
    _;
}

function name() public pure returns (string memory) {
    return _name;
}
function symbol() public pure returns (string memory) {
    return _symbol;
}
function decimals() public pure returns (uint8) {
    return _decimals;
}
function totalSupply() public pure returns (uint256) {
    return _totalSupply;
}
function balanceOf(address _owner) public view returns (uint256 balance) {
    return _balanceOf[_owner];
}
function transfer(address _to, uint256 _value) public balanceCheck(_value) returns (bool success) {
    _balanceOf[msg.sender] -= _value;
    _balanceOf[_to] += _value;
    emit Transfer(msg.sender, _to, _value);
    return true;
}
function transferFrom(address _from, address _to, uint256 _value) public _balanceCheck(_from, _to, _value) returns (bool success) {
    _balanceOf[_from] -= _value;
    allowed[_from][msg.sender] -= _value;
    _balanceOf[_to] += _value;
    return true;
}
function approve(address _spender, uint256 _value) public returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
}
function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
}
}