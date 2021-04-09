/**
 *Submitted for verification at Etherscan.io on 2021-04-09
*/

pragma solidity ^0.5.17;

library SafeMath
{
  function add(uint256 a, uint256 b) internal pure returns (uint256)
  {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Variable
{
  string public name;
  string public symbol;
  uint256 public decimals;
  uint256 public totalSupply;
  address public owner;

  uint256 internal _decimals;
  bool internal transferLock;
  
  mapping (address => bool) public allowedAddress;
  mapping (address => bool) public blockedAddress;

  mapping (address => uint256) public balanceOf;
  
  mapping (address => bool) public lockTimeAddress;
  mapping (address => uint8) public lockCountMonth;
  mapping (address => uint256) public lockPermitBalance;
  mapping (address => uint256[]) public lockTime;
  mapping (address => uint8[]) public lockPercent;
  mapping (address => bool[]) public lockCheck;
  mapping (address => uint256[]) public lockBalance;

  constructor() public
  {
    name = "Beyond Finance";
    symbol = "BYN";
    decimals = 18;
    _decimals = 10 ** uint256(decimals);
    totalSupply = _decimals * 100000000;
    transferLock = true;
    owner =  msg.sender;
    balanceOf[owner] = totalSupply;
    allowedAddress[owner] = true;
  }
}

contract Modifiers is Variable
{
  modifier isOwner
  {
    assert(owner == msg.sender);
    _;
  }
}

contract Event
{
  event Transfer(address indexed from, address indexed to, uint256 value);
  event TokenBurn(address indexed from, uint256 value);
}

contract manageAddress is Variable, Modifiers, Event
{
  function add_allowedAddress(address _address) public isOwner
  {
    allowedAddress[_address] = true;
  }
  function delete_allowedAddress(address _address) public isOwner
  {
    require(_address != owner);
    allowedAddress[_address] = false;
  }
  function add_blockedAddress(address _address) public isOwner
  {
    require(_address != owner);
    blockedAddress[_address] = true;
  }
  function delete_blockedAddress(address _address) public isOwner
  {
    blockedAddress[_address] = false;
  }
  function add_timeAddress(address _address, uint8 total_month) public isOwner
  {
    if(lockTimeAddress[_address] == true)
    {
        revert();
    }
    if(total_month < 2 && lockCountMonth[_address] > 0)
    {
        revert();
    }
    lockCountMonth[_address] = total_month;
    lockTime[_address] = new uint256[](total_month);
    lockPercent[_address] = new uint8[](total_month);
    lockCheck[_address] = new bool[](total_month);
    lockBalance[_address] = new uint256[](total_month);
  }
  function delete_timeAddress(address _address) public isOwner
  {
    lockTimeAddress[_address] = false;
    lockCountMonth[_address] = 0;
    lockPermitBalance[_address] = 0;
    for(uint8 i = 0; i < lockCountMonth[_address]; i++)
    {
        delete lockTime[_address][i];
        delete lockPercent[_address][i];
        delete lockPercent[_address][i];
        delete lockCheck[_address][i];
        delete lockBalance[_address][i];
    }
  }
  function add_timeAddressMonth(address _address,uint256 _time,uint8 idx, uint8 _percent) public isOwner
  {
    if(now > _time)
    {
        revert();
    }
    if(idx >= lockCountMonth[_address])
    {
        revert();
    }
    if(idx != 0)
    {
        if(lockTime[_address][idx - 1] >= _time)
        {
            revert();
        }
    }
    lockPercent[_address][idx] = _percent;
  }
  function add_timeAddressApply(address _address, uint256 lock_balance) public isOwner
  {
    if(balanceOf[_address] >= lock_balance && lock_balance > 0)
    {
        uint8 sum = lockPercent[_address][0];

        lockPermitBalance[_address] = 0;
        for(uint8 i = 0; i < lockCountMonth[_address]; i++)
        {
            lockBalance[_address][i] = (lock_balance * lockPercent[_address][i]) / 100;
            if(i > 0)
            {
                sum += lockPercent[_address][i];
            }
        }
        
        if(sum != 100)
        {
            revert();
        }
        lockTimeAddress[_address] = true;
    }
    else
    {
        revert();
    }
    
  }
  function refresh_lockPermitBalance() public 
  {
    if(lockTimeAddress[msg.sender] == false)
    {
        revert();  
    }
    for(uint8 i = 0; i < lockCountMonth[msg.sender]; i++)
    {
        if(now >= lockTime[msg.sender][i] && lockCheck[msg.sender][i] == false)
        {
            lockPermitBalance[msg.sender] += lockBalance[msg.sender][i];
            lockCheck[msg.sender][i] = true;
            if(lockCountMonth[msg.sender] - 1 == i)
            {
                delete_timeAddress(msg.sender);
            }
        }
    }
  }
}
contract Admin is Variable, Modifiers, Event
{
  function admin_tokenBurn(uint256 _value) public isOwner returns(bool success)
  {
    require(balanceOf[msg.sender] >= _value);
    balanceOf[msg.sender] -= _value;
    totalSupply -= _value;
    emit TokenBurn(msg.sender, _value);
    return true;
  }
}
contract Get is Variable, Modifiers
{
  function get_transferLock() public view returns(bool)
  {
    return transferLock;
  }
  function get_blockedAddress(address _address) public view returns(bool)
  {
    return blockedAddress[_address];
  }
  
  function get_lockTimeAddress(address _address) public view returns(bool)
  {
    return lockTimeAddress[_address];
  }
  function get_lockCountMonth(address _address) public view returns(uint8)
  {
    if(blockedAddress[_address])
    {
        return lockCountMonth[_address];
    }
    else return 0;
  }
  function get_lockTime(address _address,uint8 idx) public view returns(uint256)
  {
      if(blockedAddress[_address])
      {
          if(idx < lockCountMonth[_address])
          {
            return lockTime[_address][idx];
          }
          else return 0;
      }
      else return 0;
  }
  function get_lockPermitBalance(address _address) public view returns(uint256)
  {
    if(blockedAddress[_address])
    {
        return lockPermitBalance[_address];
    }
    else return 0;
  }
  function get_lockPercent(address _address,uint8 idx) public view returns(uint8)
  {
    if(blockedAddress[_address])
    {
      if(idx < lockCountMonth[_address])
      {
        return lockPercent[_address][idx];
      }
      else return 0;
    }
    else return 0;
  }
  function get_lockBalance(address _address,uint8 idx) public view returns(uint256)
  {
    if(blockedAddress[_address])
    {
      if(idx < lockCountMonth[_address])
      {
        return lockBalance[_address][idx];
       }
      else return 0;
    }
    else return 0;
  }
}

contract Set is Variable, Modifiers, Event
{
  function setTransferLock(bool _transferLock) public isOwner returns(bool success)
  {
    transferLock = _transferLock;
    return true;
  }
}

contract BYN is Variable, Event, Get, Set, Admin, manageAddress
{
  using SafeMath for uint256;

  function() external payable 
  {
    revert();
  }
  function transfer(address _to, uint256 _value) public
  {
    
    require(allowedAddress[msg.sender] || transferLock == false);
    require(!blockedAddress[msg.sender] && !blockedAddress[_to]);
    require(balanceOf[msg.sender] >= _value && _value > 0);
    require((balanceOf[_to].add(_value)) >= balanceOf[_to] );
    require(!lockTimeAddress[_to]);
    if(lockTimeAddress[msg.sender] == false)
    {
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
    }
    else
    {
        refresh_lockPermitBalance();
        require(lockPermitBalance[msg.sender] >= _value);
        lockPermitBalance[msg.sender] -= _value;
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
    }
  }
}