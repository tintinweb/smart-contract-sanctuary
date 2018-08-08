pragma solidity ^0.4.11;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
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
    if (newOwner != address(0)) {
      owner = newOwner;
    }
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
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}

contract IMintableToken {
    function mint(address _to, uint256 _amount) returns (bool);
    function finishMinting() returns (bool);
}

contract PricingStrategy {

    using SafeMath for uint;

    uint public rate0;
    uint public rate1;
    uint public rate2;

    uint public threshold1;
    uint public threshold2;

    uint public minimumWeiAmount;

    function PricingStrategy(
        uint _rate0,
        uint _rate1,
        uint _rate2,
        uint _minimumWeiAmount,
        uint _threshold1,
        uint _threshold2
    ) {
        require(_rate0 > 0);
        require(_rate1 > 0);
        require(_rate2 > 0);
        require(_minimumWeiAmount > 0);
        require(_threshold1 > 0);
        require(_threshold2 > 0);

        rate0 = _rate0;
        rate1 = _rate1;
        rate2 = _rate2;
        minimumWeiAmount = _minimumWeiAmount;
        threshold1 = _threshold1;
        threshold2 = _threshold2;
    }

    /** Interface declaration. */
    function isPricingStrategy() public constant returns (bool) {
        return true;
    }

    /** Calculate the current price for buy in amount. */
    function calculateTokenAmount(uint weiAmount) public constant returns (uint tokenAmount) {
        uint bonusRate = 0;

        if (weiAmount >= minimumWeiAmount) {
            bonusRate = rate0;
        }

        if (weiAmount >= threshold1) {
            bonusRate = rate1;
        }

        if (weiAmount >= threshold2) {
            bonusRate = rate2;
        }

        return weiAmount.mul(bonusRate);
    }
}



