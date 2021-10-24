/**
 *Submitted for verification at BscScan.com on 2021-10-23
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;

contract TUSDC {
  uint256 constant private MAX_UINT256 = 2 ** 256 - 1;

  string public name;
  uint8 public decimals;
  string public symbol;
  uint256 public totalSupply;
  mapping(address => uint256) public balances;
  mapping(address => mapping(address => uint256)) public allowed;

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  constructor(string memory _name, uint8 _decimals, string memory _symbol, uint256 _totalSupply) public {
      name = _name;
      decimals = _decimals;
      symbol = _symbol;
      totalSupply = _totalSupply;
      balances[msg.sender] = _totalSupply;
  }

  function transfer(address _to, uint256 _value) public returns (bool success) {
      require(balances[msg.sender] >= _value, 'balances not enough');
      balances[msg.sender] -= _value;
      balances[_to] += _value;
      emit Transfer(msg.sender, _to, _value);
      return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
      uint256 allowance = allowed[_from][msg.sender];
      require(balances[_from] >= _value, 'balances not enough');
      require(allowance >= _value, 'allowance not enough');

      balances[_to] += _value;
      balances[_from] -= _value;
      if (allowance < MAX_UINT256) {
          allowed[_from][msg.sender] -= _value;
      }
      emit Transfer(_from, _to, _value);
      return true;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
      return balances[_owner];
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