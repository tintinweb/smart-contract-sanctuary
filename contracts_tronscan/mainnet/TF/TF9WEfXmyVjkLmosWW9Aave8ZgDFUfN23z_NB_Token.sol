//SourceUnit: NB_Token.sol

/**
 * SETH Token
 */
pragma solidity ^0.4.23;


/**
 * @title Ownable
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
  constructor() public {
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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint);
  function balanceOf(address who) public view returns (uint);
  function transfer(address to, uint value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint);
  function transferFrom(address from, address to, uint value) public returns (bool);
  function approve(address spender, uint value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint value);
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
  function isUpgradeAgent() public pure returns (bool) {
    return true;
  }

  function upgradeFrom(address _from, uint256 _value) public;

}


/**
 * Define interface for releasing the token transfer after a successful crowdsale.
 */
contract ReleasableToken is ERC20, Ownable {

  /* The finalizer contract that allows unlift the transfer limits on this token */
  address public releaseAgent;

  /** A crowdsale contract can release us to the wild if ICO success. If false we are are in transfer lock up period.*/
  bool public released = false;

  /** Map of agents that are allowed to transfer tokens regardless of the lock down period. These are crowdsale contracts and possible the team multisig itself. */
  mapping (address => bool) public transferAgents;

  /**
   * Limit token transfer until the crowdsale is over.
   *
   */
  modifier canTransfer(address _sender) {

    if(!released) {
        if(!transferAgents[_sender]) {
            revert();
        }
    }

    _;
  }

  /**
   * Set the contract that can call release and make the token transferable.
   *
   * Design choice. Allow reset the release agent to fix fat finger mistakes.
   */
  function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {

    // We don't do interface check here as we might want to a normal wallet address to act as a release agent
    releaseAgent = addr;
  }

  /**
   * Owner can allow a particular address (a crowdsale contract) to transfer tokens despite the lock up period.
   */
  function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
    transferAgents[addr] = state;
  }

  /**
   * Release the tokens to the wild.
   *
   * Can be called only from the release agent that is the final ICO contract. It is only called if the crowdsale has been success (first milestone reached).
   */
  function releaseTokenTransfer() public onlyReleaseAgent {
    released = true;
  }

  /**
   * Unrelease the tokens to the wild.
   *
   */
  function unReleaseTokenTransfer() public onlyReleaseAgent {
    released = false;
  }

  /** The function can be called only before or after the tokens have been releasesd */
  modifier inReleaseState(bool releaseState) {
    if(releaseState != released) {
        revert();
    }
    _;
  }

  /** The function can be called only by a whitelisted release agent. */
  modifier onlyReleaseAgent() {
    if(msg.sender != releaseAgent) {
        revert();
    }
    _;
  }

  function transfer(address _to, uint _value) canTransfer(msg.sender) public returns (bool success) {
    // Call StandardToken.transfer()
   return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) canTransfer(_from) public returns (bool success) {
    // Call StandardToken.transferForm()
    return super.transferFrom(_from, _to, _value);
  }

}



/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint;

  mapping(address => uint) balances;

  uint totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint balance) {
    return balances[_owner];
  }

}

/**
 * @title Freezable Token
 * @dev Token that can be freezed.
 */

