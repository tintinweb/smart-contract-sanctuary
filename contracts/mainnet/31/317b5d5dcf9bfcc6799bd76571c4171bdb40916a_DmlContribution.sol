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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}



/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
}
















/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  /**
  * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint size) {
    require(msg.data.length >= size + 4) ;
    _;
  }

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public onlyPayloadSize(2 * 32) returns (bool) {
    require(_to != address(0));

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

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
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  /**
  * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint size) {
    require(msg.data.length >= size + 4) ;
    _;
  }

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3 * 32) returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint _addedValue)
    public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
    public returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
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
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}


/**
 * @title DML Token Contract
 * @dev DML Token Contract
 * @dev inherite from StandardToken, Pasuable and Ownable by Zeppelin
 * @author DML team
 */

contract DmlToken is StandardToken, Pausable{
	using SafeMath for uint;

 	string public constant name = "DML Token";
	uint8 public constant decimals = 18;
	string public constant symbol = &#39;DML&#39;;

	uint public constant MAX_TOTAL_TOKEN_AMOUNT = 330000000 ether;
	address public minter;
	uint public endTime;

	mapping (address => uint) public lockedBalances;

	modifier onlyMinter {
    	  assert(msg.sender == minter);
    	  _;
    }

    modifier maxDmlTokenAmountNotReached (uint amount){
    	  assert(totalSupply.add(amount) <= MAX_TOTAL_TOKEN_AMOUNT);
    	  _;
    }

    /**
     * @dev Constructor
     * @param _minter Contribution Smart Contract
     * @return _endTime End of the contribution period
     */
	function DmlToken(address _minter, uint _endTime){
    	  minter = _minter;
    	  endTime = _endTime;
    }

    /**
     * @dev Mint Token
     * @param receipent address owning mint tokens    
     * @param amount amount of token
     */
    function mintToken(address receipent, uint amount)
        external
        onlyMinter
        maxDmlTokenAmountNotReached(amount)
        returns (bool)
    {
        require(now <= endTime);
      	lockedBalances[receipent] = lockedBalances[receipent].add(amount);
      	totalSupply = totalSupply.add(amount);
      	return true;
    }

    /**
     * @dev Unlock token for trade
     */
    function claimTokens(address receipent)
        public
        onlyMinter
    {
      	balances[receipent] = balances[receipent].add(lockedBalances[receipent]);
      	lockedBalances[receipent] = 0;
    }

    function lockedBalanceOf(address _owner) constant returns (uint balance) {
        return lockedBalances[_owner];
    }

	/**
	* @dev override to add validRecipient
	* @param _to The address to transfer to.
	* @param _value The amount to be transferred.
	*/
	function transfer(address _to, uint _value)
		public
		validRecipient(_to)
		returns (bool success)
	{
		return super.transfer(_to, _value);
	}

	/**
	* @dev override to add validRecipient
	* @param _spender The address which will spend the funds.
	* @param _value The amount of tokens to be spent.
	*/
	function approve(address _spender, uint256 _value)
		public
		validRecipient(_spender)
		returns (bool)
	{
		return super.approve(_spender,  _value);
	}

	/**
	* @dev override to add validRecipient
	* @param _from address The address which you want to send tokens from
	* @param _to address The address which you want to transfer to
	* @param _value uint256 the amount of tokens to be transferred
	*/
	function transferFrom(address _from, address _to, uint256 _value)
		public
		validRecipient(_to)
		returns (bool)
	{
		return super.transferFrom(_from, _to, _value);
	}

	// MODIFIERS

 	modifier validRecipient(address _recipient) {
    	require(_recipient != address(this));
    	_;
  	}
}



/**
 * @title DML Contribution Contract
 * @dev DML Contribution Contract
 * @dev inherite from StandardToken, Ownable by Zeppelin
 * @author DML team
 */
