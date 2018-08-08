pragma solidity ^0.4.13;


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
    Halted(true);
  }

  // called by the owner on end of emergency, returns to normal state
  function unhalt() external onlyOwner onlyInEmergency {
    halted = false;
    Halted(false);
  }

}

/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint a, uint b) internal constant returns (uint) {
    return a >= b ? a : b;
  }

  function min256(uint a, uint b) internal constant returns (uint) {
    return a < b ? a : b;
  }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) public constant returns (uint);
  function transfer(address to, uint value) public returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint);
  function transferFrom(address from, address to, uint value) public returns (bool ok);
  function approve(address spender, uint value) public returns (bool ok);
  event Approval(address indexed owner, address indexed spender, uint value);
}

/**
 * A token that defines fractional units as decimals.
 */
contract FractionalERC20 is ERC20 {

  uint8 public decimals;

}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint;

  mapping(address => uint) balances;

  /**
   * Obsolete. Removed this check based on:
   * https://blog.coinfabrik.com/smart-contract-short-address-attack-mitigation-failure/
   * @dev Fix for the ERC20 short address attack.
   *
   * modifier onlyPayloadSize(uint size) {
   *    require(msg.data.length >= size + 4);
   *    _;
   * }
   */

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint _value) public returns (bool success) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public constant returns (uint balance) {
    return balances[_owner];
  }
  
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 */
contract StandardToken is BasicToken, ERC20 {

  /* Token supply got increased and a new owner received these tokens */
  event Minted(address receiver, uint amount);

  mapping (address => mapping (address => uint)) allowed;

  /* Interface declaration */
  function isToken() public constant returns (bool weAre) {
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
    uint _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require(_value <= _allowance);
    // SafeMath uses assert instead of require though, beware when using an analysis tool

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
  function approve(address _spender, uint _value) public returns (bool success) {

    // To change the approve amount you first have to reduce the addresses&#39;
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require (_value == 0 || allowed[msg.sender][_spender] == 0);

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens than an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) public constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

  /**
   * Atomic increment of approved spending
   *
   * Works around https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   */
  function addApproval(address _spender, uint _addedValue) public
  returns (bool success) {
      uint oldValue = allowed[msg.sender][_spender];
      allowed[msg.sender][_spender] = oldValue.add(_addedValue);
      Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
      return true;
  }

  /**
   * Atomic decrement of approved spending.
   *
   * Works around https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   */
  function subApproval(address _spender, uint _subtractedValue) public
  returns (bool success) {

      uint oldVal = allowed[msg.sender][_spender];

      if (_subtractedValue > oldVal) {
          allowed[msg.sender][_spender] = 0;
      } else {
          allowed[msg.sender][_spender] = oldVal.sub(_subtractedValue);
      }
      Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
      return true;
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
  modifier canTransfer(address _sender) {
    require(released || transferAgents[_sender]);
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
  function transfer(address _to, uint _value) public canTransfer(msg.sender) returns (bool success) {
    // Call StandardToken.transfer()
   return super.transfer(_to, _value);
  }

  /** We restrict transferFrom by overriding it */
  function transferFrom(address _from, address _to, uint _value) public canTransfer(_from) returns (bool success) {
    // Call StandardToken.transferForm()
    return super.transferFrom(_from, _to, _value);
  }

}

/**
 * A token that can increase its supply by another contract.
 *
 * This allows uncapped crowdsale by dynamically increasing the supply when money pours in.
 * Only mint agents, contracts whitelisted by owner, can mint new tokens.
 *
 */
contract MintableToken is StandardToken, Ownable {

  using SafeMath for uint;

  bool public mintingFinished = false;

  /** List of agents that are allowed to create new tokens */
  mapping (address => bool) public mintAgents;

  event MintingAgentChanged(address addr, bool state);


  function MintableToken(uint _initialSupply, address _multisig, bool _mintable) internal {
    require(_multisig != address(0));
    // Cannot create a token without supply and no minting
    require(_mintable || _initialSupply != 0);
    // Create initially all balance on the team multisig
    if (_initialSupply > 0)
        mintInternal(_multisig, _initialSupply);
    // No more new supply allowed after the token creation
    mintingFinished = !_mintable;
  }

  /**
   * Create new tokens and allocate them to an address.
   *
   * Only callable by a crowdsale contract (mint agent).
   */
  function mint(address receiver, uint amount) onlyMintAgent public {
    mintInternal(receiver, amount);
  }

  function mintInternal(address receiver, uint amount) canMint private {
    totalSupply = totalSupply.add(amount);
    balances[receiver] = balances[receiver].add(amount);

    // Removed because this may be confused with anonymous transfers in the upcoming fork.
    // This will make the mint transaction appear in EtherScan.io
    // We can remove this after there is a standardized minting event
    // Transfer(0, receiver, amount);

    Minted(receiver, amount);
  }

  /**
   * Owner can allow a crowdsale contract to mint new tokens.
   */
  function setMintAgent(address addr, bool state) onlyOwner canMint public {
    mintAgents[addr] = state;
    MintingAgentChanged(addr, state);
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
  function isUpgradeAgent() public constant returns (bool) {
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

  * @param _from Account to upgrade.
  * @param _value Tokens to upgrade.

  */
  function upgradeFrom(address _from, uint _value) public;

}

/**
 * A token upgrade mechanism where users can opt-in amount of tokens to the next smart contract revision.
 *
 */
contract UpgradeableToken is StandardToken {

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
   * - WaitingForAgent: Token allows upgrade, but we don&#39;t have a new agent yet
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
  function UpgradeableToken(address _upgradeMaster) {
    setUpgradeMaster(_upgradeMaster);
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

    balances[msg.sender] = balances[msg.sender].sub(value);

    // Take tokens out from circulation
    totalSupply = totalSupply.sub(value);
    totalUpgraded = totalUpgraded.add(value);

    // Upgrade agent reissues the tokens
    upgradeAgent.upgradeFrom(msg.sender, value);
    Upgrade(msg.sender, upgradeAgent, value);
  }

  /**
   * Set an upgrade agent that handles the upgrade process
   */
  function setUpgradeAgent(address agent) external {
    // Check whether the token is in a state that we could think of upgrading
    require(canUpgrade());

    require(agent != 0x0);
    // Only a master can designate the next agent
    require(msg.sender == upgradeMaster);
    // Upgrade has already begun for an agent
    require(getUpgradeState() != UpgradeState.Upgrading);

    upgradeAgent = UpgradeAgent(agent);

    // Bad interface
    require(upgradeAgent.isUpgradeAgent());
    // Make sure that token supplies match in source and target
    require(upgradeAgent.originalSupply() == totalSupply);

    UpgradeAgentSet(upgradeAgent);
  }

  /**
   * Get the state of the token upgrade.
   */
  function getUpgradeState() public constant returns(UpgradeState) {
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
  function changeUpgradeMaster(address new_master) public {
    require(msg.sender == upgradeMaster);
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
   * Child contract can enable to provide the condition when the upgrade can begin.
   */
  function canUpgrade() public constant returns(bool) {
     return true;
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
 *
 */
contract CrowdsaleToken is ReleasableToken, MintableToken, UpgradeableToken, FractionalERC20 {

  event UpdatedTokenInformation(string newName, string newSymbol);

  string public name;

  string public symbol;

  /**
   * Construct the token.
   *
   * This token must be created through a team multisig wallet, so that it is owned by that wallet.
   *
   * @param _name Token name
   * @param _symbol Token symbol - typically it&#39;s all caps
   * @param _initialSupply How many tokens we start with
   * @param _decimals Number of decimal places
   * @param _mintable Are new tokens created over the crowdsale or do we distribute only the initial supply? Note that when the token becomes transferable the minting always ends.
   */
  function CrowdsaleToken(string _name, string _symbol, uint _initialSupply, uint8 _decimals, address _multisig, bool _mintable)
    UpgradeableToken(_multisig) MintableToken(_initialSupply, _multisig, _mintable) {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
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
  function canUpgrade() public constant returns(bool) {
    return released && super.canUpgrade();
  }

  /**
   * Owner can update token information here
   */
  function setTokenInformation(string _name, string _symbol) onlyOwner {
    name = _name;
    symbol = _symbol;

    UpdatedTokenInformation(name, symbol);
  }

}

/**
 * Abstract base contract for token sales.
 *
 * Handles
 * - start and end dates
 * - accepting investments
 * - minimum funding goal and refund
 * - various statistics during the crowdfund
 * - different pricing strategies
 * - different investment policies (require server side customer id, allow only whitelisted addresses)
 *
 */
contract Crowdsale is Haltable {

  using SafeMath for uint;

  /* The token we are selling */
  CrowdsaleToken public token;

  /* How we are going to price our offering */
  PricingStrategy public pricingStrategy;

  /* How we are going to limit our offering */
  CeilingStrategy public ceilingStrategy;

  /* Post-success callback */
  FinalizeAgent public finalizeAgent;

  /* ether will be transferred to this address */
  address public multisigWallet;

  /* if the funding goal is not reached, investors may withdraw their funds */
  uint public minimumFundingGoal;

  /* the funding cannot exceed this cap; may be set later on during the crowdsale */
  uint public weiFundingCap = 0;

  /* the starting block number of the crowdsale */
  uint public startsAt;

  /* the ending block number of the crowdsale */
  uint public endsAt;

  /* the number of tokens already sold through this contract*/
  uint public tokensSold = 0;

  /* How many wei of funding we have raised */
  uint public weiRaised = 0;

  /* How many distinct addresses have invested */
  uint public investorCount = 0;

  /* How many wei we have returned back to the contract after a failed crowdfund. */
  uint public loadedRefund = 0;

  /* How many wei we have given back to investors.*/
  uint public weiRefunded = 0;

  /* Has this crowdsale been finalized */
  bool public finalized;

  /* Do we need to have a unique contributor id for each customer */
  bool public requireCustomerId;

  /** How many ETH each address has invested in this crowdsale */
  mapping (address => uint) public investedAmountOf;

  /** How many tokens this crowdsale has credited for each investor address */
  mapping (address => uint) public tokenAmountOf;

  /** Addresses that are allowed to invest even before ICO offical opens. For testing, for ICO partners, etc. */
  mapping (address => bool) public earlyParticipantWhitelist;

  /** This is for manual testing of the interaction with the owner&#39;s wallet. You can set it to any value and inspect this in a blockchain explorer to see that crowdsale interaction works. */
  uint8 public ownerTestValue;

  /** State machine
   *
   * - Prefunding: We have not reached the starting block yet
   * - Funding: Active crowdsale
   * - Success: Minimum funding goal reached
   * - Failure: Minimum funding goal not reached before the ending block
   * - Finalized: The finalize function has been called and succesfully executed
   * - Refunding: Refunds are loaded on the contract to be reclaimed by investors.
   */
  enum State{Unknown, PreFunding, Funding, Success, Failure, Finalized, Refunding}


  // A new investment was made
  event Invested(address investor, uint weiAmount, uint tokenAmount, uint128 customerId);

  // Refund was processed for a contributor
  event Refund(address investor, uint weiAmount);

  // The rules about what kind of investments we accept were changed
  event InvestmentPolicyChanged(bool requireCId);

  // Address early participation whitelist status changed
  event Whitelisted(address addr, bool status);

  // Crowdsale&#39;s finalize function has been called
  event Finalized();

  // A new funding cap has been set
  event FundingCapSet(uint newFundingCap);

  function Crowdsale(address _multisigWallet, uint _start, uint _end, uint _minimumFundingGoal) internal {
    setMultisig(_multisigWallet);

    // Don&#39;t mess the dates
    require(_start != 0 && _end != 0);
    require(block.number < _start && _start < _end);
    startsAt = _start;
    endsAt = _end;

    // Minimum funding goal can be zero
    minimumFundingGoal = _minimumFundingGoal;
  }

  /**
   * Don&#39;t expect to just send in money and get tokens.
   */
  function() payable {
    require(false);
  }

  /**
   * Make an investment.
   *
   * Crowdsale must be running for one to invest.
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
      require(earlyParticipantWhitelist[receiver]);
    }

    uint weiAmount = ceilingStrategy.weiAllowedToReceive(msg.value, weiRaised, investedAmountOf[receiver], weiFundingCap);
    uint tokenAmount = pricingStrategy.calculatePrice(weiAmount, weiRaised, tokensSold, msg.sender, token.decimals());
    
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
    uint weiToReturn = msg.value.sub(weiAmount);
    if (weiToReturn > 0) {
      msg.sender.transfer(weiToReturn);
    }
  }

  /**
   * Preallocate tokens for the early investors.
   *
   * Preallocated tokens have been sold before the actual crowdsale opens.
   * This function mints the tokens and moves the crowdsale needle.
   *
   * No money is exchanged, as the crowdsale team already have received the payment.
   *
   * @param fullTokens tokens as full tokens - decimal places added internally
   * @param weiPrice Price of a single full token in wei
   *
   */
  function preallocate(address receiver, uint fullTokens, uint weiPrice) public onlyOwner notFinished {
    require(receiver != address(0));
    uint tokenAmount = fullTokens.mul(10**uint(token.decimals()));
    require(tokenAmount != 0);
    uint weiAmount = weiPrice.mul(tokenAmount); // This can also be 0, in which case we give out tokens for free
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
    Invested(receiver, weiAmount, tokenAmount, customerId);
  }


  /**
   * Allow the owner to set a funding cap on the crowdsale.
   * The new cap should be higher than the minimum funding goal.
   * 
   * @param newCap minimum target cap that may be relaxed if it was already broken.
   */
  function setFundingCap(uint newCap) public onlyOwner notFinished {
    weiFundingCap = ceilingStrategy.relaxFundingCap(newCap, weiRaised);
    require(weiFundingCap >= minimumFundingGoal);
    FundingCapSet(weiFundingCap);
  }

  /**
   * Invest to tokens, recognize the payer.
   *
   */
  function buyWithCustomerId(uint128 customerId) public payable {
    require(customerId != 0);  // UUIDv4 sanity check
    investInternal(msg.sender, customerId);
  }

  /**
   * The basic entry point to participate in the crowdsale process.
   *
   * Pay for funding, get invested tokens back in the sender address.
   */
  function buy() public payable {
    require(!requireCustomerId); // Crowdsale needs to track participants for thank you email
    investInternal(msg.sender, 0);
  }

  /**
   * Finalize a succcesful crowdsale.
   *
   * The owner can trigger a call the contract that provides post-crowdsale actions, like releasing the tokens.
   */
  function finalize() public inState(State.Success) onlyOwner stopInEmergency {
    finalizeAgent.finalizeCrowdsale(token);
    finalized = true;
    Finalized();
  }

  /**
   * Set policy do we need to have server-side customer ids for the investments.
   *
   */
  function setRequireCustomerId(bool value) public onlyOwner stopInEmergency {
    requireCustomerId = value;
    InvestmentPolicyChanged(requireCustomerId);
  }

  /**
   * Allow addresses to do early participation.
   *
   */
  function setEarlyParticipantWhitelist(address addr, bool status) public onlyOwner notFinished stopInEmergency {
    earlyParticipantWhitelist[addr] = status;
    Whitelisted(addr, status);
  }

  /**
   * Allow to (re)set pricing strategy.
   */
  function setPricingStrategy(PricingStrategy addr) internal {
    // Disallow setting a bad agent
    require(addr.isPricingStrategy());
    pricingStrategy = addr;
  }

  /**
   * Allow to (re)set ceiling strategy.
   */
  function setCeilingStrategy(CeilingStrategy addr) internal {
    // Disallow setting a bad agent
    require(addr.isCeilingStrategy());
    ceilingStrategy = addr;
  }

  /**
   * Allow to (re)set finalize agent.
   */
  function setFinalizeAgent(FinalizeAgent addr) internal {
    // Disallow setting a bad agent
    require(addr.isFinalizeAgent());
    finalizeAgent = addr;
    require(isFinalizerSane());
  }

  /**
   * Internal setter for the multisig wallet
   */
  function setMultisig(address addr) internal {
    require(addr != 0);
    multisigWallet = addr;
  }

  /**
   * Allow load refunds back on the contract for the refunding.
   *
   * The team can transfer the funds back on the smart contract in the case that the minimum goal was not reached.
   */
  function loadRefund() public payable inState(State.Failure) stopInEmergency {
    require(msg.value >= weiRaised);
    require(weiRefunded == 0);
    uint excedent = msg.value.sub(weiRaised);
    loadedRefund = loadedRefund.add(msg.value.sub(excedent));
    investedAmountOf[msg.sender].add(excedent);
  }

  /**
   * Investors can claim refund.
   */
  function refund() public inState(State.Refunding) stopInEmergency {
    uint weiValue = investedAmountOf[msg.sender];
    require(weiValue != 0);
    investedAmountOf[msg.sender] = 0;
    weiRefunded = weiRefunded.add(weiValue);
    Refund(msg.sender, weiValue);
    msg.sender.transfer(weiValue);
  }

  /**
   * @return true if the crowdsale has raised enough money to be a success
   */
  function isMinimumGoalReached() public constant returns (bool reached) {
    return weiRaised >= minimumFundingGoal;
  }

  /**
   * Check if the contract relationship looks good.
   */
  function isFinalizerSane() public constant returns (bool sane) {
    return finalizeAgent.isSane(token);
  }

  /**
   * Crowdfund state machine management.
   *
   * This function has the timed transition builtin.
   * So there is no chance of the variable being stale.
   */
  function getState() public constant returns (State) {
    if (finalized) return State.Finalized;
    else if (block.number < startsAt) return State.PreFunding;
    else if (block.number <= endsAt && !ceilingStrategy.isCrowdsaleFull(weiRaised, weiFundingCap)) return State.Funding;
    else if (isMinimumGoalReached()) return State.Success;
    else if (!isMinimumGoalReached() && weiRaised > 0 && loadedRefund >= weiRaised) return State.Refunding;
    else return State.Failure;
  }

  /** This is for manual testing of multisig wallet interaction */
  function setOwnerTestValue(uint8 val) public onlyOwner stopInEmergency {
    ownerTestValue = val;
  }

  function assignTokens(address receiver, uint tokenAmount) private {
    token.mint(receiver, tokenAmount);
  }

  /** Interface marker. */
  function isCrowdsale() public constant returns (bool) {
    return true;
  }

  //
  // Modifiers
  //

  /** Modifier allowing execution only if the crowdsale is currently running.  */
  modifier inState(State state) {
    require(getState() == state);
    _;
  }

  modifier notFinished() {
    State current_state = getState();
    require(current_state == State.PreFunding || current_state == State.Funding);
    _;
  }

}

/**
 * Interface for defining crowdsale pricing.
 */
contract PricingStrategy {

  /** Interface declaration. */
  function isPricingStrategy() public constant returns (bool) {
    return true;
  }

  /**
   * When somebody tries to buy tokens for X eth, calculate how many tokens they get.
   *
   *
   * @param value - What is the value of the transaction sent in as wei
   * @param weiRaised - how much money has been raised this far
   * @param tokensSold - how many tokens have been sold this far
   * @param msgSender - who is the investor of this transaction
   * @param decimals - how many decimal units the token has
   * @return Amount of tokens the investor receives
   */
  function calculatePrice(uint value, uint weiRaised, uint tokensSold, address msgSender, uint decimals) public constant returns (uint tokenAmount);
}

/**
 * Fixed crowdsale pricing - everybody gets the same price.
 */
contract FlatPricing is PricingStrategy {

  using SafeMath for uint;

  /* How many weis one token costs */
  uint public oneTokenInWei;

  function FlatPricing(uint _oneTokenInWei) {
    oneTokenInWei = _oneTokenInWei;
  }

  /**
   * Calculate the current price for buy in amount.
   *
   * @ param  {uint value} Buy-in value in wei.
   * @ param
   * @ param
   * @ param
   * @ param  {uint decimals} The decimals used by the token representation (e.g. given by FractionalERC20).
   */
  function calculatePrice(uint value, uint, uint, address, uint decimals) public constant returns (uint) {
    uint multiplier = 10 ** decimals;
    return value.mul(multiplier).div(oneTokenInWei);
  }

}

/**
 * Interface for defining crowdsale ceiling.
 */
contract CeilingStrategy {

  /** Interface declaration. */
  function isCeilingStrategy() public constant returns (bool) {
    return true;
  }

  /**
   * When somebody tries to buy tokens for X wei, calculate how many weis they are allowed to use.
   *
   *
   * @param _value - What is the value of the transaction sent in as wei.
   * @param _weiRaised - How much money has been raised so far.
   * @param _weiInvestedBySender - the investment made by the address that is sending the transaction.
   * @param _weiFundingCap - the caller&#39;s declared total cap. May be reinterpreted by the implementation of the CeilingStrategy.
   * @return Amount of wei the crowdsale can receive.
   */
  function weiAllowedToReceive(uint _value, uint _weiRaised, uint _weiInvestedBySender, uint _weiFundingCap) public constant returns (uint amount);

  function isCrowdsaleFull(uint _weiRaised, uint _weiFundingCap) public constant returns (bool);

  /**
   * Calculate a new cap if the provided one is not above the amount already raised.
   *
   *
   * @param _newCap - The potential new cap.
   * @param _weiRaised - How much money has been raised so far.
   * @return The adjusted cap.
   */
  function relaxFundingCap(uint _newCap, uint _weiRaised) public constant returns (uint);

}

/**
 * Fixed cap investment per address and crowdsale
 */
contract FixedCeiling is CeilingStrategy {
    using SafeMath for uint;

    /* When relaxing a cap is necessary, we use this multiple to determine the relaxed cap */
    uint public chunkedWeiMultiple;
    /* The limit an individual address can invest */
    uint public weiLimitPerAddress;

    function FixedCeiling(uint multiple, uint limit) {
        chunkedWeiMultiple = multiple;
        weiLimitPerAddress = limit;
    }

    function weiAllowedToReceive(uint tentativeAmount, uint weiRaised, uint weiInvestedBySender, uint weiFundingCap) public constant returns (uint) {
        // First, we limit per address investment
        uint totalOfSender = tentativeAmount.add(weiInvestedBySender);
        if (totalOfSender > weiLimitPerAddress) tentativeAmount = weiLimitPerAddress.sub(weiInvestedBySender);
        // Then, we check the funding cap
        if (weiFundingCap == 0) return tentativeAmount;
        uint total = tentativeAmount.add(weiRaised);
        if (total < weiFundingCap) return tentativeAmount;
        else return weiFundingCap.sub(weiRaised);
    }

    function isCrowdsaleFull(uint weiRaised, uint weiFundingCap) public constant returns (bool) {
        return weiFundingCap > 0 && weiRaised >= weiFundingCap;
    }

    /* If the new target cap has not been reached yet, it&#39;s fine as it is */
    function relaxFundingCap(uint newCap, uint weiRaised) public constant returns (uint) {
        if (newCap > weiRaised) return newCap;
        else return weiRaised.div(chunkedWeiMultiple).add(1).mul(chunkedWeiMultiple);
    }

}

/**
 * Finalize agent defines what happens at the end of a succesful crowdsale.
 *
 * - Allocate tokens for founders, bounties and community
 * - Make tokens transferable
 * - etc.
 */
contract FinalizeAgent {

  function isFinalizeAgent() public constant returns(bool) {
    return true;
  }

  /** Return true if we can run finalizeCrowdsale() properly.
   *
   * This is a safety check function that doesn&#39;t allow crowdsale to begin
   * unless the finalizer has been set up properly.
   */
  function isSane(CrowdsaleToken token) public constant returns (bool);

  /** Called once by crowdsale finalize() if the sale was a success. */
  function finalizeCrowdsale(CrowdsaleToken token) public;

}

/**
 * At the end of the successful crowdsale allocate % bonus of tokens to the team.
 *
 * Unlock tokens.
 *
 * BonusAllocationFinal must be set as the minting agent for the MintableToken.
 *
 */
contract BonusFinalizeAgent is FinalizeAgent {

  using SafeMath for uint;

  Crowdsale public crowdsale;

  /** Total percent of tokens minted to the team at the end of the sale as base points
  bonus tokens = tokensSold * bonusBasePoints * 0.0001         */
  uint public bonusBasePoints;

  /** Implementation detail. This is the divisor of the base points **/
  uint private constant basePointsDivisor = 10000;

  /** Where we move the tokens at the end of the sale. */
  address public teamMultisig;

  /* How many bonus tokens we allocated */
  uint public allocatedBonus;

  function BonusFinalizeAgent(Crowdsale _crowdsale, uint _bonusBasePoints, address _teamMultisig) {
    require(address(_crowdsale) != 0 && address(_teamMultisig) != 0);
    crowdsale = _crowdsale;
    teamMultisig = _teamMultisig;
    bonusBasePoints = _bonusBasePoints;
  }

  /* Can we run finalize properly */
  function isSane(CrowdsaleToken token) public constant returns (bool) {
    return token.mintAgents(address(this)) && token.releaseAgent() == address(this);
  }

  /** Called once by crowdsale finalize() if the sale was a success. */
  function finalizeCrowdsale(CrowdsaleToken token) {
    require(msg.sender == address(crowdsale));

    // How many % points of tokens the founders and others get
    uint tokensSold = crowdsale.tokensSold();
    uint saleBasePoints = basePointsDivisor.sub(bonusBasePoints);
    allocatedBonus = tokensSold.mul(bonusBasePoints).div(saleBasePoints);

    // Move tokens to the team multisig wallet
    token.mint(teamMultisig, allocatedBonus);

    // Make token transferable
    token.releaseTokenTransfer();
  }

}

// This contract has the sole objective of providing a sane concrete instance of the Crowdsale contract.
contract HubiiCrowdsale is Crowdsale {
    uint private constant chunked_multiple = 18000 * (10 ** 18); // in wei
    uint private constant limit_per_address = 100000 * (10 ** 18); // in wei
    uint private constant hubii_minimum_funding = 17000 * (10 ** 18); // in wei
    uint private constant token_initial_supply = 0;
    uint8 private constant token_decimals = 15;
    bool private constant token_mintable = true;
    string private constant token_name = "Hubiits";
    string private constant token_symbol = "HBT";
    uint private constant token_in_wei = 10 ** 15;
    // The fraction of 10,000 out of the total target tokens that is used to mint bonus tokens. These are allocated to the team&#39;s multisig wallet.
    uint private constant bonus_base_points = 3000;
    function HubiiCrowdsale(address _teamMultisig, uint _start, uint _end) Crowdsale(_teamMultisig, _start, _end, hubii_minimum_funding) public {
        PricingStrategy p_strategy = new FlatPricing(token_in_wei);
        CeilingStrategy c_strategy = new FixedCeiling(chunked_multiple, limit_per_address);
        FinalizeAgent f_agent = new BonusFinalizeAgent(this, bonus_base_points, _teamMultisig); 
        setPricingStrategy(p_strategy);
        setCeilingStrategy(c_strategy);
        // Testing values
        token = new CrowdsaleToken(token_name, token_symbol, token_initial_supply, token_decimals, _teamMultisig, token_mintable);
        token.setMintAgent(address(this), true);
        token.setMintAgent(address(f_agent), true);
        token.setReleaseAgent(address(f_agent));
        setFinalizeAgent(f_agent);
    }

    // These two setters are present only to correct block numbers if they are off from their target date by more than, say, a day
    function setStartingBlock(uint startingBlock) public onlyOwner inState(State.PreFunding) {
        require(startingBlock > block.number && startingBlock < endsAt);
        startsAt = startingBlock;
    }

    function setEndingBlock(uint endingBlock) public onlyOwner notFinished {
        require(endingBlock > block.number && endingBlock > startsAt);
        endsAt = endingBlock;
    }
}