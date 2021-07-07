/**
 *Submitted for verification at Etherscan.io on 2021-07-07
*/

// "SPDX-License-Identifier: UNLICENSED"

pragma solidity 0.6.9;

contract SIMPLIS {

using SafeMath for uint256;

string public constant symbol = "SIMPLIs";
string public constant name = "SIMPLI-S DEFI TOKEN";
uint8 public constant decimals = 16;
uint256 _totalSupply;
address public owner;

mapping(address => uint256) balances;
mapping(address => mapping (address => uint256)) allowances;

constructor() public {
    owner = msg.sender;
    _totalSupply = 17650 * 10 ** uint256(decimals);
    balances[owner] = _totalSupply;
    emit Transfer(address(0), owner, _totalSupply);
}
function totalSupply() public view returns (uint256) {
   return _totalSupply;
}
function balanceOf(address account) public view returns (uint256 balance) {
   return balances[account];
}
function transfer(address _to, uint256 _amount) public returns (bool success) {
    require(msg.sender != address(0), "ERC20: approve from the zero address");
    require(_to != address(0), "ERC20: approve from the zero address");
    require(balances[msg.sender] >= _amount);
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Transfer(msg.sender, _to, _amount);
    return true;
}
function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
    require(_from != address(0), "ERC20: approve from the zero address");
    require(_to != address(0), "ERC20: approve from the zero address");
    require(balances[_from] >= _amount && allowances[_from][msg.sender] >= _amount);
    balances[_from] = balances[_from].sub(_amount);
    allowances[_from][msg.sender] = allowances[_from][msg.sender].sub(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Transfer(_from, _to, _amount);
    return true;
}
function approve(address spender, uint256 _amount) public returns (bool) {
    _approve(msg.sender, spender, _amount);
    return true;
}
function _approve(address _owner, address _spender, uint256 _amount) internal {
    require(_owner != address(0), "ERC20: approve from the zero address");
    require(_spender != address(0), "ERC20: approve to the zero address");
    allowances[_owner][_spender] = _amount;
    emit Approval(_owner, _spender, _amount);
    }
function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
   return allowances[_owner][_spender];
}

function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(msg.sender, spender, allowances[msg.sender][spender].sub(subtractedValue));
    return true;
}
function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, allowances[msg.sender][spender].add(addedValue));
        return true;
}

event Transfer(address indexed _from, address indexed _to, uint _value);
event Approval(address indexed _owner, address indexed _spender, uint _value);

}

library SafeMath {
    
function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
}
function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;
    return c;
}
}