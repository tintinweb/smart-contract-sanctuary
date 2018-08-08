pragma solidity ^0.4.24;

/**
 * Originally from https://github.com/TokenMarketNet/ico
 * Modified by https://www.coinfabrik.com/
 */

pragma solidity ^0.4.24;

/**
 * Originally from https://github.com/TokenMarketNet/ico
 * Modified by https://www.coinfabrik.com/
 */

pragma solidity ^0.4.24;

/**
 * Originally from https://github.com/OpenZeppelin/zeppelin-solidity
 * Modified by https://www.coinfabrik.com/
 */

pragma solidity ^0.4.24;

/**
 * Interface for the standard token.
 * Based on https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
 */
contract EIP20Token {

  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool success);
  function transferFrom(address from, address to, uint256 value) public returns (bool success);
  function approve(address spender, uint256 value) public returns (bool success);
  function allowance(address owner, address spender) public view returns (uint256 remaining);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  /**
  ** Optional functions
  *
  function name() public view returns (string name);
  function symbol() public view returns (string symbol);
  function decimals() public view returns (uint8 decimals);
  *
  **/

}
pragma solidity ^0.4.24;

/**
 * Originally from  https://github.com/OpenZeppelin/zeppelin-solidity
 * Modified by https://www.coinfabrik.com/
 */

/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint a, uint b) internal pure returns (uint) {
    return a >= b ? a : b;
  }

  function min256(uint a, uint b) internal pure returns (uint) {
    return a < b ? a : b;
  }
}

pragma solidity ^0.4.24;

// Interface for burning tokens
contract Burnable {
  // @dev Destroys tokens for an account
  // @param account Account whose tokens are destroyed
  // @param value Amount of tokens to destroy
  function burnTokens(address account, uint value) internal;
  event Burned(address account, uint value);
}
pragma solidity ^0.4.24;

/**
 * Authored by https://www.coinfabrik.com/
 */


/**
 * Internal interface for the minting of tokens.
 */
contract Mintable {

  /**
   * @dev Mints tokens for an account
   * This function should the Minted event.
   */
  function mintInternal(address receiver, uint amount) internal;

  /** Token supply got increased and a new owner received these tokens */
  event Minted(address receiver, uint amount);
}

/**
 * @title Standard token
 * @dev Basic implementation of the EIP20 standard token (also known as ERC20 token).
 */
contract StandardToken is EIP20Token, Burnable, Mintable {
  using SafeMath for uint;

  uint private total_supply;
  mapping(address => uint) private balances;
  mapping(address => mapping (address => uint)) private allowed;


  function totalSupply() public view returns (uint) {
    return total_supply;
  }

  /**
   * @dev transfer token for a specified address
   * @param to The address to transfer to.
   * @param value The amount to be transferred.
   */
  function transfer(address to, uint value) public returns (bool success) {
    balances[msg.sender] = balances[msg.sender].sub(value);
    balances[to] = balances[to].add(value);
    emit Transfer(msg.sender, to, value);
    return true;
  }

  /**
   * @dev Gets the balance of the specified address.
   * @param account The address whose balance is to be queried.
   * @return An uint representing the amount owned by the passed address.
   */
  function balanceOf(address account) public view returns (uint balance) {
    return balances[account];
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param from address The address which you want to send tokens from
   * @param to address The address which you want to transfer to
   * @param value uint the amout of tokens to be transfered
   */
  function transferFrom(address from, address to, uint value) public returns (bool success) {
    uint allowance = allowed[from][msg.sender];

    // Check is not needed because sub(allowance, value) will already throw if this condition is not met
    // require(value <= allowance);
    // SafeMath uses assert instead of require though, beware when using an analysis tool

    balances[from] = balances[from].sub(value);
    balances[to] = balances[to].add(value);
    allowed[from][msg.sender] = allowance.sub(value);
    emit Transfer(from, to, value);
    return true;
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   */
  function approve(address spender, uint value) public returns (bool success) {

    // To change the approve amount you first have to reduce the addresses&#39;
    //  allowance to zero by calling `approve(spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require (value == 0 || allowed[msg.sender][spender] == 0);

    allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens than an owner allowed to a spender.
   * @param account address The address which owns the funds.
   * @param spender address The address which will spend the funds.
   * @return A uint specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address account, address spender) public view returns (uint remaining) {
    return allowed[account][spender];
  }

  /**
   * Atomic increment of approved spending
   *
   * Works around https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   */
  function addApproval(address spender, uint addedValue) public returns (bool success) {
      uint oldValue = allowed[msg.sender][spender];
      allowed[msg.sender][spender] = oldValue.add(addedValue);
      emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
      return true;
  }

  /**
   * Atomic decrement of approved spending.
   *
   * Works around https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   */
  function subApproval(address spender, uint subtractedValue) public returns (bool success) {

      uint oldVal = allowed[msg.sender][spender];

      if (subtractedValue > oldVal) {
          allowed[msg.sender][spender] = 0;
      } else {
          allowed[msg.sender][spender] = oldVal.sub(subtractedValue);
      }
      emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
      return true;
  }

  /**
   * @dev Provides an internal function for destroying tokens. Useful for upgrades.
   */
  function burnTokens(address account, uint value) internal {
    balances[account] = balances[account].sub(value);
    total_supply = total_supply.sub(value);
    emit Transfer(account, 0, value);
    emit Burned(account, value);
  }

  /**
   * @dev Provides an internal minting function.
   */
  function mintInternal(address receiver, uint amount) internal {
    total_supply = total_supply.add(amount);
    balances[receiver] = balances[receiver].add(amount);
    emit Minted(receiver, amount);

    // Beware: Address zero may be used for special transactions in a future fork.
    // This will make the mint transaction appear in EtherScan.io
    // We can remove this after there is a standardized minting event
    emit Transfer(0, receiver, amount);
  }
  
}
pragma solidity ^0.4.24;

/**
 * Originally from https://github.com/OpenZeppelin/zeppelin-solidity
 * Modified by https://www.coinfabrik.com/
 */

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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    owner = newOwner;
  }

}

