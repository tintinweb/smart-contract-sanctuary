/**
 *Submitted for verification at BscScan.com on 2021-10-29
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IFipec
{

  function balance() external view returns (uint256);

  function balanceOf(address s) external view returns (uint256);

  function totalSupply() external view returns (uint256);

  function maxSupply() external view returns(uint256);

  function approve(address r, uint256 v) external returns (bool);

  function transfer(address r, uint256 v) external returns (bool);

  function transferFrom(address s, address r, uint256 v) external returns (bool);

  event Transfer(address indexed s, address indexed r, uint256 v);

  event Approval(address indexed s, address indexed r, uint256 v);

}

contract Fipec is IFipec
{

  string public _name;

  string public _symbol;

  uint8 public _decimals;

  address payable owner;

  uint256 public _totalSupply;

  uint256 public _maxSupply;

  mapping(address => uint256) public _balanceOf;

  mapping(address => mapping(address => uint256)) public _allowance;

  function balance() public view override returns (uint256)
  {

    return _balanceOf[msg.sender];

  }

  function balanceOf(address s) public view override returns (uint256)
  {

    return _balanceOf[s];

  }

  function totalSupply() public view override returns (uint256)
  {

    return _totalSupply;

  }

  function maxSupply() public view override returns (uint256)
  {

    return _maxSupply;

  }

  function approve(address s, uint256 v) public override returns (bool)
  {

    _allowance[msg.sender][s] = v;

    emit Approval(msg.sender, s, v);

    return true;

  }

  function transfer(address r, uint256 v) public override returns (bool)
  {

    return transferFrom(msg.sender, r, v);

  }

  function transferFrom(address s, address r, uint256 v) public override returns (bool)
  {

    require(s != address(0));

    require(r != address(0));

    require(balanceOf(s) >= v);

    if (s != msg.sender)
      {

        require(_allowance[s][msg.sender] >= v);

        _allowance[s][msg.sender] -= v;

      }

      _balanceOf[s] -= v;

      _balanceOf[r] += v;

      emit Transfer(s, r, v);

      return true;

  }

}

abstract contract Burnable is Fipec
{

  function _burn(address s, uint256 v) external returns (bool)
  {

    require(s != address(0));

    require(_balanceOf[s] >= v);

    require(_totalSupply >= v);

    require(_maxSupply >= v);

    _balanceOf[s] -= v;

    _totalSupply -= v;

    _maxSupply -= v;

    emit Transfer(s, address(0), v);

    return true;

  }

}

abstract contract Mintable is Fipec
{

  function _mint(address s, uint256 v) public returns (bool)
  {

    require(s != address(0));

    uint256 aftermint = _totalSupply + v;

    require(_maxSupply >= aftermint);

    _totalSupply += v;

    _balanceOf[s] += v;

    emit Transfer(address(0), s, v);

    return true;

  }

}

interface Sellable
{

  function _createSell(bool status, uint256 m, uint256 d) external returns (bool);

  function _buy() external payable returns (bool);

  event Buy(address indexed s, address indexed r, uint256 v);

}


abstract contract SellFipec is Sellable, Fipec 
{

  bool public _status;

  uint256 _m;

  uint256 _d;

  function _createSell(bool status, uint256 m, uint256 d) external returns (bool)
  {

    _status = status;

    _m = m;

    _d = d;

    return true;

  }

  function _buy() public payable returns (bool)
  {

    require(_status == true);

    uint256 _total = (msg.value * _m) / _d;

    require(balanceOf(owner) >= _total);

    _balanceOf[owner] -= _total;

    _balanceOf[msg.sender] += _total;

    owner.transfer(msg.value);

    emit Buy(owner, msg.sender, _total);

    return true;

  }

}


pragma solidity ^0.8.7;

contract Fipecrypto is Fipec, Burnable, Mintable, SellFipec 
{

  constructor()
  {

    _name = 'Fipe Crypto';

    _symbol = '$FCT';

    _maxSupply = 100000000 ether;

    _decimals = 18;

    _mint(msg.sender, 1000000 ether);

  }

}