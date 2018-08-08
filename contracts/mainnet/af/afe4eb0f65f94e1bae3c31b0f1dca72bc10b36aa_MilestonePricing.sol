/**
 * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
 *
 * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
 */


/**
 * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
 *
 * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
 */


/**
 * Interface for defining crowdsale pricing.
 */
contract PricingStrategy {

  /** Interface declaration. */
  function isPricingStrategy() public constant returns (bool) {
    return true;
  }

  /** Self check if all references are correctly set.
   *
   * Checks that pricing strategy matches crowdsale parameters.
   */
  function isSane(address crowdsale) public constant returns (bool) {
    return true;
  }

  /**
   * @dev Pricing tells if this is a presale purchase or not.
     @param purchaser Address of the purchaser
     @return False by default, true if a presale purchaser
   */
  function isPresalePurchase(address purchaser) public constant returns (bool) {
    return false;
  }

  /**
   * When somebody tries to buy tokens for X eth, calculate how many tokens they get.
   *
   *
   * @param value - What is the value of the transaction send in as wei
   * @param tokensSold - how much tokens have been sold this far
   * @param weiRaised - how much money has been raised this far in the main token sale - this number excludes presale
   * @param msgSender - who is the investor of this transaction
   * @param decimals - how many decimal units the token has
   * @return Amount of tokens the investor receives
   */
  function calculatePrice(uint value, uint weiRaised, uint tokensSold, address msgSender, uint decimals) public constant returns (uint tokenAmount);
}

/**
 * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
 *
 * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
 */


/**
 * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
 *
 * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
 */


/**
 * Safe unsigned safe math.
 *
 * https://blog.aragon.one/library-driven-development-in-solidity-2bebcaf88736#.750gwtwli
 *
 * Originally from https://raw.githubusercontent.com/AragonOne/zeppelin-solidity/master/contracts/SafeMathLib.sol
 *
 * Maintained here until merged to mainline zeppelin-solidity.
 *
 */
library SafeMathLib {

  function times(uint a, uint b) returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function minus(uint a, uint b) returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function plus(uint a, uint b) returns (uint) {
    uint c = a + b;
    assert(c>=a);
    return c;
  }

}

/**
 * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
 *
 * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
 */




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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


/*
 * Haltable
 *
 * Abstract contract that allows children to implement an
 * emergency stop mechanism. Differs from Pausable by causing a throw when in halt mode.
 *
 *
 * Originally envisioned in FirstBlood ICO contract.
 */
contract Haltable is Ownable {
  bool public halted;

  modifier stopInEmergency {
    if (halted) throw;
    _;
  }

  modifier stopNonOwnersInEmergency {
    if (halted && msg.sender != owner) throw;
    _;
  }

  modifier onlyInEmergency {
    if (!halted) throw;
    _;
  }

  // called by the owner on emergency, triggers stopped state
  function halt() external onlyOwner {
    halted = true;
  }

  // called by the owner on end of emergency, returns to normal state
  function unhalt() external onlyOwner onlyInEmergency {
    halted = false;
  }

}


/**
 * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
 *
 * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
 */


/**
 * Finalize agent defines what happens at the end of succeseful crowdsale.
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
  function isSane() public constant returns (bool);

  /** Called once by crowdsale finalize() if the sale was success. */
  function finalizeCrowdsale();

}

/**
 * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
 *
 * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
 */






/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * A token that defines fractional units as decimals.
 */
contract FractionalERC20 is ERC20 {

  uint public decimals;

}



/**
 * Abstract base contract for token sales.
 *
 * Handle
 * - start and end dates
 * - accepting investments
 * - minimum funding goal and refund
 * - various statistics during the crowdfund
 * - different pricing strategies
 * - different investment policies (require server side customer id, allow only whitelisted addresses)
 *
 */