/**
 * Define interface for releasing the token transfer after a successful crowdsale.
 */
contract ReleasableToken is StandardToken, Ownable {

  /* The finalizer contract that allows lifting the transfer limits on this token */
  address public releaseAgent;

  /** A crowdsale contract can release us to the wild if ICO success. If false we are are in transfer lock up period.*/
  bool public released = false;

  /** Map of agents that are allowed to transfer tokens regardless of the lock down period. These are crowdsale contracts and possible the team multisig itself. */
  mapping (address => bool) public transferAgents;

  /**
   * Set the contract that can call release and make the token transferable.
   *
   * Since the owner of this contract is (or should be) the crowdsale,
   * it can only be called by a corresponding exposed API in the crowdsale contract in case of input error.
   */
  function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {
    // We don&#39;t do interface check here as we might want to have a normal wallet address to act as a release agent.
    releaseAgent = addr;
  }

  /**
   * Owner can allow a particular address (e.g. a crowdsale contract) to transfer tokens despite the lock up period.
   */
  function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
    transferAgents[addr] = state;
  }

  /**
   * One way function to release the tokens into the wild.
   *
   * Can be called only from the release agent that should typically be the finalize agent ICO contract.
   * In the scope of the crowdsale, it is only called if the crowdsale has been a success (first milestone reached).
   */
  function releaseTokenTransfer() public onlyReleaseAgent {
    released = true;
  }

  /**
   * Limit token transfer until the crowdsale is over.
   */
  modifier canTransfer(address sender) {
    require(released || transferAgents[sender]);
    _;
  }

  /** The function can be called only before or after the tokens have been released */
  modifier inReleaseState(bool releaseState) {
    require(releaseState == released);
    _;
  }

  /** The function can be called only by a whitelisted release agent. */
  modifier onlyReleaseAgent() {
    require(msg.sender == releaseAgent);
    _;
  }

  /** We restrict transfer by overriding it */
  function transfer(address to, uint value) public canTransfer(msg.sender) returns (bool success) {
    // Call StandardToken.transfer()
   return super.transfer(to, value);
  }

  /** We restrict transferFrom by overriding it */
  function transferFrom(address from, address to, uint value) public canTransfer(from) returns (bool success) {
    // Call StandardToken.transferForm()
    return super.transferFrom(from, to, value);
  }

}



pragma solidity ^0.4.24;

/**
 * First envisioned by Golem and Lunyr projects.
 * Originally from https://github.com/TokenMarketNet/ico
 * Modified by https://www.coinfabrik.com/
 */

pragma solidity ^0.4.24;

/**
 * Inspired by Lunyr.
 * Originally from https://github.com/TokenMarketNet/ico
 */

/**
 * Upgrade agent transfers tokens to a new contract.
 * Upgrade agent itself can be the token contract, or just a middle man contract doing the heavy lifting.
 *
 * The Upgrade agent is the interface used to implement a token
 * migration in the case of an emergency.
 * The function upgradeFrom has to implement the part of the creation
 * of new tokens on behalf of the user doing the upgrade.
 *
 * The new token can implement this interface directly, or use.
 */
