// MeNet.IO 
pragma solidity ^0.4.11;


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
library SafeMathLibExt {

  function times(uint a, uint b) returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function divides(uint a, uint b) returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
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
 * Interface for defining crowdsale pricing.
 */
contract PricingStrategy {

  address public tier;

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

  /* How many weis one token costs */
  function updateRate(uint newOneTokenInWei) public;

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
 * Finalize agent defines what happens at the end of succeseful crowdsale.
 *
 * - Allocate tokens for founders, bounties and community
 * - Make tokens transferable
 * - etc.
 */
contract FinalizeAgent {

  bool public reservedTokensAreDistributed = false;

  function isFinalizeAgent() public constant returns(bool) {
    return true;
  }

  /** Return true if we can run finalizeCrowdsale() properly.
   *
   * This is a safety check function that doesn&#39;t allow crowdsale to begin
   * unless the finalizer has been set up properly.
   */
  function isSane() public constant returns (bool);

  function distributeReservedTokens(uint reservedTokensDistributionBatch);

  /** Called once by crowdsale finalize() if the sale was success. */
  function finalizeCrowdsale();

}
/**
 * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
 *
 * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
 */









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
contract FractionalERC20Ext is ERC20 {

  uint public decimals;
  uint public minCap;

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
contract CrowdsaleExt is Haltable {

  /* Max investment count when we are still allowed to change the multisig address */
  uint public MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE = 5;

  using SafeMathLibExt for uint;

  /* The token we are selling */
  FractionalERC20Ext public token;

  /* How we are going to price our offering */
  PricingStrategy public pricingStrategy;

  /* Post-success callback */
  FinalizeAgent public finalizeAgent;

  /* name of the crowdsale tier */
  string public name;

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

  /* How many distinct addresses have invested */
  uint public investorCount = 0;

  /* Has this crowdsale been finalized */
  bool public finalized;

  bool public isWhiteListed;

  address[] public joinedCrowdsales;
  uint8 public joinedCrowdsalesLen = 0;
  uint8 public joinedCrowdsalesLenMax = 50;
  struct JoinedCrowdsaleStatus {
    bool isJoined;
    uint8 position;
  }
  mapping (address => JoinedCrowdsaleStatus) joinedCrowdsaleState;

  /** How much ETH each address has invested to this crowdsale */
  mapping (address => uint256) public investedAmountOf;

  /** How much tokens this crowdsale has credited for each investor address */
  mapping (address => uint256) public tokenAmountOf;

  struct WhiteListData {
    bool status;
    uint minCap;
    uint maxCap;
  }

  //is crowdsale updatable
  bool public isUpdatable;

  /** Addresses that are allowed to invest even before ICO offical opens. For testing, for ICO partners, etc. */
  mapping (address => WhiteListData) public earlyParticipantWhitelist;

  /** List of whitelisted addresses */
  address[] public whitelistedParticipants;

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
   */
  enum State{Unknown, Preparing, PreFunding, Funding, Success, Failure, Finalized}

  // A new investment was made
  event Invested(address investor, uint weiAmount, uint tokenAmount, uint128 customerId);

  // Address early participation whitelist status changed
  event Whitelisted(address addr, bool status, uint minCap, uint maxCap);
  event WhitelistItemChanged(address addr, bool status, uint minCap, uint maxCap);

  // Crowdsale start time has been changed
  event StartsAtChanged(uint newStartsAt);

  // Crowdsale end time has been changed
  event EndsAtChanged(uint newEndsAt);

  function CrowdsaleExt(string _name, address _token, PricingStrategy _pricingStrategy, address _multisigWallet, uint _start, uint _end, uint _minimumFundingGoal, bool _isUpdatable, bool _isWhiteListed) {

    owner = msg.sender;

    name = _name;

    token = FractionalERC20Ext(_token);

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

    isUpdatable = _isUpdatable;

    isWhiteListed = _isWhiteListed;
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
      throw;
    } else if(getState() == State.Funding) {
      // Retail participants can only come in when the crowdsale is running
      // pass
      if(isWhiteListed) {
        if(!earlyParticipantWhitelist[receiver].status) {
          throw;
        }
      }
    } else {
      // Unwanted state
      throw;
    }

    uint weiAmount = msg.value;

    // Account presale sales separately, so that they do not count against pricing tranches
    uint tokenAmount = pricingStrategy.calculatePrice(weiAmount, weiRaised, tokensSold, msg.sender, token.decimals());

    if(tokenAmount == 0) {
      // Dust transaction
      throw;
    }

    if(isWhiteListed) {
      if(tokenAmount < earlyParticipantWhitelist[receiver].minCap && tokenAmountOf[receiver] == 0) {
        // tokenAmount < minCap for investor
        throw;
      }

      // Check that we did not bust the investor&#39;s cap
      if (isBreakingInvestorCap(receiver, tokenAmount)) {
        throw;
      }

      updateInheritedEarlyParticipantWhitelist(receiver, tokenAmount);
    } else {
      if(tokenAmount < token.minCap() && tokenAmountOf[receiver] == 0) {
        throw;
      }
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
   * Allow anonymous contributions to this crowdsale.
   */
  function invest(address addr) public payable {
    investInternal(addr, 0);
  }

  /**
   * The basic entry point to participate the crowdsale process.
   *
   * Pay for funding, get invested tokens back in the sender address.
   */
  function buy() public payable {
    invest(msg.sender);
  }

  function distributeReservedTokens(uint reservedTokensDistributionBatch) public inState(State.Success) onlyOwner stopInEmergency {
    // Already finalized
    if(finalized) {
      throw;
    }

    // Finalizing is optional. We only call it if we are given a finalizing agent.
    if(address(finalizeAgent) != address(0)) {
      finalizeAgent.distributeReservedTokens(reservedTokensDistributionBatch);
    }
  }

  function areReservedTokensDistributed() public constant returns (bool) {
    return finalizeAgent.reservedTokensAreDistributed();
  }

  function canDistributeReservedTokens() public constant returns(bool) {
    CrowdsaleExt lastTierCntrct = CrowdsaleExt(getLastTier());
    if ((lastTierCntrct.getState() == State.Success) && !lastTierCntrct.halted() && !lastTierCntrct.finalized() && !lastTierCntrct.areReservedTokensDistributed()) return true;
    return false;
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
    if(address(finalizeAgent) != address(0)) {
      finalizeAgent.finalizeCrowdsale();
    }

    finalized = true;
  }

  /**
   * Allow to (re)set finalize agent.
   *
   * Design choice: no state restrictions on setting this, so that we can fix fat finger mistakes.
   */
  function setFinalizeAgent(FinalizeAgent addr) public onlyOwner {
    assert(address(addr) != address(0));
    assert(address(finalizeAgent) == address(0));
    finalizeAgent = addr;

    // Don&#39;t allow setting bad agent
    if(!finalizeAgent.isFinalizeAgent()) {
      throw;
    }
  }

  /**
   * Allow addresses to do early participation.
   */
  function setEarlyParticipantWhitelist(address addr, bool status, uint minCap, uint maxCap) public onlyOwner {
    if (!isWhiteListed) throw;
    assert(addr != address(0));
    assert(maxCap > 0);
    assert(minCap <= maxCap);
    assert(now <= endsAt);

    if (!isAddressWhitelisted(addr)) {
      whitelistedParticipants.push(addr);
      Whitelisted(addr, status, minCap, maxCap);
    } else {
      WhitelistItemChanged(addr, status, minCap, maxCap);
    }

    earlyParticipantWhitelist[addr] = WhiteListData({status:status, minCap:minCap, maxCap:maxCap});
  }

  function setEarlyParticipantWhitelistMultiple(address[] addrs, bool[] statuses, uint[] minCaps, uint[] maxCaps) public onlyOwner {
    if (!isWhiteListed) throw;
    assert(now <= endsAt);
    assert(addrs.length == statuses.length);
    assert(statuses.length == minCaps.length);
    assert(minCaps.length == maxCaps.length);
    for (uint iterator = 0; iterator < addrs.length; iterator++) {
      setEarlyParticipantWhitelist(addrs[iterator], statuses[iterator], minCaps[iterator], maxCaps[iterator]);
    }
  }

  function updateInheritedEarlyParticipantWhitelist(address reciever, uint tokensBought) private {
    if (!isWhiteListed) throw;
    if (tokensBought < earlyParticipantWhitelist[reciever].minCap && tokenAmountOf[reciever] == 0) throw;

    uint8 tierPosition = getTierPosition(this);

    for (uint8 j = tierPosition + 1; j < joinedCrowdsalesLen; j++) {
      CrowdsaleExt crowdsale = CrowdsaleExt(joinedCrowdsales[j]);
      crowdsale.updateEarlyParticipantWhitelist(reciever, tokensBought);
    }
  }

  function updateEarlyParticipantWhitelist(address addr, uint tokensBought) public {
    if (!isWhiteListed) throw;
    assert(addr != address(0));
    assert(now <= endsAt);
    assert(isTierJoined(msg.sender));
    if (tokensBought < earlyParticipantWhitelist[addr].minCap && tokenAmountOf[addr] == 0) throw;
    //if (addr != msg.sender && contractAddr != msg.sender) throw;
    uint newMaxCap = earlyParticipantWhitelist[addr].maxCap;
    newMaxCap = newMaxCap.minus(tokensBought);
    earlyParticipantWhitelist[addr] = WhiteListData({status:earlyParticipantWhitelist[addr].status, minCap:0, maxCap:newMaxCap});
  }

  function isAddressWhitelisted(address addr) public constant returns(bool) {
    for (uint i = 0; i < whitelistedParticipants.length; i++) {
      if (whitelistedParticipants[i] == addr) {
        return true;
        break;
      }
    }

    return false;
  }

  function whitelistedParticipantsLength() public constant returns (uint) {
    return whitelistedParticipants.length;
  }

  function isTierJoined(address addr) public constant returns(bool) {
    return joinedCrowdsaleState[addr].isJoined;
  }

  function getTierPosition(address addr) public constant returns(uint8) {
    return joinedCrowdsaleState[addr].position;
  }

  function getLastTier() public constant returns(address) {
    if (joinedCrowdsalesLen > 0)
      return joinedCrowdsales[joinedCrowdsalesLen - 1];
    else
      return address(0);
  }

  function setJoinedCrowdsales(address addr) private onlyOwner {
    assert(addr != address(0));
    assert(joinedCrowdsalesLen <= joinedCrowdsalesLenMax);
    assert(!isTierJoined(addr));
    joinedCrowdsales.push(addr);
    joinedCrowdsaleState[addr] = JoinedCrowdsaleStatus({
      isJoined: true,
      position: joinedCrowdsalesLen
    });
    joinedCrowdsalesLen++;
  }

  function updateJoinedCrowdsalesMultiple(address[] addrs) public onlyOwner {
    assert(addrs.length > 0);
    assert(joinedCrowdsalesLen == 0);
    assert(addrs.length <= joinedCrowdsalesLenMax);
    for (uint8 iter = 0; iter < addrs.length; iter++) {
      setJoinedCrowdsales(addrs[iter]);
    }
  }

  function setStartsAt(uint time) onlyOwner {
    assert(!finalized);
    assert(isUpdatable);
    assert(now <= time); // Don&#39;t change past
    assert(time <= endsAt);
    assert(now <= startsAt);

    CrowdsaleExt lastTierCntrct = CrowdsaleExt(getLastTier());
    if (lastTierCntrct.finalized()) throw;

    uint8 tierPosition = getTierPosition(this);

    //start time should be greater then end time of previous tiers
    for (uint8 j = 0; j < tierPosition; j++) {
      CrowdsaleExt crowdsale = CrowdsaleExt(joinedCrowdsales[j]);
      assert(time >= crowdsale.endsAt());
    }

    startsAt = time;
    StartsAtChanged(startsAt);
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
  function setEndsAt(uint time) public onlyOwner {
    assert(!finalized);
    assert(isUpdatable);
    assert(now <= time);// Don&#39;t change past
    assert(startsAt <= time);
    assert(now <= endsAt);

    CrowdsaleExt lastTierCntrct = CrowdsaleExt(getLastTier());
    if (lastTierCntrct.finalized()) throw;


    uint8 tierPosition = getTierPosition(this);

    for (uint8 j = tierPosition + 1; j < joinedCrowdsalesLen; j++) {
      CrowdsaleExt crowdsale = CrowdsaleExt(joinedCrowdsales[j]);
      assert(time <= crowdsale.startsAt());
    }

    endsAt = time;
    EndsAtChanged(endsAt);
  }

  /**
   * Allow to (re)set pricing strategy.
   *
   * Design choice: no state restrictions on the set, so that we can fix fat finger mistakes.
   */
  function setPricingStrategy(PricingStrategy _pricingStrategy) public onlyOwner {
    assert(address(_pricingStrategy) != address(0));
    assert(address(pricingStrategy) == address(0));
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
    else return State.Failure;
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
  function isBreakingCap(uint weiAmount, uint tokenAmount, uint weiRaisedTotal, uint tokensSoldTotal) public constant returns (bool limitBroken);

  function isBreakingInvestorCap(address receiver, uint tokenAmount) public constant returns (bool limitBroken);

  /**
   * Check if the current crowdsale is full and we can no longer sell any tokens.
   */
  function isCrowdsaleFull() public constant returns (bool);

  /**
   * Create new tokens or transfer issued tokens to the investor depending on the cap model.
   */
  function assignTokens(address receiver, uint tokenAmount) private;
}

/**
 * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
 *
 * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
 */







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
            throw;
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

    // We don&#39;t do interface check here as we might want to a normal wallet address to act as a release agent
    releaseAgent = addr;
  }

  /**
   * Owner can allow a particular address (a crowdsale contract) to transfer tokens despite the lock up period.
   */
  function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
    transferAgents[addr] = state;
  }

  /**
   * One way function to release the tokens to the wild.
   *
   * Can be called only from the release agent that is the final ICO contract. It is only called if the crowdsale has been success (first milestone reached).
   */
  function releaseTokenTransfer() public onlyReleaseAgent {
    released = true;
  }

  /** The function can be called only before or after the tokens have been releasesd */
  modifier inReleaseState(bool releaseState) {
    if(releaseState != released) {
        throw;
    }
    _;
  }

  /** The function can be called only by a whitelisted release agent. */
  modifier onlyReleaseAgent() {
    if(msg.sender != releaseAgent) {
        throw;
    }
    _;
  }

  function transfer(address _to, uint _value) canTransfer(msg.sender) returns (bool success) {
    // Call StandardToken.transfer()
   return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) canTransfer(_from) returns (bool success) {
    // Call StandardToken.transferForm()
    return super.transferFrom(_from, _to, _value);
  }

}


/**
 * A finalize agent that does nothing.
 *
 * - Token transfer must be manually released by the owner
 */
contract NullFinalizeAgentExt is FinalizeAgent {

  CrowdsaleExt public crowdsale;

  function NullFinalizeAgentExt(CrowdsaleExt _crowdsale) {
    crowdsale = _crowdsale;
  }

  /** Check that we can release the token */
  function isSane() public constant returns (bool) {
    return true;
  }

  function distributeReservedTokens(uint reservedTokensDistributionBatch) public {
  }

  /** Called once by crowdsale finalize() if the sale was success. */
  function finalizeCrowdsale() public {
  }

}