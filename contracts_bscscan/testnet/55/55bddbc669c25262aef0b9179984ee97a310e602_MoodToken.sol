/**
 *Submitted for verification at BscScan.com on 2021-10-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract MoodToken {

string public constant _name = "MoodToken";
string public constant _symbol = "MOOD";
uint8 public constant _decimals = 18;
uint256 public constant _totalSupply = 22000000000000000000000000;
address _minter = msg.sender;
address _contractAddress = address(this);



mapping (address => uint256) public _balanceOf;
mapping (address => mapping (address => uint256)) public allowed;
mapping (address => bool) public admin;

event Transfer(address indexed _from, address indexed _to, uint256 _value);
event Approval(address indexed _owner, address indexed _spender, uint256 _value);
event Received(address indexed _from, uint256 _value);
event setAdmin(address indexed _newAdmin);
event remAdmin(address indexed _remAdmin);
event Bought(uint256 _amount);
event Sold(uint256 _amount);

constructor() {
    _balanceOf[_minter] = 11000000000000000000000000; 
    _balanceOf[_contractAddress] = 11000000000000000000000000;
    admin[_minter] = true;
    emit setAdmin(_minter);
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

modifier _adminCheck(address addrs) {
    require(admin[addrs] == true);
    _;
}

modifier _buyCheck(uint _value) {
    require(balanceOf(_contractAddress) >= _value, "not enoghe token in contract");
    require(_value > 0, ">0");
    _;
}

function adminsMan(address _add, bool _value) public _adminCheck(msg.sender) returns (bool success) {
    admin[_add] = _value;
    if(_value == true) {
        emit setAdmin(_add);
    } else if (_value == false) {
        emit remAdmin(_add);
    }
    return true;
}

function adminCheck(address _add) public view returns (bool success) {
    if(admin[_add] == true) {
        return true;
    } else if (admin[_add] != true) {
        return false;
    }
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

function BNBbalance() public view _adminCheck(msg.sender) returns(uint) {
    return address(this).balance;
}

function sendBNB(address payable _to) public _adminCheck(msg.sender) payable {
    (bool sent, bytes memory data) = _to.call{value: msg.value}("");
    require(sent, "Failed to send Ether");
  }
  
function tokenbal() public view _adminCheck(msg.sender) returns(uint) {
    return balanceOf(_contractAddress);
}

function buy() payable _buyCheck(msg.value) public {
    transfer(msg.sender, msg.value);
    emit Bought(msg.value);
}

function sell(uint256 amount) public {
    require(amount > 0, "You need to sell at least some token");
    uint256 allowanc = allowance(msg.sender, address(this));
    require(allowanc >= amount, "Check the token allowance");
    transferFrom(msg.sender, address(this), amount);
}

}