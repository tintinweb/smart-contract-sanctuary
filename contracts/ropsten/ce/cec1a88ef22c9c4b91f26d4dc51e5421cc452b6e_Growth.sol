pragma solidity ^0.4.25;


contract Prosperity {
	
	/**
     * Transfer tokens from the caller to a new holder.
     * Remember, there&#39;s 0% fee here.
     */
    function transfer(address _toAddress, uint256 _amountOfTokens) public returns(bool);
	
	/**
     * Retrieve the tokens owned by the caller.
     */
	function myTokens() public view returns(uint256);
	
	/**
     * Retrieve the dividends owned by the caller.
     * If `_includeReferralBonus` is 1/true, the referral bonus will be included in the calculations.
     * The reason for this, is that in the frontend, we will want to get the total divs (global + ref)
     * But in the internal calculations, we want them separate. 
     */ 
    function myDividends(bool _includeReferralBonus) public view returns(uint256);
	
	/**
     * Converts all incoming ethereum to tokens for the caller, and passes down the referral
     */
    function buy(address _referredBy) public payable returns(uint256);
	
	/**
     * Withdraws all of the callers earnings.
     */
    function withdraw() public;
	
	/**
     * Converts all of caller&#39;s dividends to tokens.
     */
	function reinvest() public;
	
	/**
     * Fallback function to handle ethereum that was send straight to the contract
     * Unfortunately we cannot use a referral address this way.
     */
	function() payable external;
}


/**
 * Definition of contract accepting THC tokens
 * Games, casinos, anything can reuse this contract to support AcceptsProsperity tokens
 * ...
 * M3Divval
 * ...
 */