contract FreezableToken is BasicToken, Ownable {

  using SafeMath for uint;
  uint public unfreezeProcessTime = 3 days;
  uint public freezeTotal;
  uint public curId;
  uint public minFreeze = 100000000;

  mapping (address => uint) public freezes;
  mapping (address => uint) public unfreezes;
  mapping (address => uint) public lastUnfreezeTime;
  mapping (uint => address) public freezerAddress;
  mapping (address => uint) public freezerIds;
  /* This notifies clients about the amount frozen */
  event Freeze(address indexed from, uint value);

  /* This notifies clients about the amount unfrozen */
  event Unfreeze(address indexed from, uint value);
  event WithdrawUnfreeze(address indexed sender, uint unfreezeAmount);
  event SettleUnfreeze(address indexed freezer, uint value);

  function freezeOf(address _tokenOwner) public view returns (uint balance) {
    return freezes[_tokenOwner];
  }

  function unfreezeOf(address _tokenOwner) public view returns (uint balance) {
    return unfreezes[_tokenOwner];
  }

  function freeze(uint _value) public returns (bool success) {
    if (freezerIds[msg.sender] == 0) {
      curId = curId.add(1);
      freezerIds[msg.sender] = curId;
      freezerAddress[curId] = msg.sender;
    }

    require(_value <= balances[msg.sender]);
    //0 not allowed
    require (_value >= minFreeze);
    address sender = msg.sender;
    balances[sender] = balances[sender].sub(_value);
    freezeTotal = freezeTotal.add(_value);
    freezes[sender] = freezes[sender].add(_value);
    emit Freeze(sender, _value);
    return true;
  }

  function unfreeze(uint _value) public returns (bool success) {
    require(_value <= freezes[msg.sender]);
    //0 not allowed
    require (_value > 0);
    address sender = msg.sender;
    freezes[sender] = freezes[sender].sub(_value);
    lastUnfreezeTime[sender] = block.timestamp;
    freezeTotal = freezeTotal.sub(_value);
    unfreezes[sender] = unfreezes[sender].add(_value);
    emit Unfreeze(sender, _value);
    return true;
  }

  function withdrawUnfreeze() public returns (bool success) {
    address sender = msg.sender;
    uint unfreezeAmount = unfreezes[sender];
    uint unfreezeTime = lastUnfreezeTime[sender].add(unfreezeProcessTime);
    require(unfreezeAmount > 0);
    require(block.timestamp > unfreezeTime);

    unfreezes[sender] = 0;
    balances[sender] = balances[sender].add(unfreezeAmount);
    emit WithdrawUnfreeze(sender, unfreezeAmount);
    return true;
  }

  function ownerSettleUnfreeze(address _freezer) onlyOwner public returns (bool success) {
    uint unfreezeAmount = unfreezes[_freezer];
    uint unfreezeTime = lastUnfreezeTime[_freezer].add(unfreezeProcessTime);
    require(unfreezeAmount > 0);
    require(block.timestamp > unfreezeTime);

    unfreezes[_freezer] = 0;
    balances[_freezer] = balances[_freezer].add(unfreezeAmount);
    emit SettleUnfreeze(_freezer, unfreezeAmount);
    return true;
  }

  function ownerSetProcessTime(uint _newTime) onlyOwner public returns (bool success) {
    unfreezeProcessTime = _newTime;
    return true;
  }

  function ownerSetMinFreeze(uint _newMinFreeze) public returns (bool success) {
    minFreeze = _newMinFreeze;
    return true;
  }
}

/**
 * Standard ERC20 token with Short Hand Attack and approve() race condition mitigation.
 *
 * Based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is BasicToken, ERC20 {
  using SafeMath for uint;

  /* approve() allowances */
  mapping (address => mapping (address => uint)) allowed;

  /* Interface declaration */
  function isToken() public pure returns (bool weAre) {
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    uint _allowance = allowed[_from][msg.sender];

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint _value) public returns (bool success) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0))
      revert();

    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint remaining) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

/**
 * Pausable token
 *
 * Simple ERC20 Token example, with pausable token creation
 **/

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint _value) whenNotPaused public returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) whenNotPaused public returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }
}

/**
 * A token upgrade mechanism where users can opt-in amount of tokens to the next smart contract revision.
 *
 * First envisioned by Golem and Lunyr projects.
 */
