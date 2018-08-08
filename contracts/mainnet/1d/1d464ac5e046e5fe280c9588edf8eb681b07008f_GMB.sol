pragma solidity ^0.4.20;
// produced by the Solididy File Flattener (c) David Appleton 2018
// contact : dave@akomba.com
// released under Apache 2.0 licence
library safeMath
{
  function mul(uint256 a, uint256 b) internal pure returns (uint256)
  {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256)
  {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Event
{
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Deposit(address indexed sender, uint256 amount , string status);
  event TokenBurn(address indexed from, uint256 value);
  event TokenAdd(address indexed from, uint256 value);
  event Set_Status(string changedStatus);
  event Set_TokenReward(uint256 changedTokenReward);
  event Set_TimeStamp(uint256 ICO_startingTime, uint256 ICO_closingTime);
  event WithdrawETH(uint256 amount);
  event BlockedAddress(address blockedAddress);
  event TempLockedAddress(address tempLockAddress, uint256 unlockTime);
}

contract Variable
{
  string public name;
  string public symbol;
  uint256 public decimals;
  uint256 public totalSupply;
  address public owner;
  string public status;

  uint256 internal _decimals;
  uint256 internal tokenReward;
  uint256 internal ICO_startingTime;
  uint256 internal ICO_closingTime;
  bool internal transferLock;
  bool internal depositLock;
  mapping (address => bool) public allowedAddress;
  mapping (address => bool) public blockedAddress;
  mapping (address => uint256) public tempLockedAddress;

  address withdraw_wallet;
  mapping (address => uint256) public balanceOf;


  constructor() public
  {
    name = "GMB";
    symbol = "GMB";
    decimals = 18;
    _decimals = 10 ** uint256(decimals);
    tokenReward = 0;
    totalSupply = _decimals * 5000000000;
    status = "";
    ICO_startingTime = 0;// 18.01.01 00:00:00 1514732400;
    ICO_closingTime = 0;// 18.12.31 23.59.59 1546268399;
    transferLock = true;
    depositLock = true;
    owner =  0xEfe9f7A61083ffE83Cbf833EeE61Eb1757Dd17BB;
    balanceOf[owner] = totalSupply;
    allowedAddress[owner] = true;
    withdraw_wallet = 0x7f7e8355A4c8fA72222DC66Bbb3E701779a2808F;
  }
}

contract Modifiers is Variable
{
  modifier isOwner
  {
    assert(owner == msg.sender);
    _;
  }

  modifier isValidAddress
  {
    assert(0x0 != msg.sender);
    _;
  }
}

contract Set is Variable, Modifiers, Event
{
  function setStatus(string _status) public isOwner returns(bool success)
  {
    status = _status;
    emit Set_Status(status);
    return true;
  }
  function setTokenReward(uint256 _tokenReward) public isOwner returns(bool success)
  {
    tokenReward = _tokenReward;
    emit Set_TokenReward(tokenReward);
    return true;
  }
  function setTimeStamp(uint256 _ICO_startingTime,uint256 _ICO_closingTime) public isOwner returns(bool success)
  {
    ICO_startingTime = _ICO_startingTime;
    ICO_closingTime = _ICO_closingTime;

    emit Set_TimeStamp(ICO_startingTime, ICO_closingTime);
    return true;
  }
  function setTransferLock(bool _transferLock) public isOwner returns(bool success)
  {
    transferLock = _transferLock;
    return true;
  }
  function setDepositLock(bool _depositLock) public isOwner returns(bool success)
  {
    depositLock = _depositLock;
    return true;
  }
  function setTimeStampStatus(uint256 _ICO_startingTime, uint256 _ICO_closingTime, string _status) public isOwner returns(bool success)
  {
    ICO_startingTime = _ICO_startingTime;
    ICO_closingTime = _ICO_closingTime;
    status = _status;
    emit Set_TimeStamp(ICO_startingTime,ICO_closingTime);
    emit Set_Status(status);
    return true;
  }
}

contract manageAddress is Variable, Modifiers, Event
{

  function add_allowedAddress(address _address) public isOwner
  {
    allowedAddress[_address] = true;
  }

  function add_blockedAddress(address _address) public isOwner
  {
    require(_address != owner);
    blockedAddress[_address] = true;
    emit BlockedAddress(_address);
  }

  function delete_allowedAddress(address _address) public isOwner
  {
    require(_address != owner);
    allowedAddress[_address] = false;
  }

  function delete_blockedAddress(address _address) public isOwner
  {
    blockedAddress[_address] = false;
  }
}

contract Get is Variable, Modifiers
{
  function get_tokenTime() public view returns(uint256 start, uint256 stop)
  {
    return (ICO_startingTime,ICO_closingTime);
  }
  function get_transferLock() public view returns(bool)
  {
    return transferLock;
  }
  function get_depositLock() public view returns(bool)
  {
    return depositLock;
  }
  function get_tokenReward() public view returns(uint256)
  {
    return tokenReward;
  }

}

contract Admin is Variable, Modifiers, Event
{
  function admin_transfer_tempLockAddress(address _to, uint256 _value, uint256 _unlockTime) public isOwner returns(bool success)
  {
    require(balanceOf[msg.sender] >= _value);
    require(balanceOf[_to] + (_value ) >= balanceOf[_to]);
    balanceOf[msg.sender] -= _value;
    balanceOf[_to] += _value;
    tempLockedAddress[_to] = _unlockTime;
    emit Transfer(msg.sender, _to, _value);
    emit TempLockedAddress(_to, _unlockTime);
    return true;
  }
  function admin_transferFrom(address _from, address _to, uint256 _value) public isOwner returns(bool success)
  {
    require(balanceOf[_from] >= _value);
    require(balanceOf[_to] + (_value ) >= balanceOf[_to]);
    balanceOf[_from] -= _value;
    balanceOf[_to] += _value;
    emit Transfer(_from, _to, _value);
    return true;
  }
  function admin_tokenBurn(uint256 _value) public isOwner returns(bool success)
  {
    require(balanceOf[msg.sender] >= _value);
    balanceOf[msg.sender] -= _value;
    totalSupply -= _value;
    emit TokenBurn(msg.sender, _value);
    return true;
  }
  function admin_tokenAdd(uint256 _value) public isOwner returns(bool success)
  {
    balanceOf[msg.sender] += _value;
    totalSupply += _value;
    emit TokenAdd(msg.sender, _value);
    return true;
  }
  function admin_renewLockedAddress(address _address, uint256 _unlockTime) public isOwner returns(bool success)
  {
    tempLockedAddress[_address] = _unlockTime;
    emit TempLockedAddress(_address, _unlockTime);
    return true;
  }
}

contract GMB is Variable, Event, Get, Set, Admin, manageAddress
{
  using safeMath for uint256;

  function() payable public
  {
    require(ICO_startingTime < block.timestamp && ICO_closingTime > block.timestamp);
    require(!depositLock);
    uint256 tokenValue;
    tokenValue = (msg.value).mul(tokenReward);
    require(balanceOf[owner] >= tokenValue);
    require(balanceOf[msg.sender].add(tokenValue) >= balanceOf[msg.sender]);
    emit Deposit(msg.sender, msg.value, status);
    balanceOf[owner] -= tokenValue;
    balanceOf[msg.sender] += tokenValue;
    emit Transfer(owner, msg.sender, tokenValue);
  }
  function transfer(address _to, uint256 _value) public isValidAddress
  {
    require(allowedAddress[msg.sender] || transferLock == false);
    require(tempLockedAddress[msg.sender] < block.timestamp);
    require(!blockedAddress[msg.sender] && !blockedAddress[_to]);
    require(balanceOf[msg.sender] >= _value);
    require((balanceOf[_to].add(_value)) >= balanceOf[_to]);
    balanceOf[msg.sender] -= _value;
    balanceOf[_to] += _value;
    emit Transfer(msg.sender, _to, _value);
  }
  function ETH_withdraw(uint256 amount) public isOwner returns(bool)
  {
    withdraw_wallet.transfer(amount);
    emit WithdrawETH(amount);
    return true;
  }
}