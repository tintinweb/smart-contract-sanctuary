// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./SafeMath.sol";

import "./ICollectCoinIco.sol";
import "./TimeLockedWalletFactory.sol";
import "./CollectCoin.sol";
import "./Haltable.sol";
import "./IPricingStrategy.sol";

contract CollectCoinIco is Haltable, ICollectCoinIco  {

    using SafeMath for uint256;

    /* The token we are selling */
    CollectCoin public token;

    // How we are going to price our offering
    IPricingStrategy public pricingStrategy;

    TimeLockedWalletFactory walletFactory;

    // tokens will be transfered from this address
    address payable public multisigWallet;

    /* Maximum amount of tokens this crowdsale can sell. */
    uint public maximumSellableTokens;

    /* if the funding goal is not reached, investors may withdraw their funds */
    uint public minimumFundingGoal;

    /* the maximum one person is allowed to invest in CLCT */
    uint256 public tokenInvestorCap;

    /* How many distinct addresses have invested */
    uint public investorCount = 0;

    /* the UNIX timestamp start date of the ico */
    uint public startsAt;

    /* the UNIX timestamp end date of the ico */
    uint public endsAt;

    uint256 walletUnlockPeriod; 
    uint256 walletUnlockPercentage;

    /* Has this crowdsale been finalized */
    bool public finalized;

    /* the number of tokens already sold through this contract*/
    uint public tokensSold = 0;

    /* How many wei of funding we have raised */
    uint public weiRaised = 0;

    /* How much wei we have returned back to the contract after a failed crowdfund. */
    uint public loadedRefund = 0;

    address public timeLockedWallet;

    address public tokenOwner;

    // A new investment was made
    event Invested(address investor, uint weiAmount, uint tokenAmount, uint128 customerId);

    // A refund has been processed
    event Withdrawn(address indexed refundee, uint256 weiAmount);

    /* List of all investors */
    mapping (address => address payable) public investors;

    /** How much ETH each address has invested to this crowdsale */
    mapping (address => uint256) public investedAmountOf;

    /** How much tokens this crowdsale has credited for each investor address */
    mapping (address => uint256) public override tokenAmountOf;

    /** Modified allowing execution only if the crowdsale is currently running.  */
    modifier inState(State state) {
        if(getState() != state) revert();
        _;
    }

    /**@dev Create a new ICO contract instance
     * @param _token The ERC-20 token contract address
     * @param _pricingStrategy The Pricing strategy contract address which determines the price for a specific amount of wei or tokens
     * @param _multisigWallet The address of the account that receives the wei of the investors
     * @param _start The time this contracts accepts funding
     * @param _end The time the token sale ends. This is also when success or failure is determined.
     * @param _minimumFundingGoal The min amount of tokens required to be sold for the sale to succeed, aka soft cap
     * @param _maxSellableTokens The max amount of tokens to be sold in this sale 
     * @param _walletUnlockPeriod The length of a lock period in seconds 
     * @param _walletUnlockPercentage The percentage being unlocked with each period, number between 1 and 100
     */
    constructor(address _token, 
                IPricingStrategy _pricingStrategy,
                address payable _multisigWallet, 
                uint _start, uint _end, 
                uint _minimumFundingGoal, uint _maxSellableTokens, uint256 _tokenInvestorCap,
                uint256 _walletUnlockPeriod, uint256 _walletUnlockPercentage) 
    {
        token = CollectCoin(_token);
        pricingStrategy = _pricingStrategy;

        tokenInvestorCap = _tokenInvestorCap;
        
        multisigWallet = _multisigWallet;
        if(multisigWallet == address(0)) {
            revert();
        }

        if(_start == 0) {
            revert();
        }

        startsAt = _start;

        if(_end == 0) {
            revert();
        }

        endsAt = _end;

        // Don't mess the dates
        if(startsAt >= endsAt) {
            revert();
        }

        walletUnlockPeriod = _walletUnlockPeriod;
        walletUnlockPercentage = _walletUnlockPercentage;

        require(_maxSellableTokens >= _minimumFundingGoal, "Maximum sellable tokens is lower than minimum funding goal.");

        // Minimum funding goal can be zero
        minimumFundingGoal = _minimumFundingGoal;
        maximumSellableTokens = _maxSellableTokens;
    }

    /**
    * @dev Make an investment.
    *
    * Crowdsale must be running for one to invest.
    * We must have not pressed the emergency brake.
    *
    * @param receiver The Ethereum address who receives the tokens
    * @param customerId (optional) UUID v4 to track the successful payments on the server side'
    * @param tokenAmount Amount of tokens which be credited to receiver
    *
    * @return tokensBought How mony tokens were bought
    */
    function buyTokens(address payable receiver, uint128 customerId, uint256 tokenAmount) stopInEmergency inState(State.Funding) internal returns(uint tokensBought) 
    {
        require(getState() == State.Funding || getState() == State.Success, "Contract not in Funding or Success state.");

        uint weiAmount = msg.value;

        // Dust transaction
        require(tokenAmount != 0);

        // don't allow investment to exceed the investor cap
        require(tokenAmountOf[receiver] + tokenAmount <= tokenInvestorCap);

        if(investedAmountOf[receiver] == 0) {
            // A new investor
            investorCount++;
            investors[receiver] = receiver;
        }

        // Update investor
        investedAmountOf[receiver] = investedAmountOf[receiver].add(weiAmount);
        tokenAmountOf[receiver] = tokenAmountOf[receiver].add(tokenAmount);

        // Update totals
        weiRaised = weiRaised.add(weiAmount);
        tokensSold = tokensSold.add(tokenAmount);

        // Check that we did not bust the cap
        require(tokensSold <= maximumSellableTokens, "Requested token amount exceeds remaining capacity");

        // Tell us invest was success
        emit Invested(receiver, weiAmount, tokenAmount, customerId);

        return tokenAmount;
    }

    function setStartsAt(uint256 _startsAt) external onlyOwner {
        startsAt = _startsAt;
    }

    function setEndsAt(uint256 _endsAt) external onlyOwner {
        endsAt = _endsAt;
    }

    function availableInvestment() external view returns(uint256)
    {
        return tokenInvestorCap - tokenAmountOf[msg.sender];
    }

    /**
    * Finalize a succcesful crowdsale.
    *
    * The owner can triggre a call the contract that provides post-crowdsale actions, like releasing the tokens.
    * @param _walletLockDate The time from when the locking calculations for the investor's time locked tokens begin to count
    */
    function finalize(uint256 _walletLockDate) external override inState(State.Success) onlyOwner stopInEmergency {

        require(!finalized, "already finalized");
        require(isMinimumGoalReached(), "goal not reached");
        
        uint256 walletLockDate = _walletLockDate > 0 ? _walletLockDate : block.timestamp;
        require(walletLockDate >= block.timestamp, "LockDate cannot be in the past");

        finalized = true;

        timeLockedWallet = walletFactory.newPeriodicTimeLockedMonoWallet(tokenOwner, address(this), walletLockDate, walletUnlockPeriod, walletUnlockPercentage);

        // Pocket the money, or fail the transaction if we for some reason cannot send the money to our multisig
        if(!multisigWallet.send(weiRaised)) revert();
    }

    function setWalletFactory(TimeLockedWalletFactory addr) external override onlyOwner {
        walletFactory = addr;
    }

    function setTokenOwner(address _tokenOwner) external override onlyOwner {

        uint balance = token.balanceOf(_tokenOwner);

        require(balance >= maximumSellableTokens, "Token owner has not enough tokens!");
        
        tokenOwner = _tokenOwner;
    }
    
    /**
    * state machine management.
    *
    * We make it a function and do not assign the result to a variable, so there is no chance of the variable being stale.
    */
    function getState() public override virtual view returns (State) {
        if(finalized) return State.Finalized;
        else if (address(walletFactory) == address(0)) return State.Preparing;
        else if (tokenOwner == address(0)) return State.Preparing;
        else if (!pricingStrategy.isSane()) return State.Preparing;
        else if (block.timestamp < startsAt) return State.Preparing;
        else if (block.timestamp <= endsAt && !isFull()) return State.Funding;
        else if (isMinimumGoalReached()) return State.Success;
        else if (!isMinimumGoalReached() && weiRaised > 0 && loadedRefund < weiRaised) return State.Refunding;
        else return State.Failure;
    }

     /**
    * Check if the current crowdsale is full and we can no longer sell any tokens.
    */
    function isFull() public override view returns (bool) {
        return tokensSold >= maximumSellableTokens;
    }

    /**
    * @return reached == true if the crowdsale has raised enough money to be a successful.
    */
    function isMinimumGoalReached() public override view returns (bool reached) {
        return tokensSold >= minimumFundingGoal;
    }


    // -----------------------------------------
    // Crowdsale external interface
    // -----------------------------------------

    fallback () external payable {
        revert();
    }

    /**
    * @dev low level token purchase ***DO NOT OVERRIDE***
    * @param _beneficiary Address performing the token purchase
    */
    function buyTokens(address payable _beneficiary) public override virtual payable {

        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);

        buyTokens(_beneficiary, 0, tokens);
    }

    receive () external payable {
        buyTokens(payable(msg.sender));
    }

    /**
     * @dev Investors can claim refunds here if crowdsale is unsuccessful.
     * @param refundee Whose refund will be claimed.
     */
    function claimRefund(address payable refundee) inState(State.Refunding) external {
        
        address payable refundAddress = investors[refundee];
        require(refundAddress != address(0), "Not an Investor");

        uint256 payment = investedAmountOf[refundAddress];
        require(payment > 0, "No refund available");

        investedAmountOf[refundAddress] = 0;
        tokenAmountOf[refundAddress] = 0;

        loadedRefund += payment;
        
        emit Withdrawn(refundAddress, payment);

        refundAddress.transfer(payment);
    }


    // -----------------------------------------
    // Internal interface (extensible)
    // -----------------------------------------

    /**
    * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
    * @param _beneficiary Address performing the token purchase
    * @param _weiAmount Value in wei involved in the purchase
    */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal pure {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
    }

    /**
    * @dev Override to extend the way in which ether is converted to tokens.
    * @param _weiAmount Value in wei to be converted into tokens
    * @return Number of tokens that can be purchased with the specified _weiAmount
    */
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        uint256 tokenAmount = pricingStrategy.calculateTokenAmount(_weiAmount, tokensSold, token.decimals());
        return tokenAmount;
    }
}