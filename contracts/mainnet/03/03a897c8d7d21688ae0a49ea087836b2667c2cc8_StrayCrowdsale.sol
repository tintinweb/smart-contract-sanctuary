pragma solidity ^0.4.24;
// produced by the Solididy File Flattener (c) David Appleton 2018
// contact : <span class="__cf_email__" data-cfemail="f591948390b5949e9a989794db969a98">[email&#160;protected]</span>
// released under Apache 2.0 licence
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

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



library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}

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

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

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

contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

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

contract StrayToken is StandardToken, BurnableToken, Ownable {
	using SafeERC20 for ERC20;
	
	uint256 public INITIAL_SUPPLY = 1000000000;
	
	string public name = "Stray";
	string public symbol = "ST";
	uint8 public decimals = 18;

	address public companyWallet;
	address public privateWallet;
	address public fund;
	
	/**
	 * @param _companyWallet The company wallet which reserves 15% of the token.
	 * @param _privateWallet Private wallet which reservers 25% of the token.
	 */
	constructor(address _companyWallet, address _privateWallet) public {
		require(_companyWallet != address(0));
		require(_privateWallet != address(0));
		
		totalSupply_ = INITIAL_SUPPLY * (10 ** uint256(decimals));
		companyWallet = _companyWallet;
		privateWallet = _privateWallet;
		
		// 15% of tokens for company reserved.
		_preSale(companyWallet, totalSupply_.mul(15).div(100));
		
		// 25% of tokens for private funding.
		_preSale(privateWallet, totalSupply_.mul(25).div(100));
		
		// 60% of tokens for crowdsale.
		uint256 sold = balances[companyWallet].add(balances[privateWallet]);
	    balances[msg.sender] = balances[msg.sender].add(totalSupply_.sub(sold));
	    emit Transfer(address(0), msg.sender, balances[msg.sender]);
	}
	
	/**
	 * @param _fund The DAICO fund contract address.
	 */
	function setFundContract(address _fund) onlyOwner public {
	    require(_fund != address(0));
	    //require(_fund != owner);
	    //require(_fund != msg.sender);
	    require(_fund != address(this));
	    
	    fund = _fund;
	}
	
	/**
	 * @dev The DAICO fund contract calls this function to burn the user&#39;s token
	 * to avoid over refund.
	 * @param _from The address which just took its refund.
	 */
	function burnAll(address _from) public {
	    require(fund == msg.sender);
	    require(0 != balances[_from]);
	    
	    _burn(_from, balances[_from]);
	}
	
	/**
	 * @param _to The address which will get the token.
	 * @param _value The token amount.
	 */
	function _preSale(address _to, uint256 _value) internal onlyOwner {
		balances[_to] = _value;
		emit Transfer(address(0), _to, _value);
	}
	
}

contract Crowdsale {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

  // The token being sold
  ERC20 public token;

  // Address where funds are collected
  address public wallet;

  // How many token units a buyer gets per wei.
  // The rate is the conversion between wei and the smallest and indivisible token unit.
  // So, if you are using a rate of 1 with a DetailedERC20 token with 3 decimals called TOK
  // 1 wei will give you 1 unit, or 0.001 TOK.
  uint256 public rate;

  // Amount of wei raised
  uint256 public weiRaised;

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

  /**
   * @param _rate Number of token units a buyer gets per wei
   * @param _wallet Address where collected funds will be forwarded to
   * @param _token Address of the token being sold
   */
  constructor(uint256 _rate, address _wallet, ERC20 _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = _token;
  }

  // -----------------------------------------
  // Crowdsale external interface
  // -----------------------------------------

  /**
   * @dev fallback function ***DO NOT OVERRIDE***
   */
  function () external payable {
    buyTokens(msg.sender);
  }

  /**
   * @dev low level token purchase ***DO NOT OVERRIDE***
   * @param _beneficiary Address performing the token purchase
   */
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

    // calculate token amount to be created
    uint256 tokens = _getTokenAmount(weiAmount);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }

  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

  /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

  /**
   * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _postValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    // optional override
  }

  /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param _beneficiary Address performing the token purchase
   * @param _tokenAmount Number of tokens to be emitted
   */
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    token.safeTransfer(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param _beneficiary Address receiving the tokens
   * @param _tokenAmount Number of tokens to be purchased
   */
  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
   * @param _beneficiary Address receiving the tokens
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    // optional override
  }

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256)
  {
    return _weiAmount.mul(rate);
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}
contract RefundVault is Ownable {
  using SafeMath for uint256;

  enum State { Active, Refunding, Closed }

  mapping (address => uint256) public deposited;
  address public wallet;
  State public state;

  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

  /**
   * @param _wallet Vault address
   */
  constructor(address _wallet) public {
    require(_wallet != address(0));
    wallet = _wallet;
    state = State.Active;
  }

  /**
   * @param investor Investor address
   */
  function deposit(address investor) onlyOwner public payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }

  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    emit Closed();
    wallet.transfer(address(this).balance);
  }

  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    emit RefundsEnabled();
  }

  /**
   * @param investor Investor address
   */
  function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    emit Refunded(investor, depositedValue);
  }
}

contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public openingTime;
  uint256 public closingTime;

  /**
   * @dev Reverts if not in crowdsale time range.
   */
  modifier onlyWhileOpen {
    // solium-disable-next-line security/no-block-members
    require(block.timestamp >= openingTime && block.timestamp <= closingTime);
    _;
  }

  /**
   * @dev Constructor, takes crowdsale opening and closing times.
   * @param _openingTime Crowdsale opening time
   * @param _closingTime Crowdsale closing time
   */
  constructor(uint256 _openingTime, uint256 _closingTime) public {
    // solium-disable-next-line security/no-block-members
    require(_openingTime >= block.timestamp);
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;
  }

  /**
   * @dev Checks whether the period in which the crowdsale is open has already elapsed.
   * @return Whether crowdsale period has elapsed
   */
  function hasClosed() public view returns (bool) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp > closingTime;
  }

  /**
   * @dev Extend parent behavior requiring to be within contributing period
   * @param _beneficiary Token purchaser
   * @param _weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
    onlyWhileOpen
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

contract FinalizableCrowdsale is TimedCrowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

  /**
   * @dev Must be called after crowdsale ends, to do some extra finalization
   * work. Calls the contract&#39;s finalization function.
   */
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasClosed());

    finalization();
    emit Finalized();

    isFinalized = true;
  }

  /**
   * @dev Can be overridden to add finalization logic. The overriding function
   * should call super.finalization() to ensure the chain of finalization is
   * executed entirely.
   */
  function finalization() internal {
  }

}

