pragma solidity ^0.4.23;

/**
 * @title SafeMath
 */
library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title ERC20 interface
 */
contract ERC20 {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _owner) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
  function approve(address _spender, uint256 _value) public returns (bool);
  function allowance(address _owner, address _spender) public view returns (uint256);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/**
 * @title Owned
 */
contract Owned {
  address public owner;

  constructor() public {
    owner = msg.sender;
  }
  
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }
}

/**
 * @title ERC20 token
 */
contract ERC20Token is ERC20 {
  using SafeMath for uint256;

  mapping(address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;
  uint256 public totalToken;

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(balances[msg.sender] >= _value);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(balances[_from] >= _value);
    require(allowed[_from][msg.sender] >= _value);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function totalSupply() public view returns (uint256) {
    return totalToken;
  }

  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }
}

/**
 * @title CCCCTest
 */
contract KKKKTEST is ERC20Token, Owned {

  string  public constant name     = "KKKK Token";
  string  public constant symbol   = "KKKK";
  uint256 public constant decimals = 18;

  uint256 public constant initialToken      = 500000000 * (10 ** decimals);

  uint256 public constant publicSellToken   = initialToken * 350 / 1000; // 35%
  uint256 public constant privateSell1Token = initialToken * 125 / 1000; // 12.5%
  uint256 public constant privateSell2Token = initialToken * 125 / 1000; // 12.5%
  uint256 public constant team1Token        = initialToken * 100 / 1000; // 10%
  uint256 public constant team2Token        = initialToken * 100 / 1000; // 10%
  uint256 public constant team3Token        = initialToken * 100 / 1000; // 10%
  uint256 public constant team4Token        = initialToken * 100 / 1000; // 10%

  address public constant privateSell1Address = 0x4eE26F915f55d9833e7Adb5a07F010819D84682A;
  address public constant privateSell2Address = 0xFA4A129f698C9c1c3545Caf994D8B3B24E234CcF;
  address public constant team1Address        = 0x2cFD5263896aA51085FFaBF0183dA67F26e5789c;
  address public constant team2Address        = 0x86BEa0b293dE7975aA9Dd49b8a52c0e10BD243dC;
  address public constant team3Address        = 0x998D65FB3cAF5da8bE56890414d9fC42a1A8952b;
  address public constant team4Address        = 0x7fb80E0bc908e02a6E7b0cA438370Af31B739445;
  address public constant rescueAddress       = 0x83Af23a1794886F5C680ba3448D7E43dBf851658;

  uint256 public constant publicSellLockEndTime   = 1526566422; // 2018-06-05 04:00:00 GMT
  uint256 public constant privateSell1LockEndTime = 1526568125; // 2018-07-15 04:00:00 GMT
  uint256 public constant privateSell2LockEndTime = 1526568125; // 2018-09-01 04:00:00 GMT
  uint256 public constant team1LockEndTime        = 1526568125; // 2018-06-05 04:00:00 GMT
  uint256 public constant team2LockEndTime        = 1526568125; // 2019-06-05 04:00:00 GMT
  uint256 public constant team3LockEndTime        = 1526568125; // 2020-06-05 04:00:00 GMT
  uint256 public constant team4LockEndTime        = 1526568125; // 2021-06-05 04:00:00 GMT

  uint256 public constant maxDestroyThreshold = initialToken / 2;
  uint256 public constant maxBurnThreshold    = maxDestroyThreshold / 8;
  
  mapping(address => bool) lockAddresses;

  uint256 public destroyedToken;

  event Burn(address indexed _burner, uint256 _value);

  constructor() public {
    totalToken     = initialToken;

    balances[msg.sender]          = publicSellToken;
    balances[privateSell1Address] = privateSell1Token;
    balances[privateSell2Address] = privateSell2Token;
    balances[team1Address]        = team1Token;
    balances[team2Address]        = team2Token;
    balances[team3Address]        = team3Token;
    balances[team4Address]        = team4Token;

    lockAddresses[privateSell1Address] = true;
    lockAddresses[privateSell2Address] = true;
    lockAddresses[team1Address]        = true;
    lockAddresses[team2Address]        = true;
    lockAddresses[team3Address]        = true;
    lockAddresses[team4Address]        = true;

    destroyedToken = 0;
  }

  modifier transferable(address _addr) {
    require(!lockAddresses[_addr]);
    _;
  }

  function unlock() public onlyOwner {
    if (lockAddresses[privateSell1Address] && now >= privateSell1LockEndTime)
      lockAddresses[privateSell1Address] = false;
    if (lockAddresses[privateSell2Address] && now >= privateSell2LockEndTime)
      lockAddresses[privateSell2Address] = false;
    if (lockAddresses[team1Address] && now >= team1LockEndTime)
      lockAddresses[team1Address] = false;
    if (lockAddresses[team2Address] && now >= team2LockEndTime)
      lockAddresses[team2Address] = false;
    if (lockAddresses[team3Address] && now >= team3LockEndTime)
      lockAddresses[team3Address] = false;
    if (lockAddresses[team4Address] && now >= team4LockEndTime)
      lockAddresses[team4Address] = false;
  }

  function transfer(address _to, uint256 _value) public transferable(msg.sender) returns (bool) {
    return super.transfer(_to, _value);
  }

  function approve(address _spender, uint256 _value) public transferable(msg.sender) returns (bool) {
    return super.approve(_spender, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public transferable(_from) returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function burn(uint256 _value) public onlyOwner returns (bool) {
    require(balances[msg.sender] >= _value);
    require(maxBurnThreshold >= _value);
    require(maxDestroyThreshold >= destroyedToken.add(_value));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    totalToken = totalToken.sub(_value);
    destroyedToken = destroyedToken.add(_value);
    emit Transfer(msg.sender, 0x0, _value);
    emit Burn(msg.sender, _value);
    return true;
  }

  function transferAnyERC20Token(address _tokenAddress, uint256 _value) public onlyOwner returns (bool) {
    return ERC20(_tokenAddress).transfer(rescueAddress, _value);
  }
}