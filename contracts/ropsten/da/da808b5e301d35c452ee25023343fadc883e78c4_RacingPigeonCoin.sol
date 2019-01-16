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
 * @title Racing Pigeon Coin
 */
contract RacingPigeonCoin is ERC20Token, Owned {

  string  public constant name     = "Racing Pigeon Coin";
  string  public constant symbol   = "RPC";
  uint256 public constant decimals = 18;

  uint256 public constant initialToken     = 500000000 * (10 ** decimals);

  uint256 public constant unlockedToken = initialToken * 40 / 100; // 40%
  uint256 public constant team1Token    = initialToken * 15 / 100; // 15%
  uint256 public constant team2Token    = initialToken * 15 / 100; // 15%
  uint256 public constant team3Token    = initialToken * 15 / 100; // 15%
  uint256 public constant team4Token    = initialToken * 15 / 100; // 15%

  address public constant team1Address  = 0x00602F855B9EC54D8A02aFb7d8a36d0129729242;
  address public constant team2Address  = 0x00215cFb433105d55344b6f8c9c8d6557203b858;
  address public constant team3Address  = 0x004a9b534313fA84Ed0295c5f255448bD68F085C;
  address public constant team4Address  = 0x00B219Cb01c0ba8176CFbB0bDA16d2729d9E2823;
  address public constant rescueAddress = 0x00bACAfB97DCcDb091e2b3554F6D3A2838383334;

  uint256 public constant team1LockEndTime = 1558314000; // 2019-05-20 01:00:00 GMT
  uint256 public constant team2LockEndTime = 1574211600; // 2019-11-20 01:00:00 GMT
  uint256 public constant team3LockEndTime = 1589936400; // 2020-05-20 01:00:00 GMT
  uint256 public constant team4LockEndTime = 1605834000; // 2020-11-20 01:00:00 GMT

  uint256 public constant maxDestroyThreshold = initialToken / 2;
  uint256 public constant maxBurnThreshold    = maxDestroyThreshold / 50;
  
  mapping(address => bool) lockAddresses;

  uint256 public destroyedToken;

  event Burn(address indexed _burner, uint256 _value);

  constructor() public {
    totalToken     = initialToken;

    balances[msg.sender]   = unlockedToken;
    balances[team1Address] = team1Token;
    balances[team2Address] = team2Token;
    balances[team3Address] = team3Token;
    balances[team4Address] = team4Token;

    emit Transfer(0x0, msg.sender, unlockedToken);
    emit Transfer(0x0, team1Address, team1Token);
    emit Transfer(0x0, team2Address, team2Token);
    emit Transfer(0x0, team3Address, team3Token);
    emit Transfer(0x0, team4Address, team4Token);

    lockAddresses[team1Address] = true;
    lockAddresses[team2Address] = true;
    lockAddresses[team3Address] = true;
    lockAddresses[team4Address] = true;

    destroyedToken = 0;
  }

  modifier transferable(address _addr) {
    require(!lockAddresses[_addr]);
    _;
  }

  function unlock() public onlyOwner {
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