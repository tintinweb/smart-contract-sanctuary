pragma solidity ^0.4.15;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

/**
 * @title Contracts that should not own Tokens
 * @author Remco Bloemen <<span class="__cf_email__" data-cfemail="6a180f0709052a58">[email&#160;protected]</span>π.com>
 * @dev This blocks incoming ERC23 tokens to prevent accidental loss of tokens.
 * Should tokens (any ERC20Basic compatible) end up in the contract, it allows the
 * owner to reclaim the tokens.
 */
contract HasNoTokens is Ownable {

 /**
  * @dev Reject all ERC23 compatible tokens
  * @param from_ address The address that is transferring the tokens
  * @param value_ uint256 the amount of the specified token
  * @param data_ Bytes The data passed from the caller.
  */
  function tokenFallback(address from_, uint256 value_, bytes data_) external {
    revert();
  }

  /**
   * @dev Reclaim all ERC20Basic compatible tokens
   * @param tokenAddr address The address of the token contract
   */
  function reclaimToken(address tokenAddr) external onlyOwner {
    ERC20Basic tokenInst = ERC20Basic(tokenAddr);
    uint256 balance = tokenInst.balanceOf(this);
    tokenInst.transfer(owner, balance);
  }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

contract MigrationAgent {
  /*
    MigrationAgent contracts need to have this exact constant!
    it is intended to be identify the contract, since there is no way to tell
    if a contract is indeed an instance of the right type of contract otherwise
  */
  uint256 public constant MIGRATE_MAGIC_ID = 0x6e538c0d750418aae4131a91e5a20363;

  /*
    A contract implementing this interface is assumed to implement the neccessary
    access controls. E.g;
    * token being migrated FROM is the only one allowed to call migrateTo
    * token being migrated TO has a minting function that can only be called by
      the migration agent
  */
  function migrateTo(address beneficiary, uint256 amount) external;
}

/// @title Moeda Loyalty Points token contract
/// @author Erik Mossberg
contract MoedaToken is StandardToken, Ownable, HasNoTokens {
  string public constant name = "Moeda Loyalty Points";
  string public constant symbol = "MDA";
  uint8 public constant decimals = 18;

  // The migration agent is used to be to allow opt-in transfer of tokens to a
  // new token contract. This could be set sometime in the future if additional
  // functionality needs be added.
  MigrationAgent public migrationAgent;

  // used to ensure that a given address is an instance of a particular contract
  uint256 constant AGENT_MAGIC_ID = 0x6e538c0d750418aae4131a91e5a20363;
  uint256 public totalMigrated;

  uint constant TOKEN_MULTIPLIER = 10**uint256(decimals);
  // don&#39;t allow creation of more than this number of tokens
  uint public constant MAX_TOKENS = 20000000 * TOKEN_MULTIPLIER;

  // transfers are locked during minting
  bool public mintingFinished;

  // Log when tokens are migrated to a new contract
  event LogMigration(address indexed spender, address grantee, uint256 amount);
  event LogCreation(address indexed donor, uint256 tokensReceived);
  event LogDestruction(address indexed sender, uint256 amount);
  event LogMintingFinished();

  modifier afterMinting() {
    require(mintingFinished);
    _;
  }

  modifier canTransfer(address recipient) {
    require(mintingFinished && recipient != address(0));
    _;
  }

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /// @dev Create moeda token and assign partner allocations
  function MoedaToken() {
    // manual distribution
    issueTokens();
  }

  function issueTokens() internal {
    mint(0x2f37be861699b6127881693010596B4bDD146f5e, MAX_TOKENS);
  }

  /// @dev start a migration to a new contract
  /// @param agent address of contract handling migration
  function setMigrationAgent(address agent) external onlyOwner afterMinting {
    require(agent != address(0) && isContract(agent));
    require(MigrationAgent(agent).MIGRATE_MAGIC_ID() == AGENT_MAGIC_ID);
    require(migrationAgent == address(0));
    migrationAgent = MigrationAgent(agent);
  }

  function isContract(address addr) internal constant returns (bool) {
    uint256 size;
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

  /// @dev move a given amount of tokens a new contract (destroying them here)
  /// @param beneficiary address that will get tokens in new contract
  /// @param amount the number of tokens to migrate
  function migrate(address beneficiary, uint256 amount) external afterMinting {
    require(beneficiary != address(0));
    require(migrationAgent != address(0));
    require(amount > 0);

    // safemath subtraction will throw if balance < amount
    balances[msg.sender] = balances[msg.sender].sub(amount);
    totalSupply = totalSupply.sub(amount);
    totalMigrated = totalMigrated.add(amount);
    migrationAgent.migrateTo(beneficiary, amount);

    LogMigration(msg.sender, beneficiary, amount);
  }

  /// @dev destroy a given amount of tokens owned by sender
  // anyone that owns tokens can destroy them, reducing the total supply
  function burn(uint256 amount) external {
    require(amount > 0);
    balances[msg.sender] = balances[msg.sender].sub(amount);
    totalSupply = totalSupply.sub(amount);

    LogDestruction(msg.sender, amount);
  }

  /// @dev unlock transfers
  function unlock() external onlyOwner canMint {
    mintingFinished = true;
    LogMintingFinished();
  }

  /// @dev create tokens, only usable before minting has ended
  /// @param recipient address that will receive the created tokens
  /// @param amount the number of tokens to create
  function mint(address recipient, uint256 amount) internal canMint {
    require(amount > 0);
    require(totalSupply.add(amount) <= MAX_TOKENS);

    balances[recipient] = balances[recipient].add(amount);
    totalSupply = totalSupply.add(amount);

    LogCreation(recipient, amount);
  }

  // only allowed after minting has ended
  // note: transfers to null address not allowed, use burn(value)
  function transfer(address to, uint _value)
  public canTransfer(to) returns (bool)
  {
    return super.transfer(to, _value);
  }

  // only allowed after minting has ended
  // note: transfers to null address not allowed, use burn(value)
  function transferFrom(address from, address to, uint value)
  public canTransfer(to) returns (bool)
  {
    return super.transferFrom(from, to, value);
  }
}