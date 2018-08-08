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
 * @title OOTest
 */
contract OOTEST is ERC20Token, Owned {

  string  public constant name     = "OO Token";
  string  public constant symbol   = "OO";
  uint256 public constant decimals = 18;

  uint256 public constant initialToken      = 500000000 * (10 ** decimals);

  uint256 public constant publicSellToken   = initialToken * 350 / 1000; // 35%
  uint256 public constant privateSell1Token = initialToken * 125 / 1000; // 12.5%
  uint256 public constant privateSell2Token = initialToken * 125 / 1000; // 12.5%
  uint256 public constant team1Token        = initialToken * 100 / 1000; // 10%
  uint256 public constant team2Token        = initialToken * 100 / 1000; // 10%
  uint256 public constant team3Token        = initialToken * 100 / 1000; // 10%
  uint256 public constant team4Token        = initialToken * 100 / 1000; // 10%

  // mainnet
  address public constant privateSell1Address = 0x00f32621bc1f641afec54f82fc5416f090c8f936;
  address public constant privateSell2Address = 0x00e2b13871235796f0a5d2fd0fafe013f15f13f6;
  address public constant team1Address        = 0x00dc41ccc0f0844e37838badac5dc97bc2cf206f;
  address public constant team2Address        = 0x00ca7106cc04dba804d59f6fb9acef58d16d18c3;
  address public constant team3Address        = 0x0052f120c691e35d8b6845af8e963322a7895551;
  address public constant team4Address        = 0x005eb7b659e66cc11210e0407186ebb51ecf4d59;
  address public constant rescueAddress       = 0x00d952948a1d10a08bc419146620ed0f147ecef3;

  // mainnet
  uint256 public constant publicSellLockEndTime   = 1526860800; // 2018-06-05 04:00:00 GMT
  uint256 public constant privateSell1LockEndTime = 1526866200; // 2018-07-15 04:00:00 GMT
  uint256 public constant privateSell2LockEndTime = 1526871600; // 2018-09-01 04:00:00 GMT
  uint256 public constant team1LockEndTime        = 1526877000; // 2018-06-05 04:00:00 GMT
  uint256 public constant team2LockEndTime        = 1526882400; // 2019-06-05 04:00:00 GMT
  uint256 public constant team3LockEndTime        = 1526887800; // 2020-06-05 04:00:00 GMT
  uint256 public constant team4LockEndTime        = 1526893200; // 2021-06-05 04:00:00 GMT

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

    emit Transfer(0x0, msg.sender, publicSellToken);
    emit Transfer(0x0, privateSell1Address, privateSell1Token);
    emit Transfer(0x0, privateSell2Address, privateSell2Token);
    emit Transfer(0x0, team1Address, team1Token);
    emit Transfer(0x0, team2Address, team2Token);
    emit Transfer(0x0, team3Address, team3Token);
    emit Transfer(0x0, team4Address, team4Token);

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