contract UpgradeAgent {

  /** This value should be the same as the original token&#39;s total supply */
  uint public originalSupply;

  /** Interface to ensure the contract is correctly configured */
  function isUpgradeAgent() public pure returns (bool) {
    return true;
  }

  /**
  Upgrade an account

  When the token contract is in the upgrade status the each user will
  have to call `upgrade(value)` function from UpgradeableToken.

  The upgrade function adjust the balance of the user and the supply
  of the previous token and then call `upgradeFrom(value)`.

  The UpgradeAgent is the responsible to create the tokens for the user
  in the new contract.

  * @param from Account to upgrade.
  * @param value Tokens to upgrade.

  */
  function upgradeFrom(address from, uint value) public;

}


/**
 * A token upgrade mechanism where users can opt-in amount of tokens to the next smart contract revision.
 *
 */
contract UpgradeableToken is EIP20Token, Burnable {
  using SafeMath for uint;

  /** Contract / person who can set the upgrade path. This can be the same as team multisig wallet, as what it is with its default value. */
  address public upgradeMaster;

  /** The next contract where the tokens will be migrated. */
  UpgradeAgent public upgradeAgent;

  /** How many tokens we have upgraded by now. */
  uint public totalUpgraded = 0;

  /**
   * Upgrade states.
   *
   * - NotAllowed: The child contract has not reached a condition where the upgrade can begin
   * - WaitingForAgent: Token allows upgrade, but we don&#39;t have a new agent yet
   * - ReadyToUpgrade: The agent is set, but not a single token has been upgraded yet. This allows changing the upgrade agent while there is time.
   * - Upgrading: Upgrade agent is set and the balance holders can upgrade their tokens
   *
   */
  enum UpgradeState {Unknown, NotAllowed, WaitingForAgent, ReadyToUpgrade, Upgrading}

  /**
   * Somebody has upgraded some of his tokens.
   */
  event Upgrade(address indexed from, address to, uint value);

  /**
   * New upgrade agent available.
   */
  event UpgradeAgentSet(address agent);

  /**
   * Do not allow construction without upgrade master set.
   */
  constructor(address master) internal {
    setUpgradeMaster(master);
  }

  /**
   * Allow the token holder to upgrade some of their tokens to a new contract.
   */
  function upgrade(uint value) public {
    UpgradeState state = getUpgradeState();
    // Ensure it&#39;s not called in a bad state
    require(state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading);

    // Validate input value.
    require(value != 0);

    // Upgrade agent reissues the tokens
    upgradeAgent.upgradeFrom(msg.sender, value);
    
    // Take tokens out from circulation
    burnTokens(msg.sender, value);
    totalUpgraded = totalUpgraded.add(value);

    emit Upgrade(msg.sender, upgradeAgent, value);
  }

  /**
   * Set an upgrade agent that handles the upgrade process
   */
  function setUpgradeAgent(address agent) onlyMaster external {
    // Check whether the token is in a state that we could think of upgrading
    require(canUpgrade());

    require(agent != 0x0);
    // Upgrade has already begun for an agent
    require(getUpgradeState() != UpgradeState.Upgrading);

    upgradeAgent = UpgradeAgent(agent);

    // Bad interface
    require(upgradeAgent.isUpgradeAgent());
    // Make sure that token supplies match in source and target
    require(upgradeAgent.originalSupply() == totalSupply());

    emit UpgradeAgentSet(upgradeAgent);
  }

  /**
   * Get the state of the token upgrade.
   */
  function getUpgradeState() public view returns(UpgradeState) {
    if (!canUpgrade()) return UpgradeState.NotAllowed;
    else if (address(upgradeAgent) == 0x00) return UpgradeState.WaitingForAgent;
    else if (totalUpgraded == 0) return UpgradeState.ReadyToUpgrade;
    else return UpgradeState.Upgrading;
  }

  /**
   * Change the upgrade master.
   *
   * This allows us to set a new owner for the upgrade mechanism.
   */
  function changeUpgradeMaster(address new_master) onlyMaster public {
    setUpgradeMaster(new_master);
  }

  /**
   * Internal upgrade master setter.
   */
  function setUpgradeMaster(address new_master) private {
    require(new_master != 0x0);
    upgradeMaster = new_master;
  }

  /**
   * Child contract can override to provide the condition in which the upgrade can begin.
   */
  function canUpgrade() public view returns(bool) {
     return true;
  }


  modifier onlyMaster() {
    require(msg.sender == upgradeMaster);
    _;
  }
}

pragma solidity ^0.4.24;

/**
 * Authored by https://www.coinfabrik.com/
 */