contract StrayCrowdsale is FinalizableCrowdsale {
    using SafeMath for uint256;
    
    // Soft cap and hard cap in distributed token.
    uint256 public softCapInToken;
    uint256 public hardCapInToken;
    uint256 public soldToken = 0;
    
    // Bouns stage time.
    uint256 public bonusClosingTime0;
    uint256 public bonusClosingTime1;
    
    // Bouns rate.
    uint256 public bonusRateInPercent0 = 33;
    uint256 public bonusRateInPercent1 = 20;
    
    // Mininum contribute: 100 USD.
    uint256 public mininumContributeUSD = 100;
    
    // The floating exchange rate from external API.
    uint256 public decimalsETHToUSD;
    uint256 public exchangeRateETHToUSD;
   
   // The mininum purchase token quantity.
    uint256 public mininumPurchaseTokenQuantity;
    
    // The calculated mininum contribute Wei.
    uint256 public mininumContributeWei;
    
    // The exchange rate from USD to Token.
    // 1 USD => 100 Token (0.01 USD => 1 Token).
    uint256 public exchangeRateUSDToToken = 100;
    
    // Stray token contract.
    StrayToken public strayToken;
    
    // Refund vault used to hold funds while crowdsale is running
    RefundVault public vault;
    
    // Event 
    event RateUpdated(uint256 rate, uint256 mininumContributeWei);
    
    /**
     * @param _softCapInUSD Minimal funds to be collected.
     * @param _hardCapInUSD Maximal funds to be collected.
     * @param _fund The Stray DAICO fund contract address.
     * @param _token Stray ERC20 contract.
     * @param _openingTime Crowdsale opening time.
     * @param _closingTime Crowdsale closing time.
     * @param _bonusClosingTime0 Bonus stage0 closing time.
     * @param _bonusClosingTime1 Bonus stage1 closing time.
     */
    constructor(uint256 _softCapInUSD
        , uint256 _hardCapInUSD
        , address _fund
        , ERC20 _token
        , uint256 _openingTime
        , uint256 _closingTime
        , uint256 _bonusClosingTime0
        , uint256 _bonusClosingTime1
        ) 
        Crowdsale(1, _fund, _token)
        TimedCrowdsale(_openingTime, _closingTime)
        public 
    {
        // Validate ico stage time.
        require(_bonusClosingTime0 >= _openingTime);
        require(_bonusClosingTime1 >= _bonusClosingTime0);
        require(_closingTime >= _bonusClosingTime1);
        
        bonusClosingTime0 = _bonusClosingTime0;
        bonusClosingTime1 = _bonusClosingTime1;
        
        // Create the token.
        strayToken = StrayToken(token);
        
        // Set soft cap and hard cap.
        require(_softCapInUSD > 0 && _softCapInUSD <= _hardCapInUSD);
        
        softCapInToken = _softCapInUSD * exchangeRateUSDToToken * (10 ** uint256(strayToken.decimals()));
        hardCapInToken = _hardCapInUSD * exchangeRateUSDToToken * (10 ** uint256(strayToken.decimals()));
        
        require(strayToken.balanceOf(owner) >= hardCapInToken);
        
        // Create the refund vault.
        vault = new RefundVault(_fund);
        
        // Calculate mininum purchase token.
        mininumPurchaseTokenQuantity = exchangeRateUSDToToken * mininumContributeUSD 
            * (10 ** (uint256(strayToken.decimals())));
        
        // Set default exchange rate ETH => USD: 400.00
        setExchangeRateETHToUSD(40000, 2);
    }
    
    /**
     * @dev Set the exchange rate from ETH to USD.
     * @param _rate The exchange rate.
     * @param _decimals The decimals of input rate.
     */
    function setExchangeRateETHToUSD(uint256 _rate, uint256 _decimals) onlyOwner public {
        // wei * 1e-18 * _rate * 1e(-_decimals) * 1e2          = amount * 1e(-token.decimals);
        // -----------   ----------------------   -------------
        // Wei => ETH      ETH => USD             USD => Token
        //
        // If _rate = 1, wei = 1,
        // Then  amount = 1e(token.decimals + 2 - 18 - _decimals).
        // We need amount >= 1 to ensure the precision.
        
        require(uint256(strayToken.decimals()).add(2) >= _decimals.add(18));
        
        exchangeRateETHToUSD = _rate;
        decimalsETHToUSD = _decimals;
        rate = _rate.mul(exchangeRateUSDToToken);
        if (uint256(strayToken.decimals()) >= _decimals.add(18)) {
            rate = rate.mul(10 ** (uint256(strayToken.decimals()).sub(18).sub(_decimals)));
        } else {
            rate = rate.div(10 ** (_decimals.add(18).sub(uint256(strayToken.decimals()))));
        }
        
        mininumContributeWei = mininumPurchaseTokenQuantity.div(rate); 
        
        // Avoid rounding error.
        if (mininumContributeWei * rate < mininumPurchaseTokenQuantity)
            mininumContributeWei += 1;
            
        emit RateUpdated(rate, mininumContributeWei);
    }
    
    /**
     * @dev Investors can claim refunds here if crowdsale is unsuccessful
     */
    function claimRefund() public {
        require(isFinalized);
        require(!softCapReached());

        vault.refund(msg.sender);
    }
    
    /**
     * @dev Checks whether funding goal was reached.
     * @return Whether funding goal was reached
     */
    function softCapReached() public view returns (bool) {
        return soldToken >= softCapInToken;
    }
    
    /**
     * @dev Validate if it is in ICO stage 1.
     */
    function isInStage1() view public returns (bool) {
        return now <= bonusClosingTime0 && now >= openingTime;
    }
    
    /**
     * @dev Validate if it is in ICO stage 2.
     */
    function isInStage2() view public returns (bool) {
        return now <= bonusClosingTime1 && now > bonusClosingTime0;
    }
    
    /**
     * @dev Validate if crowdsale has started.
     */
    function hasStarted() view public returns (bool) {
        return now >= openingTime;
    }
    
    /**
     * @dev Validate the mininum contribution requirement.
     */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount)
        internal
    {
        super._preValidatePurchase(_beneficiary, _weiAmount);
        require(_weiAmount >= mininumContributeWei);
    }
    
    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
     * @param _beneficiary Address receiving the tokens
     * @param _tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        soldToken = soldToken.add(_tokenAmount);
        require(soldToken <= hardCapInToken);
        
       _tokenAmount = _addBonus(_tokenAmount);
        
        super._processPurchase(_beneficiary, _tokenAmount);
    }
    
    /**
     * @dev Finalization task, called when owner calls finalize()
     */
    function finalization() internal {
        if (softCapReached()) {
            vault.close();
        } else {
            vault.enableRefunds();
        }
        
        // Burn all the unsold token.
        strayToken.burn(token.balanceOf(address(this)));
        
        super.finalization();
    }

    /**
     * @dev Overrides Crowdsale fund forwarding, sending funds to vault.
     */
    function _forwardFunds() internal {
        vault.deposit.value(msg.value)(msg.sender);
    }
    
    /**
     * @dev Calculate the token amount and add bonus if needed.
     */
    function _addBonus(uint256 _tokenAmount) internal view returns (uint256) {
        if (bonusClosingTime0 >= now) {
            _tokenAmount = _tokenAmount.mul(100 + bonusRateInPercent0).div(100);
        } else if (bonusClosingTime1 >= now) {
            _tokenAmount = _tokenAmount.mul(100 + bonusRateInPercent1).div(100);
        }
        
        require(_tokenAmount <= token.balanceOf(address(this)));
        
        return _tokenAmount;
    }
}