contract Crowdsale is Haltable {

  /* Max investment count when we are still allowed to change the multisig address */
  uint public MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE = 5;

  using SafeMathLib for uint;

  /* The token we are selling */
  FractionalERC20 public token;

  /* How we are going to price our offering */
  PricingStrategy public pricingStrategy;

  /* Post-success callback */
  FinalizeAgent public finalizeAgent;

  /* tokens will be transfered from this address */
  address public multisigWallet;

  /* if the funding goal is not reached, investors may withdraw their funds */
  uint public minimumFundingGoal;

  /* the UNIX timestamp start date of the crowdsale */
  uint public startsAt;

  /* the UNIX timestamp end date of the crowdsale */
  uint public endsAt;

  /* the number of tokens already sold through this contract*/
  uint public tokensSold = 0;

  /* How many wei of funding we have raised */
  uint public weiRaised = 0;

  /* Calculate incoming funds from presale contracts and addresses */
  uint public presaleWeiRaised = 0;

  /* How many distinct addresses have invested */
  uint public investorCount = 0;

  /* How much wei we have returned back to the contract after a failed crowdfund. */
  uint public loadedRefund = 0;

  /* How much wei we have given back to investors.*/
  uint public weiRefunded = 0;

  /* Has this crowdsale been finalized */
  bool public finalized;

  /* Do we need to have unique contributor id for each customer */
  bool public requireCustomerId;

  /**
    * Do we verify that contributor has been cleared on the server side (accredited investors only).
    * This method was first used in FirstBlood crowdsale to ensure all contributors have accepted terms on sale (on the web).
    */
  bool public requiredSignedAddress;

  /* Server side address that signed allowed contributors (Ethereum addresses) that can participate the crowdsale */
  address public signerAddress;

  /** How much ETH each address has invested to this crowdsale */
  mapping (address => uint256) public investedAmountOf;

  /** How much tokens this crowdsale has credited for each investor address */
  mapping (address => uint256) public tokenAmountOf;

  /** Addresses that are allowed to invest even before ICO offical opens. For testing, for ICO partners, etc. */
  mapping (address => bool) public earlyParticipantWhitelist;

  /** This is for manul testing for the interaction from owner wallet. You can set it to any value and inspect this in blockchain explorer to see that crowdsale interaction works. */
  uint public ownerTestValue;

  /** State machine
   *
   * - Preparing: All contract initialization calls and variables have not been set yet
   * - Prefunding: We have not passed start time yet
   * - Funding: Active crowdsale
   * - Success: Minimum funding goal reached
   * - Failure: Minimum funding goal not reached before ending time
   * - Finalized: The finalized has been called and succesfully executed
   * - Refunding: Refunds are loaded on the contract for reclaim.
   */
  enum State{Unknown, Preparing, PreFunding, Funding, Success, Failure, Finalized, Refunding}

  // A new investment was made
  event Invested(address investor, uint weiAmount, uint tokenAmount, uint128 customerId);

  // Refund was processed for a contributor
  event Refund(address investor, uint weiAmount);

  // The rules were changed what kind of investments we accept
  event InvestmentPolicyChanged(bool newRequireCustomerId, bool newRequiredSignedAddress, address newSignerAddress);

  // Address early participation whitelist status changed
  event Whitelisted(address addr, bool status);

  // Crowdsale end time has been changed
  event EndsAtChanged(uint newEndsAt);

  function Crowdsale(address _token, PricingStrategy _pricingStrategy, address _multisigWallet, uint _start, uint _end, uint _minimumFundingGoal) {

    owner = msg.sender;

    token = FractionalERC20(_token);

    setPricingStrategy(_pricingStrategy);

    multisigWallet = _multisigWallet;
    if(multisigWallet == 0) {
        throw;
    }

    if(_start == 0) {
        throw;
    }

    startsAt = _start;

    if(_end == 0) {
        throw;
    }

    endsAt = _end;

    // Don&#39;t mess the dates
    if(startsAt >= endsAt) {
        throw;
    }

    // Minimum funding goal can be zero
    minimumFundingGoal = _minimumFundingGoal;
  }

  /**
   * Don&#39;t expect to just send in money and get tokens.
   */
  function() payable {
    throw;
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
  function investInternal(address receiver, uint128 customerId) stopInEmergency private {

    // Determine if it&#39;s a good time to accept investment from this participant
    if(getState() == State.PreFunding) {
      // Are we whitelisted for early deposit
      if(!earlyParticipantWhitelist[receiver]) {
        throw;
      }
    } else if(getState() == State.Funding) {
      // Retail participants can only come in when the crowdsale is running
      // pass
    } else {
      // Unwanted state
      throw;
    }

    uint weiAmount = msg.value;

    // Account presale sales separately, so that they do not count against pricing tranches
    uint tokenAmount = pricingStrategy.calculatePrice(weiAmount, weiRaised - presaleWeiRaised, tokensSold, msg.sender, token.decimals());

    if(tokenAmount == 0) {
      // Dust transaction
      throw;
    }

    if(investedAmountOf[receiver] == 0) {
       // A new investor
       investorCount++;
    }

    // Update investor
    investedAmountOf[receiver] = investedAmountOf[receiver].plus(weiAmount);
    tokenAmountOf[receiver] = tokenAmountOf[receiver].plus(tokenAmount);

    // Update totals
    weiRaised = weiRaised.plus(weiAmount);
    tokensSold = tokensSold.plus(tokenAmount);

    if(pricingStrategy.isPresalePurchase(receiver)) {
        presaleWeiRaised = presaleWeiRaised.plus(weiAmount);
    }

    // Check that we did not bust the cap
    if(isBreakingCap(weiAmount, tokenAmount, weiRaised, tokensSold)) {
      throw;
    }

    assignTokens(receiver, tokenAmount);

    // Pocket the money
    if(!multisigWallet.send(weiAmount)) throw;

    // Tell us invest was success
    Invested(receiver, weiAmount, tokenAmount, customerId);
  }

  /**
   * Preallocate tokens for the early investors.
   *
   * Preallocated tokens have been sold before the actual crowdsale opens.
   * This function mints the tokens and moves the crowdsale needle.
   *
   * Investor count is not handled; it is assumed this goes for multiple investors
   * and the token distribution happens outside the smart contract flow.
   *
   * No money is exchanged, as the crowdsale team already have received the payment.
   *
   * @param fullTokens tokens as full tokens - decimal places added internally
   * @param weiPrice Price of a single full token in wei
   *
   */
  function preallocate(address receiver, uint fullTokens, uint weiPrice) public onlyOwner {

    uint tokenAmount = fullTokens * 10**token.decimals();
    uint weiAmount = weiPrice * fullTokens; // This can be also 0, we give out tokens for free

    weiRaised = weiRaised.plus(weiAmount);
    tokensSold = tokensSold.plus(tokenAmount);

    investedAmountOf[receiver] = investedAmountOf[receiver].plus(weiAmount);
    tokenAmountOf[receiver] = tokenAmountOf[receiver].plus(tokenAmount);

    assignTokens(receiver, tokenAmount);

    // Tell us invest was success
    Invested(receiver, weiAmount, tokenAmount, 0);
  }

  /**
   * Allow anonymous contributions to this crowdsale.
   */
  function investWithSignedAddress(address addr, uint128 customerId, uint8 v, bytes32 r, bytes32 s) public payable {
     bytes32 hash = sha256(addr);
     if (ecrecover(hash, v, r, s) != signerAddress) throw;
     if(customerId == 0) throw;  // UUIDv4 sanity check
     investInternal(addr, customerId);
  }

  /**
   * Track who is the customer making the payment so we can send thank you email.
   */
  function investWithCustomerId(address addr, uint128 customerId) public payable {
    if(requiredSignedAddress) throw; // Crowdsale allows only server-side signed participants
    if(customerId == 0) throw;  // UUIDv4 sanity check
    investInternal(addr, customerId);
  }

  /**
   * Allow anonymous contributions to this crowdsale.
   */
  function invest(address addr) public payable {
    if(requireCustomerId) throw; // Crowdsale needs to track participants for thank you email
    if(requiredSignedAddress) throw; // Crowdsale allows only server-side signed participants
    investInternal(addr, 0);
  }

  /**
   * Invest to tokens, recognize the payer and clear his address.
   *
   */
  function buyWithSignedAddress(uint128 customerId, uint8 v, bytes32 r, bytes32 s) public payable {
    investWithSignedAddress(msg.sender, customerId, v, r, s);
  }

  /**
   * Invest to tokens, recognize the payer.
   *
   */
  function buyWithCustomerId(uint128 customerId) public payable {
    investWithCustomerId(msg.sender, customerId);
  }

  /**
   * The basic entry point to participate the crowdsale process.
   *
   * Pay for funding, get invested tokens back in the sender address.
   */
  function buy() public payable {
    invest(msg.sender);
  }

  /**
   * Finalize a succcesful crowdsale.
   *
   * The owner can triggre a call the contract that provides post-crowdsale actions, like releasing the tokens.
   */
  function finalize() public inState(State.Success) onlyOwner stopInEmergency {

    // Already finalized
    if(finalized) {
      throw;
    }

    // Finalizing is optional. We only call it if we are given a finalizing agent.
    if(address(finalizeAgent) != 0) {
      finalizeAgent.finalizeCrowdsale();
    }

    finalized = true;
  }

  /**
   * Allow to (re)set finalize agent.
   *
   * Design choice: no state restrictions on setting this, so that we can fix fat finger mistakes.
   */
  function setFinalizeAgent(FinalizeAgent addr) onlyOwner {
    finalizeAgent = addr;

    // Don&#39;t allow setting bad agent
    if(!finalizeAgent.isFinalizeAgent()) {
      throw;
    }
  }

  /**
   * Set policy do we need to have server-side customer ids for the investments.
   *
   */
  function setRequireCustomerId(bool value) onlyOwner {
    requireCustomerId = value;
    InvestmentPolicyChanged(requireCustomerId, requiredSignedAddress, signerAddress);
  }

  /**
   * Set policy if all investors must be cleared on the server side first.
   *
   * This is e.g. for the accredited investor clearing.
   *
   */
  function setRequireSignedAddress(bool value, address _signerAddress) onlyOwner {
    requiredSignedAddress = value;
    signerAddress = _signerAddress;
    InvestmentPolicyChanged(requireCustomerId, requiredSignedAddress, signerAddress);
  }

  /**
   * Allow addresses to do early participation.
   *
   * TODO: Fix spelling error in the name
   */
  function setEarlyParicipantWhitelist(address addr, bool status) onlyOwner {
    earlyParticipantWhitelist[addr] = status;
    Whitelisted(addr, status);
  }

  /**
   * Allow crowdsale owner to close early or extend the crowdsale.
   *
   * This is useful e.g. for a manual soft cap implementation:
   * - after X amount is reached determine manual closing
   *
   * This may put the crowdsale to an invalid state,
   * but we trust owners know what they are doing.
   *
   */
  function setEndsAt(uint time) onlyOwner {

    if(now > time) {
      throw; // Don&#39;t change past
    }

    endsAt = time;
    EndsAtChanged(endsAt);
  }

  /**
   * Allow to (re)set pricing strategy.
   *
   * Design choice: no state restrictions on the set, so that we can fix fat finger mistakes.
   */
  function setPricingStrategy(PricingStrategy _pricingStrategy) onlyOwner {
    pricingStrategy = _pricingStrategy;

    // Don&#39;t allow setting bad agent
    if(!pricingStrategy.isPricingStrategy()) {
      throw;
    }
  }

  /**
   * Allow to change the team multisig address in the case of emergency.
   *
   * This allows to save a deployed crowdsale wallet in the case the crowdsale has not yet begun
   * (we have done only few test transactions). After the crowdsale is going
   * then multisig address stays locked for the safety reasons.
   */
  function setMultisig(address addr) public onlyOwner {

    // Change
    if(investorCount > MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE) {
      throw;
    }

    multisigWallet = addr;
  }

  /**
   * Allow load refunds back on the contract for the refunding.
   *
   * The team can transfer the funds back on the smart contract in the case the minimum goal was not reached..
   */
  function loadRefund() public payable inState(State.Failure) {
    if(msg.value == 0) throw;
    loadedRefund = loadedRefund.plus(msg.value);
  }

  /**
   * Investors can claim refund.
   *
   * Note that any refunds from proxy buyers should be handled separately,
   * and not through this contract.
   */
  function refund() public inState(State.Refunding) {
    uint256 weiValue = investedAmountOf[msg.sender];
    if (weiValue == 0) throw;
    investedAmountOf[msg.sender] = 0;
    weiRefunded = weiRefunded.plus(weiValue);
    Refund(msg.sender, weiValue);
    if (!msg.sender.send(weiValue)) throw;
  }

  /**
   * @return true if the crowdsale has raised enough money to be a successful.
   */
  function isMinimumGoalReached() public constant returns (bool reached) {
    return weiRaised >= minimumFundingGoal;
  }

  /**
   * Check if the contract relationship looks good.
   */
  function isFinalizerSane() public constant returns (bool sane) {
    return finalizeAgent.isSane();
  }

  /**
   * Check if the contract relationship looks good.
   */
  function isPricingSane() public constant returns (bool sane) {
    return pricingStrategy.isSane(address(this));
  }

  /**
   * Crowdfund state machine management.
   *
   * We make it a function and do not assign the result to a variable, so there is no chance of the variable being stale.
   */
  function getState() public constant returns (State) {
    if(finalized) return State.Finalized;
    else if (address(finalizeAgent) == 0) return State.Preparing;
    else if (!finalizeAgent.isSane()) return State.Preparing;
    else if (!pricingStrategy.isSane(address(this))) return State.Preparing;
    else if (block.timestamp < startsAt) return State.PreFunding;
    else if (block.timestamp <= endsAt && !isCrowdsaleFull()) return State.Funding;
    else if (isMinimumGoalReached()) return State.Success;
    else if (!isMinimumGoalReached() && weiRaised > 0 && loadedRefund >= weiRaised) return State.Refunding;
    else return State.Failure;
  }

  /** This is for manual testing of multisig wallet interaction */
  function setOwnerTestValue(uint val) onlyOwner {
    ownerTestValue = val;
  }

  /** Interface marker. */
  function isCrowdsale() public constant returns (bool) {
    return true;
  }

  //
  // Modifiers
  //

  /** Modified allowing execution only if the crowdsale is currently running.  */
  modifier inState(State state) {
    if(getState() != state) throw;
    _;
  }


  //
  // Abstract functions
  //

  /**
   * Check if the current invested breaks our cap rules.
   *
   *
   * The child contract must define their own cap setting rules.
   * We allow a lot of flexibility through different capping strategies (ETH, token count)
   * Called from invest().
   *
   * @param weiAmount The amount of wei the investor tries to invest in the current transaction
   * @param tokenAmount The amount of tokens we try to give to the investor in the current transaction
   * @param weiRaisedTotal What would be our total raised balance after this transaction
   * @param tokensSoldTotal What would be our total sold tokens count after this transaction
   *
   * @return true if taking this investment would break our cap rules
   */
  function isBreakingCap(uint weiAmount, uint tokenAmount, uint weiRaisedTotal, uint tokensSoldTotal) constant returns (bool limitBroken);

  /**
   * Check if the current crowdsale is full and we can no longer sell any tokens.
   */
  function isCrowdsaleFull() public constant returns (bool);

  /**
   * Create new tokens or transfer issued tokens to the investor depending on the cap model.
   */
  function assignTokens(address receiver, uint tokenAmount) private;
}





/// @dev Time milestone based pricing with special support for pre-ico deals.
contract MilestonePricing is PricingStrategy, Ownable {

  using SafeMathLib for uint;

  uint public constant MAX_MILESTONE = 10;

  // This contains all pre-ICO addresses, and their prices (weis per token)
  mapping (address => uint) public preicoAddresses;

  /**
  * Define pricing schedule using milestones.
  */
  struct Milestone {

      // UNIX timestamp when this milestone kicks in
      uint time;

      // How many tokens per satoshi you will get after this milestone has been passed
      uint price;
  }

  // Store milestones in a fixed array, so that it can be seen in a blockchain explorer
  // Milestone 0 is always (0, 0)
  // (TODO: change this when we confirm dynamic arrays are explorable)
  Milestone[10] public milestones;

  // How many active milestones we have
  uint public milestoneCount;

  /// @dev Contruction, creating a list of milestones
  /// @param _milestones uint[] milestones Pairs of (time, price)
  function MilestonePricing(uint[] _milestones) {
    // Need to have tuples, length check
    if(_milestones.length % 2 == 1 || _milestones.length >= MAX_MILESTONE*2) {
      throw;
    }

    milestoneCount = _milestones.length / 2;

    uint lastTimestamp = 0;

    for(uint i=0; i<_milestones.length/2; i++) {
      milestones[i].time = _milestones[i*2];
      milestones[i].price = _milestones[i*2+1];

      // No invalid steps
      if((lastTimestamp != 0) && (milestones[i].time <= lastTimestamp)) {
        throw;
      }

      lastTimestamp = milestones[i].time;
    }

    // Last milestone price must be zero, terminating the crowdale
    if(milestones[milestoneCount-1].price != 0) {
      throw;
    }
  }

  /// @dev This is invoked once for every pre-ICO address, set pricePerToken
  ///      to 0 to disable
  /// @param preicoAddress PresaleFundCollector address
  /// @param pricePerToken How many weis one token cost for pre-ico investors
  function setPreicoAddress(address preicoAddress, uint pricePerToken)
    public
    onlyOwner
  {
    preicoAddresses[preicoAddress] = pricePerToken;
  }

  /// @dev Iterate through milestones. You reach end of milestones when price = 0
  /// @return tuple (time, price)
  function getMilestone(uint n) public constant returns (uint, uint) {
    return (milestones[n].time, milestones[n].price);
  }

  function getFirstMilestone() private constant returns (Milestone) {
    return milestones[0];
  }

  function getLastMilestone() private constant returns (Milestone) {
    return milestones[milestoneCount-1];
  }

  function getPricingStartsAt() public constant returns (uint) {
    return getFirstMilestone().time;
  }

  function getPricingEndsAt() public constant returns (uint) {
    return getLastMilestone().time;
  }

  function isSane(address _crowdsale) public constant returns(bool) {
    Crowdsale crowdsale = Crowdsale(_crowdsale);
    return crowdsale.startsAt() == getPricingStartsAt() && crowdsale.endsAt() == getPricingEndsAt();
  }

  /// @dev Get the current milestone or bail out if we are not in the milestone periods.
  /// @return {[type]} [description]
  function getCurrentMilestone() private constant returns (Milestone) {
    uint i;

    for(i=0; i<milestones.length; i++) {
      if(now < milestones[i].time) {
        return milestones[i-1];
      }
    }
  }

  /// @dev Get the current price.
  /// @return The current price or 0 if we are outside milestone period
  function getCurrentPrice() public constant returns (uint result) {
    return getCurrentMilestone().price;
  }

  /// @dev Calculate the current price for buy in amount.
  function calculatePrice(uint value, uint weiRaised, uint tokensSold, address msgSender, uint decimals) public constant returns (uint) {

    uint multiplier = 10 ** decimals;

    // This investor is coming through pre-ico
    if(preicoAddresses[msgSender] > 0) {
      return value.times(multiplier) / preicoAddresses[msgSender];
    }

    uint price = getCurrentPrice();
    return value.times(multiplier) / price;
  }

  function isPresalePurchase(address purchaser) public constant returns (bool) {
    if(preicoAddresses[purchaser] > 0)
      return true;
    else
      return false;
  }

  function() payable {
    throw; // No money on this contract
  }

}