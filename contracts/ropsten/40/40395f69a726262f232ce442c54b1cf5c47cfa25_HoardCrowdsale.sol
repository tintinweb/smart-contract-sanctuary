/**
 * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
 *
 * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
 *
 ** Code Modified by : TokenMagic
 ** Change Log: 
 *** Solidity version upgraded from 0.4.8 to 0.4.23
 */
 
 
pragma solidity ^0.4.23;

/*
* Ownable Contract
* Added by : TokenMagic
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

/*
* Haltable Contract
* Added by : TokenMagic
*/
contract Haltable is Ownable {
  bool public halted;

  modifier stopInEmergency {
    require(!halted);
    _;
  }

  modifier stopNonOwnersInEmergency {
    require(!halted && msg.sender == owner);
    _;
  }

  modifier onlyInEmergency {
    require(halted);
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

/*
* SafeMathLib Library
* Added by : TokenMagic
*/
library SafeMathLib {

  function times(uint a, uint b) public pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

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
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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


/*
* Token Contract 
* Added by : TokenMagic
*/
contract FractionalERC20 {

  uint public decimals;

  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/*
* Crowdsale Contract
* Added by : TokenMagic
*/
contract HoardCrowdsale is Haltable {

  using SafeMathLib for uint;

  /* The token we are selling */
  FractionalERC20 public token;

  /* tokens will be transfered from this address */
  address public multisigWallet;
  
  /* Founders team MultiSig Wallet address */
  address public foundersTeamMultisig;
  
  /* if the funding goal is not reached, investors may withdraw their funds */
  uint public minimumFundingGoal = 50000000000000000000; // 50 ETH in Wei

  /* the UNIX timestamp start date of the crowdsale */
  uint public startsAt;

  /* the UNIX timestamp end date of the crowdsale */
  uint public endsAt;

  /* the number of tokens already sold through this contract*/
  uint public tokensSold = 0;

  /* the number of tokens already sold through this contract for presale*/
  uint public presaleTokensSold = 0;

  /* the number of tokens already sold before presale*/
  uint public prePresaleTokensSold = 0;

  /* Maximum number tokens that presale can assign*/ 
  uint public presaleTokenLimit = 80000000000000000000000000; //80,000,000 token

  /* Maximum number tokens that crowdsale can assign*/ 
  uint public crowdsaleTokenLimit = 120000000000000000000000000; //120,000,000 token
  
  /** Total percent of tokens allocated to the founders team multiSig wallet at the end of the sale */
  uint public percentageOfSoldTokensForFounders = 50; // 50% of solded token as bonus to founders team multiSig wallet
  
  /* How much bonus tokens we allocated */
  uint public tokensForFoundingBoardWallet;
  
  /* The party who holds the full token pool and has approve()&#39;ed tokens for this crowdsale */
  address public beneficiary;
  
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

  /** How much ETH each address has invested to this crowdsale */
  mapping (address => uint256) public investedAmountOf;

  /** How much tokens this crowdsale has credited for each investor address */
  mapping (address => uint256) public tokenAmountOf;

  /** Presale Addresses that are allowed to invest. */
  mapping (address => bool) public presaleWhitelist;

  /** Addresses that are allowed to invest. */
  mapping (address => bool) public participantWhitelist;

  /** This is for manul testing for the interaction from owner wallet. You can set it to any value and inspect this in blockchain explorer to see that crowdsale interaction works. */
  uint public ownerTestValue;

  uint public oneTokenInWei;

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
  event Invested(address investor, uint weiAmount, uint tokenAmount);

  // Refund was processed for a contributor
  event Refund(address investor, uint weiAmount);

  // Address participation whitelist status changed
  event Whitelisted(address[] addr, bool status);

  // Presale Address participation whitelist status changed
  event PresaleWhitelisted(address addr, bool status);
    
  // Crowdsale start time has been changed
  event StartsAtChanged(uint newStartsAt);
      
  // Crowdsale end time has been changed
  event EndsAtChanged(uint newEndsAt);
  
  // Crowdsale token price has been changed
  event TokenPriceChanged(uint tokenPrice);
    
  // Crowdsale multisig address has been changed    
  event MultiSigChanged(address newAddr);
  
  // Crowdsale beneficiary address has been changed    
  event BeneficiaryChanged(address newAddr);
  
  // Founders Team Wallet Address Changed 
  event FoundersWalletChanged(address newAddr);
  
  // Founders Team Token Allocation Percentage Changed 
  event FoundersTokenAllocationChanged(uint newValue);
  
  // Pre-Presale Tokens Value Changed
  event PrePresaleTokensValueChanged(uint newValue);

  constructor(address _token, uint _oneTokenInWei, address _multisigWallet, uint _start, uint _end, address _beneficiary, address _foundersTeamMultisig) public {

    require(_multisigWallet != address(0) && _start != 0 && _end != 0 && _start <= _end);
    owner = msg.sender;

    token = FractionalERC20(_token);
    oneTokenInWei = _oneTokenInWei;

    multisigWallet = _multisigWallet;
    startsAt = _start;
    endsAt = _end;

    beneficiary = _beneficiary;
    foundersTeamMultisig = _foundersTeamMultisig;
  }
  
  /**
   * Just send in money and get tokens.
   * Modified by : TokenMagic
   */
  function() payable public {
    investInternal(msg.sender,0);
  }
  
  /** 
  * Pre-sale contract call this function and get tokens 
  * Modified by : TokenMagic
  */
  function invest(address addr,uint tokenAmount) public payable {
    investInternal(addr,tokenAmount);
  }
  
  /**
   * Make an investment.
   *
   * Crowdsale must be running for one to invest.
   * We must have not pressed the emergency brake.
   *
   * @param receiver The Ethereum address who receives the tokens
   *
   * @return tokenAmount How mony tokens were bought
   *
   * Modified by : TokenMagic
   */
  function investInternal(address receiver, uint tokens) stopInEmergency internal returns(uint tokensBought) {

    uint weiAmount = msg.value;
    uint tokenAmount = tokens;
    if(getState() == State.PreFunding || getState() == State.Funding) {
      if(presaleWhitelist[msg.sender]){
        // Allow presale particaipants
        presaleWeiRaised = presaleWeiRaised.add(weiAmount);
        presaleTokensSold = presaleTokensSold.add(tokenAmount);
        require(presaleTokensSold <= presaleTokenLimit); 
      }
      else if(participantWhitelist[receiver]){
        uint multiplier = 10 ** token.decimals();
        tokenAmount = weiAmount.times(multiplier) / oneTokenInWei;
        // Allow whitelisted participants    
      }
      else {
        revert();
      }
    } else {
      // Unwanted state
      revert();
    }
    
    // Dust transaction
    require(tokenAmount != 0);

    if(investedAmountOf[receiver] == 0) {
      // A new investor
      investorCount++;
    }

    // Update investor
    investedAmountOf[receiver] = investedAmountOf[receiver].add(weiAmount);
    tokenAmountOf[receiver] = tokenAmountOf[receiver].add(tokenAmount);

    // Update totals
    weiRaised = weiRaised.add(weiAmount);
    tokensSold = tokensSold.add(tokenAmount);
    
    require(tokensSold.sub(presaleTokensSold) <= crowdsaleTokenLimit);
    
    // Check that we did not bust the cap
    require(!isBreakingCap(tokenAmount));
    require(token.transferFrom(beneficiary, receiver, tokenAmount));

    emit Invested(receiver, weiAmount, tokenAmount);
    multisigWallet.transfer(weiAmount);
    return tokenAmount;
  }

  /**
   * Finalize a succcesful crowdsale.
   * The owner can triggre a call the contract that provides post-crowdsale actions, like releasing the tokens.
   * Added by : TokenMagic
   */
  function finalize() public inState(State.Success) onlyOwner stopInEmergency {
    require(!finalized); // Not already finalized
    
    // How many % of tokens the founders and others get
    tokensForFoundingBoardWallet = tokensSold.times(percentageOfSoldTokensForFounders) / 100;
    tokensForFoundingBoardWallet = tokensForFoundingBoardWallet.add(prePresaleTokensSold);
    require(token.transferFrom(beneficiary, foundersTeamMultisig, tokensForFoundingBoardWallet));
    
    finalized = true;
  }

  /**
   * Allow owner to change the percentage value of solded tokens to founders team wallet after finalize. Default value is 50.
   * Added by : TokenMagic
   */ 
  function setFoundersTokenAllocation(uint _percentageOfSoldTokensForFounders) public onlyOwner{
    percentageOfSoldTokensForFounders = _percentageOfSoldTokensForFounders;
    emit FoundersTokenAllocationChanged(percentageOfSoldTokensForFounders);
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
  function setEndsAt(uint time) onlyOwner public {
    require(now < time && startsAt < time);
    endsAt = time;
    emit EndsAtChanged(endsAt);
  }
  
  /**
   * Allow owner to change crowdsale startsAt data.
   * Added by : TokenMagic
   **/ 
  function setStartsAt(uint time) onlyOwner public {
    require(time < endsAt);
    startsAt = time;
    emit StartsAtChanged(startsAt);
  }

  /**
   * Allow to change the team multisig address in the case of emergency.
   *
   * This allows to save a deployed crowdsale wallet in the case the crowdsale has not yet begun
   * (we have done only few test transactions). After the crowdsale is going
   * then multisig address stays locked for the safety reasons.
   */
  function setMultisig(address addr) public onlyOwner {
    multisigWallet = addr;
    emit MultiSigChanged(addr);
  }

  /**
   * Allow load refunds back on the contract for the refunding.
   *
   * The team can transfer the funds back on the smart contract in the case the minimum goal was not reached..
   */
  function loadRefund() public payable inState(State.Failure) {
    require(msg.value > 0);
    loadedRefund = loadedRefund.add(msg.value);
  }

  /**
   * Investors can claim refund.
   *
   * Note that any refunds from proxy buyers should be handled separately,
   * and not through this contract.
   */
  function refund() public inState(State.Refunding) {
    // require(token.transferFrom(msg.sender,address(this),tokenAmountOf[msg.sender])); user should approve their token to this contract before this.
    uint256 weiValue = investedAmountOf[msg.sender];
    require(weiValue > 0);
    investedAmountOf[msg.sender] = 0;
    weiRefunded = weiRefunded.add(weiValue);
    emit Refund(msg.sender, weiValue);
    msg.sender.transfer(weiValue);
  }

  /**
   * @return true if the crowdsale has raised enough money to be a successful.
   */
  function isMinimumGoalReached() public view  returns (bool reached) {
    return weiRaised >= minimumFundingGoal;
  }


  /**
   * Crowdfund state machine management.
   * We make it a function and do not assign the result to a variable, so there is no chance of the variable being stale.
   * Modified by : TokenMagic
   */
  function getState() public view returns (State) {
    if(finalized) return State.Finalized;
    else if (block.timestamp < startsAt) return State.PreFunding;
    else if (block.timestamp <= endsAt && !isCrowdsaleFull()) return State.Funding;
    else if (isMinimumGoalReached()) return State.Success;
    else if (!isMinimumGoalReached() && weiRaised > 0 && loadedRefund >= weiRaised) return State.Refunding;
    else return State.Failure;
  }

  /** This is for manual testing of multisig wallet interaction */
  function setOwnerTestValue(uint val) onlyOwner public {
    ownerTestValue = val;
  }

  /**
  * Allow owner to change PrePresaleTokensSold value 
  * Added by : TokenMagic
  **/
  function setPrePresaleTokens(uint _value) onlyOwner public {
    prePresaleTokensSold = _value;
    emit PrePresaleTokensValueChanged(_value);
  }

  /**
   * Allow addresses to do participation.
   * Modified by : TokenMagic
  */
  function setParticipantWhitelist(address[] addr, bool status) onlyOwner public {
    for(uint i = 0; i < addr.length; i++ ){
      participantWhitelist[addr[i]] = status;
    }
    emit Whitelisted(addr, status);
  }

  /**
   * Allow presale to do participation.
   * Added by : TokenMagic
  */
  function setPresaleWhitelist(address addr, bool status) onlyOwner public {
    presaleWhitelist[addr] = status;
    emit PresaleWhitelisted(addr, status);
  }
  
  /**
   * Allow crowdsale owner to change the crowdsale token price.
   * Added by : TokenMagic
  */
  function setPricing(uint _oneTokenInWei) onlyOwner public{
    oneTokenInWei = _oneTokenInWei;
    emit TokenPriceChanged(oneTokenInWei);
  } 
  
  /**
   * Allow crowdsale owner to change the crowdsale beneficiary address.
   * Added by : TokenMagic
  */
  function changeBeneficiary(address _beneficiary) onlyOwner public{
    beneficiary = _beneficiary; 
    emit BeneficiaryChanged(beneficiary);
  }
  
  /**
   * Allow crowdsale owner to change the crowdsale founders team address.
   * Added by : TokenMagic
  */
  function changeFoundersWallet(address _foundersTeamMultisig) onlyOwner public{
    foundersTeamMultisig = _foundersTeamMultisig;
    emit FoundersWalletChanged(foundersTeamMultisig);
  } 
  
  /** Interface marker. */
  function isCrowdsale() public pure returns (bool) {
    return true;
  }

  //
  // Modifiers
  //

  /** Modified allowing execution only if the crowdsale is currently running.  */
  modifier inState(State state) {
    require(getState() == state);
    _;
  }

 /**
   * Called from invest() to confirm if the curret investment does not break our cap rule.
   */
  function isBreakingCap(uint tokenAmount) public view returns (bool limitBroken)  {
    if(tokenAmount > getTokensLeft()) {
      return true;
    } else {
      return false;
    }
  }

  /**
   * We are sold out when our approve pool becomes empty.
   */
  function isCrowdsaleFull() public view returns (bool) {
    return getTokensLeft() == 0;
  }

  /**
   * Get the amount of unsold tokens allocated to this contract;
   */
  function getTokensLeft() public view returns (uint) {
    return token.allowance(beneficiary, this);
  }

}