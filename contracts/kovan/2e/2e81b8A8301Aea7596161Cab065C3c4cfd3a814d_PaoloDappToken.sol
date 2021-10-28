// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PaoloDappToken{
  string public name = "Paolo Dapp Token";        //Token name
  string public symbol = "DAPP";            //Toekn symbol
  string public standard = "Paolo Dapp Token v1.0";
  uint256 public totalSupply;
  uint8 public decimals = 2;
  
  mapping(address => uint256) public balanceOf;
  mapping(address => mapping(address => uint256)) public allowance;   

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  
  constructor() {
    totalSupply = 100000;
  }

  function transfer (address _to, uint256 _value) public returns (bool success){
    require (balanceOf[msg.sender] >= _value, "PaoloDappToken: not enough balance");
    balanceOf[msg.sender] -= _value;
    balanceOf[_to] += _value;
    emit Transfer(msg.sender, _to, _value);
    return true; 
  }

  function approve (address _spender, uint256 _value) public returns (bool success) {
    allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function transferFrom (address _from, address _to, uint256 _value) public returns (bool success){
    require (_value <= balanceOf[_from], "PaoloDappToken: not enough balance");
    require (_value <= allowance[_from][msg.sender], "PaoloDappToken: not enough allowance");
    
    balanceOf[_from] -= _value;
    balanceOf[_to] += _value;
    allowance[_from][msg.sender] -= _value;

    emit Transfer(_from, _to, _value);
    return true;
  }
}