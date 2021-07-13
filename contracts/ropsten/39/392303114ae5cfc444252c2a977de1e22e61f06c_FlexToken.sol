/**
 *Submitted for verification at Etherscan.io on 2021-07-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FlexToken {

  uint _totalSupply;
  string public name;
  string public symbol;
  uint8 _decimal;
  address _owner;
  
  mapping(address => uint) _balance;
  mapping(address => mapping(address => uint)) _allowances;
  
  event Transfer(address indexed from, address indexed to, uint tokens);  
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
  
  constructor (uint _initSupply) {
    _owner = msg.sender;
    _mint(_owner, _initSupply);
    name = "Flex Token";
    symbol = "FLEXT";
  }
  
  function _mint(address _account,uint _amount) internal {
    _totalSupply += _amount;
    _balance[_account] += _amount;
    emit Transfer(address(0), _account, _amount);
  }
  
  function totalSupply() public view returns (uint) {
    return _totalSupply;
  }
  function balanceOf(address _tokenOwner) public view returns (uint balance) {
    return _balance[_tokenOwner];
  }
  function allowance(address _tokenOwner, address _spender) public view returns (uint remaining) {
    return _allowances[_tokenOwner][_spender];
  }
  function transfer(address _to, uint _tokens) public returns (bool success) {
    require(_balance[msg.sender] >= _tokens, "not enough money");
    require(_to == msg.sender, "Can't transfer token to self address");
    if ( msg.sender == _owner ) {
        _totalSupply -= _tokens;
    }
    _balance[msg.sender] -= _tokens;
    _balance[_to] += _tokens;
    emit Transfer(msg.sender, _to, _tokens);
    return true;
  }
  function approve(address _spender, uint _tokens) public returns (bool success) {
    require(msg.sender != address(0), "ERC20: transfer from the zero address");
    require(_spender != address(0), "ERC20: transfer to the zero address");
    if ( msg.sender == _owner ) {
        _totalSupply -= _tokens;
    }
    _allowances[msg.sender][_spender] += _tokens;
    _balance[msg.sender] -= _tokens;
    
    return true;
  }
  function transferFrom(address _tokenOwner, address _spender, uint _tokens) public returns (bool success) {
    _allowances[_tokenOwner][_spender] -= _tokens;
    _balance[_spender] += _tokens;
    emit Approval(_tokenOwner, _spender, _tokens);
    return true;
  }
}