contract UpgradeableToken is StandardToken {
  using SafeMath for uint;
  /** Contract / person who can set the upgrade path. This can be the same as team multisig wallet, as what it is with its default value. */
  address public upgradeMaster;

  /** The next contract where the tokens will be migrated. */
  UpgradeAgent public upgradeAgent;

  /** How many tokens we have upgraded by now. */
  uint public totalUpgraded;

  /**
   * Upgrade states.
   *
   * - NotAllowed: The child contract has not reached a condition where the upgrade can bgun
   * - WaitingForAgent: Token allows upgrade, but we don't have a new agent yet
   * - ReadyToUpgrade: The agent is set, but not a single token has been upgraded yet
   * - Upgrading: Upgrade agent is set and the balance holders can upgrade their tokens
   *
   */
  enum UpgradeState {Unknown, NotAllowed, WaitingForAgent, ReadyToUpgrade, Upgrading}

  /**
   * Somebody has upgraded some of his tokens.
   */
  event Upgrade(address indexed _from, address indexed _to, uint _value);

  /**
   * New upgrade agent available.
   */
  event UpgradeAgentSet(address agent);

  /**
   * Do not allow construction without upgrade master set.
   */
  constructor(address _upgradeMaster) public {
    upgradeMaster = _upgradeMaster;
  }
  /**
   * Allow the token holder to upgrade some of their tokens to a new contract.
   */
  function upgrade(uint value) public {

      UpgradeState state = getUpgradeState();
      if (!(state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading)) {
        // Called in a bad state
        revert();
      }

      // Validate input value.
      if (value == 0) revert();

      balances[msg.sender] = balances[msg.sender].sub(value);

      // Take tokens out from circulation
      totalSupply_ = totalSupply_.sub(value);
      totalUpgraded = totalUpgraded.add(value);

      // Upgrade agent reissues the tokens
      upgradeAgent.upgradeFrom(msg.sender, value);
      emit Upgrade(msg.sender, upgradeAgent, value);
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
      if (upgradeAgent.originalSupply() != totalSupply_) revert();

      emit UpgradeAgentSet(upgradeAgent);
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
   * Child contract can enable to provide the condition when the upgrade can begun.
   */
  function canUpgrade() public pure returns(bool) {
     return true;
  }

}


/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint _value) public {
    require(_value <= balances[msg.sender]);
    // no need to require value <= totalSupply, since that would imply the
    // sender's balance is greater than the totalSupply, which *should* be an assertion failure

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(burner, _value);
    emit Transfer(burner, address(0), _value);
  }
}

/**
 * Blacklist token
 *
 * Simple ERC20 Token example, with Blacklist token creation
 **/

contract BlacklistToken is BasicToken, ERC20, Ownable {

	event DestroyedBlackFunds(address _blackListedUser, uint _balance);
	event AddedBlackList(address _user);
	event RemovedBlackList(address _user);

	mapping (address => bool) public isBlackListed;

	modifier whenNotBlacklisted(address _sender) {
		require(!isBlackListed[_sender]);
		_;
	}

	function getBlackListStatus(address _maker) external constant returns (bool) {
	    return isBlackListed[_maker];
	}

	function addBlackList (address _evilUser) public onlyOwner {
	    isBlackListed[_evilUser] = true;
	    emit AddedBlackList(_evilUser); //event emmiting
	}

	function removeBlackList (address _clearedUser) public onlyOwner {
	    isBlackListed[_clearedUser] = false;
	    emit RemovedBlackList(_clearedUser);
	}

	function destroyBlackFunds (address _blackListedUser) public onlyOwner {
	    require(isBlackListed[_blackListedUser]);
	    uint dirtyFunds = balanceOf(_blackListedUser);
	    balances[_blackListedUser] = 0;
	    totalSupply_ -= dirtyFunds;
	    emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
	}

	function transfer(address _to, uint _value) whenNotBlacklisted(msg.sender) public returns (bool) {
		return super.transfer(_to, _value);
	}

	function transferFrom(address _from, address _to, uint _value) whenNotBlacklisted(msg.sender) public returns (bool) {
		return super.transferFrom(_from, _to, _value);
	}
}

/**
 * @title Approvable Token
 * @dev Token that can be approve and call.
 */
interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}

contract ApprovableToken is StandardToken, Ownable {

  using SafeMath for uint;
      /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
  function approveAndCall(address _spender, uint256 _value, bytes memory _extraData)
      public
      returns (bool success) {
      tokenRecipient spender = tokenRecipient(_spender);
      if (approve(_spender, _value)) {
          spender.receiveApproval(msg.sender, _value, address(this), _extraData);
          return true;
      }
  }
}


/**
 *
 * Token supply is created in the token contract creation and allocated to owner.
 * The owner can then transfer from its supply to crowdsale participants.
 *
 */
contract NB_Token is UpgradeableToken, ReleasableToken, PausableToken, BurnableToken, FreezableToken, ApprovableToken, BlacklistToken {

  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(address _owner)  UpgradeableToken(_owner) public {
    name = "NIU BI";
    symbol = "NB";
    totalSupply_ = 21000000000000;
    decimals = 6;

    // Allocate initial balance to the owner
    balances[_owner] = totalSupply_;
  }
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}