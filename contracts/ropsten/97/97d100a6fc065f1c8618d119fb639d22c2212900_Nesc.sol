pragma solidity ^0.4.18;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions"
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner
   * @param newOwner The address to transfer ownership to
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

/*
 * @title Migration Agent interface
 */
contract MigrationAgent {
  function migrateFrom(address _from, uint256 _value);
}

contract ERC20 {
    function totalSupply() constant returns (uint256);
    function balanceOf(address who) constant returns (uint256);
    function transfer(address to, uint256 value);
    function transferFrom(address from, address to, uint256 value);
    function approve(address spender, uint256 value);
    function allowance(address owner, address spender) constant returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Nesc is Ownable, ERC20 {
  using SafeMath for uint256;

  uint8 private _decimals = 18;
  uint256 private decimalMultiplier = 10**(uint256(_decimals));

  string private _name = "Nebula Exchange Token";
  string private _symbol = "NESC";
  uint256 private _totalSupply = 10000000 * decimalMultiplier;

  bool public tradable = true;

  // Wallet Address of Token
  address public multisig;

  // Function to access name of token
  function name() constant returns (string) {
    return _name;
  }

  // Function to access symbol of token
  function symbol() constant returns (string) {
    return _symbol;
  }

  // Function to access decimals of token
  function decimals() constant returns (uint8) {
    return _decimals;
  }

  // Function to access total supply of tokens
  function totalSupply() constant returns (uint256) {
    return _totalSupply;
  }

  mapping(address => uint256) balances;
  mapping(address => mapping (address => uint256)) allowed;
  mapping(address => uint256) releaseTimes;
  address public migrationAgent;
  uint256 public totalMigrated;

  event Migrate(address indexed _from, address indexed _to, uint256 _value);

  // Constructor
  // @notice Nesc Contract
  // @return the transaction address
  function Nesc(address _multisig) {
    require(_multisig != 0x0);
    multisig = _multisig;
    balances[multisig] = _totalSupply;
  }

  modifier canTrade() {
    require(tradable);
    _;
  }

  // Standard function transfer similar to ERC20 transfer with no _data
  // Added due to backwards compatibility reasons
  function transfer(address to, uint256 value) canTrade {
    require(!isLocked(msg.sender));
    require (balances[msg.sender] >= value && value > 0);
    balances[msg.sender] = balances[msg.sender].sub(value);
    balances[to] = balances[to].add(value);
    Transfer(msg.sender, to, value);
  }

  /**
   * @dev Gets the balance of the specified address
   * @param who The address to query the the balance of
   * @return An uint256 representing the amount owned by the passed address
   */
  function balanceOf(address who) constant returns (uint256) {
    return balances[who];
  }

 /**
  * @dev Transfer tokens from one address to another
  * @param from address The address which you want to send tokens from
  * @param to address The address which you want to transfer to
  * @param value uint256 the amount of tokens to be transfered
  */
  function transferFrom(address from, address to, uint256 value) canTrade {
    require(to != 0x0);
    require(!isLocked(from));
    uint256 _allowance = allowed[from][msg.sender];
    require(value > 0 && _allowance >= value);
    balances[from] = balances[from].sub(value);
    balances[to] = balances[to].add(value);
    allowed[from][msg.sender] = _allowance.sub(value);
    Transfer(from, to, value);
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
   * @param spender The address which will spend the funds
   * @param value The amount of tokens to be spent
   */
  function approve(address spender, uint256 value) canTrade {
    require((value >= 0) && (allowed[msg.sender][spender] >= 0));
    allowed[msg.sender][spender] = value;
    Approval(msg.sender, spender, value);
  }

  // Check the allowed value for the spender to withdraw from owner
  // @param owner The address of the owner
  // @param spender The address of the spender
  // @return the amount which spender is still allowed to withdraw from owner
  function allowance(address owner, address spender) constant returns (uint256) {
    return allowed[owner][spender];
  }

  /**
   * @dev Function to update tradable status
   * @param _newTradableState New tradable state
   * @return A boolean that indicates if the operation was successful
   */
  function setTradable(bool _newTradableState) onlyOwner public {
    tradable = _newTradableState;
  }

  /**
   * Function to lock a given address until the specified date
   * @param spender Address to lock
   * @param date A timestamp specifying when the account will be unlocked
   * @return A boolean that indicates if the operation was successful
   */
  function timeLock(address spender, uint256 date) public onlyOwner returns (bool) {
    releaseTimes[spender] = date;
    return true;
  }

  /**
   * Function to check if a given address is locked or not
   * @param _spender Address
   * @return A boolean that indicates if the account is locked or not
   */
  function isLocked(address _spender) public view returns (bool) {
    if (releaseTimes[_spender] == 0 || releaseTimes[_spender] <= block.timestamp) {
      return false;
    }
    return true;
  }

  /**
   * @notice Set address of migration target contract and enable migration process
   * @dev Required state: Operational Normal
   * @dev State transition: -> Operational Migration
   * @param _agent The address of the MigrationAgent contract
   */
  function setMigrationAgent(address _agent) external onlyOwner {
    require(migrationAgent == 0x0 && totalMigrated == 0);
    migrationAgent = _agent;
  }

  /*
   * @notice Migrate tokens to the new token contract.
   * @dev Required state: Operational Migration
   * @param _value The amount of token to be migrated
   */
  function migrate(uint256 value) external {
    require(migrationAgent != 0x0);
    require(value >= 0);
    require(value <= balances[msg.sender]);

    balances[msg.sender] -= value;
    _totalSupply = _totalSupply.sub(value);
    totalMigrated = totalMigrated.add(value);
    MigrationAgent(migrationAgent).migrateFrom(msg.sender, value);
    Migrate(msg.sender, migrationAgent, value);
  }
}