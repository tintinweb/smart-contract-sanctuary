/**
 *Submitted for verification at Etherscan.io on 2021-07-07
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

contract LabNFT {
  string public constant name = "BLKCHN Lab 2021 Winner";
  string public constant symbol = "L21W";
  uint8 public constant decimals = 0;

  address[] public owners;

  mapping(address => mapping(address => bool)) public allownces;

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  constructor() public {
    owners.push(msg.sender);
  }

  function totalSupply() public pure returns (uint256) {
    return 1;
  }

  function balanceOf(address _owner) public view returns (uint256) {
    for(uint256 i = 0; i < owners.length; i++) {
      if(owners[i] == _owner)
        return 1;
    }

    return 0;
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
    if(allownces[_owner][_spender]) {
      for(uint256 i = 0; i < owners.length; i++) {
        if(!allownces[owners[i]][_spender])
          return 0;
      } 

      return 1;
    } else {
      return 0;
    }
  }

  function transfer(address _to, uint256 _tokens) public returns (bool) {
    if(_tokens == 0) {
      emit Transfer(msg.sender, _to, _tokens);
      return true;
    }

    require(_tokens == 1);
    address[] memory to = new address[](1);
    to[0] = _to;
    
    return transferToMany(to);
  }

  function transferToMany(address[] memory _to) public returns (bool) {
    bool isOwner = false;
    for(uint256 i = 0; i < owners.length; i++) {
      if(owners[i] == msg.sender)
        isOwner = true;
    }

    require(isOwner);

    for(uint256 i = 0; i < owners.length; i++) {
      for(uint256 j = 0; j < _to.length; j++) {
        if(allownces[owners[i]][_to[j]] == false) {
          require(owners[i] == msg.sender);
          allownces[owners[i]][_to[j]] = false;
        }
      }
    }

    delete owners;
    
    for(uint256 i = 0; i < _to.length; i++) {
      owners.push(_to[i]);

      emit Transfer(msg.sender, _to[i], 1);
    }

    return true;
  }

  function approve(address _spender, uint256 _tokens) public returns (bool) {
    require(_tokens <= 1);

    allownces[msg.sender][_spender] = _tokens == 1;

    emit Approval(msg.sender, _spender, _tokens);
    
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _tokens) public returns (bool) {
    if(_tokens == 0) {
      emit Transfer(_from, _to, _tokens);
      return true;
    }

    require(_tokens == 1);

    address[] memory to = new address[](1);
    to[0] = _to;
    return transferFromToMany(_from, to);
  }

  function transferFromToMany(address _from, address[] memory _to) public returns (bool) {
    for(uint256 i = 0; i < _to.length; i++) {
      require(allownces[_from][_to[i]]);
    } 

    for(uint256 i = 0; i < owners.length; i++) {
      for(uint256 j = 0; j < _to.length; j++) {
        require(allownces[owners[i]][_to[j]]);
      }
    }

    delete owners;
    for(uint256 j = 0; j < _to.length; j++) {
      owners.push(_to[j]);
      emit Transfer(_from, _to[j], 1);
    } 

    return true;
  }
}