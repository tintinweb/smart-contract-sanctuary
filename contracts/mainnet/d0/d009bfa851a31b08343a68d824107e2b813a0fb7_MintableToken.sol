pragma solidity ^0.4.18;


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


contract BasicToken {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

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
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}


contract ERC20 {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
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
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

/**
 * @title Manageable
 */
contract Manageable is Ownable
{
	address public manager;
	
	event ManagerChanged(address indexed _oldManager, address _newManager);
	
	function Manageable() public
	{
		manager = msg.sender;
	}
	
	modifier onlyManager()
	{
		require(msg.sender == manager);
		_;
	}
	
	modifier onlyOwnerOrManager() 
	{
		require(msg.sender == owner || msg.sender == manager);
		_;
	}
	
	function changeManager(address _newManager) onlyOwner public 
	{
		require(_newManager != address(0));
		
		address oldManager = manager;
		if (oldManager != _newManager)
		{
			manager = _newManager;
			
			ManagerChanged(oldManager, _newManager);
		}
	}
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Manageable {
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
  function pause() onlyOwnerOrManager whenNotPaused public {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwnerOrManager whenPaused public {
    paused = false;
    Unpause();
  }
}

/**
 * @title Mintable token + Pausable token + BurnableToken
 */
contract MintableToken is StandardToken, Manageable, Pausable  {
  
  string public name = "Pointium";
  string public symbol = "PNT";
  uint256 public decimals = 18;
  
  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  event Burn(address indexed burner, uint256 value);

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwnerOrManager canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwnerOrManager canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
  
  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
  
  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) onlyOwnerOrManager public {
    require(_value <= balances[msg.sender]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
  }
    function burn_from(address _address, uint256 _value) onlyOwnerOrManager public {
    require(_value <= balances[_address]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    address burner = _address;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
  }
}

/**
 * @title Crowdsale
 */
contract Crowdsale is Manageable{
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

  MintableToken public token; // The token being sold

  uint256 public startTime;
  uint256 public endTime;

  address public wallet; // address where funds are collected

  uint256 public rate; // how many token units a buyer gets per wei

  uint256 public weiRaised; // amount of raised money in wei

  uint256 public cap; // a max amount of funds raised
  
  uint256 public tokenWeiMax;
  
  uint256 public tokenWeiMin;
  
  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  
  function init(uint256 _startTime, uint256 _endTime, uint256 _cap, uint256 _rate, address _wallet, MintableToken _token, uint256 _tokenWeiMax, uint256 _tokenWeiMin) onlyOwner public{

    
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));
    require(_cap > 0);
    require(_tokenWeiMax > 0);
    require(_tokenWeiMin > 0);

    cap = _cap;
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
    token = _token;
    tokenWeiMax = _tokenWeiMax;
    tokenWeiMin = _tokenWeiMin;
  }

  // fallback function can be used to buy tokens
  function () external payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;

    // calculate token amount to be created
    uint256 tokens = getTokenAmount(weiAmount);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

  // @return true if crowdsale event has ended
  function hasEnded() public view returns (bool) {
    bool capReached = weiRaised >= cap;
    return capReached || now > endTime;
  }

  // Override this method to have a way to add business logic to your crowdsale when buying
  function getTokenAmount(uint256 weiAmount) internal view returns(uint256) {
    if(now <= startTime.add(1209600)){
        return weiAmount.mul(rate);
    }
    else{
        return weiAmount.mul(rate.sub(8500));
    }
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    bool withinCap = weiRaised.add(msg.value) <= cap;
    bool withinMaxMin = tokenWeiMax >= msg.value && tokenWeiMin <= msg.value;
    return withinCap && withinPeriod && nonZeroPurchase && withinMaxMin;
  }
}

contract CrowdsaleManager is Manageable {
    using SafeMath for uint256;
    MintableToken public token;
    Crowdsale public sale1;
    Crowdsale public sale2;
    
    function CreateToken() onlyOwner public {
        token = new MintableToken();
        token.mint(0xB63E25a133635237f970B5B38B858DE8323E82B6,784000000000000000000000000);
        token.pause();
    }
    
    function createSale1() onlyOwner public
    {
        sale1 = new Crowdsale();
    }
    
    function initSale1() onlyOwner public
    {
        uint256 startTime = 1522587600;
        uint256 endTime = 1525006800;
        uint256 cap = 2260000000000000000000;
        uint256 rate = 110500; // bounus + normal
        address wallet = 0x5F94072FA770E688C30F50C21410aA6bd5779d87;
        uint256 tokenWeiMax = 500000000000000000000;
        uint256 tokenWeiMin = 200000000000000000;
        sale1.init(startTime, endTime, cap, rate, wallet, token, tokenWeiMax, tokenWeiMin);
        token.changeManager(sale1);
    }
    
    function createSale2() onlyOwner public
    {
        sale2 = new Crowdsale();
    }
    
    function initSale2() onlyOwner public
    {
        uint256 startTime = 1525179600;
        uint256 endTime = 1527598800;
        uint256 cap = 6725000000000000000000;
        uint256 rate = 93500; // bounus + normal
        address wallet = 0x555b6789f0749fbcfA188f0140c38606B6021A86;
        uint256 tokenWeiMax = 500000000000000000000;
        uint256 tokenWeiMin = 200000000000000000;
        sale2.init(startTime, endTime, cap, rate, wallet, token, tokenWeiMax, tokenWeiMin);
        token.changeManager(sale2);
    }
    
    function changeTokenManager(address _newManager) onlyOwner public
    {
  	    token.changeManager(_newManager);
    }
}