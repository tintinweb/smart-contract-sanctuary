/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.9.0;

contract ERC223 {
  function balanceOf(address who) public view returns (uint);

  function name() public view returns (string memory _name);
  function symbol() public view returns (string memory _symbol);
  function decimals() public view returns (uint8 _decimals);
  function totalSupply() public view returns (uint256 _supply);

  function transfer(address to, uint value) public returns (bool ok);
  function transfer(address to, uint value, bytes memory data) public returns (bool ok);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event ERC223Transfer(address indexed _from, address indexed _to, uint256 _value, bytes _data);
}

contract ContractReceiver {
  function tokenFallback(address _from, uint _value, bytes memory _data) public;
}

contract ERC223Token is ERC223 {

  mapping(address => uint) balances;

  // Function to access name of token .
  function name() public view returns (string memory _name) {
      _name = "SBTERC223";
      return _name;
  }
  // Function to access symbol of token .
  function symbol() public view returns (string memory _symbol) {
      _symbol = "SBT";
      return _symbol;
  }
  // Function to access decimals of token .
  function decimals() public view returns (uint8 _decimals) {
      return 18;
  }
  // Function to access total supply of tokens .
  function totalSupply() public view returns (uint256 _totalSupply) {
      return 400000000;
  }

  function transfer(address _to, uint _value, bytes memory _data) public returns (bool success) {
    if(isContract(_to)) {
        return transferToContract(_to, _value, _data);
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
}

  function transfer(address _to, uint _value) public returns (bool success) {

    bytes memory empty;
    if(isContract(_to)) {
        return transferToContract(_to, _value, empty);
    }
    else {
        return transferToAddress(_to, _value, empty);
    }
}

  function isContract(address _addr) private returns (bool is_contract) {
      uint length;
      assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        if(length>0) {
            return true;
        }
        else {
            return false;
        }
    }

  function transferToAddress(address _to, uint _value, bytes memory _data) private returns (bool success) {
    if (balanceOf(msg.sender) < _value) revert();
    balances[msg.sender] = balanceOf(msg.sender);
    balances[_to] = balanceOf(_to);
    emit Transfer(msg.sender, _to, _value);
    emit ERC223Transfer(msg.sender, _to, _value, _data);
    return true;
  }

  function transferToContract(address _to, uint _value, bytes memory _data) private returns (bool success) {
    if (balanceOf(msg.sender) < _value) revert();
    balances[msg.sender] = balanceOf(msg.sender);
    balances[_to] = balanceOf(_to);
    ContractReceiver reciever = ContractReceiver(_to);
    reciever.tokenFallback(msg.sender, _value, _data);
    emit Transfer(msg.sender, _to, _value);
    emit ERC223Transfer(msg.sender, _to, _value, _data);
    return true;
  }


  function balanceOf(address _owner) public view returns (uint balance) {
    return balances[_owner];
  }
}