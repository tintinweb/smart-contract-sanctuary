pragma solidity ^0.4.21;


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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}
/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
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
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

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
    emit Transfer(msg.sender, _to, _value);
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

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
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
    emit Transfer(_from, _to, _value);
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
    emit Approval(msg.sender, _spender, _value);
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
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

/**
 * @title Gene Nuggets Token
 *
 * @dev Implementation of the Gene Nuggets Token.
 */
contract GeneNuggetsToken is Pausable,StandardToken {
  using SafeMath for uint256;
  
  string public name = "Gene Nuggets";
  string public symbol = "GNUS";
   
  //constants
  uint8 public decimals = 6;
  uint256 public decimalFactor = 10 ** uint256(decimals);
  uint public CAP = 30e8 * decimalFactor; //Maximal GNUG supply = 3 billion
  
  //contract state
  uint256 public circulatingSupply;
  uint256 public totalUsers;
  uint256 public exchangeLimit = 10000*decimalFactor;
  uint256 public exchangeThreshold = 2000*decimalFactor;
  uint256 public exchangeInterval = 60;
  uint256 public destroyThreshold = 100*decimalFactor;
 
  //managers address
  address public CFO; //CFO address
  mapping(address => uint256) public CustomerService; //customer service addresses
  
  //mining rules
  uint[10] public MINING_LAYERS = [0,10e4,30e4,100e4,300e4,600e4,1000e4,2000e4,3000e4,2**256 - 1];
  uint[9] public MINING_REWARDS = [1000*decimalFactor,600*decimalFactor,300*decimalFactor,200*decimalFactor,180*decimalFactor,160*decimalFactor,60*decimalFactor,39*decimalFactor,0];
  
  //events
  event UpdateTotal(uint totalUser,uint totalSupply);
  event Exchange(address indexed user,uint256 amount);
  event Destory(address indexed user,uint256 amount);

  modifier onlyCFO() {
    require(msg.sender == CFO);
    _;
  }


  modifier onlyCustomerService() {
    require(CustomerService[msg.sender] != 0);
    _;
  }

  /**
  * @dev ccontract constructor
  */  
  function GeneNuggetsToken() public {}

  /**
  * @dev fallback revert eth transfer
  */   
  function() public {
    revert();
  }
  
  /**
   * @dev Allows the current owner to change token name.
   * @param newName The name to change to.
   */
  function setName(string newName) external onlyOwner {
    name = newName;
  }
  
  /**
   * @dev Allows the current owner to change token symbol.
   * @param newSymbol The symbol to change to.
   */
  function setSymbol(string newSymbol) external onlyOwner {
    symbol = newSymbol;
  }
  
  /**
   * @dev Allows the current owner to change CFO address.
   * @param newCFO The address to change to.
   */
  function setCFO(address newCFO) external onlyOwner {
    CFO = newCFO;
  }
  
  /**
   * @dev Allows owner to change exchangeInterval.
   * @param newInterval The new interval to change to.
   */
  function setExchangeInterval(uint newInterval) external onlyCFO {
    exchangeInterval = newInterval;
  }

  /**
   * @dev Allows owner to change exchangeLimit.
   * @param newLimit The new limit to change to.
   */
  function setExchangeLimit(uint newLimit) external onlyCFO {
    exchangeLimit = newLimit;
  }

  /**
   * @dev Allows owner to change exchangeThreshold.
   * @param newThreshold The new threshold to change to.
   */
  function setExchangeThreshold(uint newThreshold) external onlyCFO {
    exchangeThreshold = newThreshold;
  }
  
  /**
   * @dev Allows owner to change destroyThreshold.
   * @param newThreshold The new threshold to change to.
   */
  function setDestroyThreshold(uint newThreshold) external onlyCFO {
    destroyThreshold = newThreshold;
  }
  
  /**
   * @dev Allows CFO to add customer service address.
   * @param cs The address to add.
   */
  function addCustomerService(address cs) onlyCFO external {
    CustomerService[cs] = block.timestamp;
  }
  
  /**
   * @dev Allows CFO to remove customer service address.
   * @param cs The address to remove.
   */
  function removeCustomerService(address cs) onlyCFO external {
    CustomerService[cs] = 0;
  }

  /**
   * @dev Function to allow CFO update tokens amount according to user amount.Attention: newly mined token still outside contract until exchange on user&#39;s requirments.  
   * @param _userAmount current gene nuggets user amount.
   */
  function updateTotal(uint256 _userAmount) onlyCFO external {
    require(_userAmount>totalUsers);
    uint newTotalSupply = calTotalSupply(_userAmount);
    require(newTotalSupply<=CAP && newTotalSupply>totalSupply_);
    
    uint _amount = newTotalSupply.sub(totalSupply_);
    totalSupply_ = newTotalSupply;
    totalUsers = _userAmount;
    emit UpdateTotal(_amount,totalSupply_); 
  }

  /**
   * @dev Uitl function to calculate total supply according to total user amount.
   * @param _userAmount total user amount.
   */  
  function calTotalSupply(uint _userAmount) private view returns (uint ret) {
    uint tokenAmount = 0;
	  for (uint8 i = 0; i < MINING_LAYERS.length ; i++ ) {
	    if(_userAmount < MINING_LAYERS[i+1]) {
	      tokenAmount = tokenAmount.add(MINING_REWARDS[i].mul(_userAmount.sub(MINING_LAYERS[i])));
	      break;
	    }else {
        tokenAmount = tokenAmount.add(MINING_REWARDS[i].mul(MINING_LAYERS[i+1].sub(MINING_LAYERS[i])));
	    }
	  }
	  return tokenAmount;
  }

  /**
   * @dev Function for Customer Service exchange off-chain points to GNUG on user&#39;s behalf. That is to say exchange GNUG into this contract.
   * @param user The user tokens distributed to.
   * @param _amount The amount of tokens to exchange.
   */
  function exchange(address user,uint256 _amount) whenNotPaused onlyCustomerService external {
  	
  	require((block.timestamp-CustomerService[msg.sender])>exchangeInterval);

  	require(_amount <= exchangeLimit && _amount >= exchangeThreshold);

    circulatingSupply = circulatingSupply.add(_amount);
    
    balances[user] = balances[user].add(_amount);
    
    CustomerService[msg.sender] = block.timestamp;
    
    emit Exchange(user,_amount);
    
    emit Transfer(address(0),user,_amount);
    
  }
  

  /**
   * @dev Function for user can destory GNUG, exchange back to off-chain points.That is to say destroy GNUG out of this contract.
   * @param _amount The amount of tokens to destory.
   */
  function destory(uint256 _amount) external {  
    require(balances[msg.sender]>=_amount && _amount>destroyThreshold && circulatingSupply>=_amount);

    circulatingSupply = circulatingSupply.sub(_amount);
    
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    
    emit Destory(msg.sender,_amount);
    
    emit Transfer(msg.sender,0x0,_amount);
    
  }

  function emergencyERC20Drain( ERC20 token, uint amount ) onlyOwner external {
    // owner can drain tokens that are sent here by mistake
    token.transfer( owner, amount );
  }
  
}