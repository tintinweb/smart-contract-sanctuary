/**
 *Submitted for verification at BscScan.com on 2021-10-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Fipecrypto 
{

  string public name = 'Fipe Crypto';

  string public symbol = '$FCT';

  uint8 public decimals = 18;

  uint256 public maxSupply;

  uint256 public totalSupply;

  address payable private owner;

  bool private onSale;

  uint256 private _m;

  uint256 private _d;

  uint256 public assets;

  mapping(address => uint256) public balanceOf;

  mapping(address => mapping(address => uint256)) public allownaces;

  event Transfer(address indexed s, address indexed r, uint256 v);

  event Approval(address indexed s, address indexed r, uint256 v);

  event Buy(address indexed s, address indexed r, uint256 v);

  event Withdraw(address indexed d, uint256 v);

  constructor()
  {

    owner = payable(msg.sender);

  }

  function balance() public view returns (uint256)
  {

    return balanceOf[msg.sender];

  }

  modifier onlyOwner 
  {

    require(msg.sender == owner, 'Only owner can use this function');

    _;

  }

  function mint(address r, uint256 v) public onlyOwner returns (bool)
  {

    uint256 aftermint = totalSupply + v;

    require(maxSupply >= aftermint, 'Reached maximum supply');

    balanceOf[r] += v;

    totalSupply = aftermint;

    emit Transfer(address(0), r, v);

    return true;

  }

  function burn(address s, uint256 v) public onlyOwner returns (bool)
  {

    require(balanceOf[s] >= v);

    balanceOf[s] -= v;

    maxSupply -= v;

    totalSupply -= v;

    emit Transfer(s, address(0), v);

    return true;

  }

  function approve(address r, uint256 v) public returns (bool)
  {

    allownaces[msg.sender][r] = v;

    emit Approval(msg.sender, r, v);

    return true;

  }

  function transfer(address r, uint256 v) public returns (bool)
  {

    return transferFrom(msg.sender, r, v);

  }

  function transferFrom(address s, address r, uint256 v) public returns (bool)
  {

    require(balanceOf[s] >= v, 'Insufficient balance');
    require(s != address(0), 'Cannot transfer from zero address');

    require(r != address(0), 'Cannot transfer to zero address');

    if (s != msg.sender)
    {

      require(allownaces[s][msg.sender] >= v, 'You doesnt have permission to transfer from this address');

      allownaces[s][msg.sender] -= v;

    }

    balanceOf[s] -= v;

    balanceOf[r] += v;

    emit Transfer(s, r, v);

    return true;

  }

  function setSell(bool status, uint256 m, uint256 d) public onlyOwner
  {

    onSale = status;

    _m = m;

    _d = d;

  }

  function buy() public payable 
  {

    require(onSale == true, 'Sale is off');

    uint256 totalBuy = (msg.value * _m) / _d;

    require(balanceOf[owner] >= totalBuy, 'Seller has insufficient balance');

    balanceOf[owner] -= totalBuy;

    balanceOf[msg.sender] += totalBuy;

    assets += msg.value;

    emit Buy(owner, msg.sender, totalBuy);

  }

  function withdraw(uint256 v) public onlyOwner returns (bool)
  {

    require(assets >= v, 'Insufficient balance');

    assets -= v;

    owner.transfer(v);

    emit Withdraw(msg.sender, v);

    return true;

  }

}