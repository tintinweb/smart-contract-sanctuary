pragma solidity ^0.4.24;

/**
 * Authored by https://www.coinfabrik.com/
 */

pragma solidity ^0.4.24;

/**
 * Originally from https://github.com/TokenMarketNet/ico
 * Modified by https://www.coinfabrik.com/
 */

pragma solidity ^0.4.24;

/**
 * Envisioned in FirstBlood ICO contract.
 * Originally from https://github.com/TokenMarketNet/ico
 * Modified by https://www.coinfabrik.com/
 */

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
 * Abstract contract that allows children to implement an
 * emergency stop mechanism. Differs from Pausable by causing a throw when in halt mode.
 *
 */
contract Haltable is Ownable {
  bool public halted;

  event Halted(bool halted);

  modifier stopInEmergency {
    require(!halted);
    _;
  }

  modifier onlyInEmergency {
    require(halted);
    _;
  }

  // called by the owner on emergency, triggers stopped state
  function halt() external onlyOwner {
    halted = true;
    emit Halted(true);
  }

  // called by the owner on end of emergency, returns to normal state
  function unhalt() external onlyOwner onlyInEmergency {
    halted = false;
    emit Halted(false);
  }
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

/**
 * Abstract base contract for token sales.
 *
 * Handles
 * - start and end dates
 * - accepting investments
 * - various statistics during the crowdfund
 * - different investment policies (require server side customer id, allow only whitelisted addresses)
 *
 */
contract GenericCrowdsale is Haltable {

  using SafeMath for uint;

  /* The token we are selling */
  CrowdsaleToken public token;

  /* ether will be transferred to this address */
  address public multisigWallet;

  /* the starting timestamp of the crowdsale */
  uint public startsAt;

  /* the ending timestamp of the crowdsale */
  uint public endsAt;

  /* the number of tokens already sold through this contract*/
  uint public tokensSold = 0;

  /* How many wei of funding we have raised */
  uint public weiRaised = 0;

  /* How many distinct addresses have invested */
  uint public investorCount = 0;

  /* Has this crowdsale been finalized */
  bool public finalized = false;

  /* Do we need to have a unique contributor id for each customer */
  bool public requireCustomerId = false;

  /* Has this crowdsale been configured */
  bool public configured = false;

  /**
   * Do we verify that contributor has been cleared on the server side (accredited investors only).
   * This method was first used in the FirstBlood crowdsale to ensure all contributors had accepted terms of sale (on the web).
   */
  bool public requiredSignedAddress = false;

  /** Server side address that signed allowed contributors (Ethereum addresses) that can participate the crowdsale */
  address public signerAddress;

  /** How many ETH each address has invested in this crowdsale */
  mapping (address => uint) public investedAmountOf;

  /** How many tokens this crowdsale has credited for each investor address */
  mapping (address => uint) public tokenAmountOf;

  /** Addresses that are allowed to invest even before ICO officially opens. For testing, for ICO partners, etc. */
  mapping (address => bool) public earlyParticipantWhitelist;

  /** State machine
   *
   * - PendingConfiguration: Crowdsale not yet configured
   * - Prefunding: We have not reached the starting timestamp yet
   * - Funding: Active crowdsale
   * - Success: Crowdsale ended
   * - Finalized: The finalize function has been called and successfully executed
   */
  enum State{Unknown, PendingConfiguration, PreFunding, Funding, Success, Finalized}


  // A new investment was made
  event Invested(address investor, uint weiAmount, uint tokenAmount, uint128 customerId);

  // The rules about what kind of investments we accept were changed
  event InvestmentPolicyChanged(bool requireCId, bool requireSignedAddress, address signer);

  // Address early participation whitelist status changed
  event Whitelisted(address addr, bool status);

  // Crowdsale&#39;s finalize function has been called
  event Finalized();

  /*
   * The configuration from the constructor was moved to the configurationGenericCrowdsale function.
   *
   * @param team_multisig Address of the multisignature wallet of the team that will receive all the funds contributed in the crowdsale.
   * @param start Timestamp where the crowdsale will be officially started. It should be greater than the timestamp in which the contract is deployed.
   * @param end Timestamp where the crowdsale finishes. No tokens can be sold through this contract after this timestamp.
   *
   * configurationGenericCrowdsale can only be called when in State.PendingConfiguration because of the inState modifier.
   */
  function configurationGenericCrowdsale(address team_multisig, uint start, uint end) internal inState(State.PendingConfiguration) {
    setMultisig(team_multisig);

    // Don&#39;t mess the dates
    require(start != 0 && end != 0);
    require(now < start && start < end);
    startsAt = start;
    endsAt = end;
    configured = true;
  }

  /**
   * Default fallback behaviour is to call buy.
   * Ideally, no contract calls this crowdsale without supporting ERC20.
   * However, some sort of refunding function may be desired to cover such situations.
   */
  function() payable public {
    buy();
  }

  /**
   * Make an investment.
   *
   * The crowdsale must be running for one to invest.
   * We must have not pressed the emergency brake.
   *
   * @param receiver The Ethereum address who receives the tokens
   * @param customerId (optional) UUID v4 to track the successful payments on the server side
   *
   */
  function investInternal(address receiver, uint128 customerId) stopInEmergency notFinished private {
    // Determine if it&#39;s a good time to accept investment from this participant
    if (getState() == State.PreFunding) {
      // Are we whitelisted for early deposit
      require(earlyParticipantWhitelist[msg.sender]);
    }

    uint weiAmount;
    uint tokenAmount;
    (weiAmount, tokenAmount) = calculateTokenAmount(msg.value, receiver);
    // Sanity check against bad implementation.
    assert(weiAmount <= msg.value);
    
    // Dust transaction if no tokens can be given
    require(tokenAmount != 0);

    if (investedAmountOf[receiver] == 0) {
      // A new investor
      investorCount++;
    }
    updateInvestorFunds(tokenAmount, weiAmount, receiver, customerId);

    // Pocket the money
    multisigWallet.transfer(weiAmount);

    // Return excess of money
    returnExcedent(msg.value.sub(weiAmount), msg.sender);
  }

  /**
   * Preallocate tokens for the early investors.
   *
   * Preallocated tokens have been sold before the actual crowdsale opens.
   * This function mints the tokens and moves the crowdsale needle.
   *
   * No money is exchanged, as the crowdsale team already have received the payment.
   *
   * @param receiver Account that receives the tokens.
   * @param fullTokens tokens as full tokens - decimal places are added internally.
   * @param weiPrice Price of a single indivisible token in wei.
   *
   */
  function preallocate(address receiver, uint fullTokens, uint weiPrice) external onlyOwner notFinished {
    uint tokenAmount = fullTokens.mul(10**uint(token.decimals()));
    // weiAmount can also be 0, in which case weiRaised is not increased.
    uint weiAmount = weiPrice.mul(tokenAmount);
    granularPreallocate(receiver, tokenAmount, weiAmount);
  }

  /**
   * Preallocate tokens for the early investors.
   *
   * Preallocated tokens have been sold before the actual crowdsale opens.
   * This function mints the tokens and moves the crowdsale needle.
   *
   * No money is exchanged, as the crowdsale team already have received the payment.
   *
   * @param receiver Account that receives the tokens.
   * @param tokenAmount Indivisible tokens.
   * @param weiAmount Equivalent of tokens in wei.
   *
   */
  function granularPreallocate(address receiver, uint tokenAmount, uint weiAmount) public onlyOwner notFinished {
    require(receiver != address(0));
    require(tokenAmount != 0);
    updateInvestorFunds(tokenAmount, weiAmount, receiver , 0);
  }

  /**
   * Private function to update accounting in the crowdsale.
   */
  function updateInvestorFunds(uint tokenAmount, uint weiAmount, address receiver, uint128 customerId) private {
    // Update investor
    investedAmountOf[receiver] = investedAmountOf[receiver].add(weiAmount);
    tokenAmountOf[receiver] = tokenAmountOf[receiver].add(tokenAmount);

    // Update totals
    weiRaised = weiRaised.add(weiAmount);
    tokensSold = tokensSold.add(tokenAmount);

    assignTokens(receiver, tokenAmount);
    // Tell us that the investment was completed successfully
    emit Invested(receiver, weiAmount, tokenAmount, customerId);
  }

  /**
   * Investing function that recognizes the receiver and verifies he is allowed to invest.
   *
   * @param customerId UUIDv4 that identifies this contributor
   */
  function buyOnBehalfWithSignedAddress(address receiver, uint128 customerId, uint8 v, bytes32 r, bytes32 s) public payable validCustomerId(customerId) {
    bytes32 hash = sha256(receiver);
    require(ecrecover(hash, v, r, s) == signerAddress);
    investInternal(receiver, customerId);
  }

  /**
   * Investing function that recognizes the receiver.
   * 
   * @param customerId UUIDv4 that identifies this contributor
   */
  function buyOnBehalfWithCustomerId(address receiver, uint128 customerId) public payable validCustomerId(customerId) unsignedBuyAllowed {
    investInternal(receiver, customerId);
  }

  /**
   * Buys tokens on behalf of an address.
   *
   * Pay for funding, get invested tokens back in the receiver address.
   */
  function buyOnBehalf(address receiver) public payable unsignedBuyAllowed {
    require(!requireCustomerId); // Crowdsale needs to track participants for thank you email
    investInternal(receiver, 0);
  }

  /**
   * Investing function that recognizes the payer and verifies he is allowed to invest.
   *
   * @param customerId UUIDv4 that identifies this contributor
   */
  function buyWithSignedAddress(uint128 customerId, uint8 v, bytes32 r, bytes32 s) public payable {
    buyOnBehalfWithSignedAddress(msg.sender, customerId, v, r, s);
  }


  /**
   * Investing function that recognizes the payer.
   * 
   * @param customerId UUIDv4 that identifies this contributor
   */
  function buyWithCustomerId(uint128 customerId) public payable {
    buyOnBehalfWithCustomerId(msg.sender, customerId);
  }

  /**
   * The basic entry point to participate in the crowdsale process.
   *
   * Pay for funding, get invested tokens back in the sender address.
   */
  function buy() public payable {
    buyOnBehalf(msg.sender);
  }

  /**
   * Finalize a successful crowdsale.
   *
   * The owner can trigger post-crowdsale actions, like releasing the tokens.
   * Note that by default tokens are not in a released state.
   */
  function finalize() public inState(State.Success) onlyOwner stopInEmergency {
    finalized = true;
    emit Finalized();
  }

  /**
   * Set policy do we need to have server-side customer ids for the investments.
   *
   */
  function setRequireCustomerId(bool value) public onlyOwner {
    requireCustomerId = value;
    emit InvestmentPolicyChanged(requireCustomerId, requiredSignedAddress, signerAddress);
  }

  /**
   * Set policy if all investors must be cleared on the server side first.
   *
   * This is e.g. for the accredited investor clearing.
   *
   */
  function setRequireSignedAddress(bool value, address signer) public onlyOwner {
    requiredSignedAddress = value;
    signerAddress = signer;
    emit InvestmentPolicyChanged(requireCustomerId, requiredSignedAddress, signerAddress);
  }

  /**
   * Allow addresses to do early participation.
   */
  function setEarlyParticipantWhitelist(address addr, bool status) public onlyOwner notFinished stopInEmergency {
    earlyParticipantWhitelist[addr] = status;
    emit Whitelisted(addr, status);
  }

  /**
   * Internal setter for the multisig wallet
   */
  function setMultisig(address addr) internal {
    require(addr != 0);
    multisigWallet = addr;
  }

  /**
   * Crowdfund state machine management.
   *
   * This function has the timed transition builtin.
   * So there is no chance of the variable being stale.
   */
  function getState() public view returns (State) {
    if (finalized) return State.Finalized;
    else if (!configured) return State.PendingConfiguration;
    else if (now < startsAt) return State.PreFunding;
    else if (now <= endsAt && !isCrowdsaleFull()) return State.Funding;
    else return State.Success;
  }

  /** Internal functions that exist to provide inversion of control should they be overriden */

  /** Interface for the concrete instance to interact with the token contract in a customizable way */
  function assignTokens(address receiver, uint tokenAmount) internal;

  /**
   *  Determine if the goal was already reached in the current crowdsale
   */
  function isCrowdsaleFull() internal view returns (bool full);

  /**
   * Returns any excess wei received
   * 
   * This function can be overriden to provide a different refunding method.
   */
  function returnExcedent(uint excedent, address receiver) internal {
    if (excedent > 0) {
      receiver.transfer(excedent);
    }
  }

  /** 
   *  Calculate the amount of tokens that corresponds to the received amount.
   *  The wei amount is returned too in case not all of it can be invested.
   *
   *  Note: When there&#39;s an excedent due to rounding error, it should be returned to allow refunding.
   *  This is worked around in the current design using an appropriate amount of decimals in the FractionalERC20 standard.
   *  The workaround is good enough for most use cases, hence the simplified function signature.
   *  @return weiAllowed The amount of wei accepted in this transaction.
   *  @return tokenAmount The tokens that are assigned to the receiver in this transaction.
   */
  function calculateTokenAmount(uint weiAmount, address receiver) internal view returns (uint weiAllowed, uint tokenAmount);

  //
  // Modifiers
  //

  modifier inState(State state) {
    require(getState() == state);
    _;
  }

  modifier unsignedBuyAllowed() {
    require(!requiredSignedAddress);
    _;
  }

  /** Modifier allowing execution only if the crowdsale is currently running.  */
  modifier notFinished() {
    State current_state = getState();
    require(current_state == State.PreFunding || current_state == State.Funding);
    _;
  }

  modifier validCustomerId(uint128 customerId) {
    require(customerId != 0);  // UUIDv4 sanity check
    _;
  }
}
pragma solidity ^0.4.24;

// Simple deployment information store inside contract storage.
contract DeploymentInfo {
  uint private deployed_on;

  constructor() public {
    deployed_on = block.number;
  }


  function getDeploymentBlock() public view returns (uint) {
    return deployed_on;
  }
}

/**
 * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
 *
 * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
 *
 * Heavily modified by https://www.coinfabrik.com/
 */

pragma solidity ^0.4.24;


/// @dev Tranche based pricing.
///      Implementing "first price" tranches, meaning, that if a buyer&#39;s order is
///      covering more than one tranche, the price of the lowest tranche will apply
///      to the whole order.
contract TokenTranchePricing {

  using SafeMath for uint;

  /**
   * Define pricing schedule using tranches.
   */
  struct Tranche {
      // Amount in tokens when this tranche becomes inactive
      uint amount;
      // Timestamp interval [start, end)
      // Starting timestamp (included in the interval)
      uint start;
      // Ending timestamp (excluded from the interval)
      uint end;
      // How many tokens per wei you will get while this tranche is active
      uint price;
  }
  // We define offsets and size for the deserialization of ordered tuples in raw arrays
  uint private constant amount_offset = 0;
  uint private constant start_offset = 1;
  uint private constant end_offset = 2;
  uint private constant price_offset = 3;
  uint private constant tranche_size = 4;

  Tranche[] public tranches;

  function getTranchesLength() public view returns (uint) {
    return tranches.length;
  }
  
  // The configuration from the constructor was moved to the configurationTokenTranchePricing function.
  //
  /// @dev Construction, creating a list of tranches
  /* @param init_tranches Raw array of ordered tuples: (start amount, start timestamp, end timestamp, price) */
  //
  function configurationTokenTranchePricing(uint[] init_tranches) internal {
    // Need to have tuples, length check
    require(init_tranches.length % tranche_size == 0);
    // A tranche with amount zero can never be selected and is therefore useless.
    // This check and the one inside the loop ensure no tranche can have an amount equal to zero.
    require(init_tranches[amount_offset] > 0);

    uint input_tranches_length = init_tranches.length.div(tranche_size);
    Tranche memory last_tranche;
    for (uint i = 0; i < input_tranches_length; i++) {
      uint tranche_offset = i.mul(tranche_size);
      uint amount = init_tranches[tranche_offset.add(amount_offset)];
      uint start = init_tranches[tranche_offset.add(start_offset)];
      uint end = init_tranches[tranche_offset.add(end_offset)];
      uint price = init_tranches[tranche_offset.add(price_offset)];
      // No invalid steps
      require(start < end && now < end);
      // Bail out when entering unnecessary tranches
      // This is preferably checked before deploying contract into any blockchain.
      require(i == 0 || (end >= last_tranche.end && amount > last_tranche.amount) ||
              (end > last_tranche.end && amount >= last_tranche.amount));

      last_tranche = Tranche(amount, start, end, price);
      tranches.push(last_tranche);
    }
  }

  /// @dev Get the current tranche or bail out if there is no tranche defined for the current timestamp.
  /// @param tokensSold total amount of tokens sold, for calculating the current tranche
  /// @return Returns the struct representing the current tranche
  function getCurrentTranche(uint tokensSold) private view returns (Tranche storage) {
    for (uint i = 0; i < tranches.length; i++) {
      if (tranches[i].start <= now && now < tranches[i].end && tokensSold < tranches[i].amount) {
        return tranches[i];
      }
    }
    // No tranche is currently active
    revert();
  }

  /// @dev Get the current price. May revert if there is no tranche currently active.
  /// @param tokensSold total amount of tokens sold, for calculating the current tranche
  /// @return The current price
  function getCurrentPrice(uint tokensSold) public view returns (uint result) {
    return getCurrentTranche(tokensSold).price;
  }

}

// This contract has the sole objective of providing a sane concrete instance of the Crowdsale contract.
contract Crowdsale is GenericCrowdsale, LostAndFoundToken, DeploymentInfo, TokenTranchePricing {
  uint public sellable_tokens;
  uint public initial_tokens;
  uint public milieurs_per_eth;
  // Minimum amounts of tokens that must be bought by an investor
  uint public minimum_buy_value;
  address public price_agent; 

  /*
   * The constructor for the crowdsale was removed given it didn&#39;t receive any arguments nor had any body.
   *
   * The configuration from the constructor was moved to the configurationCrowdsale function which creates the token contract and also calls the configuration functions from GenericCrowdsale and TokenTranchePricing.
   * 
   *
   * @param team_multisig Address of the multisignature wallet of the team that will receive all the funds contributed in the crowdsale.
   * @param start Timestamp where the crowdsale will be officially started. It should be greater than the timestamp in which the contract is deployed.
   * @param end Timestamp where the crowdsale finishes. No tokens can be sold through this contract after this timestamp.
   * @param token_retriever Address that will handle tokens accidentally sent to the token contract. See the LostAndFoundToken and CrowdsaleToken contracts for further details.
   */

  function configurationCrowdsale(address team_multisig, uint start, uint end,
  address token_retriever, uint[] init_tranches, uint multisig_supply, uint crowdsale_supply,
  uint8 token_decimals) public onlyOwner {

    initial_tokens = multisig_supply;
    minimum_buy_value = uint(100).mul(10 ** uint(token_decimals));
    token = new CrowdsaleToken(multisig_supply, token_decimals, team_multisig, token_retriever);
    // Necessary if assignTokens mints
    token.setMintAgent(address(this), true);
    // Necessary if finalize is overriden to release the tokens for public trading.
    token.setReleaseAgent(address(this));
    // Necessary for the execution of buy function and of the subsequent CrowdsaleToken&#39;s transfer function. 
    token.setTransferAgent(address(this), true);
    // Necessary for the delivery of bounties 
    token.setTransferAgent(team_multisig, true);
    // Crowdsale mints to himself the initial supply
    token.mint(address(this), crowdsale_supply);
    // Necessary if assignTokens mints
    token.setMintAgent(address(this), false);

    sellable_tokens = crowdsale_supply;

    // Configuration functionality for GenericCrowdsale.
    configurationGenericCrowdsale(team_multisig, start, end);

    // Configuration functionality for TokenTranchePricing.
    configurationTokenTranchePricing(init_tranches);
  }

  //token assignation
  function assignTokens(address receiver, uint tokenAmount) internal {
    token.transfer(receiver, tokenAmount);
  }

  //token amount calculation
  function calculateTokenAmount(uint weiAmount, address receiver) internal view returns (uint weiAllowed, uint tokenAmount) {
    //Divided by 1000 because eth eth_price_in_eurs is multiplied by 1000
    uint tokensPerEth = getCurrentPrice(tokensSold).mul(milieurs_per_eth).div(1000);
    uint maxWeiAllowed = sellable_tokens.sub(tokensSold).mul(1 ether).div(tokensPerEth);
    weiAllowed = maxWeiAllowed.min256(weiAmount);

    if (weiAmount < maxWeiAllowed) {
      tokenAmount = tokensPerEth.mul(weiAmount).div(1 ether);
    }
    // With this case we let the crowdsale end even when there are rounding errors due to the tokens to wei ratio
    else {
      tokenAmount = sellable_tokens.sub(tokensSold);
    }

    // Require a minimum contribution of 100 fulltokens
    require(token.balanceOf(receiver).add(tokenAmount) >= minimum_buy_value);
  }

  // Implements funding state criterion
  function isCrowdsaleFull() internal view returns (bool full) {
    return tokensSold >= sellable_tokens;
  }

  /**
   * Finalize a successful crowdsale.
   *
   * The owner can trigger post-crowdsale actions, like releasing the tokens.
   * Note that by default tokens are not in a released state.
   */
  function finalize() public inState(State.Success) onlyOwner stopInEmergency {
    //Tokens sold + bounties represent 82% of the total, the other 18% goes to the multisig, partners and market making
    uint sold = tokensSold.add(initial_tokens);
    uint toShare = sold.mul(18).div(82);

    // Mint the 18% to the multisig
    token.setMintAgent(address(this), true);
    token.mint(multisigWallet, toShare);
    token.setMintAgent(address(this), false);

    // Release transfers and burn unsold tokens.
    token.releaseTokenTransfer();
    token.burn(token.balanceOf(address(this)));

    super.finalize();
  }

  /**
   * This function decides who handles lost tokens.
   * Do note that this function is NOT meant to be used in a token refund mecahnism.
   * Its sole purpose is determining who can move around ERC20 tokens accidentally sent to this contract.
   */
  function getLostAndFoundMaster() internal view returns (address) {
    return owner;
  }

  // These two setters are present only to correct timestamps if they are off from their target date by more than, say, a day
  function setStartingTime(uint startingTime) public onlyOwner inState(State.PreFunding) {
    require(now < startingTime && startingTime < endsAt);
    startsAt = startingTime;
  }

  function setEndingTime(uint endingTime) public onlyOwner notFinished {
    require(now < endingTime && startsAt < endingTime);
    endsAt = endingTime;
  }

  function updateEursPerEth (uint milieurs_amount) public notFinished {
    require(milieurs_amount >= 100);
    require(msg.sender == price_agent);
    milieurs_per_eth = milieurs_amount;
  }

  function updatePriceAgent(address new_price_agent) public onlyOwner notFinished {
    price_agent = new_price_agent;
  }

  /**
   * @param new_minimum New minimum amount of indivisible tokens to be required
   */
  function setMinimumBuyValue(uint new_minimum) public onlyOwner notFinished {
    minimum_buy_value = new_minimum;
  }
}