contract Reservation is Pausable {

    using SafeMath for uint;

    /* Max investment count when we are still allowed to change the multisig address */
    uint public MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE = 500;

    /* The token we are selling */
    IMintableToken public token;

    /* How we are going to price our offering */
    PricingStrategy public pricingStrategy;

    /* tokens will be transfered from this address */
    address public multisigWallet;

    /* if the funding goal is not reached, investors may withdraw their funds */
    uint public minimumFundingGoal;

    /* the UNIX timestamp start date of the reservation */
    uint public startsAt;

    /* the UNIX timestamp end date of the reservation */
    uint public endsAt;

    /* Maximum amount of tokens this reservation can sell. */
    uint public tokensHardCap;

    /* the number of tokens already sold through this contract*/
    uint public tokensSold = 0;

    /* How many wei of funding we have raised */
    uint public weiRaised = 0;

    /* How many distinct addresses have invested */
    uint public investorCount = 0;

    /* How much wei we have returned back to the contract after a failed crowdfund. */
    uint public loadedRefund = 0;

    /* How much wei we have given back to investors.*/
    uint public weiRefunded = 0;

    /** How much ETH each address has invested to this reservation */
    mapping (address => uint256) public investedAmountOf;

    /** How much tokens this reservation has credited for each investor address */
    mapping (address => uint256) public tokenAmountOf;

    /** Addresses that are allowed to invest even before ICO offical opens. Only for testing purpuses. */
    mapping (address => bool) public earlyParticipantWhitelist;

    /** State machine
    *
    * - Preparing: All contract initialization calls and variables have not been set yet
    * - Prefunding: We have not passed start time yet
    * - Funding: Active reservation
    * - Success: Minimum funding goal reached
    * - Failure: Minimum funding goal not reached before ending time
    * - Refunding: Refunds are loaded on the contract for reclaim.
    */
    enum State{Unknown, Preparing, PreFunding, Funding, Success, Failure, Refunding}

    // A new investment was made
    event Invested(address investor, uint weiAmount, uint tokenAmount);

    // Refund was processed for a contributor
    event Refund(address investor, uint weiAmount);

    // Address early participation whitelist status changed
    event Whitelisted(address addr, bool status);

    // Reservation end time has been changed
    event EndsAtChanged(uint endsAt);

    function Reservation(
        address _token, 
        address _pricingStrategy, 
        address _multisigWallet, 
        uint _start, 
        uint _end, 
        uint _tokensHardCap,
        uint _minimumFundingGoal
    ) {
        require(_token != 0);
        require(_pricingStrategy != 0);
        require(_multisigWallet != 0);
        require(_start != 0);
        require(_end != 0);
        require(_start < _end);
        require(_tokensHardCap != 0);

        token = IMintableToken(_token);
        setPricingStrategy(_pricingStrategy);
        multisigWallet = _multisigWallet;
        startsAt = _start;
        endsAt = _end;
        tokensHardCap = _tokensHardCap;
        minimumFundingGoal = _minimumFundingGoal;
    }

    /**
    * Buy tokens
    */
    function() payable {
        invest(msg.sender);
    }

    /**
    * Make an investment.
    *
    * Reservation must be running for one to invest.
    * We must have not pressed the emergency brake.
    *
    * @param receiver The Ethereum address who receives the tokens
    */
    function invest(address receiver) whenNotPaused payable {

        // Determine if it&#39;s a good time to accept investment from this participant
        if (getState() == State.PreFunding) {
            // Are we whitelisted for early deposit
            require(earlyParticipantWhitelist[receiver]);
        } else {
            require(getState() == State.Funding);
        }

        uint weiAmount = msg.value;

        // Account reservation sales separately, so that they do not count against pricing tranches
        uint tokenAmount = pricingStrategy.calculateTokenAmount(weiAmount);

        // Dust transaction
        require(tokenAmount > 0);

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

        // Check that we did not bust the cap
        require(!isBreakingCap(tokensSold));

        token.mint(receiver, tokenAmount);

        // Pocket the money
        multisigWallet.transfer(weiAmount);

        // Tell us invest was success
        Invested(receiver, weiAmount, tokenAmount);
    }

    /**
    * Allow addresses to do early participation.
    *
    */
    function setEarlyParicipantWhitelist(address addr, bool status) onlyOwner {
        earlyParticipantWhitelist[addr] = status;
        Whitelisted(addr, status);
    }

    /**
    * Allow reservation owner to close early or extend the reservation.
    *
    * This is useful e.g. for a manual soft cap implementation:
    * - after X amount is reached determine manual closing
    *
    * This may put the reservation to an invalid state,
    * but we trust owners know what they are doing.
    *
    */
    function setEndsAt(uint time) onlyOwner {

        require(now <= time);

        endsAt = time;
        EndsAtChanged(endsAt);
    }

    /**
    * Allow to (re)set pricing strategy.
    *
    * Design choice: no state restrictions on the set, so that we can fix fat finger mistakes.
    */
    function setPricingStrategy(address _pricingStrategy) onlyOwner {
        pricingStrategy = PricingStrategy(_pricingStrategy);

        // Don&#39;t allow setting bad agent
        require(pricingStrategy.isPricingStrategy());
    }

    /**
    * Allow to change the team multisig address in the case of emergency.
    *
    * This allows to save a deployed reservation wallet in the case the reservation has not yet begun
    * (we have done only few test transactions). After the reservation is going
    * then multisig address stays locked for the safety reasons.
    */
    function setMultisig(address addr) public onlyOwner {

        require(investorCount <= MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE);

        multisigWallet = addr;
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
        uint256 weiValue = investedAmountOf[msg.sender];
        require(weiValue > 0);

        investedAmountOf[msg.sender] = 0;
        weiRefunded = weiRefunded.add(weiValue);
        Refund(msg.sender, weiValue);
        
        msg.sender.transfer(weiValue);
    }

    /**
    * Crowdfund state machine management.
    *
    * We make it a function and do not assign the result to a variable, so there is no chance of the variable being stale.
    */
    function getState() public constant returns (State) {
        if (address(pricingStrategy) == 0)
            return State.Preparing;
        else if (block.timestamp < startsAt)
            return State.PreFunding;
        else if (block.timestamp <= endsAt && !isReservationFull())
            return State.Funding;
        else if (isMinimumGoalReached())
            return State.Success;
        else if (!isMinimumGoalReached() && weiRaised > 0 && loadedRefund >= weiRaised)
            return State.Refunding;
        else
            return State.Failure;
    }

    /**
    * @return true if the reservation has raised enough money to be a successful.
    */
    function isMinimumGoalReached() public constant returns (bool reached) {
        return weiRaised >= minimumFundingGoal;
    }

    /**
    * Called from invest() to confirm if the curret investment does not break our cap rule.
    */
    function isBreakingCap(uint tokensSoldTotal) constant returns (bool) {
        return tokensSoldTotal > tokensHardCap;
    }

    function isReservationFull() public constant returns (bool) {
        return tokensSold >= tokensHardCap;
    }

    //
    // Modifiers
    //

    /** Modified allowing execution only if the reservation is currently running.  */
    modifier inState(State state) {
        require(getState() == state);
        _;
    }
}