pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
	function totalSupply() public view returns (uint256);
	function balanceOf(address who) public view returns (uint256);
	function transfer(address to, uint256 value) public returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

	/**
  	* @dev Multiplies two numbers, throws on overflow.
  	*/
  	function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
		// Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
		// benefit is lost if &#39;b&#39; is also tested.
		// See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
		if (a == 0) {
	  	return 0;
		}

	c = a * b;
	assert(c / a == b);
	return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
	// assert(b > 0); // Solidity automatically throws when dividing by 0
	// uint256 c = a / b;
	// assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
	return a / b;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
	c = a + b;
	assert(c >= a);
	return c;
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
	return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
	require(_to != address(0));
	require(_value <= balances[msg.sender]);

	balances[msg.sender] = balances[msg.sender].sub(_value);
	balances[_to] = balances[_to].add(_value);
	emit Transfer(msg.sender, _to, _value);
	return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
	return balances[_owner];
  }

}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
	public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
	public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
	address indexed owner,
	address indexed spender,
	uint256 value
  );
}

// File: openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
	address _from,
	address _to,
	uint256 _value
  )
	public
	returns (bool)
  {
	require(_to != address(0));
	require(_value <= balances[_from]);
	require(_value <= allowed[_from][msg.sender]);

	balances[_from] = balances[_from].sub(_value);
	balances[_to] = balances[_to].add(_value);
	allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
	emit Transfer(_from, _to, _value);
	return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
	allowed[msg.sender][_spender] = _value;
	emit Approval(msg.sender, _spender, _value);
	return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
	address _owner,
	address _spender
   )
	public
	view
	returns (uint256)
  {
	return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
	address _spender,
	uint256 _addedValue
  )
	public
	returns (bool)
  {
	allowed[msg.sender][_spender] = (
	  allowed[msg.sender][_spender].add(_addedValue));
	emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
	return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
	address _spender,
	uint256 _subtractedValue
  )
	public
	returns (bool)
  {
	uint256 oldValue = allowed[msg.sender][_spender];
	if (_subtractedValue > oldValue) {
	  allowed[msg.sender][_spender] = 0;
	} else {
	  allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
	}
	emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
	return true;
  }

}

// File: contracts/PowhToken.sol

/**
 * ________                                    _____          __                 
 * \______ \    _________    _____   ____     /     \ _____  |  | __ ___________ 
 * |    |  \  / ___\__  \  /     \_/ __ \   /  \ /  \\__  \ |  |/ // __ \_  __ \
 * |    `   \/ /_/  > __ \|  Y Y  \  ___/  /    Y    \/ __ \|    <\  ___/|  | \/
 * /_______  /\___  (____  /__|_|  /\___  > \____|__  (____  /__|_ \\___  >__|   
 *         \//_____/     \/      \/     \/          \/     \/     \/    \/       
 * Powered by Andoromeda 
 */

/**
 * @title Dgame Maker Token
 * @dev Dgame Maker Token which can be trade in the contract.
 * we support buy() and sell() function in a simpilified 50% CW bancor algorithm.
 */
