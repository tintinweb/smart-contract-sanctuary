pragma solidity ^0.4.11;

/** Prosperium Presale Token (PP)
 * ERC-20 Token
 * Ability to upgrade to new contract - main Prosperium contract - when deployed by token Owner
 * 


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 * from https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol
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


contract StandardToken{
    
    using SafeMath for uint256;
    
    // create mapping from ether address to uint for balances
    mapping (address => uint256) balances;
    
    mapping (address => mapping(address => uint256)) approved;
    
    // public events on ether network for Transfer and Approval 
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    uint256 public totalSupply;
    
    // returns the total supply of all prosperium presale tokens
    function totalSupply() constant returns (uint totalSupply){
        return totalSupply;
    }
    
    // returns address specified as "_owner"
    function balanceOf(address _owner) constant returns (uint256 balance){
        return balances[_owner];
    }
    
    // transfer _value PP tokens from msg.sender to _to 
    function transfer(address _to, uint256 _value) returns (bool success){
        
        require(_to != address(0));
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
        
    }
    
    // permission from owner to approve spender(s)
    function approve(address _spender, uint _value) returns (bool success){
        
        require((_value == 0) || (approved[msg.sender][_spender] == 0));

        approved[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
        
    }
    
    // amount of coins allowed to spend from another account
    function allowance(address _owner, address _spender) constant returns (uint256 remaining){
        
        return approved[_owner][_spender];
        
    }
    
    /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until 
   * the first transaction is mined)
   * from https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/token/StandardToken.sol
   */
    function increaseApproval (address _spender, uint _addedValue) 
    returns (bool success) {
    approved[msg.sender][_spender] = approved[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, approved[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) 
    returns (bool success) {
    uint oldValue = approved[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      approved[msg.sender][_spender] = 0;
    } else {
      approved[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, approved[msg.sender][_spender]);
    return true;
  }
    // transfer tokens from owners account to given address _to
    function transferFrom(address _from, address _to, uint _value) returns (bool success){
        
        require(_to != address(0));
        
         var _allowance = approved[_from][msg.sender];

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        approved[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
        
    }
    
}

/**
 * @title Ownable
 * from OpenZeppelin
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// prosperium will be mintable only by owner
// from OpenZeppelin https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/token/MintableToken.sol
contract ProsperMintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}


/**
 * inspirsed from Civic token
 * Upgrade agent interface inspired by Lunyr.
 *
 * Upgrade agent transfers tokens to a new version of a token contract.
 * Upgrade agent can be set on a token by the upgrade master.
 *
 * Steps are
 * - Upgradeabletoken.upgradeMaster calls UpgradeableToken.setUpgradeAgent()
 * - Individual token holders can now call UpgradeableToken.upgrade()
 *   -> This results to call UpgradeAgent.upgradeFrom() that issues new tokens
 *   -> UpgradeableToken.upgrade() reduces the original total supply based on amount of upgraded tokens
 *
 */


contract UpgradeAgent {

  uint public originalSupply;

  /** Interface marker */
  function isUpgradeAgent() public constant returns (bool) {
    return true;
  }

  /**
   * Upgrade amount of tokens to a new version.
   *
   * Only callable by UpgradeableToken.
   *
   * @param _tokenHolder Address that wants to upgrade its tokens
   * @param _amount Number of tokens to upgrade. The address may consider to hold back some amount of tokens in the old version.
   */
  function upgradeFrom(address _tokenHolder, uint256 _amount) external;
}



/**
 * A token upgrade mechanism where users can opt-in amount of tokens to the next smart contract revision.
 *
 * First envisioned by Golem and Lunyr projects.
 */
contract UpgradeableToken is ProsperMintableToken {

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
   * Upgrade master updated.
   */
  event NewUpgradeMaster(address upgradeMaster);

  /**
   * Do not allow construction without upgrade master set.
   */
  function UpgradeableToken(address _upgradeMaster) {
    upgradeMaster = _upgradeMaster;
    NewUpgradeMaster(upgradeMaster);
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
      NewUpgradeMaster(upgradeMaster);
  }

  /**
   * Child contract can enable to provide the condition when the upgrade can begun.
   */
  function canUpgrade() public constant returns(bool) {
     return true;
  }

}

contract ProsperPresaleToken is UpgradeableToken {
    
    
    string public name;
    string public symbol;
    uint8 public decimals;

  
    function ProsperPresaleToken(address _owner, string _name, string _symbol, uint256 _initSupply, uint8 _decimals) UpgradeableToken(_owner) {
        
        name = _name;
        symbol = _symbol;
        totalSupply = _initSupply;
        decimals = _decimals;
        
        balances[_owner] = _initSupply;
        
    }
    
}