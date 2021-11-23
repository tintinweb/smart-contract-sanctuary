// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Owned.sol";

contract TokenFactory is Owned {
  string public name;
  string public symbol;
  uint8 public decimals = 18;
  uint256 public totalSupply;

  mapping (address => uint256) public balanceOf;
  mapping (address =>  mapping (address => uint256)) public allowance;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  constructor(uint256 initialSupply, string memory tokenName, string memory tokenSymbol) {
    totalSupply = initialSupply * 10 ** uint256(decimals);
    balanceOf[msg.sender] = totalSupply;
    name = tokenName;
    symbol = tokenSymbol;
  }

  function _transfer(address _from, address _to, uint256 _value) internal {
    require(_to != address(0));
    require(balanceOf[_from] >= _value);
    require(balanceOf[_to] + _value >= balanceOf[_to]);

    uint256 previousBalances = balanceOf[_from] + balanceOf[_to];

    balanceOf[_from] -= _value;
    balanceOf[_to] += _value;
    emit Transfer(_from, _to, _value);
    assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
  }

  function transfer(address _to, uint256 _value) public returns (bool success) {
    _transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    require(_value <= allowance[_from][msg.sender]);
    allowance[_from][msg.sender] -= _value;
    _transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool success) {
    allowance[msg.sender][_spender] -= _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function mintToken(address target, uint256 mintedAmount) restricted public {
    balanceOf[target] += mintedAmount * 10 ** uint256(decimals);
    totalSupply += mintedAmount * 10 ** uint256(decimals);
    emit Transfer(address(0), owner, mintedAmount);
    emit Transfer(owner, target, mintedAmount);
  }
}