contract DmlContribution is Ownable {
    using SafeMath for uint;

    /// Constant fields
    /// total tokens supply
    uint public constant DML_TOTAL_SUPPLY = 330000000 ether;
    uint public constant EARLY_CONTRIBUTION_DURATION = 24 hours;
    uint public constant MAX_CONTRIBUTION_DURATION = 5 days;

    /// Exchange rates
    uint public constant PRICE_RATE_FIRST = 3780;
    uint public constant PRICE_RATE_SECOND = 4158;

    /// ----------------------------------------------------------------------------------------------------
    /// |                                   |              |                    |             |            |
    /// |    SALE (PRESALE + PUBLIC SALE)   |  ECO SYSTEM  |  COMMUNITY BOUNTY  |  OPERATION  |  RESERVES  |
    /// |            36%                    |     9.9%     |         8.3%       |     30.8%   |     15%    |
    /// ----------------------------------------------------------------------------------------------------
    uint public constant SALE_STAKE = 360;  // 36% for open sale

    // Reserved stakes
    uint public constant ECO_SYSTEM_STAKE = 99;   // 9.9%
    uint public constant COMMUNITY_BOUNTY_STAKE = 83; // 8.3%
    uint public constant OPERATION_STAKE = 308;     // 30.8%
    uint public constant RESERVES_STAKE = 150;     // 15.0%

    uint public constant DIVISOR_STAKE = 1000;

    uint public constant PRESALE_RESERVERED_AMOUNT = 56899342578812412860512236;
    
    /// Holder address
    address public constant ECO_SYSTEM_HOLDER = 0x2D8C705a66b2E87A9249380d4Cdfe9D80BBF826B;
    address public constant COMMUNITY_BOUNTY_HOLDER = 0x68500ffEfb57D88A600E2f1c63Bb5866e7107b6B;
    address public constant OPERATION_HOLDER = 0xC7b6DFf52014E59Cb88fAc3b371FA955D0A9249F;
    address public constant RESERVES_HOLDER = 0xab376b3eC2ed446444911E549c7C953fB086070f;
    address public constant PRESALE_HOLDER = 0xcB52583D19fd42c0f85a0c83A45DEa6C73B9EBfb;
    
    uint public MAX_PUBLIC_SOLD = DML_TOTAL_SUPPLY * SALE_STAKE / DIVISOR_STAKE - PRESALE_RESERVERED_AMOUNT;

    /// Fields that are only changed in constructor    
    /// Address that storing all ETH
    address public dmlwallet;
    uint public earlyWhitelistBeginTime;
    uint public startTime;
    uint public endTime;

    /// Fields that can be changed by functions
    /// Accumulator for open sold tokens
    uint public openSoldTokens;
    /// Due to an emergency, set this to true to halt the contribution
    bool public halted; 
    /// ERC20 compilant DML token contact instance
    DmlToken public dmlToken; 

    mapping (address => WhitelistUser) private whitelisted;
    address[] private whitelistedIndex;

    struct WhitelistUser {
      uint256 quota;
      uint index;
      uint level;
    }
    /// level 1 Main Whitelist
    /// level 2 Early Whitelist
    /// level 3 Early Super Whitelist

    uint256 public maxBuyLimit = 68 ether;

    /*
     * EVENTS
     */

    event NewSale(address indexed destAddress, uint ethCost, uint gotTokens);
    event ToFundAmount(uint ethCost);
    event ValidFundAmount(uint ethCost);
    event Debug(uint number);
    event UserCallBuy();
    event ShowTokenAvailable(uint);
    event NowTime(uint, uint, uint, uint);

    /*
     * MODIFIERS
     */

    modifier notHalted() {
        require(!halted);
        _;
    }

    modifier initialized() {
        require(address(dmlwallet) != 0x0);
        _;
    }    

    modifier notEarlierThan(uint x) {
        require(now >= x);
        _;
    }

    modifier earlierThan(uint x) {
        require(now < x);
        _;
    }

    modifier ceilingNotReached() {
        require(openSoldTokens < MAX_PUBLIC_SOLD);
        _;
    }  

    modifier isSaleEnded() {
        require(now > endTime || openSoldTokens >= MAX_PUBLIC_SOLD);
        _;
    }


    /**
     * CONSTRUCTOR 
     * 
     * @dev Initialize the DML contribution contract
     * @param _dmlwallet The escrow account address, all ethers will be sent to this address.
     * @param _bootTime ICO boot time
     */
    function DmlContribution(address _dmlwallet, uint _bootTime){
        require(_dmlwallet != 0x0);

        halted = false;
        dmlwallet = _dmlwallet;
        earlyWhitelistBeginTime = _bootTime;
        startTime = earlyWhitelistBeginTime + EARLY_CONTRIBUTION_DURATION;
        endTime = startTime + MAX_CONTRIBUTION_DURATION;
        openSoldTokens = 0;
        dmlToken = new DmlToken(this, endTime);

        uint stakeMultiplier = DML_TOTAL_SUPPLY / DIVISOR_STAKE;
        
        dmlToken.mintToken(ECO_SYSTEM_HOLDER, ECO_SYSTEM_STAKE * stakeMultiplier);
        dmlToken.mintToken(COMMUNITY_BOUNTY_HOLDER, COMMUNITY_BOUNTY_STAKE * stakeMultiplier);
        dmlToken.mintToken(OPERATION_HOLDER, OPERATION_STAKE * stakeMultiplier);
        dmlToken.mintToken(RESERVES_HOLDER, RESERVES_STAKE * stakeMultiplier);

        dmlToken.mintToken(PRESALE_HOLDER, PRESALE_RESERVERED_AMOUNT);      
        
    }

    /**
     * Fallback function 
     * 
     * @dev Set it to buy Token if anyone send ETH
     */
    function () public payable {
        buyDmlCoin(msg.sender);
        //NowTime(now, earlyWhitelistBeginTime, startTime, endTime);
    }

    /*
     * PUBLIC FUNCTIONS
     */

    /// @dev Exchange msg.value ether to DML for account recepient
    /// @param receipient DML tokens receiver
    function buyDmlCoin(address receipient) 
        public 
        payable 
        notHalted 
        initialized 
        ceilingNotReached 
        notEarlierThan(earlyWhitelistBeginTime)
        earlierThan(endTime)
        returns (bool) 
    {
        require(receipient != 0x0);
        require(isWhitelisted(receipient));

        // Do not allow contracts to game the system
        require(!isContract(msg.sender));        
        require( tx.gasprice <= 99000000000 wei );

        if( now < startTime && now >= earlyWhitelistBeginTime)
        {
            if (whitelisted[receipient].level >= 2)
            {
                require(msg.value >= 1 ether);
            }
            else
            {
                require(msg.value >= 0.5 ether);
            }
            buyEarlyWhitelist(receipient);
        }
        else
        {
            require(msg.value >= 0.1 ether);
            require(msg.value <= maxBuyLimit);
            buyRemaining(receipient);
        }

        return true;
    }

    function setMaxBuyLimit(uint256 limit)
        public
        initialized
        onlyOwner
        earlierThan(endTime)
    {
        maxBuyLimit = limit;
    }


    /// @dev batch set quota for early user quota
    function addWhiteListUsers(address[] userAddresses, uint256[] quota, uint[] level)
        public
        onlyOwner
        earlierThan(endTime)
    {
        for( uint i = 0; i < userAddresses.length; i++) {
            addWhiteListUser(userAddresses[i], quota[i], level[i]);
        }
    }

    function addWhiteListUser(address userAddress, uint256 quota, uint level)
        public
        onlyOwner
        earlierThan(endTime)
    {
        if (!isWhitelisted(userAddress)) {
            whitelisted[userAddress].quota = quota;
            whitelisted[userAddress].level = level;
            whitelisted[userAddress].index = whitelistedIndex.push(userAddress) - 1;
        }
    }

    /**
    * @dev Get a user&#39;s whitelisted state
    * @param userAddress      address       the wallet address of the user
    * @return bool  true if the user is in the whitelist
    */
    function isWhitelisted (address userAddress) public constant returns (bool isIndeed) {
        if (whitelistedIndex.length == 0) return false;
        return (whitelistedIndex[whitelisted[userAddress].index] == userAddress);
    }

    /*****
    * @dev Get a whitelisted user
    * @param userAddress      address       the wallet address of the user
    * @return uint256  the amount pledged by the user
    * @return uint     the index of the user
    */
    function getWhitelistUser (address userAddress) public constant returns (uint256 quota, uint index, uint level) {
        require(isWhitelisted(userAddress));
        return(whitelisted[userAddress].quota, whitelisted[userAddress].index, whitelisted[userAddress].level);
    }


    /// @dev Emergency situation that requires contribution period to stop.
    /// Contributing not possible anymore.
    function halt() public onlyOwner{
        halted = true;
    }

    /// @dev Emergency situation resolved.
    /// Contributing becomes possible again withing the outlined restrictions.
    function unHalt() public onlyOwner{
        halted = false;
    }

    /// @dev Emergency situation
    function changeWalletAddress(address newAddress) onlyOwner{ 
        dmlwallet = newAddress; 
    }

    /// @return true if sale not ended, false otherwise.
    function saleNotEnd() constant returns (bool) {
        return now < endTime && openSoldTokens < MAX_PUBLIC_SOLD;
    }

    /// CONSTANT METHODS
    /// @dev Get current exchange rate
    function priceRate() public constant returns (uint) {
        // Two price tiers
        if (earlyWhitelistBeginTime <= now && now < startTime)
        {
            if (whitelisted[msg.sender].level >= 2)
            {
                return PRICE_RATE_SECOND;
            }
            else
            {
                return PRICE_RATE_FIRST;
            }
        }
        if (startTime <= now && now < endTime)
        {
            return PRICE_RATE_FIRST;
        }
        // Should not be called before or after contribution period
        assert(false);
    }
    function claimTokens(address receipent)
        public
        isSaleEnded
    {
        dmlToken.claimTokens(receipent);
    }

    /*
     * INTERNAL FUNCTIONS
     */

    /// @dev early_whitelist to buy token with quota
    function buyEarlyWhitelist(address receipient) internal {
        uint quotaAvailable = whitelisted[receipient].quota;
        require(quotaAvailable > 0);

        uint tokenAvailable = MAX_PUBLIC_SOLD.sub(openSoldTokens);
        ShowTokenAvailable(tokenAvailable);
        require(tokenAvailable > 0);

        uint validFund = quotaAvailable.min256(msg.value);
        ValidFundAmount(validFund);

        uint toFund;
        uint toCollect;
        (toFund, toCollect) = costAndBuyTokens(tokenAvailable, validFund);

        whitelisted[receipient].quota = whitelisted[receipient].quota.sub(toFund);
        buyCommon(receipient, toFund, toCollect);
    }

    /// @dev early_whitelist and main whitelist to buy token with their quota + extra quota
    function buyRemaining(address receipient) internal {
        uint tokenAvailable = MAX_PUBLIC_SOLD.sub(openSoldTokens);
        ShowTokenAvailable(tokenAvailable);
        require(tokenAvailable > 0);

        uint toFund;
        uint toCollect;
        (toFund, toCollect) = costAndBuyTokens(tokenAvailable, msg.value);
        
        buyCommon(receipient, toFund, toCollect);
    }

    /// @dev Utility function for buy token
    function buyCommon(address receipient, uint toFund, uint dmlTokenCollect) internal {
        require(msg.value >= toFund); // double check

        if(toFund > 0) {
            require(dmlToken.mintToken(receipient, dmlTokenCollect));
            ToFundAmount(toFund);
            dmlwallet.transfer(toFund);
            openSoldTokens = openSoldTokens.add(dmlTokenCollect);
            NewSale(receipient, toFund, dmlTokenCollect);            
        }

        uint toReturn = msg.value.sub(toFund);
        if(toReturn > 0) {
            msg.sender.transfer(toReturn);
        }
    }

    /// @dev Utility function for calculate available tokens and cost ethers
    function costAndBuyTokens(uint availableToken, uint validFund) constant internal returns (uint costValue, uint getTokens){
        // all conditions has checked in the caller functions
        uint exchangeRate = priceRate();
        getTokens = exchangeRate * validFund;

        if(availableToken >= getTokens){
            costValue = validFund;
        } else {
            costValue = availableToken / exchangeRate;
            getTokens = availableToken;
        }
    }

    /// @dev Internal function to determine if an address is a contract
    /// @param _addr The address being queried
    /// @return True if `_addr` is a contract
    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }
}