// This contract aims to provide an inheritable way to recover tokens from a contract not meant to hold tokens
// To use this contract, have your token-ignoring contract inherit this one and implement getLostAndFoundMaster to decide who can move lost tokens.
// Of course, this contract imposes support costs upon whoever is the lost and found master.
contract LostAndFoundToken {
  /**
   * @return Address of the account that handles movements.
   */
  function getLostAndFoundMaster() internal view returns (address);

  /**
   * @param agent Address that will be able to move tokens with transferFrom
   * @param tokens Amount of tokens approved for transfer
   * @param token_contract Contract of the token
   */
  function enableLostAndFound(address agent, uint tokens, EIP20Token token_contract) public {
    require(msg.sender == getLostAndFoundMaster());
    // We use approve instead of transfer to minimize the possibility of the lost and found master
    //  getting them stuck in another address by accident.
    token_contract.approve(agent, tokens);
  }
}
pragma solidity ^0.4.24;

/**
 * Originally from https://github.com/TokenMarketNet/ico
 * Modified by https://www.coinfabrik.com/
 */


/**
 * A public interface to increase the supply of a token.
 *
 * This allows uncapped crowdsale by dynamically increasing the supply when money pours in.
 * Only mint agents, usually contracts whitelisted by the owner, can mint new tokens.
 *
 */
contract MintableToken is Mintable, Ownable {

  using SafeMath for uint;

  bool public mintingFinished = false;

  /** List of agents that are allowed to create new tokens */
  mapping (address => bool) public mintAgents;

  event MintingAgentChanged(address addr, bool state);


  constructor(uint initialSupply, address multisig, bool mintable) internal {
    require(multisig != address(0));
    // Cannot create a token without supply and no minting
    require(mintable || initialSupply != 0);
    // Create initially all balance on the team multisig
    if (initialSupply > 0)
      mintInternal(multisig, initialSupply);
    // No more new supply allowed after the token creation
    mintingFinished = !mintable;
  }

  /**
   * Create new tokens and allocate them to an address.
   *
   * Only callable by a mint agent (e.g. crowdsale contract).
   */
  function mint(address receiver, uint amount) onlyMintAgent canMint public {
    mintInternal(receiver, amount);
  }

  /**
   * Owner can allow a crowdsale contract to mint new tokens.
   */
  function setMintAgent(address addr, bool state) onlyOwner canMint public {
    mintAgents[addr] = state;
    emit MintingAgentChanged(addr, state);
  }

  modifier onlyMintAgent() {
    // Only mint agents are allowed to mint new tokens
    require(mintAgents[msg.sender]);
    _;
  }

  /** Make sure we are not done yet. */
  modifier canMint() {
    require(!mintingFinished);
    _;
  }
}

/**
 * A crowdsale token.
 *
 * An ERC-20 token designed specifically for crowdsales with investor protection and further development path.
 *
 * - The token transfer() is disabled until the crowdsale is over
 * - The token contract gives an opt-in upgrade path to a new contract
 * - The same token can be part of several crowdsales through the approve() mechanism
 * - The token can be capped (supply set in the constructor) or uncapped (crowdsale contract can mint new tokens)
 * - ERC20 tokens transferred to this contract can be recovered by a lost and found master
 *
 */
contract CrowdsaleToken is ReleasableToken, MintableToken, UpgradeableToken, LostAndFoundToken {

  string public name = "Kryptobits";

  string public symbol = "KBE";

  uint8 public decimals;

  address public lost_and_found_master;

  /**
   * Construct the token.
   *
   * This token must be created through a team multisig wallet, so that it is owned by that wallet.
   *
   * @param initial_supply How many tokens we start with.
   * @param token_decimals Number of decimal places.
   * @param team_multisig Address of the multisig that receives the initial supply and is set as the upgrade master.
   * @param token_retriever Address of the account that handles ERC20 tokens that were accidentally sent to this contract.
   */
  constructor(uint initial_supply, uint8 token_decimals, address team_multisig, address token_retriever) public
  UpgradeableToken(team_multisig) MintableToken(initial_supply, team_multisig, true) {
    require(token_retriever != address(0));
    decimals = token_decimals;
    lost_and_found_master = token_retriever;
  }

  /**
   * When token is released to be transferable, prohibit new token creation.
   */
  function releaseTokenTransfer() public onlyReleaseAgent {
    mintingFinished = true;
    super.releaseTokenTransfer();
  }

  /**
   * Allow upgrade agent functionality to kick in only if the crowdsale was a success.
   */
  function canUpgrade() public view returns(bool) {
    return released && super.canUpgrade();
  }

  function burn(uint value) public {
    burnTokens(msg.sender, value);
  }

  function getLostAndFoundMaster() internal view returns(address) {
    return lost_and_found_master;
  }
}