contract PowhToken is StandardToken {
	/*=================================
	=            MODIFIERS            =
	=================================*/
	// only people with tokens
	modifier onlyBagholders() {
		require(myTokens() > 0);
		_;
	}
	
	// only people with profits
	modifier onlyStronghands() {
		require(myDividends(true) > 0);
		_;
	}
	
	// administrators can:
	// -> change the name of the contract
	// -> change the name of the token
	// -> change the PoS difficulty (How many tokens it costs to hold a masternode, in case it gets crazy high later)
	// they CANNOT:
	// -> take funds
	// -> disable withdrawals
	// -> kill the contract
	// -> change the price of tokens
	modifier onlyAdministrator() {
		address _customerAddress = msg.sender;
		require(administrators[keccak256(abi.encodePacked(_customerAddress))]);
		_;
	}
		
	
	/*==============================
	=            EVENTS            =
	==============================*/
	event OnTokenPurchase(
		address indexed customerAddress,
		uint256 incomingEthereum,
		uint256 tokensMinted,
		address indexed referredBy
	);
	
	event OnReinvestment(
		address indexed customerAddress,
		uint256 ethereumReinvested,
		uint256 tokensMinted
	);
	
	event OnTokenSell(
		address indexed customerAddress,
		uint256 tokensBurned,
		uint256 ethereumEarned
	);
	
	event OnWithdraw(
		address indexed customerAddress,
		uint256 ethereumWithdrawn
	);
	
	// ERC20
	event Transfer(
		address indexed from,
		address indexed to,
		uint256 tokens
	);
	
	
	/*=====================================
	=            CONFIGURABLES            =
	=====================================*/
	string public name = "Dgame Maker";
	string public symbol = "DGM";
	uint8 constant public decimals = 18;
	uint8 constant internal dividendFee_ = 20;
	uint8 constant internal communityFee_ = 50;
	uint256 constant internal tokenPriceInitial_ = 0.0000001 ether;
	uint256 constant internal tokenPriceIncremental_ = 0.00000001 ether;
	uint256 constant internal magnitude = 2**64;
	
	// Referrer Bonus
	uint256 public minReferrerBonus = 1; // 1%
	uint256 public maxReferrerBonus = 10; // 10%
	uint256 public maxReferrerBonusRequirement = 100e18; // 100 DGM
		
   /*================================
	=            DATASETS            =
	================================*/
	// amount of shares for each address (scaled number)
	mapping(address => uint256) internal balances;
	mapping(address => uint256) internal referralBalance_;
	mapping(address => int256) internal payoutsTo_;
	mapping(address => uint256) internal ambassadorAccumulatedQuota_;
	uint256 internal tokenSupply_ = 0;
	uint256 internal profitPerShare_;
	uint256 internal communityFeeTo_ = 0; // admins can withdraw amount;

	
	// administrator list (see above on what they can do)
	mapping(bytes32 => bool) public administrators;
	
	// when this is set to true, only ambassadors can purchase tokens (this prevents a whale premine, it ensures a fairly distributed upper pyramid)
	bool public onlyAmbassadors = true;
	
	/*=======================================
	=            PUBLIC FUNCTIONS            =
	=======================================*/
	/*
	* -- APPLICATION ENTRY POINTS --  
	*/
	constructor()
		public
	{
		// add administrators here
		administrators[keccak256(abi.encodePacked(msg.sender))] = true;        
	}


	/**
	* @dev Make profit from an external project
	*/
	function makeProfit() external payable {
		makeProfit(msg.value);
	}    

	/**
	* @dev Make profit inside this contact
	*/
	function makeProfit(uint256 _profit) internal {
		// take the amount of dividends gained through this transaction, and allocates them evenly to each shareholder
		profitPerShare_ = SafeMath.add(profitPerShare_, (_profit * magnitude) / tokenSupply_);            
	}

	/**
	 * Converts all incoming ethereum to tokens for the caller, and passes down the referral addy (if any)
	 */
	function buy(address _referredBy)
		public
		payable
		returns(uint256)
	{
		purchaseTokens(msg.value, _referredBy);
	}
	
	/**
	 * Fallback function to handle ethereum that was send straight to the contract
	 * Unfortunately we cannot use a referral address this way.
	 */
	function()
		payable
		public
	{
		purchaseTokens(msg.value, 0x0);
	}
	
	/**
	 * Converts all of caller&#39;s dividends to tokens.
	 */
	function reinvest()
		onlyStronghands()
		public
	{
		// fetch dividends
		uint256 _dividends = myDividends(false); // retrieve ref. bonus later in the code
		
		// pay out the dividends virtually
		address _customerAddress = msg.sender;
		payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);
		
		// retrieve ref. bonus
		_dividends += referralBalance_[_customerAddress];
		referralBalance_[_customerAddress] = 0;
		
		// dispatch a buy order with the virtualized "withdrawn dividends"
		uint256 _tokens = purchaseTokens(_dividends, 0x0);
		
		// fire event
		emit OnReinvestment(_customerAddress, _dividends, _tokens);
	}

	/**
	 * Alias of sell() and withdraw().
	 */
	function exit()
		public
	{
		// get token count for caller & sell them all
		address _customerAddress = msg.sender;
		uint256 _tokens = balances[_customerAddress];
		if(_tokens > 0) sell(_tokens);
		
		// lambo delivery service
		withdraw();
	}

	/**
	 * Withdraws all of the callers earnings.
	 */
	function withdraw()
		onlyStronghands()
		public
	{
		// setup data
		address _customerAddress = msg.sender;
		uint256 _dividends = myDividends(false); // get ref. bonus later in the code
		
		// update dividend tracker
		payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);
		
		// add ref. bonus
		_dividends += referralBalance_[_customerAddress];
		referralBalance_[_customerAddress] = 0;
		
		// lambo delivery service
		_customerAddress.transfer(_dividends);
		
		// fire event
		emit OnWithdraw(_customerAddress, _dividends);
	}

	/**
	 * @dev withdraw communityFee_
	 */
	function withdrawCommunity(uint256 _amount)
		public
		onlyAdministrator
	{
		require(_amount <= communityFeeTo_);

		msg.sender.transfer(_amount);
	}
	
	/**
	 * Liquifies tokens to ethereum.
	 */
	function sell(uint256 _amountOfTokens)
		onlyBagholders()
		public
	{
		// setup data
		address _customerAddress = msg.sender;
		// russian hackers BTFO
		require(_amountOfTokens <= balances[_customerAddress]);
		uint256 _tokens = _amountOfTokens;
		uint256 _ethereum = tokensToEthereum_(_tokens);
		uint256 _dividends = SafeMath.div(_ethereum, communityFee_);
		uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
		
		// burn the sold tokens
		tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
		balances[_customerAddress] = SafeMath.sub(balances[_customerAddress], _tokens);
		
		communityFeeTo_ = SafeMath.add(communityFeeTo_, _dividends);
		
		// update dividends tracker
		int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedEthereum * magnitude));
		payoutsTo_[_customerAddress] -= _updatedPayouts;   
		
		// dividing by zero is a bad idea
		// 卖出抽水并没有加入分红池，上线前删除这句注释。。。
		/*
		if (tokenSupply_ > 0) {
			// update the amount of dividends per token
			makeProfit(_dividends);
		}
		*/
		
		// fire event
		emit OnTokenSell(_customerAddress, _tokens, _taxedEthereum);
	}
	
	
	
	/**
	 * Transfer tokens from the caller to a new holder.
	 * Remember, there&#39;s a 10% fee here as well.
	 */
	function transfer(address _toAddress, uint256 _amountOfTokens)
		onlyBagholders()
		public
		returns(bool)
	{
		// setup
		address _customerAddress = msg.sender;
		
		// make sure we have the requested tokens
		// also disables transfers until ambassador phase is over
		// ( we dont want whale premines )
		require(!onlyAmbassadors && _amountOfTokens <= balances[_customerAddress]);
		
		// withdraw all outstanding dividends first
		if(myDividends(true) > 0) withdraw();
		
		// liquify 10% of the tokens that are transfered
		// these are dispersed to shareholders
		uint256 _tokenFee = SafeMath.div(_amountOfTokens, dividendFee_);
		uint256 _taxedTokens = SafeMath.sub(_amountOfTokens, _tokenFee);
		uint256 _dividends = tokensToEthereum_(_tokenFee);
  
		// burn the fee tokens
		tokenSupply_ = SafeMath.sub(tokenSupply_, _tokenFee);

		// exchange tokens
		balances[_customerAddress] = SafeMath.sub(balances[_customerAddress], _amountOfTokens);
		balances[_toAddress] = SafeMath.add(balances[_toAddress], _taxedTokens);
		
		// update dividend trackers
		payoutsTo_[_customerAddress] -= (int256) (profitPerShare_ * _amountOfTokens);
		payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _taxedTokens);
		
		// disperse dividends among holders
		makeProfit(_dividends);
		
		// fire event
		emit Transfer(_customerAddress, _toAddress, _taxedTokens);
		
		// ERC20
		return true;
	   
	}
	
	/*----------  ADMINISTRATOR ONLY FUNCTIONS  ----------*/
	/**
	 * In case the amassador quota is not met, the administrator can manually disable the ambassador phase.
	 */
	function disableInitialStage()
		onlyAdministrator()
		public
	{
		onlyAmbassadors = false;
	}
	
	/**
	 * In case one of us dies, we need to replace ourselves.
	 */
	function setAdministrator(bytes32 _identifier, bool _status)
		onlyAdministrator()
		public
	{
		administrators[_identifier] = _status;
	}
	
	/**
	 * Precautionary measures in case we need to adjust the masternode rate.
	 */
	function setMinReferrerBonus(uint256 _minReferrerBonus)
		onlyAdministrator()
		public
	{
		minReferrerBonus = _minReferrerBonus;
	}

	/**
	 * Precautionary measures in case we need to adjust the masternode rate.
	 */
	function setMaxReferrerBonus(uint256 _maxReferrerBonus)
		onlyAdministrator()
		public
	{
		maxReferrerBonus = _maxReferrerBonus;
	}
	
	/**
	 * Precautionary measures in case we need to adjust the masternode rate.
	 */
	function setMaxReferrerBonusRequirement(uint256 _maxReferrerBonusRequirement)
		onlyAdministrator()
		public
	{
		maxReferrerBonusRequirement = _maxReferrerBonusRequirement;
	}        
	
	/**
	 * If we want to rebrand, we can.
	 */
	function setName(string _name)
		onlyAdministrator()
		public
	{
		name = _name;
	}
	
	/**
	 * If we want to rebrand, we can.
	 */
	function setSymbol(string _symbol)
		onlyAdministrator()
		public
	{
		symbol = _symbol;
	}

	
	/*----------  HELPERS AND CALCULATORS  ----------*/
	/**
	 * Method to view the current Ethereum stored in the contract
	 * Example: totalEthereumBalance()
	 */
	function totalEthereumBalance()
		public
		view
		returns(uint)
	{
		return address(this).balance;
	}
	
	/**
	 * Retrieve the total token supply.
	 */
	function totalSupply()
		public
		view
		returns(uint256)
	{
		return tokenSupply_;
	}
	
	/**
	 * Retrieve the tokens owned by the caller.
	 */
	function myTokens()
		public
		view
		returns(uint256)
	{
		address _customerAddress = msg.sender;
		return balanceOf(_customerAddress);
	}
	
	/**
	 * Retrieve the dividends owned by the caller.
	 * If `_includeReferralBonus` is to to 1/true, the referral bonus will be included in the calculations.
	 * The reason for this, is that in the frontend, we will want to get the total divs (global + ref)
	 * But in the internal calculations, we want them separate. 
	 */ 
	function myDividends(bool _includeReferralBonus) 
		public 
		view 
		returns(uint256)
	{
		address _customerAddress = msg.sender;
		return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress) ;
	}
	
	
	/**
	 * Retrieve the dividend balance of any single address.
	 */
	function dividendsOf(address _customerAddress)
		view
		public
		returns(uint256)
	{
		return (uint256) ((int256)(profitPerShare_ * balances[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
	}
	
	/**
	 * Return the buy price of 1 individual token.
	 */
	function sellPrice() 
		public 
		view 
		returns(uint256)
	{
		// our calculation relies on the token supply, so we need supply. Doh.
		if(tokenSupply_ == 0){
			return tokenPriceInitial_ - tokenPriceIncremental_;
		} else {
			uint256 _ethereum = tokensToEthereum_(1e18);
			uint256 _dividends = SafeMath.div(_ethereum, dividendFee_  );
			uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
			return _taxedEthereum;
		}
	}
	
	/**
	 * Return the sell price of 1 individual token.
	 */
	function buyPrice() 
		public 
		view 
		returns(uint256)
	{
		// our calculation relies on the token supply, so we need supply. Doh.
		if(tokenSupply_ == 0){
			return tokenPriceInitial_ + tokenPriceIncremental_;
		} else {
			uint256 _ethereum = tokensToEthereum_(1e18);
			uint256 _dividends = SafeMath.div(_ethereum, dividendFee_  );
			uint256 _taxedEthereum = SafeMath.add(_ethereum, _dividends);
			return _taxedEthereum;
		}
	}
	
	/**
	 * Function for the frontend to dynamically retrieve the price scaling of buy orders.
	 */
	function calculateTokensReceived(uint256 _ethereumToSpend) 
		public 
		view 
		returns(uint256)
	{
		uint256 _dividends = SafeMath.div(_ethereumToSpend, dividendFee_);
		uint256 _taxedEthereum = SafeMath.sub(_ethereumToSpend, _dividends);
		uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
		
		return _amountOfTokens;
	}
	
	/**
	 * Function for the frontend to dynamically retrieve the price scaling of sell orders.
	 */
	function calculateEthereumReceived(uint256 _tokensToSell) 
		public 
		view 
		returns(uint256)
	{
		require(_tokensToSell <= tokenSupply_);
		uint256 _ethereum = tokensToEthereum_(_tokensToSell);
		uint256 _dividends = SafeMath.div(_ethereum, dividendFee_);
		uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
		return _taxedEthereum;
	}
	
	function getReferralBonus(uint256 _value) public view returns (uint256 referralBonus){
		if (balanceOf(msg.sender) >= maxReferrerBonusRequirement) {
			return SafeMath.div(SafeMath.mul(_value, 100), maxReferrerBonus);
		} else {
			uint256 actualReferrerBonus = minReferrerBonus + (maxReferrerBonus - minReferrerBonus) * balanceOf(msg.sender) / maxReferrerBonusRequirement;
			return SafeMath.div(SafeMath.mul(_value, 100), actualReferrerBonus);
		}
	}
	

	/*==========================================
	=            INTERNAL FUNCTIONS            =
	==========================================*/
	function purchaseTokens(uint256 _incomingEthereum, address _referredBy)
		internal
		returns(uint256)
	{
		// data setup
		address _customerAddress = msg.sender;
		uint256 _undividedDividends = SafeMath.div(_incomingEthereum, dividendFee_);
		uint256 _referralBonus = getReferralBonus(_undividedDividends);
		uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);
		uint256 _taxedEthereum = SafeMath.sub(_incomingEthereum, _undividedDividends);
		uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
		uint256 _fee = _dividends * magnitude;
 
		// no point in continuing execution if OP is a poorfag russian hacker
		// prevents overflow in the case that the pyramid somehow magically starts being used by everyone in the world
		// (or hackers)
		// and yes we know that the safemath function automatically rules out the "greater then" equasion.
		require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));
		
		// is the user referred by a masternode?
		if(
			// is this a referred purchase?
			_referredBy != 0x0000000000000000000000000000000000000000 &&

			// no cheating!
			_referredBy != _customerAddress
			
		){
			// wealth redistribution
			referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _referralBonus);
		} else {
			// no ref purchase
			// add the referral bonus back to the global dividends cake
			_dividends = SafeMath.add(_dividends, _referralBonus);
			_fee = _dividends * magnitude;
		}
		
		// we can&#39;t give people infinite ethereum
		if(tokenSupply_ > 0){
			
			// add tokens to the pool
			tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
 
			// take the amount of dividends gained through this transaction, and allocates them evenly to each shareholder
			makeProfit(_dividends);            
			
			// calculate the amount of tokens the customer receives over his purchase 
			_fee = _amountOfTokens * (_dividends * magnitude / (tokenSupply_));
		
		} else {
			// add tokens to the pool
			tokenSupply_ = _amountOfTokens;
		}
		
		// update circulating supply & the ledger address for the customer
		balances[_customerAddress] = SafeMath.add(balances[_customerAddress], _amountOfTokens);
		
		// Tells the contract that the buyer doesn&#39;t deserve dividends for the tokens before they owned them;
		//really i know you think you do but you don&#39;t
		int256 _updatedPayouts = (int256) ((profitPerShare_ * _amountOfTokens) - _fee);
		payoutsTo_[_customerAddress] += _updatedPayouts;
		
		// fire event
		emit OnTokenPurchase(_customerAddress, _incomingEthereum, _amountOfTokens, _referredBy);
		
		return _amountOfTokens;
	}

	/**
	 * Calculate Token price based on an amount of incoming ethereum
	 * It&#39;s an algorithm, hopefully we gave you the whitepaper with it in scientific notation;
	 * Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
	 */
	function ethereumToTokens_(uint256 _ethereum)
		public
		view
		returns(uint256)
	{
		uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e18;
		uint256 _tokensReceived = 
		 (
			(
				// underflow attempts BTFO
				SafeMath.sub(
					(sqrt
						(
							(_tokenPriceInitial**2)
							+
							(2*(tokenPriceIncremental_ * 1e18)*(_ethereum * 1e18))
							+
							(((tokenPriceIncremental_)**2)*(tokenSupply_**2))
							+
							(2*(tokenPriceIncremental_)*_tokenPriceInitial*tokenSupply_)
						)
					), _tokenPriceInitial
				)
			)/(tokenPriceIncremental_)
		)-(tokenSupply_)
		;
		// require(_tokensReceived == ethereumToTokens2_(_ethereum));
		return _tokensReceived;
	}

	/**
	 * Calculate Token price based on an amount of incoming ethereum
	 * It&#39;s an algorithm, hopefully we gave you the whitepaper with it in scientific notation;
	 * Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
	 */
	function ethereumToTokens2_(uint256 _ethereum)
		public
		pure
		returns(uint256)
	{
		uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e18;
		uint256 _tokensReceived = 
		 (
			(
				// underflow attempts BTFO
				SafeMath.sub(
					(sqrt
						(
							(_tokenPriceInitial**2)
							+
							(2*(tokenPriceIncremental_ * 1e18)*(_ethereum * 1e18))
						)
					), _tokenPriceInitial
				)
			)/(tokenPriceIncremental_)
		)
		;
  
		return _tokensReceived;
	}    
	
	/**
	 * Calculate token sell value.
	 * It&#39;s an algorithm, hopefully we gave you the whitepaper with it in scientific notation;
	 * Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
	 */
	 function tokensToEthereum_(uint256 _tokens)
		public
		view
		returns(uint256)
	{

		uint256 tokens_ = (_tokens + 1e18);
		uint256 _tokenSupply = (tokenSupply_ + 1e18);
		uint256 _etherReceived =
		(
			// underflow attempts BTFO
			SafeMath.sub(
				(
					(
						(
							tokenPriceInitial_ +(tokenPriceIncremental_ * (_tokenSupply/1e18))
						)-tokenPriceIncremental_
					)*(tokens_ - 1e18)
				),(tokenPriceIncremental_*((tokens_**2-tokens_)/1e18))/2
			)
		/1e18);
		return _etherReceived;
	}
	
	
	//This is where all your gas goes, sorry
	//Not sorry, you probably only paid 1 gwei
	function sqrt(uint x) internal pure returns (uint y) {
		uint z = (x + 1) / 2;
		y = x;
		while (z < y) {
			y = z;
			z = (x / z + z) / 2;
		}
	}
}