/**
 *Submitted for verification at Etherscan.io on 2021-04-13
*/

pragma solidity ^0.5.17;

library SafeMath
{
	function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
		c = a + b;
		require(c >= a, "SafeMath: addition overflow");
	}
	function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
		require(b <= a, "SafeMath: subtraction overflow");
		c = a - b;
	}
	function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
		c = a * b;
		require(a == 0 || c / a == b, "SafeMath: multiplication overflow");
	}
	function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
		require(b > 0, "SafeMath: division by zero");
		c = a / b;
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
  using SafeMath for uint256;
  function add_allowedAddress(address _address) public isOwner
  {
    allowedAddress[_address] = true;
  }
  function delete_allowedAddress(address _address) public isOwner
  {
    require(_address != owner,"Not owner");
    allowedAddress[_address] = false;
  }
  function add_blockedAddress(address _address) public isOwner
  {
    require(_address != owner,"Not owner");
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
        revert("Already set address");
    }
    if(total_month < 2 && lockCountMonth[_address] > 0)
    {
        revert("Period want to set is short");
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
        revert("Must greater than current time");
    }
    if(idx >= lockCountMonth[_address])
    {
        revert("Invalid Setup Period");
    }
    if(idx != 0 && lockTime[_address][idx - 1] >= _time)
    {
        revert("Must greater than previous time");
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
            lockBalance[_address][i] = (lock_balance.mul(lockPercent[_address][i])).div(100);
            if(i > 0)
            {
                sum += lockPercent[_address][i];
            }
        }
        
        if(sum != 100)
        {
            revert("Invalid percentage");
        }
        lockTimeAddress[_address] = true;
    }
    else
    {
        revert("Invalid balance");
    }
    
  }
  function refresh_lockPermitBalance(address _address) public 
  {
    if(lockTimeAddress[_address] == false)
    {
        revert("Address without Lock");  
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
  using SafeMath for uint256;
  
  function admin_tokenBurn(uint256 _value) public isOwner returns(bool success)
  {
    require(balanceOf[msg.sender] >= _value, "Invalid balance");
    balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
    totalSupply = totalSupply.sub(_value);
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
  function() external payable 
  {
    revert();
  }
  function allowance(address tokenOwner, address spender) public view returns (uint256 remaining) 
  {
    return allowed[tokenOwner][spender];
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
    require(allowedAddress[_from] || transferLock == false, "Transfer lock : true");
    require(!blockedAddress[_from] && !blockedAddress[_to] && !blockedAddress[msg.sender], "Blocked address");
    require(balanceOf[_from] >= _value && (balanceOf[_to].add(_value)) >= balanceOf[_to], "Invalid balance");
    require(lockTimeAddress[_to] == false, "Lock address : to");
    require(_value <= allowed[_from][msg.sender], "Invalid balance : allowed");

    if(lockTimeAddress[_from])
    {
        lockPermitBalance[_from] = lockPermitBalance[_from].sub(_value);
    }

    balanceOf[_from] = balanceOf[_from].sub(_value);
    balanceOf[_to] = balanceOf[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);

    return true;

  }
  
  function transfer(address _to, uint256 _value) public returns (bool)  
  {
    require(allowedAddress[msg.sender] || transferLock == false, "Transfer lock : true");
    require(!blockedAddress[msg.sender] && !blockedAddress[_to], "Blocked address");
    require(balanceOf[msg.sender] >= _value && (balanceOf[_to].add(_value)) >= balanceOf[_to], "Invalid balance");
    require(lockTimeAddress[_to] == false, "Lock address : to");

    if(lockTimeAddress[msg.sender])
    {
        lockPermitBalance[msg.sender] = lockPermitBalance[msg.sender].sub(_value);
    }

    balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
    balanceOf[_to] = balanceOf[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
        
    return true;
  }
}