contract Growth {
	using SafeMath for *;
	
	/*==============================
    =            EVENTS            =
    ==============================*/    
    // ERC20
    event Transfer (
        address indexed from,
        address indexed to,
        uint256 tokens
    );
	
	event onReinvest (
		
	);
	
	
	/*=================================
    =            MODIFIERS            =
    =================================*/	
	modifier onlyTokenContract {
        require(msg.sender == address(tokenContract_));
        _;
    }
	
	// only people with deposit
    modifier onlyBagholders() {
        require(myDeposit() > 0);
        _;
    }
    
    // only people with profits
    modifier onlyStronghands() {
        require(myProfit(msg.sender) > 0);
        _;
    }
	
	// administrators can:
    // -> change the name of the contract
    // -> change the name of the token
    // -> change the PoS difficulty (How many tokens it costs to hold a masternode, in case it gets crazy high later)
    // they CANNOT:
    // -> take funds, except the funding contract
    // -> disable withdrawals
    // -> kill the contract
    // -> change the price of tokens
    modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(administrator_ == _customerAddress);
        _;
    }
	
	
	/*================================
    =            DATASETS            =
    ================================*/
    // amount of shares for each address (scaled number)
    mapping(address => Dealer) internal dealers_; 	// address => Dealer
    uint256 internal totalDeposit_ = 0;
	
	// token exchange contract
	Prosperity public tokenContract_;
	
	// administrator (see above on what they can do)
    address internal administrator_;
	
	// Player data
	struct Dealer {
		uint256 deposit;		// active deposit
		uint256 profit;			// old outstanding profits
		uint256 time;			// last time profits have been moved
	}
    
	
	/*=======================================
    =            PUBLIC FUNCTIONS            =
    =======================================*/
    constructor() public {
		administrator_ = 0xA1bAeAaC24AeC31FBF0F8895bf8177cDB7Ccc759;
    }
	
	function() payable external {
		// prevent invalid or unintentional calls
		//require(msg.data.length == 0);
	}
	
	/**
    * @dev Standard ERC677 function that will handle incoming token transfers.
    *
    * @param _from  Token sender address.
    * @param _value Amount of tokens.
    * @param _data  Transaction metadata.
    */
    function tokenFallback(address _from, uint256 _value, bytes _data)
		onlyTokenContract()
		external
		returns (bool)
	{
        // data setup
		Dealer storage _dealer = dealers_[_from];
		
		// profit and deposit tracking
		_dealer.profit = myProfit(_from);	/* saves the new generated profit; old profit will be taken into account within the calculation
											   last time deposit timer is 0 for the first deposit */
		_dealer.time = now;					// so we set the timer AFTER calculating profits
        
		// allocate tokens
		_dealer.deposit = _dealer.deposit.add(_value);
		totalDeposit_ = totalDeposit_.add(_value);
		
		return true;
		
		// silence compiler warning
		_data;
	}
	
	/**
	 * Reinvest generated profit
	 */
	function reinvestProfit()
		onlyStronghands()
		public 
	{
		address _customerAddress = msg.sender;
		Dealer storage _dealer = dealers_[_customerAddress];
		
		uint256 _profits = myProfit(_customerAddress);
		
		// update Dealer
		_dealer.deposit = _dealer.deposit.add(_profits);	// add new tokens to active deposit
		_dealer.profit = 0;									// old tokens have been reinvested
		_dealer.time = now;									// generate tokens from now
		
		// update total deposit value
		totalDeposit_ = totalDeposit_.add(_profits);
	}
	
	/**
	 * Withdraw profit to token exchange
	 */
	function withdrawProfit()
		onlyStronghands()
		public
	{
		address _customerAddress = msg.sender;
		Dealer storage _dealer = dealers_[_customerAddress];
		
		uint256 _profits = myProfit(_customerAddress);
		
		// update profits
		_dealer.profit = 0;		// old tokens have been reinvested
		_dealer.time = now;		// generate tokens from now
		
		// transfer tokens from exchange to sender
		tokenContract_.transfer(_customerAddress, _profits);
	}
	
	/**
	 * Withdraw deposit to token exchange. 25% fee will be incured
	 */
	function withdrawCapital()
		onlyBagholders()
		public
	{
		address _customerAddress = msg.sender;
		Dealer storage _dealer = dealers_[_customerAddress];
		
		uint256 _deposit = _dealer.deposit;
		uint256 _taxedDeposit = _deposit.mul(75).div(100);
		uint256 _profits = myProfit(_customerAddress);
		
		// update deposit
		_dealer.deposit = 0;
		_dealer.profit = _profits;
		
		// reduce tokens in lending deposit ledger
		// use the untaxed value, bcs Dealers deposit will drop to 0,
		// but token transfer (below) will be taxed
		totalDeposit_ = totalDeposit_.sub(_deposit);
		
		// transfer tokens from exchange to sender
		tokenContract_.transfer(_customerAddress, _taxedDeposit);
	}
	
	/**
	 * Lending will reinvest its ETH
	 */
	function reinvestEther()
		public
	{
		uint256 _balance = address(this).balance;
		if (_balance > 0) {
			// triggers exchanges payable fallback buy function
			if(!address(tokenContract_).call.value(_balance)()) {
				// Some failure code
				revert();
			}
		}
	}
	
	/**
	 * Lending will reinvest its dividends
	 */
	function reinvestDividends()
		public
	{
		uint256 _dividends = myDividends(true);
		if (_dividends > 0) {
			tokenContract_.reinvest();
		}
	}
	
	
	/*----------  HELPERS AND CALCULATORS  ----------*/	
    /**
     * Retrieve the total token supply.
     */
    function totalDeposit()
        public
        view
        returns(uint256)
    {
        return totalDeposit_;
    }
	
	/**
     * Retrieve the total token supply.
     */
    function totalSupply()
        public
        view
        returns(uint256)
    {
        return tokenContract_.myTokens();
    }
	
	function surplus()
		public
		view
		returns(int256)
	{
		uint256 _tokens = totalSupply();
		
		// we cannot divide by 0
		if (totalDeposit_ > 0) {
			// returns a value that indicates the surplus of the lending contract
			// based on 1000 => 1000 = 100%; 303 = 30.3%; -200 = -20%
			return int256((1000).mul(_tokens).div(totalDeposit_) - 1000);
		} else {
			return 1000;	// 100%
		}
	}
	
	/**
     * Retrieve the tokens owned by the caller.
     */
    function myDeposit()
        public
        view
        returns(uint256)
    {
		address _customerAddress = msg.sender;
        Dealer storage _dealer = dealers_[_customerAddress];
        return _dealer.deposit;
    }
	
	/**
     * Retrieve the profit of the caller. Profits are virtual
     */
	function myProfit(address _customerAddress)
		public
		view
		returns(uint256)
	{
		Dealer storage _dealer = dealers_[_customerAddress];
		uint256 _oldProfits = _dealer.profit;
		uint256 _newProfits = 0;
		
		if (
			// if time is 0, the dealer has not deposited tokens yet
			_dealer.time == 0 ||
			
			// dealer has currently no tokens deposited
			_dealer.deposit == 0
		)
		{
			_newProfits = 0;
		} else {
			// get the last deposit time stamp
			uint256 _timeLending = now - _dealer.time;
			
			_newProfits = _timeLending	// time difference since profits are being generated
				.mul(_dealer.deposit)	// current deposit
				.mul(1337)				// 1.337% (daily)
				.div(100000)			// to base 100%
				.div(86400);			// 1 day in seconds
		}
		
		// Dealer may have tokens in profit wallet left, so always add the old value
		return _newProfits.add(_oldProfits);
	}
	
	function myDividends(bool _includeReferralBonus)
		public
		view
		returns(uint256)
	{
		return tokenContract_.myDividends(_includeReferralBonus);
	}
	
	/**
	 * Set the token contract
	 */
	function setTokenContract(address _tokenContract)
		onlyAdministrator()
		public
	{
		tokenContract_ = Prosperity(_tokenContract);
	}
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

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
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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