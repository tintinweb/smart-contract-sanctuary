/**
 *Submitted for verification at Etherscan.io on 2021-04-12
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
   function sub(uint256 a, uint256 b) internal pure returns (uint256) 
  {
    assert(b <= a);
    return a - b;
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
  
  mapping (address => mapping (address => uint256)) internal allowed;

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
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
    lockPermitBalance[_address] = 0;
    for(uint8 i = 0; i < lockCountMonth[_address]; i++)
    {
        lockTime[_address][i] = 0;
        lockPercent[_address][i] = 0;
        lockCheck[_address][i] = false;
        lockBalance[_address][i] = 0;
        delete lockTime[_address][i];
        delete lockPercent[_address][i];
        delete lockCheck[_address][i];
        delete lockBalance[_address][i];
    }
    lockCountMonth[_address] = 0;
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
    lockTime[_address][idx] = _time;
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
  function refresh_lockPermitBalance(address _address) public 
  {
    if(lockTimeAddress[_address] == false)
    {
        revert();  
    }
    for(uint8 i = 0; i < lockCountMonth[msg.sender]; i++)
    {
        if(now >= lockTime[_address][i] && lockCheck[_address][i] == false)
        {
            lockPermitBalance[_address] += lockBalance[_address][i];
            lockCheck[_address][i] = true;
            if(lockCountMonth[_address] - 1 == i)
            {
                delete_timeAddress(_address);
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
  
  function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) 
  {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
  function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) 
    {
        allowed[msg.sender][_spender] = 0;
    } 
    else
    {
        allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
  function approve(address _spender, uint256 _value) public returns (bool)
  {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) 
  {
    require(_to != address(0));
    require(_value <= balanceOf[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balanceOf[_from] = balanceOf[_from].sub(_value);
    balanceOf[_to] = balanceOf[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);

    return true;
  }
  
  function transfer(address _to, uint256 _value) public
  {
    
    require(allowedAddress[msg.sender] || transferLock == false);
    require(!blockedAddress[msg.sender] && !blockedAddress[_to]);
    require(balanceOf[msg.sender] >= _value && _value > 0);
    require((balanceOf[_to].add(_value)) >= balanceOf[_to] );
    require(lockTimeAddress[_to] == false);
    if(lockTimeAddress[msg.sender] == false)
    {
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
    }
    else
    {
        require(lockPermitBalance[msg.sender] >= _value);
        lockPermitBalance[msg.sender] -= _value;
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
    }
  }
}