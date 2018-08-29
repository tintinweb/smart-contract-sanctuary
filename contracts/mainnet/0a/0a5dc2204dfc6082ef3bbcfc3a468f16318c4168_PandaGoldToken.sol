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
 * @title PandaGold Token
 */
contract PandaGoldToken is ERC20Token, Owned {

  string  public constant name     = "PandaGold Token";
  string  public constant symbol   = "PANDA";
  uint256 public constant decimals = 18;

  uint256 public constant initialToken     = 2000000000 * (10 ** decimals);

  uint256 public constant publicToken      = initialToken * 55 / 100; // 55%
  uint256 public constant founderToken     = initialToken * 10 / 100; // 10%
  uint256 public constant developmentToken = initialToken * 10 / 100; // 10%
  uint256 public constant bountyToken      = initialToken *  5 / 100; //  5%
  uint256 public constant privateSaleToken = initialToken * 10 / 100; // 10%
  uint256 public constant preSaleToken     = initialToken * 10 / 100; // 10%

  address public constant founderAddress     = 0x003d9d0ebfbDa7AEc39EEAEcc4D47Dd18eA3c495;
  address public constant developmentAddress = 0x00aCede2bdf8aecCedb0B669DbA662edC93D6178;
  address public constant bountyAddress      = 0x00D42B2864C6E383b1FD9E56540c43d3815D486e;
  address public constant privateSaleAddress = 0x00507Bf4d07A693fB7C4F9d846d58951042260aa;
  address public constant preSaleAddress     = 0x00241bD9aa09b440DE23835BB2EE0a45926Bb61A;
  address public constant rescueAddress      = 0x005F25Bc2386BfE9E5612f2C437c5e5E45720874;

  uint256 public constant founderLockEndTime     = 1577836800; // 2020-01-01 00:00:00 GMT
  uint256 public constant developmentLockEndTime = 1559347200; // 2019-06-01 00:00:00 GMT
  uint256 public constant bountyLockEndTime      = 1543363200; // 2018-11-28 00:00:00 GMT
  uint256 public constant privateSaleLockEndTime = 1546300800; // 2019-01-01 00:00:00 GMT
  uint256 public constant preSaleLockEndTime     = 1543363200; // 2018-11-28 00:00:00 GMT

  uint256 public constant maxDestroyThreshold = initialToken / 2;
  uint256 public constant maxBurnThreshold    = maxDestroyThreshold / 50;
  
  mapping(address => bool) lockAddresses;

  uint256 public destroyedToken;

  event Burn(address indexed _burner, uint256 _value);

  constructor() public {
    totalToken     = initialToken;

    balances[msg.sender]         = publicToken;
    balances[founderAddress]     = founderToken;
    balances[developmentAddress] = developmentToken;
    balances[bountyAddress]      = bountyToken;
    balances[privateSaleAddress] = privateSaleToken;
    balances[preSaleAddress]     = preSaleToken;

    emit Transfer(0x0, msg.sender, publicToken);
    emit Transfer(0x0, founderAddress, founderToken);
    emit Transfer(0x0, developmentAddress, developmentToken);
    emit Transfer(0x0, bountyAddress, bountyToken);
    emit Transfer(0x0, privateSaleAddress, privateSaleToken);
    emit Transfer(0x0, preSaleAddress, preSaleToken);

    lockAddresses[founderAddress]     = true;
    lockAddresses[developmentAddress] = true;
    lockAddresses[bountyAddress]      = true;
    lockAddresses[privateSaleAddress] = true;
    lockAddresses[preSaleAddress]     = true;

    destroyedToken = 0;
  }

  modifier transferable(address _addr) {
    require(!lockAddresses[_addr]);
    _;
  }

  function unlock() public onlyOwner {
    if (lockAddresses[founderAddress] && now >= founderLockEndTime)
      lockAddresses[founderAddress] = false;
    if (lockAddresses[developmentAddress] && now >= developmentLockEndTime)
      lockAddresses[developmentAddress] = false;
    if (lockAddresses[bountyAddress] && now >= bountyLockEndTime)
      lockAddresses[bountyAddress] = false;
    if (lockAddresses[privateSaleAddress] && now >= privateSaleLockEndTime)
      lockAddresses[privateSaleAddress] = false;
    if (lockAddresses[preSaleAddress] && now >= preSaleLockEndTime)
      lockAddresses[preSaleAddress] = false;
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