pragma solidity ^0.4.18;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
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
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

  //Allow transfers from owner even in paused state - block all others
  modifier whenNotPaused() {
    require(!paused || msg.sender == owner);
    _;
  }

  modifier whenPaused() {
    require(paused);
    _;
  }

  // called by the owner on emergency, triggers paused state
  function pause() onlyOwner public{
    require(paused == false);
    paused = true;
    Pause();
  }

  // called by the owner on end of emergency, returns to normal state
  function unpause() onlyOwner whenPaused public{
    paused = false;
    Unpause();
  }

}


// allow contract to be destructible
contract Mortal is Ownable {
    function kill() onlyOwner public {
        selfdestruct(owner);
    }
}


/**
 * Upgrade agent interface inspired by Lunyr.
 *
 * Upgrade agent transfers tokens to a new contract.
 * Upgrade agent itself can be the token contract, or just a middle man contract doing the heavy lifting.
 */
contract UpgradeAgent {

  uint public originalSupply;

  /** Interface marker */
  function isUpgradeAgent() public constant returns (bool) {
    return true;
  }

  function upgradeFrom(address _from, uint256 _value) public;

}


contract BaseToken is Ownable, Pausable, Mortal{

  using SafeMath for uint256;

  // ERC20 State
  mapping (address => uint256) public balances;
  mapping (address => mapping (address => uint256)) public allowances;
  mapping (address => bool) public frozenAccount;
  uint256 public totalSupply;

  // Human State
  string public name;
  uint8 public decimals;
  string public symbol;
  string public version;

  // ERC20 Events
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  //Frozen event
  event FrozenFunds(address target, bool frozen);

  // ERC20 Methods
  function totalSupply() public constant returns (uint _totalSupply) {
      return totalSupply;
  }

  function balanceOf(address _address) public view returns (uint256 balance) {
    return balances[_address];
  }

  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowances[_owner][_spender];
  }

  //Freeze/unfreeze specific address
  function freezeAccount(address target, bool freeze) onlyOwner public{
    frozenAccount[target] = freeze;
    FrozenFunds(target, freeze);
    }

  //Check if given address is frozen
  function isFrozen(address _address) public view returns (bool frozen) {
      return frozenAccount[_address];
  }

  //ERC20 transfer
  function transfer(address _to, uint256 _value) whenNotPaused public returns (bool success)  {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    //REMOVED - SH 20180430 - WOULD PREVENT SENDING TO MULTISIG WALLET
    //require(isContract(_to) == false);
    require(!frozenAccount[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  //REMOVED - SH 20180430 - WOULD PREVENT SENDING TO MULTISIG WALLET
  //Check if to address is contract
  //function isContract(address _addr) private constant returns (bool) {
  //      uint codeSize;
  //      assembly {
  //          codeSize := extcodesize(_addr)
  //      }
  //      return codeSize > 0;
  //  }

  function approve(address _spender, uint256 _value) public returns (bool success) {
    allowances[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function transferFrom(address _owner, address _to, uint256 _value) whenNotPaused public returns (bool success) {
    require(_to != address(0));
    require(_value <= balances[_owner]);
    require(_value <= allowances[_owner][msg.sender]);
    require(!frozenAccount[_owner]);

    balances[_owner] = balances[_owner].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowances[_owner][msg.sender] = allowances[_owner][msg.sender].sub(_value);
    Transfer(_owner, _to, _value);
    return true;
  }

}


/**
 * A token upgrade mechanism where users can opt-in amount of tokens to the next smart contract revision.
 *
 * First envisioned by Golem and Lunyr projects.
 */
contract UpgradeableToken is BaseToken {

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
  function UpgradeAgentEnabledToken(address _upgradeMaster) {
    upgradeMaster = _upgradeMaster;
  }

  /**
   * Allow the token holder to upgrade some of their tokens to a new contract.
   */
  function upgrade(uint256 value) public {

      UpgradeState state = getUpgradeState();
      if(!(state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading)) {
        // Called in a bad state
        revert();
      }

      // Validate input value.
      if (value == 0) revert();

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
        revert();
      }

      if (agent == 0x0) revert();
      // Only a master can designate the next agent
      if (msg.sender != upgradeMaster) revert();
      // Upgrade has already begun for an agent
      if (getUpgradeState() == UpgradeState.Upgrading) revert();

      upgradeAgent = UpgradeAgent(agent);

      // Bad interface
      if(!upgradeAgent.isUpgradeAgent()) revert();
      // Make sure that token supplies match in source and target
      if (upgradeAgent.originalSupply() != totalSupply) revert();

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
      if (master == 0x0) revert();
      if (msg.sender != upgradeMaster) revert();
      upgradeMaster = master;
  }

  /**
   * Child contract can enable to provide the condition when the upgrade can begin.
   */
  function canUpgrade() public constant returns(bool) {
     return true;
  }

}


/**
 * A crowdsaled token.
 *
 * An ERC-20 token designed specifically for crowdsales with investor protection and further development path.
 *
 * - The token contract gives an opt-in upgrade path to a new contract
 *
 */
contract YBKToken is UpgradeableToken {

  string public name;
  string public symbol;
  uint public decimals;
  string public version;

  /**
   * Construct the token.
   */
   // Constructor
   function YBKToken(string _name, string _symbol, uint _initialSupply, uint _decimals, string _version) public {

     owner = msg.sender;

     // Initially set the upgrade master same as owner
     upgradeMaster = owner;

     name = _name;
     decimals = _decimals;
     symbol = _symbol;
     version = _version;

     totalSupply = _initialSupply;
     balances[msg.sender] = totalSupply;

   }

}