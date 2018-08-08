pragma solidity ^0.4.11;

contract FitToken {
string public symbol;
string public name;
uint256 public decimals;
uint256 _totalSupply;

address public owner;

mapping(address => uint256) balances;

mapping(address => mapping (address => uint256)) allowed;

modifier onlyOwner() {
if (msg.sender != owner) {
revert();
}
_;
}

event Approval(address indexed _owner, address indexed _spender, uint256 _value);
event Transfer(address indexed _from, address indexed _to, uint256 _value);


function FitToken() {
owner = msg.sender;
decimals = 18;
_totalSupply = 400000000 * (10**decimals);
balances[owner] = _totalSupply;
symbol = "FIT";
name = "FIT TOKEN";
}


function totalSupply() public constant returns (uint256 totalSupply) {
totalSupply = _totalSupply;
}


function balanceOf(address _owner) public constant returns (uint256 balance) {
return balances[_owner];
}


function transfer(address _to, uint256 _amount) public returns (bool success) {
if (balances[msg.sender] >= _amount 
&& _amount > 0
&& balances[_to] + _amount > balances[_to]) {
balances[msg.sender] -= _amount;
balances[_to] += _amount;
Transfer(msg.sender, _to, _amount);
return true;
} else {
return false;
}
}


function transferFrom (
address _from,
address _to,
uint256 _amount
) public returns (bool success) {
if (balances[_from] >= _amount
&& allowed[_from][msg.sender] >= _amount
&& _amount > 0
&& balances[_to] + _amount > balances[_to]) {
balances[_from] -= _amount;
allowed[_from][msg.sender] -= _amount;
balances[_to] += _amount;
Transfer(_from, _to, _amount);
return true;
} else {
return false;
}
}


function approve(address _spender, uint256 _amount) public returns (bool success) {
allowed[msg.sender][_spender] = _amount;
Approval(msg.sender, _spender, _amount);
return true;
}

function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
return allowed[_owner][_spender];
}
}