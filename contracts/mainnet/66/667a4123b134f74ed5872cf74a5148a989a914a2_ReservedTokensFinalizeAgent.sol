pragma solidity 0.4.24;


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

    function times(uint a, uint b) public pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function divides(uint a, uint b) public pure returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function minus(uint a, uint b) public pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function plus(uint a, uint b) public pure returns (uint) {
        uint c = a + b;
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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor () public {
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
        if (halted) 
            revert();
        _;
    }

    modifier stopNonOwnersInEmergency {
        if (halted && msg.sender != owner) 
            revert();
        _;
    }

    modifier onlyInEmergency {
        if (!halted) 
            revert();
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
 * Interface for defining crowdsale pricing.
 */
contract PricingStrategy {

    address public tier;

    /** Interface declaration. */
    function isPricingStrategy() public pure returns (bool) {
        return true;
    }

    /** Self check if all references are correctly set.
    *
    * Checks that pricing strategy matches crowdsale parameters.
    */
    function isSane() public pure returns (bool) {
        return true;
    }

    /**
    * @dev Pricing tells if this is a presale purchase or not.  
      @return False by default, true if a presale purchaser
    */
    function isPresalePurchase() public pure returns (bool) {
        return false;
    }

    /* How many weis one token costs */
    function updateRate(uint oneTokenInCents) public;

    /**
    * When somebody tries to buy tokens for X eth, calculate how many tokens they get.
    *
    *
    * @param value - What is the value of the transaction send in as wei
    * @param tokensSold - how much tokens have been sold this far
    * @param decimals - how many decimal units the token has
    * @return Amount of tokens the investor receives
    */
    function calculatePrice(uint value, uint tokensSold, uint decimals) public view returns (uint tokenAmount);

    function oneTokenInWei(uint tokensSold, uint decimals) public view returns (uint);
}

/**
 * Finalize agent defines what happens at the end of succeseful crowdsale.
 *
 * - Allocate tokens for founders, bounties and community
 * - Make tokens transferable
 * - etc.
 */
contract FinalizeAgent {

    bool public reservedTokensAreDistributed = false;

    function isFinalizeAgent() public pure returns(bool) {
        return true;
    }

    /** Return true if we can run finalizeCrowdsale() properly.
    *
    * This is a safety check function that doesn&#39;t allow crowdsale to begin
    * unless the finalizer has been set up properly.
    */
    function isSane() public view returns (bool);

    function distributeReservedTokens(uint reservedTokensDistributionBatch) public;

    /** Called once by crowdsale finalize() if the sale was success. */
    function finalizeCrowdsale() public;
    
    /**
    * Allow to (re)set Token.
    */
    function setCrowdsaleTokenExtv1(address _token) public;
}

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
contract FractionalERC20Ext is ERC20 {
    uint public decimals;
    uint public minCap;
}

contract Allocatable is Ownable {

  /** List of agents that are allowed to allocate new tokens */
    mapping (address => bool) public allocateAgents;

    event AllocateAgentChanged(address addr, bool state  );

  /**
   * Owner can allow a crowdsale contract to allocate new tokens.
   */
    function setAllocateAgent(address addr, bool state) public onlyOwner  
    {
        allocateAgents[addr] = state;
        emit AllocateAgentChanged(addr, state);
    }

    modifier onlyAllocateAgent() {
        //Only crowdsale contracts are allowed to allocate new tokens
        require(allocateAgents[msg.sender]);
        _;
    }
}

/**
 * Contract to enforce Token Vesting
 */
contract TokenVesting is Allocatable {

    using SafeMathLibExt for uint;

    address public crowdSaleTokenAddress;

    /** keep track of total tokens yet to be released, 
     * this should be less than or equal to UTIX tokens held by this contract. 
     */
    uint256 public totalUnreleasedTokens;

    // default vesting parameters
    uint256 private startAt = 0;
    uint256 private cliff = 1;
    uint256 private duration = 4; 
    uint256 private step = 300; //15778463;  //2592000;
    bool private changeFreezed = false;

    struct VestingSchedule {
        uint256 startAt;
        uint256 cliff;
        uint256 duration;
        uint256 step;
        uint256 amount;
        uint256 amountReleased;
        bool changeFreezed;
    }

    mapping (address => VestingSchedule) public vestingMap;

    event VestedTokensReleased(address _adr, uint256 _amount);
    
    constructor(address _tokenAddress) public {
        
        crowdSaleTokenAddress = _tokenAddress;
    }

    /** Modifier to check if changes to vesting is freezed  */
    modifier changesToVestingFreezed(address _adr) {
        require(vestingMap[_adr].changeFreezed);
        _;
    }

    /** Modifier to check if changes to vesting is not freezed yet  */
    modifier changesToVestingNotFreezed(address adr) {
        require(!vestingMap[adr].changeFreezed); // if vesting not set then also changeFreezed will be false
        _;
    }

    /** Function to set default vesting schedule parameters. */
    function setDefaultVestingParameters(
        uint256 _startAt, uint256 _cliff, uint256 _duration,
        uint256 _step, bool _changeFreezed) public onlyAllocateAgent {

        // data validation
        require(_step != 0);
        require(_duration != 0);
        require(_cliff <= _duration);

        startAt = _startAt;
        cliff = _cliff;
        duration = _duration; 
        step = _step;
        changeFreezed = _changeFreezed;

    }

    /** Function to set vesting with default schedule. */
    function setVestingWithDefaultSchedule(address _adr, uint256 _amount) 
    public 
    changesToVestingNotFreezed(_adr) onlyAllocateAgent {
       
        setVesting(_adr, startAt, cliff, duration, step, _amount, changeFreezed);
    }    

    /** Function to set/update vesting schedule. PS - Amount cannot be changed once set */
    function setVesting(
        address _adr,
        uint256 _startAt,
        uint256 _cliff,
        uint256 _duration,
        uint256 _step,
        uint256 _amount,
        bool _changeFreezed) 
    public changesToVestingNotFreezed(_adr) onlyAllocateAgent {

        VestingSchedule storage vestingSchedule = vestingMap[_adr];

        // data validation
        require(_step != 0);
        require(_amount != 0 || vestingSchedule.amount > 0);
        require(_duration != 0);
        require(_cliff <= _duration);

        //if startAt is zero, set current time as start time.
        if (_startAt == 0) 
            _startAt = block.timestamp;

        vestingSchedule.startAt = _startAt;
        vestingSchedule.cliff = _cliff;
        vestingSchedule.duration = _duration;
        vestingSchedule.step = _step;

        // special processing for first time vesting setting
        if (vestingSchedule.amount == 0) {
            // check if enough tokens are held by this contract
            ERC20 token = ERC20(crowdSaleTokenAddress);
            require(token.balanceOf(this) >= totalUnreleasedTokens.plus(_amount));
            totalUnreleasedTokens = totalUnreleasedTokens.plus(_amount);
            vestingSchedule.amount = _amount; 
        }

        vestingSchedule.amountReleased = 0;
        vestingSchedule.changeFreezed = _changeFreezed;
    }

    function isVestingSet(address adr) public view returns (bool isSet) {
        return vestingMap[adr].amount != 0;
    }

    function freezeChangesToVesting(address _adr) public changesToVestingNotFreezed(_adr) onlyAllocateAgent {
        require(isVestingSet(_adr)); // first check if vesting is set
        vestingMap[_adr].changeFreezed = true;
    }

    /** Release tokens as per vesting schedule, called by contributor  */
    function releaseMyVestedTokens() public changesToVestingFreezed(msg.sender) {
        releaseVestedTokens(msg.sender);
    }

    /** Release tokens as per vesting schedule, called by anyone  */
    function releaseVestedTokens(address _adr) public changesToVestingFreezed(_adr) {
        VestingSchedule storage vestingSchedule = vestingMap[_adr];
        
        // check if all tokens are not vested
        require(vestingSchedule.amount.minus(vestingSchedule.amountReleased) > 0);
        
        // calculate total vested tokens till now
        uint256 totalTime = block.timestamp - vestingSchedule.startAt;
        uint256 totalSteps = totalTime / vestingSchedule.step;

        // check if cliff is passed
        require(vestingSchedule.cliff <= totalSteps);

        uint256 tokensPerStep = vestingSchedule.amount / vestingSchedule.duration;
        // check if amount is divisble by duration
        if (tokensPerStep * vestingSchedule.duration != vestingSchedule.amount) tokensPerStep++;

        uint256 totalReleasableAmount = tokensPerStep.times(totalSteps);

        // handle the case if user has not claimed even after vesting period is over or amount was not divisible
        if (totalReleasableAmount > vestingSchedule.amount) totalReleasableAmount = vestingSchedule.amount;

        uint256 amountToRelease = totalReleasableAmount.minus(vestingSchedule.amountReleased);
        vestingSchedule.amountReleased = vestingSchedule.amountReleased.plus(amountToRelease);

        // transfer vested tokens
        ERC20 token = ERC20(crowdSaleTokenAddress);
        token.transfer(_adr, amountToRelease);
        // decrement overall unreleased token count
        totalUnreleasedTokens = totalUnreleasedTokens.minus(amountToRelease);
        emit VestedTokensReleased(_adr, amountToRelease);
    }

    /**
    * Allow to (re)set Token.
    */
    function setCrowdsaleTokenExtv1(address _token) public onlyAllocateAgent {       
        crowdSaleTokenAddress = _token;
    }
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
contract CrowdsaleExt is Allocatable, Haltable {

    /* Max investment count when we are still allowed to change the multisig address */
    uint public MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE = 5;

    using SafeMathLibExt for uint;

    /* The token we are selling */
    FractionalERC20Ext public token;

    /* How we are going to price our offering */
    PricingStrategy public pricingStrategy;

    /* Post-success callback */
    FinalizeAgent public finalizeAgent;

    TokenVesting public tokenVesting;

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

      /* Token Vesting Contract */
    address public tokenVestingAddress;

    address[] public joinedCrowdsales;
    uint8 public joinedCrowdsalesLen = 0;
    uint8 public joinedCrowdsalesLenMax = 50;

    struct JoinedCrowdsaleStatus {
        bool isJoined;
        uint8 position;
    }

    mapping (address => JoinedCrowdsaleStatus) public joinedCrowdsaleState;

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

    /** This is for manul testing for the interaction from owner wallet. 
    You can set it to any value and inspect this in blockchain explorer to see that crowdsale interaction works. */
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
    enum State { Unknown, Preparing, PreFunding, Funding, Success, Failure, Finalized }

    // A new investment was made
    event Invested(address investor, uint weiAmount, uint tokenAmount, uint128 customerId);

    // Address early participation whitelist status changed
    event Whitelisted(address addr, bool status, uint minCap, uint maxCap);
    event WhitelistItemChanged(address addr, bool status, uint minCap, uint maxCap);

    // Crowdsale start time has been changed
    event StartsAtChanged(uint newStartsAt);

    // Crowdsale end time has been changed
    event EndsAtChanged(uint newEndsAt);

    constructor(string _name, address _token, PricingStrategy _pricingStrategy, 
    address _multisigWallet, uint _start, uint _end, 
    uint _minimumFundingGoal, bool _isUpdatable, 
    bool _isWhiteListed, address _tokenVestingAddress) public {

        owner = msg.sender;

        name = _name;

        tokenVestingAddress = _tokenVestingAddress;

        token = FractionalERC20Ext(_token);

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

        isUpdatable = _isUpdatable;

        isWhiteListed = _isWhiteListed;
    }

    /**
    * Don&#39;t expect to just send in money and get tokens.
    */
    function() external payable {
        buy();
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
    * Allow anonymous contributions to this crowdsale.
    */
    function invest(address addr) public payable {
        investInternal(addr, 0);
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
    function investInternal(address receiver, uint128 customerId) private stopInEmergency {

        // Determine if it&#39;s a good time to accept investment from this participant
        if (getState() == State.PreFunding) {
            // Are we whitelisted for early deposit
            revert();
        } else if (getState() == State.Funding) {
            // Retail participants can only come in when the crowdsale is running
            // pass
            if (isWhiteListed) {
                if (!earlyParticipantWhitelist[receiver].status) {
                    revert();
                }
            }
        } else {
            // Unwanted state
            revert();
        }

        uint weiAmount = msg.value;

        // Account presale sales separately, so that they do not count against pricing tranches
        uint tokenAmount = pricingStrategy.calculatePrice(weiAmount, tokensSold, token.decimals());

        if (tokenAmount == 0) {
          // Dust transaction
            revert();
        }

        if (isWhiteListed) {
            if (weiAmount < earlyParticipantWhitelist[receiver].minCap && tokenAmountOf[receiver] == 0) {
              // weiAmount < minCap for investor
                revert();
            }

            // Check that we did not bust the investor&#39;s cap
            if (isBreakingInvestorCap(receiver, weiAmount)) {
                revert();
            }

            updateInheritedEarlyParticipantWhitelist(receiver, weiAmount);
        } else {
            if (weiAmount < token.minCap() && tokenAmountOf[receiver] == 0) {
                revert();
            }
        }

        if (investedAmountOf[receiver] == 0) {
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
        if (isBreakingCap(tokensSold)) {
            revert();
        }

        assignTokens(receiver, tokenAmount);

        // Pocket the money
        if (!multisigWallet.send(weiAmount)) revert();

        // Tell us invest was success
        emit Invested(receiver, weiAmount, tokenAmount, customerId);
    }

    /**
    * allocate tokens for the early investors.
    *
    * Preallocated tokens have been sold before the actual crowdsale opens.
    * This function mints the tokens and moves the crowdsale needle.
    *
    * Investor count is not handled; it is assumed this goes for multiple investors
    * and the token distribution happens outside the smart contract flow.
    *
    * No money is exchanged, as the crowdsale team already have received the payment.
    *
    * param weiPrice Price of a single full token in wei
    *
    */
    function allocate(address receiver, uint256 tokenAmount, uint128 customerId, uint256 lockedTokenAmount) public onlyAllocateAgent {

      // cannot lock more than total tokens
        require(lockedTokenAmount <= tokenAmount);
        uint weiPrice = pricingStrategy.oneTokenInWei(tokensSold, token.decimals());
        // This can be also 0, we give out tokens for free
        uint256 weiAmount = (weiPrice * tokenAmount)/10**uint256(token.decimals());         

        weiRaised = weiRaised.plus(weiAmount);
        tokensSold = tokensSold.plus(tokenAmount);

        investedAmountOf[receiver] = investedAmountOf[receiver].plus(weiAmount);
        tokenAmountOf[receiver] = tokenAmountOf[receiver].plus(tokenAmount);

        // assign locked token to Vesting contract
        if (lockedTokenAmount > 0) {
            tokenVesting = TokenVesting(tokenVestingAddress);
            // to prevent minting of tokens which will be useless as vesting amount cannot be updated
            require(!tokenVesting.isVestingSet(receiver));
            assignTokens(tokenVestingAddress, lockedTokenAmount);
            // set vesting with default schedule
            tokenVesting.setVestingWithDefaultSchedule(receiver, lockedTokenAmount); 
        }

        // assign remaining tokens to contributor
        if (tokenAmount - lockedTokenAmount > 0) {
            assignTokens(receiver, tokenAmount - lockedTokenAmount);
        }

        // Tell us invest was success
        emit Invested(receiver, weiAmount, tokenAmount, customerId);
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

    function distributeReservedTokens(uint reservedTokensDistributionBatch) 
    public inState(State.Success) onlyOwner stopInEmergency {
      // Already finalized
        if (finalized) {
            revert();
        }

        // Finalizing is optional. We only call it if we are given a finalizing agent.
        if (address(finalizeAgent) != address(0)) {
            finalizeAgent.distributeReservedTokens(reservedTokensDistributionBatch);
        }
    }

    function areReservedTokensDistributed() public view returns (bool) {
        return finalizeAgent.reservedTokensAreDistributed();
    }

    function canDistributeReservedTokens() public view returns(bool) {
        CrowdsaleExt lastTierCntrct = CrowdsaleExt(getLastTier());
        if ((lastTierCntrct.getState() == State.Success) &&
        !lastTierCntrct.halted() && !lastTierCntrct.finalized() && !lastTierCntrct.areReservedTokensDistributed())
            return true;
        return false;
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
        if (address(finalizeAgent) != address(0)) {
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
        if (!finalizeAgent.isFinalizeAgent()) {
            revert();
        }
    }

    /**
    * Allow addresses to do early participation.
    */
    function setEarlyParticipantWhitelist(address addr, bool status, uint minCap, uint maxCap) public onlyOwner {
        if (!isWhiteListed) revert();
        assert(addr != address(0));
        assert(maxCap > 0);
        assert(minCap <= maxCap);
        assert(now <= endsAt);

        if (!isAddressWhitelisted(addr)) {
            whitelistedParticipants.push(addr);
            emit Whitelisted(addr, status, minCap, maxCap);
        } else {
            emit WhitelistItemChanged(addr, status, minCap, maxCap);
        }

        earlyParticipantWhitelist[addr] = WhiteListData({status:status, minCap:minCap, maxCap:maxCap});
    }

    function setEarlyParticipantWhitelistMultiple(address[] addrs, bool[] statuses, uint[] minCaps, uint[] maxCaps) 
    public onlyOwner {
        if (!isWhiteListed) revert();
        assert(now <= endsAt);
        assert(addrs.length == statuses.length);
        assert(statuses.length == minCaps.length);
        assert(minCaps.length == maxCaps.length);
        for (uint iterator = 0; iterator < addrs.length; iterator++) {
            setEarlyParticipantWhitelist(addrs[iterator], statuses[iterator], minCaps[iterator], maxCaps[iterator]);
        }
    }

    function updateEarlyParticipantWhitelist(address addr, uint weiAmount) public {
        if (!isWhiteListed) revert();
        assert(addr != address(0));
        assert(now <= endsAt);
        assert(isTierJoined(msg.sender));
        if (weiAmount < earlyParticipantWhitelist[addr].minCap && tokenAmountOf[addr] == 0) revert();
        //if (addr != msg.sender && contractAddr != msg.sender) throw;
        uint newMaxCap = earlyParticipantWhitelist[addr].maxCap;
        newMaxCap = newMaxCap.minus(weiAmount);
        earlyParticipantWhitelist[addr] = WhiteListData({status:earlyParticipantWhitelist[addr].status, minCap:0, maxCap:newMaxCap});
    }

    function updateInheritedEarlyParticipantWhitelist(address reciever, uint weiAmount) private {
        if (!isWhiteListed) revert();
        if (weiAmount < earlyParticipantWhitelist[reciever].minCap && tokenAmountOf[reciever] == 0) revert();

        uint8 tierPosition = getTierPosition(this);

        for (uint8 j = tierPosition + 1; j < joinedCrowdsalesLen; j++) {
            CrowdsaleExt crowdsale = CrowdsaleExt(joinedCrowdsales[j]);
            crowdsale.updateEarlyParticipantWhitelist(reciever, weiAmount);
        }
    }

    function isAddressWhitelisted(address addr) public view returns(bool) {
        for (uint i = 0; i < whitelistedParticipants.length; i++) {
            if (whitelistedParticipants[i] == addr) {
                return true;
                break;
            }
        }

        return false;
    }

    function whitelistedParticipantsLength() public view returns (uint) {
        return whitelistedParticipants.length;
    }

    function isTierJoined(address addr) public view returns(bool) {
        return joinedCrowdsaleState[addr].isJoined;
    }

    function getTierPosition(address addr) public view returns(uint8) {
        return joinedCrowdsaleState[addr].position;
    }

    function getLastTier() public view returns(address) {
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

    function setStartsAt(uint time) public onlyOwner {
        assert(!finalized);
        assert(isUpdatable);
        assert(now <= time); // Don&#39;t change past
        assert(time <= endsAt);
        assert(now <= startsAt);

        CrowdsaleExt lastTierCntrct = CrowdsaleExt(getLastTier());
        if (lastTierCntrct.finalized()) revert();

        uint8 tierPosition = getTierPosition(this);

        //start time should be greater then end time of previous tiers
        for (uint8 j = 0; j < tierPosition; j++) {
            CrowdsaleExt crowdsale = CrowdsaleExt(joinedCrowdsales[j]);
            assert(time >= crowdsale.endsAt());
        }

        startsAt = time;
        emit StartsAtChanged(startsAt);
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
        if (lastTierCntrct.finalized()) revert();


        uint8 tierPosition = getTierPosition(this);

        for (uint8 j = tierPosition + 1; j < joinedCrowdsalesLen; j++) {
            CrowdsaleExt crowdsale = CrowdsaleExt(joinedCrowdsales[j]);
            assert(time <= crowdsale.startsAt());
        }

        endsAt = time;
        emit EndsAtChanged(endsAt);
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
        if (!pricingStrategy.isPricingStrategy()) {
            revert();
        }
    }

    /**
    * Allow to (re)set Token.
    * @param _token upgraded token address
    */
    function setCrowdsaleTokenExtv1(address _token) public onlyOwner {
        assert(_token != address(0));
        token = FractionalERC20Ext(_token);
        
        if (address(finalizeAgent) != address(0)) {
            finalizeAgent.setCrowdsaleTokenExtv1(_token);
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
    * @return true if the crowdsale has raised enough money to be a successful.
    */
    function isMinimumGoalReached() public view returns (bool reached) {
        return weiRaised >= minimumFundingGoal;
    }

    /**
    * Check if the contract relationship looks good.
    */
    function isFinalizerSane() public view returns (bool sane) {
        return finalizeAgent.isSane();
    }

    /**
    * Check if the contract relationship looks good.
    */
    function isPricingSane() public view returns (bool sane) {
        return pricingStrategy.isSane();
    }

    /**
    * Crowdfund state machine management.
    *
    * We make it a function and do not assign the result to a variable, 
    * so there is no chance of the variable being stale.
    */
    function getState() public view returns (State) {
        if(finalized) return State.Finalized;
        else if (address(finalizeAgent) == 0) return State.Preparing;
        else if (!finalizeAgent.isSane()) return State.Preparing;
        else if (!pricingStrategy.isSane()) return State.Preparing;
        else if (block.timestamp < startsAt) return State.PreFunding;
        else if (block.timestamp <= endsAt && !isCrowdsaleFull()) return State.Funding;
        else if (isMinimumGoalReached()) return State.Success;
        else return State.Failure;
    }

    /** Interface marker. */
    function isCrowdsale() public pure returns (bool) {
        return true;
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
    * @param tokensSoldTotal What would be our total sold tokens count after this transaction
    *
    * @return true if taking this investment would break our cap rules
    */
    function isBreakingCap(uint tokensSoldTotal) public view returns (bool limitBroken);

    function isBreakingInvestorCap(address receiver, uint tokenAmount) public view returns (bool limitBroken);

    /**
    * Check if the current crowdsale is full and we can no longer sell any tokens.
    */
    function isCrowdsaleFull() public view returns (bool);

    /**
    * Create new tokens or transfer issued tokens to the investor depending on the cap model.
    */
    function assignTokens(address receiver, uint tokenAmount) private;
}

/**
 * Standard ERC20 token with Short Hand Attack and approve() race condition mitigation.
 *
 * Based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20 {

    using SafeMathLibExt for uint;
    /* Token supply got increased and a new owner received these tokens */
    event Minted(address receiver, uint amount);

    /* Actual balances of token holders */
    mapping(address => uint) public balances;

    /* approve() allowances */
    mapping (address => mapping (address => uint)) public allowed;

    /* Interface declaration */
    function isToken() public pure returns (bool weAre) {
        return true;
    }

    function transfer(address _to, uint _value) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].minus(_value);
        balances[_to] = balances[_to].plus(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        uint _allowance = allowed[_from][msg.sender];

        balances[_to] = balances[_to].plus(_value);
        balances[_from] = balances[_from].minus(_value);
        allowed[_from][msg.sender] = _allowance.minus(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint _value) public returns (bool success) {

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) revert();

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }

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
 * A token upgrade mechanism where users can opt-in amount of tokens to the next smart contract revision.
 *
 * First envisioned by Golem and Lunyr projects.
 */
contract UpgradeableToken is StandardToken {

    /** Contract / person who can set the upgrade path. 
        This can be the same as team multisig wallet, as what it is with its default value. */
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
    * Do not allow construction without upgrade master set.
    */
    constructor(address _upgradeMaster) public {
        upgradeMaster = _upgradeMaster;
    }

    /**
    * Allow the token holder to upgrade some of their tokens to a new contract.
    */
    function upgrade(uint256 value) public {

        UpgradeState state = getUpgradeState();
        if (!(state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading)) {
            // Called in a bad state
            revert();
        }

        // Validate input value.
        if (value == 0) revert();

        balances[msg.sender] = balances[msg.sender].minus(value);

        // Take tokens out from circulation
        totalSupply = totalSupply.minus(value);
        totalUpgraded = totalUpgraded.plus(value);

        // Upgrade agent reissues the tokens
        upgradeAgent.upgradeFrom(msg.sender, value);
        emit Upgrade(msg.sender, upgradeAgent, value);
    }

    /**
    * Child contract can enable to provide the condition when the upgrade can begun.
    */
    function canUpgrade() public view returns(bool) {
        return true;
    }

    /**
    * Set an upgrade agent that handles
    */
    function setUpgradeAgent(address agent) external {
        if (!canUpgrade()) {
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
        if (!upgradeAgent.isUpgradeAgent()) revert();      

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
    function setUpgradeMaster(address master) public {
        if (master == 0x0) revert();
        if (msg.sender != upgradeMaster) revert();
        upgradeMaster = master;
    }
}

 /**
  * Define interface for releasing the token transfer after a successful crowdsale.
  */
contract ReleasableToken is ERC20, Ownable {

    /* The finalizer contract that allows unlift the transfer limits on this token */
    address public releaseAgent;

    /** A crowdsale contract can release us to the wild if ICO success. 
        If false we are are in transfer lock up period.*/
    bool public released = false;

    /** Map of agents that are allowed to transfer tokens regardless of the lock down period. 
        These are crowdsale contracts and possible the team multisig itself. */
    mapping (address => bool) public transferAgents;

    /**
    * Limit token transfer until the crowdsale is over.
    *
    */
    modifier canTransfer(address _sender) {

        if (!released) {
            if (!transferAgents[_sender]) {
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
    function setReleaseAgent(address addr) public onlyOwner inReleaseState(false) {
        // We don&#39;t do interface check here as we might want to a normal wallet address to act as a release agent
        releaseAgent = addr;
    }

    /**
    * Owner can allow a particular address (a crowdsale contract) to transfer tokens despite the lock up period.
    */
    function setTransferAgent(address addr, bool state) public onlyOwner inReleaseState(false) {
        transferAgents[addr] = state;
    }

    /**
    * One way function to release the tokens to the wild.
    *
    * Can be called only from the release agent that is the final ICO contract. 
    * It is only called if the crowdsale has been success (first milestone reached).
    */
    function releaseTokenTransfer() public onlyReleaseAgent {
        released = true;
    }

    /** The function can be called only before or after the tokens have been releasesd */
    modifier inReleaseState(bool releaseState) {
        if (releaseState != released) {
            revert();
        }
        _;
    }

    /** The function can be called only by a whitelisted release agent. */
    modifier onlyReleaseAgent() {
        if (msg.sender != releaseAgent) {
            revert();
        }
        _;
    }

    function transfer(address _to, uint _value) public canTransfer(msg.sender) returns (bool success) {
        // Call StandardToken.transfer()
        return super.transfer(_to, _value);
    }

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
contract MintableTokenExt is StandardToken, Ownable {

    using SafeMathLibExt for uint;

    bool public mintingFinished = false;

    /** List of agents that are allowed to create new tokens */
    mapping (address => bool) public mintAgents;

    event MintingAgentChanged(address addr, bool state  );

    /** inPercentageUnit is percents of tokens multiplied to 10 up to percents decimals.
    * For example, for reserved tokens in percents 2.54%
    * inPercentageUnit = 254
    * inPercentageDecimals = 2
    */
    struct ReservedTokensData {
        uint inTokens;
        uint inPercentageUnit;
        uint inPercentageDecimals;
        bool isReserved;
        bool isDistributed;
        bool isVested;
    }

    mapping (address => ReservedTokensData) public reservedTokensList;
    address[] public reservedTokensDestinations;
    uint public reservedTokensDestinationsLen = 0;
    bool private reservedTokensDestinationsAreSet = false;

    modifier onlyMintAgent() {
        // Only crowdsale contracts are allowed to mint new tokens
        if (!mintAgents[msg.sender]) {
            revert();
        }
        _;
    }

    /** Make sure we are not done yet. */
    modifier canMint() {
        if (mintingFinished) revert();
        _;
    }

    function finalizeReservedAddress(address addr) public onlyMintAgent canMint {
        ReservedTokensData storage reservedTokensData = reservedTokensList[addr];
        reservedTokensData.isDistributed = true;
    }

    function isAddressReserved(address addr) public view returns (bool isReserved) {
        return reservedTokensList[addr].isReserved;
    }

    function areTokensDistributedForAddress(address addr) public view returns (bool isDistributed) {
        return reservedTokensList[addr].isDistributed;
    }

    function getReservedTokens(address addr) public view returns (uint inTokens) {
        return reservedTokensList[addr].inTokens;
    }

    function getReservedPercentageUnit(address addr) public view returns (uint inPercentageUnit) {
        return reservedTokensList[addr].inPercentageUnit;
    }

    function getReservedPercentageDecimals(address addr) public view returns (uint inPercentageDecimals) {
        return reservedTokensList[addr].inPercentageDecimals;
    }

    function getReservedIsVested(address addr) public view returns (bool isVested) {
        return reservedTokensList[addr].isVested;
    }

    function setReservedTokensListMultiple(
        address[] addrs, 
        uint[] inTokens, 
        uint[] inPercentageUnit, 
        uint[] inPercentageDecimals,
        bool[] isVested
        ) public canMint onlyOwner {
        assert(!reservedTokensDestinationsAreSet);
        assert(addrs.length == inTokens.length);
        assert(inTokens.length == inPercentageUnit.length);
        assert(inPercentageUnit.length == inPercentageDecimals.length);
        for (uint iterator = 0; iterator < addrs.length; iterator++) {
            if (addrs[iterator] != address(0)) {
                setReservedTokensList(
                    addrs[iterator],
                    inTokens[iterator],
                    inPercentageUnit[iterator],
                    inPercentageDecimals[iterator],
                    isVested[iterator]
                    );
            }
        }
        reservedTokensDestinationsAreSet = true;
    }

    /**
    * Create new tokens and allocate them to an address..
    *
    * Only callably by a crowdsale contract (mint agent).
    */
    function mint(address receiver, uint amount) public onlyMintAgent canMint {
        totalSupply = totalSupply.plus(amount);
        balances[receiver] = balances[receiver].plus(amount);

        // This will make the mint transaction apper in EtherScan.io
        // We can remove this after there is a standardized minting event
        emit Transfer(0, receiver, amount);
    }

    /**
    * Owner can allow a crowdsale contract to mint new tokens.
    */
    function setMintAgent(address addr, bool state) public onlyOwner canMint {
        mintAgents[addr] = state;
        emit MintingAgentChanged(addr, state);
    }

    function setReservedTokensList(address addr, uint inTokens, uint inPercentageUnit, uint inPercentageDecimals,bool isVested) 
    private canMint onlyOwner {
        assert(addr != address(0));
        if (!isAddressReserved(addr)) {
            reservedTokensDestinations.push(addr);
            reservedTokensDestinationsLen++;
        }

        reservedTokensList[addr] = ReservedTokensData({
            inTokens: inTokens,
            inPercentageUnit: inPercentageUnit,
            inPercentageDecimals: inPercentageDecimals,
            isReserved: true,
            isDistributed: false,
            isVested:isVested
        });
    }
}

/**
 * A crowdsaled token.
 *
 * An ERC-20 token designed specifically for crowdsales with investor protection and further development path.
 *
 * - The token transfer() is disabled until the crowdsale is over
 * - The token contract gives an opt-in upgrade path to a new contract
 * - The same token can be part of several crowdsales through approve() mechanism
 * - The token can be capped (supply set in the constructor) or uncapped (crowdsale contract can mint new tokens)
 *
 */
contract CrowdsaleTokenExt is ReleasableToken, MintableTokenExt, UpgradeableToken {

    /** Name and symbol were updated. */
    event UpdatedTokenInformation(string newName, string newSymbol);

    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);

    string public name;

    string public symbol;

    uint public decimals;

    /* Minimum ammount of tokens every buyer can buy. */
    uint public minCap;

    /**
    * Construct the token.
    *
    * This token must be created through a team multisig wallet, so that it is owned by that wallet.
    *
    * @param _name Token name
    * @param _symbol Token symbol - should be all caps
    * @param _initialSupply How many tokens we start with
    * @param _decimals Number of decimal places
    * @param _mintable Are new tokens created over the crowdsale or do we distribute only the initial supply? 
    * Note that when the token becomes transferable the minting always ends.
    */
    constructor(string _name, string _symbol, uint _initialSupply, uint _decimals, bool _mintable, uint _globalMinCap) 
    public UpgradeableToken(msg.sender) {

        // Create any address, can be transferred
        // to team multisig via changeOwner(),
        // also remember to call setUpgradeMaster()
        owner = msg.sender;

        name = _name;
        symbol = _symbol;

        totalSupply = _initialSupply;

        decimals = _decimals;

        minCap = _globalMinCap;

        // Create initially all balance on the team multisig
        balances[owner] = totalSupply;

        if (totalSupply > 0) {
            emit Minted(owner, totalSupply);
        }

        // No more new supply allowed after the token creation
        if (!_mintable) {
            mintingFinished = true;
            if (totalSupply == 0) {
                revert(); // Cannot create a token without supply and no minting
            }
        }
    }

    /**
    * When token is released to be transferable, enforce no new tokens can be created.
    */
    function releaseTokenTransfer() public onlyReleaseAgent {
        mintingFinished = true;
        super.releaseTokenTransfer();
    }

    /**
    * Allow upgrade agent functionality kick in only if the crowdsale was success.
    */
    function canUpgrade() public view returns(bool) {
        return released && super.canUpgrade();
    }

    /**
    * Owner can update token information here.
    *
    * It is often useful to conceal the actual token association, until
    * the token operations, like central issuance or reissuance have been completed.
    *
    * This function allows the token owner to rename the token after the operations
    * have been completed and then point the audience to use the token contract.
    */
    function setTokenInformation(string _name, string _symbol) public onlyOwner {
        name = _name;
        symbol = _symbol;

        emit UpdatedTokenInformation(name, symbol);
    }

    /**
    * Claim tokens that were accidentally sent to this contract.
    *
    * @param _token The address of the token contract that you want to recover.
    */
    function claimTokens(address _token) public onlyOwner {
        require(_token != address(0));

        ERC20 token = ERC20(_token);
        uint balance = token.balanceOf(this);
        token.transfer(owner, balance);

        emit ClaimedTokens(_token, owner, balance);
    }

}

/**
 * The default behavior for the crowdsale end.
 *
 * Unlock tokens.
 */
contract ReservedTokensFinalizeAgent is FinalizeAgent {
    using SafeMathLibExt for uint;
    CrowdsaleTokenExt public token;
    CrowdsaleExt public crowdsale;

    uint public distributedReservedTokensDestinationsLen = 0;

    constructor(CrowdsaleTokenExt _token, CrowdsaleExt _crowdsale) public {
        token = _token;
        crowdsale = _crowdsale;
    }

    /** Check that we can release the token */
    function isSane() public view returns (bool) {
        return (token.releaseAgent() == address(this));
    }
    
    /**
    * Allow to (re)set Token.
    */
    function setCrowdsaleTokenExtv1(address _token) public {
        assert(msg.sender == address(crowdsale));
        token = CrowdsaleTokenExt(_token);
    }

    //distributes reserved tokens. Should be called before finalization
    function distributeReservedTokens(uint reservedTokensDistributionBatch) public {
        assert(msg.sender == address(crowdsale));

        assert(reservedTokensDistributionBatch > 0);
        assert(!reservedTokensAreDistributed);
        assert(distributedReservedTokensDestinationsLen < token.reservedTokensDestinationsLen());

        // How many % of tokens the founders and others get
        uint tokensSold = 0;
        for (uint8 i = 0; i < crowdsale.joinedCrowdsalesLen(); i++) {
            CrowdsaleExt tier = CrowdsaleExt(crowdsale.joinedCrowdsales(i));
            tokensSold = tokensSold.plus(tier.tokensSold());
        }

        uint startLooping = distributedReservedTokensDestinationsLen;
        uint batch = token.reservedTokensDestinationsLen().minus(distributedReservedTokensDestinationsLen);
        if (batch >= reservedTokensDistributionBatch) {
            batch = reservedTokensDistributionBatch;
        }
        uint endLooping = startLooping + batch;

        // move reserved tokens
        for (uint j = startLooping; j < endLooping; j++) {
            address reservedAddr = token.reservedTokensDestinations(j);
            if (!token.areTokensDistributedForAddress(reservedAddr)) {
                uint allocatedBonusInPercentage;
                uint allocatedBonusInTokens = token.getReservedTokens(reservedAddr);
                uint percentsOfTokensUnit = token.getReservedPercentageUnit(reservedAddr);
                uint percentsOfTokensDecimals = token.getReservedPercentageDecimals(reservedAddr);
                bool isVested = token.getReservedIsVested(reservedAddr);

                if (percentsOfTokensUnit > 0) {
                    allocatedBonusInPercentage = tokensSold * percentsOfTokensUnit / 10**percentsOfTokensDecimals / 100;
                    if(isVested) {                    
                        crowdsale.allocate(reservedAddr, allocatedBonusInPercentage, 0, allocatedBonusInPercentage);
                    }
                    else {
                        token.mint(reservedAddr, allocatedBonusInPercentage);
                    }
                }

                if (allocatedBonusInTokens > 0) {
                    if(isVested) {                     
                        crowdsale.allocate(reservedAddr, allocatedBonusInTokens, 0, allocatedBonusInTokens);
                    }
                    else {
                        token.mint(reservedAddr, allocatedBonusInTokens);
                    }
                }

                token.finalizeReservedAddress(reservedAddr);
                distributedReservedTokensDestinationsLen++;
            }
        }

        if (distributedReservedTokensDestinationsLen == token.reservedTokensDestinationsLen()) {
            reservedTokensAreDistributed = true;
        }
    }

    /** Called once by crowdsale finalize() if the sale was success. */
    function finalizeCrowdsale() public {
        assert(msg.sender == address(crowdsale));

        if (token.reservedTokensDestinationsLen() > 0) {
            assert(reservedTokensAreDistributed);
        }

        token.releaseTokenTransfer();
    }

}