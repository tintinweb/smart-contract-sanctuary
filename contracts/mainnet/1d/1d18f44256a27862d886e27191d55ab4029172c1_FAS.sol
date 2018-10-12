pragma solidity ^0.4.20;

// solc -v : 0.4.23+commit.124ca40d.Emscripten.clang

library safeMath
{
  function mul(uint256 a, uint256 b) internal pure returns (uint256)
  {
    if(a==0) return 0;
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256)
  {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

contract Event
{
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Deposit(address indexed sender, uint256 amount);
  event TokenBurn(address indexed from, uint256 value);
  event TokenAdd(address indexed from, uint256 value);
  event Set_TokenReward(uint256 changedTokenReward);
  event Set_DepositPeriod(uint256 startingTime, uint256 closingTime);
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
  uint256 internal _decimals;
  uint256 internal tokenReward;
  uint256 internal startingTime;
  uint256 internal closingTime;
  bool internal transferLock;
  bool internal depositLock;
  mapping (address => bool) public allowedAddress;
  mapping (address => bool) public blockedAddress;
  mapping (address => uint256) public tempLockedAddress;

  address withdraw_wallet;
  mapping (address => uint256) public balanceOf;


  constructor() public
  {
    name = "FAS";
    symbol = "FAS";
    decimals = 18;
    _decimals = 10 ** uint256(decimals);
    tokenReward = 0;
    totalSupply = _decimals * 3600000000;
    startingTime = 0;// 18.01.01 00:00:00 1514732400;
    closingTime = 0;// 18.12.31 23.59.59 1546268399;
    transferLock = true;
    depositLock = true;
    owner =  0x562C15Bb5Bd14Ed949b0dab50CcC45f75A9484CD;
    balanceOf[owner] = totalSupply;
    allowedAddress[owner] = true;
    withdraw_wallet = 0x562C15Bb5Bd14Ed949b0dab50CcC45f75A9484CD;
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
  function setTokenReward(uint256 _tokenReward) public isOwner returns(bool success)
  {
    tokenReward = _tokenReward;
    emit Set_TokenReward(tokenReward);
    return true;
  }
  function setDepositPeriod(uint256 _startingTime,uint256 _closingTime) public isOwner returns(bool success)
  {
    startingTime = _startingTime;
    closingTime = _closingTime;

    emit Set_DepositPeriod(startingTime, closingTime);
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
    return (startingTime,closingTime);
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
  using safeMath for uint256;

  function admin_transfer_tempLockAddress(address _to, uint256 _value, uint256 _unlockTime) public isOwner returns(bool success)
  {
    balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
    balanceOf[_to] = balanceOf[_to].add(_value);
    tempLockedAddress[_to] = _unlockTime;
    emit Transfer(msg.sender, _to, _value);
    emit TempLockedAddress(_to, _unlockTime);
    return true;
  }
  function admin_transferFrom(address _from, address _to, uint256 _value) public isOwner returns(bool success)
  {
    balanceOf[_from] = balanceOf[_from].sub(_value);
    balanceOf[_to] = balanceOf[_to].add(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }
  function admin_tokenBurn(uint256 _value) public isOwner returns(bool success)
  {
    balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
    totalSupply = totalSupply.sub(_value);
    emit TokenBurn(msg.sender, _value);
    return true;
  }
  function admin_tokenAdd(uint256 _value) public isOwner returns(bool success)
  {
    balanceOf[msg.sender] = balanceOf[msg.sender].add(_value);
    totalSupply = totalSupply.add(_value);
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

contract FAS is Variable, Event, Get, Set, Admin, manageAddress
{
  using safeMath for uint256;

  function() payable public
  {
    require(startingTime < block.timestamp && closingTime > block.timestamp);
    require(!depositLock);
    uint256 tokenValue;
    tokenValue = (msg.value).mul(tokenReward);
    emit Deposit(msg.sender, msg.value);
    balanceOf[owner] = balanceOf[owner].sub(tokenValue);
    balanceOf[msg.sender] = balanceOf[msg.sender].add(tokenValue);
    emit Transfer(owner, msg.sender, tokenValue);
  }
  function transfer(address _to, uint256 _value) public isValidAddress
  {
    require(allowedAddress[msg.sender] || transferLock == false);
    require(tempLockedAddress[msg.sender] < block.timestamp);
    require(!blockedAddress[msg.sender] && !blockedAddress[_to]);
    balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
    balanceOf[_to] = balanceOf[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
  }
  function withdraw(uint256 amount) public isOwner returns(bool)
  {
    withdraw_wallet.transfer(amount);
    emit WithdrawETH(amount);
    return true;
  }
}