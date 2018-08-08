/**
 * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
 *
 * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
 */

pragma solidity ^0.4.15;

// import "./Crowdsale.sol";
/**
 * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
 *
 * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
 */

// pragma solidity ^0.4.15;

// import &#39;zeppelin-solidity/contracts/math/SafeMath.sol&#39;;
// pragma solidity ^0.4.18;


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
// import "./Haltable.sol";
/**
 * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
 *
 * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
 */

// pragma solidity ^0.4.15;

// import "zeppelin-solidity/contracts/ownership/Ownable.sol";
// pragma solidity ^0.4.18;


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
  function Ownable() public {
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
    if (halted) revert();
    _;
  }

  modifier stopNonOwnersInEmergency {
    if (halted && msg.sender != owner) revert();
    _;
  }

  modifier onlyInEmergency {
    if (!halted) revert();
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

// import "./PricingStrategy.sol";
/**
 * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
 *
 * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
 */

// pragma solidity ^0.4.15;

// import "zeppelin-solidity/contracts/ownership/Ownable.sol";

/**
 * Interface for defining crowdsale pricing.
 */
contract PricingStrategy is Ownable {

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

// import "./FinalizeAgent.sol";
/**
 * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
 *
 * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
 */

// pragma solidity ^0.4.15;

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

// import "./FractionalERC20.sol";
/**
 * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
 *
 * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
 */

// pragma solidity ^0.4.15;

// import "zeppelin-solidity/contracts/token/ERC20.sol";
// pragma solidity ^0.4.18;


// import &#39;./ERC20Basic.sol&#39;;
// pragma solidity ^0.4.18;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
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
  /* Time period to scale eth cap */
  uint public constant TIME_PERIOD_IN_SEC = 1 days;

  /* Base eth cap */
  uint public baseEthCap;

  /* Max eth per address */
  uint public maxEthPerAddress;

  /* Max investment count when we are still allowed to change the multisig address */
  uint public MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE = 5;

  using SafeMath for uint;

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
  uint256 public tokensSold = 0;

  /* How many wei of funding we have raised */
  uint256 public weiRaised = 0;

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
  event Invested(address investor, uint256 weiAmount, uint256 tokenAmount, uint128 customerId);

  // Refund was processed for a contributor
  event Refund(address investor, uint weiAmount);

  // The rules were changed what kind of investments we accept
  event InvestmentPolicyChanged(bool newRequireCustomerId, bool newRequiredSignedAddress, address newSignerAddress);

  // Crowdsale end time has been changed
  event EndsAtChanged(uint newEndsAt);

  // Base eth cap has been changed
  event BaseEthCapChanged(uint newBaseEthCap);

  // Max eth per address changed
  event MaxEthPerAddressChanged(uint newMaxEthPerAddress);

  function Crowdsale(address _token, PricingStrategy _pricingStrategy, address _multisigWallet, uint _start, uint _end, uint _minimumFundingGoal, uint _baseEthCap, uint _maxEthPerAddress) {

    owner = msg.sender;

    baseEthCap = _baseEthCap;

    maxEthPerAddress = _maxEthPerAddress;

    token = FractionalERC20(_token);

    setPricingStrategy(_pricingStrategy);

    multisigWallet = _multisigWallet;
    if (multisigWallet == 0) {
        revert();
    }

    if (_start == 0) {
        revert();
    }

    startsAt = _start;

    if (_end == 0) {
        revert();
    }

    endsAt = _end;

    // Don&#39;t mess the dates
    if (startsAt >= endsAt) {
        revert();
    }

    // Minimum funding goal can be zero
    minimumFundingGoal = _minimumFundingGoal;
  }

  function() payable {
    buy();
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
    uint weiAmount = msg.value;    

    // Account presale sales separately, so that they do not count against pricing tranches
    uint tokenAmount = pricingStrategy.calculatePrice(weiAmount, weiRaised - presaleWeiRaised, tokensSold, msg.sender, token.decimals());

    if (tokenAmount == 0) {
      // Dust transaction
      revert();
    }

    //get the eth cap for the time period
    uint currentFgcCap = getCurrentFgcCap();
    if (tokenAmount > currentFgcCap) {
      // We don&#39;t allow more than the current cap
      revert();
    }

    if (investedAmountOf[receiver] == 0) {
       // A new investor
       investorCount++;
    }

    // Update investor
    investedAmountOf[receiver] = investedAmountOf[receiver].add(weiAmount);
    tokenAmountOf[receiver] = tokenAmountOf[receiver].add(tokenAmount);    
    
    // Update totals
    weiRaised = weiRaised.add(weiAmount);
    tokensSold = tokensSold.add(tokenAmount);

    if (pricingStrategy.isPresalePurchase(receiver)) {
        presaleWeiRaised = presaleWeiRaised.add(weiAmount);
    }

    // Check that we did not bust the cap
    if (isBreakingCap(weiAmount, tokenAmount, weiRaised, tokensSold)) {
      revert();
    }

    assignTokens(receiver, tokenAmount);

    // Pocket the money
    if (!multisigWallet.send(weiAmount)) 
      revert();

    // Tell us invest was success
    Invested(receiver, weiAmount, tokenAmount, customerId);
  }

  function getCurrentFgcCap() public constant returns (uint) {
    if (block.timestamp < startsAt) 
      return maxEthPerAddress;

    uint timeSinceStart = block.timestamp.sub(startsAt);
    uint currentPeriod = timeSinceStart.div(TIME_PERIOD_IN_SEC).add(1);

    if (currentPeriod < 2) {
      return 5000 * 10**token.decimals();
    }
    if (currentPeriod > 2 && currentPeriod < 5) {
      return 1000 * 10**token.decimals();
    }
    if (currentPeriod > 4 && currentPeriod < 6) {
      return 500 * 10**token.decimals();
    }
    if (currentPeriod > 5 && currentPeriod < 9) {
      return 200 * 10**token.decimals();
    }
    if (currentPeriod > 8 && currentPeriod < 11) {
      return 100 * 10**token.decimals();
    }

    return maxEthPerAddress;
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
  function preallocate(address receiver, uint256 fullTokens, uint256 weiPrice) public onlyOwner {

    uint256 tokenAmount = fullTokens;
	//uint256 tokenAmount = fullTokens * 10**token.decimals();
    uint256 weiAmount = weiPrice * fullTokens; // This can be also 0, we give out tokens for free

    weiRaised = weiRaised.add(weiAmount);
    tokensSold = tokensSold.add(tokenAmount);

    investedAmountOf[receiver] = investedAmountOf[receiver].add(weiAmount);
    tokenAmountOf[receiver] = tokenAmountOf[receiver].add(tokenAmount);

    assignTokens(receiver, tokenAmount);

    // Tell us invest was success
    Invested(receiver, weiAmount, tokenAmount, 0);
  }

  /**
   * Allow anonymous contributions to this crowdsale.
   */
  function investWithSignedAddress(address addr, uint128 customerId, uint8 v, bytes32 r, bytes32 s) public payable {
     bytes32 hash = sha256(addr);
     if (ecrecover(hash, v, r, s) != signerAddress) 
      revert();
     if (customerId == 0) 
      revert();  // UUIDv4 sanity check
     investInternal(addr, customerId);
  }

  /**
   * Track who is the customer making the payment so we can send thank you email.
   */
  function investWithCustomerId(address addr, uint128 customerId) public payable {
    if (requiredSignedAddress) 
      revert(); // Crowdsale allows only server-side signed participants
    if (customerId == 0) 
      revert();  // UUIDv4 sanity check
    investInternal(addr, customerId);
  }

  /**
   * Allow anonymous contributions to this crowdsale.
   */
  function invest(address addr) public payable {
    if (requireCustomerId) 
      revert(); // Crowdsale needs to track partipants for thank you email
    if (requiredSignedAddress) 
      revert(); // Crowdsale allows only server-side signed participants
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
    if (finalized) {
      revert();
    }

    // Finalizing is optional. We only call it if we are given a finalizing agent.
    if (address(finalizeAgent) != 0) {
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
    if (!finalizeAgent.isFinalizeAgent()) {
      revert();
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
   * Set the base eth cap
   */
  function setBaseEthCap(uint _baseEthCap) onlyOwner {
    if (_baseEthCap == 0) 
      revert();
    baseEthCap = _baseEthCap;
    BaseEthCapChanged(baseEthCap);
  }

  /**
   * Set the max eth per address
   */
  function setMaxEthPerAddress(uint _maxEthPerAddress) onlyOwner {
    if(_maxEthPerAddress == 0)
      revert();
    maxEthPerAddress = _maxEthPerAddress;
    MaxEthPerAddressChanged(maxEthPerAddress);
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
    if (now > time) {
      revert(); // Don&#39;t change past
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
    if (!pricingStrategy.isPricingStrategy()) {
      revert();
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
    if (investorCount > MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE) {
      revert();
    }

    multisigWallet = addr;
  }

  /**
   * Allow load refunds back on the contract for the refunding.
   *
   * The team can transfer the funds back on the smart contract in the case the minimum goal was not reached..
   */
  function loadRefund() public payable inState(State.Failure) {
    if (msg.value == 0) 
      revert();
    loadedRefund = loadedRefund.add(msg.value);
  }

  /**
   * Investors can claim refund.
   *
   * Note that any refunds from proxy buyers should be handled separately,
   * and not through this contract.
   */
  function refund() public inState(State.Refunding) {
    uint256 weiValue = investedAmountOf[msg.sender];
    if (weiValue == 0) 
      revert();
    investedAmountOf[msg.sender] = 0;
    weiRefunded = weiRefunded.add(weiValue);
    Refund(msg.sender, weiValue);
    if (!msg.sender.send(weiValue)) 
      revert();
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
    if (finalized) 
      return State.Finalized;
    else if (address(finalizeAgent) == 0) 
      return State.Preparing;
    else if (!finalizeAgent.isSane()) 
      return State.Preparing;
    else if (!pricingStrategy.isSane(address(this))) 
      return State.Preparing;
    else if (block.timestamp < startsAt) 
      return State.PreFunding;
    else if (block.timestamp <= endsAt && !isCrowdsaleFull()) 
      return State.Funding;
    else if (isMinimumGoalReached()) 
      return State.Success;
    else if (!isMinimumGoalReached() && weiRaised > 0 && loadedRefund >= weiRaised) 
      return State.Refunding;
    else 
      return State.Failure;
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
    if (getState() != state) 
      revert();
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

// import "./PricingStrategy.sol";
/**
 * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
 *
 * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
 */

// pragma solidity ^0.4.15;

// import "zeppelin-solidity/contracts/ownership/Ownable.sol";


/**
 * A crowdsale that is selling tokens from a preallocated pool
 *
 *
 * - Tokens have precreated supply "premined"
 *
 * - Token owner must transfer sellable tokens to the crowdsale contract using ERC20.approve()
 *
 */
contract AllocatedCrowdsale is Crowdsale {

  /* The party who holds the full token pool and has approve()&#39;ed tokens for this crowdsale */
  address public beneficiary;

  function AllocatedCrowdsale(address _token, PricingStrategy _pricingStrategy, address _multisigWallet, uint _start, uint _end, uint _minimumFundingGoal, address _beneficiary, uint baseEthCap, uint maxEthPerAddress) 
    Crowdsale(_token, _pricingStrategy, _multisigWallet, _start, _end, _minimumFundingGoal, baseEthCap, maxEthPerAddress) {
    beneficiary = _beneficiary;
  }

  /**
   * Called from invest() to confirm if the curret investment does not break our cap rule.
   */
  function isBreakingCap(uint weiAmount, uint tokenAmount, uint weiRaisedTotal, uint tokensSoldTotal) constant returns (bool limitBroken) {
    if (tokenAmount > getTokensLeft()) {
      return true;
    } else {
      return false;
    }
  }

  /**
   * We are sold out when our approve pool becomes empty.
   */
  function isCrowdsaleFull() public constant returns (bool) {
    return getTokensLeft() == 0;
  }

  /**
   * Get the amount of unsold tokens allocated to this contract;
   */
  function getTokensLeft() public constant returns (uint) {
    return token.allowance(owner, this);
  }

  /**
   * Transfer tokens from approve() pool to the buyer.
   *
   * Use approve() given to this crowdsale to distribute the tokens.
   */
  function assignTokens(address receiver, uint256 tokenAmount) private {
    if (!token.transferFrom(beneficiary, receiver, tokenAmount)) 
      revert();
  }
}