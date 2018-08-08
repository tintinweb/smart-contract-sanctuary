pragma solidity ^0.4.6;

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

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

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

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
   * @return A uint256 specifing the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

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
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

contract Recoverable is Ownable {

  /// @dev Empty constructor (for now)
  function Recoverable() {
  }

  /// @dev This will be invoked by the owner, when owner wants to rescue tokens
  /// @param token Token which will we rescue to the owner from the contract
  function recoverTokens(ERC20Basic token) onlyOwner public {
    token.transfer(owner, tokensToBeReturned(token));
  }

  /// @dev Interface function, can be overwritten by the superclass
  /// @param token Token which balance we will check and return
  /// @return The amount of tokens (in smallest denominator) the contract owns
  function tokensToBeReturned(ERC20Basic token) public returns (uint) {
    return token.balanceOf(this);
  }
}

contract StandardTokenExt is Recoverable, StandardToken {

  /* Interface declaration */
  function isToken() public constant returns (bool weAre) {
    return true;
  }
}

contract BurnableToken is StandardTokenExt {

  // @notice An address for the transfer event where the burned tokens are transferred in a faux Transfer event
  address public constant BURN_ADDRESS = 0;

  /** How many tokens we burned */
  event Burned(address burner, uint burnedAmount);

  /**
   * Burn extra tokens from a balance.
   *
   */
  function burn(uint burnAmount) {
    address burner = msg.sender;
    balances[burner] = balances[burner].sub(burnAmount);
    totalSupply = totalSupply.sub(burnAmount);
    Burned(burner, burnAmount);

    // Inform the blockchain explores that track the
    // balances only by a transfer event that the balance in this
    // address has decreased
    Transfer(burner, BURN_ADDRESS, burnAmount);
  }
}


contract UpgradeableToken is StandardTokenExt {

  /** Contract / person who can set the upgrade path. This can be the same as team multisig wallet, as what it is with its default value. */
  address public upgradeMaster;

  /** The next contract where the tokens will be migrated. */
  UpgradeAgent public upgradeAgent;

  /** How many tokens we have upgraded by now. */
  uint256 public totalUpgraded;

  /**
   * Upgrade states.
   *
   * - NotAllowed: The child contract has not reached a condition where the upgrade can bgun
   * - WaitingForAgent: Token allows upgrade, but we don&#39;t have a new agent yet
   * - ReadyToUpgrade: The agent is set, but not a single token has been upgraded yet
   * - Upgrading: Upgrade agent is set and the balance holders can upgrade their tokens
   *
   */
  enum UpgradeState {Unknown, NotAllowed, WaitingForAgent, ReadyToUpgrade, Upgrading}

  /**
   * Somebody has upgraded some of his tokens.
   */
  event Upgrade(address indexed _from, address indexed _to, uint256 _value);

  /**
   * New upgrade agent available.
   */
  event UpgradeAgentSet(address agent);

  /**
   * Do not allow construction without upgrade master set.
   */
  function UpgradeableToken(address _upgradeMaster) {
    upgradeMaster = _upgradeMaster;
  }

  /**
   * Allow the token holder to upgrade some of their tokens to a new contract.
   */
  function upgrade(uint256 value) public {

      UpgradeState state = getUpgradeState();
      if(!(state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading)) {
        // Called in a bad state
        throw;
      }

      // Validate input value.
      if (value == 0) throw;

      balances[msg.sender] = balances[msg.sender].sub(value);

      // Take tokens out from circulation
      totalSupply = totalSupply.sub(value);
      totalUpgraded = totalUpgraded.add(value);

      // Upgrade agent reissues the tokens
      upgradeAgent.upgradeFrom(msg.sender, value);
      Upgrade(msg.sender, upgradeAgent, value);
  }

  /**
   * Set an upgrade agent that handles
   */
  function setUpgradeAgent(address agent) external {

      if(!canUpgrade()) {
        // The token is not yet in a state that we could think upgrading
        throw;
      }

      if (agent == 0x0) throw;
      // Only a master can designate the next agent
      if (msg.sender != upgradeMaster) throw;
      // Upgrade has already begun for an agent
      if (getUpgradeState() == UpgradeState.Upgrading) throw;

      upgradeAgent = UpgradeAgent(agent);

      // Bad interface
      if(!upgradeAgent.isUpgradeAgent()) throw;
      // Make sure that token supplies match in source and target
      if (upgradeAgent.originalSupply() != totalSupply) throw;

      UpgradeAgentSet(upgradeAgent);
  }

  /**
   * Get the state of the token upgrade.
   */
  function getUpgradeState() public constant returns(UpgradeState) {
    if(!canUpgrade()) return UpgradeState.NotAllowed;
    else if(address(upgradeAgent) == 0x00) return UpgradeState.WaitingForAgent;
    else if(totalUpgraded == 0) return UpgradeState.ReadyToUpgrade;
    else return UpgradeState.Upgrading;
  }

  /**
   * Change the upgrade master.
   *
   * This allows us to set a new owner for the upgrade mechanism.
   */
  function setUpgradeMaster(address master) public {
      if (master == 0x0) throw;
      if (msg.sender != upgradeMaster) throw;
      upgradeMaster = master;
  }

  /**
   * Child contract can enable to provide the condition when the upgrade can begun.
   */
  function canUpgrade() public constant returns(bool) {
     return true;
  }

}

contract UpgradeAgent {

  uint public originalSupply;

  /** Interface marker */
  function isUpgradeAgent() public constant returns (bool) {
    return true;
  }

  function upgradeFrom(address _from, uint256 _value) public;

}

contract ReVo is BurnableToken, UpgradeableToken {

  // Token meta information
  string public name;
  string public symbol;
  uint public decimals;

  event UpdatedTokenInformation(string newName, string newSymbol);

  function ReVo()  UpgradeableToken(msg.sender) {
    name = "ReVo";
    symbol = "RV";
    totalSupply = 100000000000000000000000000;
    decimals = 18;

    // Allocate initial balance to the owner
    balances[msg.sender] = totalSupply;

  }

  function setTokenInformation(string _name, string _symbol) {

    if(msg.sender != upgradeMaster) {
      throw;
    }

    name = _name;
    symbol = _symbol;
    UpdatedTokenInformation(name, symbol);
  }


  function transfer(address _to, uint _value) returns (bool success) {
    return super.transfer(_to, _value);
  }

}