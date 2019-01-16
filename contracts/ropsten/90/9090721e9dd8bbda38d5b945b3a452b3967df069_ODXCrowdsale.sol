pragma solidity ^0.4.23;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**************************************************************************/
/**
 * @title ERC20 interface
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**************************************************************************/
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
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

/**************************************************************************/
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

/**************************************************************************/
/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic, Ownable {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;
  
  bool public stopped = false;
  
  event Stop(address indexed from);
  
  event Start(address indexed from);
  
  modifier isRunning {
    assert (!stopped);
    _;
  }

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
  function transfer(address _to, uint256 _value) isRunning public returns (bool) {
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
  function balanceOf(address _owner) public view returns (uint256 ownerBalance) {
    return balances[_owner];
  }
  
  function stop() onlyOwner public {
    stopped = true;
    emit Stop(msg.sender);
  }

  function start() onlyOwner public {
    stopped = false;
    emit Start(msg.sender);
  }

}
/**************************************************************************/
/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
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
    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

/**************************************************************************/
/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) isRunning public returns (bool) {
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
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) isRunning public returns (bool) {
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
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) isRunning public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) isRunning public returns (bool) {
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

/**************************************************************************/
/**
 * @title Standard Burnable Token
 * @dev Adds burnFrom method to ERC20 implementations
 */
contract StandardBurnableToken is BurnableToken, StandardToken {

  /**
   * @dev Burns a specific amount of tokens from the target address and decrements allowance
   * @param _from address The address which you want to send tokens from
   * @param _value uint256 The amount of token to be burned
   */
  function burnFrom(address _from, uint256 _value) public {
    require(_value <= allowed[_from][msg.sender]);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _burn(_from, _value);
  }
}

/**************************************************************************/
/**
 * @title CappedMintableToken token
 */
contract CappedMintableToken is StandardToken {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  event MintingAgentChanged(address addr, bool state);

  uint256 public cap;

  bool public mintingFinished = false;
  mapping (address => bool) public mintAgents;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }
  
  modifier onlyMintAgent() {
    // crowdsale contracts or owner are allowed to mint new tokens
    if(!mintAgents[msg.sender] && (msg.sender != owner)) {
        revert();
    }
    _;
  }


  constructor(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }


  /**
   * Owner can allow a crowdsale contract to mint new tokens.
   */
  function setMintAgent(address addr, bool state) onlyOwner canMint public {
    mintAgents[addr] = state;
    emit MintingAgentChanged(addr, state);
  }
  
  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyMintAgent canMint isRunning public returns (bool) {
    require(totalSupply_.add(_amount) <= cap);
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

/**************************************************************************/
/**
 * @title ODXToken
 * @dev Simple ERC20 Token,   
 * Tokens are mintable and burnable.
 * No initial token upon creation
 * Added max token supply
 */
contract ODXToken is CappedMintableToken, StandardBurnableToken {

  string public name; 
  string public symbol; 
  uint8 public decimals; 

  /**
   * @dev set totalSupply_ = 0;
   */
  constructor(
      string _name, 
      string _symbol, 
      uint8 _decimals, 
      uint256 _maxTokens
  ) 
    public 
    CappedMintableToken(_maxTokens) 
  {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    totalSupply_ = 0;
  }
  
  function () payable public {
      revert();
  }

}

/**************************************************************************/

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conform
 * the base architecture for crowdsales. They are *not* intended to be modified / overriden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using &#39;super&#39; where appropiate to concatenate
 * behavior.
 */
 
contract Crowdsale {
  using SafeMath for uint256;

  // The token being sold
  ERC20 public token;

  // Address where funds are collected
  address public wallet;

  // How many token units a buyer gets per wei
  uint256 public rate;

  // Amount of wei raised
  uint256 public weiRaised;

  // Amount of tokens to be minted
  uint256 public tokensToBeMinted;

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event AllocateTokens(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

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

    // calculate token amount to be created
    uint256 tokens = _getTokenAmount(weiAmount);
    
    _preValidatePurchase(_beneficiary, weiAmount, tokens);
    
    //updated token count to be minted
    tokensToBeMinted = tokensToBeMinted.add(tokens);

    // update weiRaised
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit AllocateTokens(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    //_updatePurchasingState(_beneficiary, weiAmount);
    
    _forwardFunds();
    //_postValidatePurchase(_beneficiary, weiAmount);
  }

  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

  /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount, uint256 _tokenToBeMinted) internal {
    require(_beneficiary != address(0));
    //require(_weiAmount >= minContribution);
    
  }

  /**
   * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  //function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    // optional override
  //}

  /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param _beneficiary Address performing the token purchase
   * @param _tokenAmount Number of tokens to be emitted
   */
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.transfer(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param _beneficiary Address receiving the tokens
   * @param _tokenAmount Number of tokens to be purchased
   */
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
  }
  
  /**
   * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
   * @param _beneficiary Address receiving the tokens
   * @param _weiAmount Value in wei involved in the purchase
   */
  //function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
    // optional override
  //}

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    return _weiAmount.mul(rate);
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}
/**************************************************************************/

/**
 * @title CappedCrowdsale
 * @dev Crowdsale with a limit for total contributions.
 * And limits the number of tokens to be minted for the crowdsale
 */
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;
  uint256 public tokenCap;

  /**
   * @dev Constructor, takes maximum amount of wei accepted in the crowdsale.
   * @param _cap Max amount of wei to be contributed
   */
  constructor(uint256 _cap, uint256 _tokenCap) public {
    require(_cap > 0);
    require(_tokenCap > 0);
    cap = _cap;
    tokenCap = _tokenCap;
  }
  

  /**
   * @dev Checks whether the cap has been reached. 
   * @return Whether the cap was reached
   */
  function capReached() public view returns (bool) {
    return weiRaised >= cap;
  }

  /**
   * @dev Checks whether the token cap has been reached. 
   * @return Whether the token cap was reached
   */
  function tokenCapReached() public view returns (bool) {
    return tokensToBeMinted >= tokenCap;
  }

}
/**************************************************************************/
/**
 * @title TimedCrowdsale
 * @dev Crowdsale accepting contributions only within a time frame.
 */
contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public openingTime;
  uint256 public closingTime;

  /**
   * @dev Reverts if not in crowdsale time range.
   */
  modifier onlyWhileOpen {
    require(block.timestamp >= openingTime && block.timestamp <= closingTime);
    _;
  }

  /**
   * @dev Constructor, takes crowdsale opening and closing times.
   * @param _openingTime Crowdsale opening time
   * @param _closingTime Crowdsale closing time
   */
  constructor(uint256 _openingTime, uint256 _closingTime) public {
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
    return block.timestamp > closingTime;
  }

}
/**************************************************************************/
/**
 * @title WhitelistedCrowdsale
 * @dev Crowdsale that whitelists investors.
 */
contract WhitelistedCrowdsale is Crowdsale, Ownable {
  using SafeMath for uint256;

  mapping(address => bool) public whitelist;
  
  mapping (address => bool) public whitelistAgents;
  
  event WhitelistAgentChanged(address addr, bool state);
  event AddToWhitelist(address addr, bool state);
  event RemoveFromWhitelist(address addr, bool state);
  
  modifier onlyWhitelistAgent() {
    // crowdsale contracts or owner are allowed to whitelist address
    if(!whitelistAgents[msg.sender] && (msg.sender != owner)) {
        revert();
    }
    _;
  }
  
  /**
   * @dev Reverts if beneficiary is not whitelisted. Can be used when extending this contract.
   */
  modifier isWhitelisted(address _beneficiary) {
    require(whitelist[_beneficiary]);
    _;
  }

  /**
   * Owner can add an address to the whitelistagents.
   */
  function setWhitelistAgent(address addr, bool state) onlyOwner public {
    whitelistAgents[addr] = state;
    emit WhitelistAgentChanged(addr, state);
  }
  
  
  /**
   * @dev Adds single address to whitelist.
   * @param _beneficiary Address to be added to the whitelist
   */
  function addToWhitelist(address _beneficiary) external onlyWhitelistAgent {
    whitelist[_beneficiary] = true;
    emit AddToWhitelist(_beneficiary, true);
  }

  /**
   * @dev Adds list of addresses to whitelist. Not overloaded due to limitations with truffle testing.
   * @param _beneficiaries Addresses to be added to the whitelist
   */
  function addManyToWhitelist(address[] _beneficiaries) external onlyWhitelistAgent {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
      emit AddToWhitelist(_beneficiaries[i], true);
    }
  }

  /**
   * @dev Removes single address from whitelist.
   * @param _beneficiary Address to be removed to the whitelist
   */
  function removeFromWhitelist(address _beneficiary) external onlyWhitelistAgent {
    whitelist[_beneficiary] = false;
    emit RemoveFromWhitelist(_beneficiary, true);
  }

}
/**************************************************************************/
/**
 * @title CrowdsaleFromOtherSource
 * @dev Crowdsale that accepts contribution from other sources/coins.
 */
contract CrowdsaleFromOtherSource is Crowdsale, Ownable {
  using SafeMath for uint256;

  mapping (address => bool) public allowedAgentsForOtherSource;
  
  mapping(string => uint256) raisedAmount;
  
  event AllowedAgentsForOtherSourceChanged(address addr, bool state);
  
  modifier onlyAllowedAgentForOtherSource() {
    // crowdsale contracts or owner are allowed to whitelist address
    if(!allowedAgentsForOtherSource[msg.sender] && (msg.sender != owner)) {
        revert();
    }
    _;
  }
  
  constructor() public {
  }
  
  /**
   * Owner can add an address to the whitelistagents.
   */
  function setAllowedAgentsForOtherSource(address addr, bool state) onlyOwner public {
    allowedAgentsForOtherSource[addr] = state;
    emit AllowedAgentsForOtherSourceChanged(addr, state);
  }
  
  function validOtherSource(string _newOtherSource) internal view returns (bool) {
    if (keccak256(_newOtherSource)==keccak256("BTC") || keccak256(_newOtherSource)==keccak256("LTC")) return true;
    return false;
  }
  
  function getRaisedAmount(string source) public view returns (uint256){
      return raisedAmount[source];
  }
  
}
/**************************************************************************/
/**
 * @title ETHRateAgents
 * @dev set addresses that can call the update rate function
 */
contract ETHRateAgents is Ownable {
  using SafeMath for uint256;

  mapping (address => bool) public ethRateAgents;
  
  event ETHRateAgentChanged(address addr, bool state);
  
  modifier onlyETHRateAgent() {
    // crowdsale contracts or owner are allowed to update eth rate
    if(!ethRateAgents[msg.sender] && (msg.sender != owner)) {
        revert();
    }
    _;
  }
  
  /**
   * Owner can add an address to the ethRateAgents.
   */
  function setETHRateAgent(address addr, bool state) onlyOwner public {
    ethRateAgents[addr] = state;
    emit ETHRateAgentChanged(addr, state);
  }
  
}
/**************************************************************************/
/**
 * @title CrowdsaleRules
 * @dev Crowdsale that locks tokens from withdrawal until it ends and makes sure that only whitelisted address can withdraw tokens.
 * Tokens are minted every withdrawal/sendtoken function.
 * gives bonus tokens to early investors
 * 061118 - removed presale
 * 061218 - required whitelisting before accepting funds
 * 061418 - removed use of vault
 * 080118 - removed unused events 
 * 100518 - removed capping of weiraised.  Added CrowdsaleFromOtherSource
 * 102318 - added agents for update rate.
 * 102518 - removed goal checking
 */
contract CrowdsaleNewRules is CappedCrowdsale, TimedCrowdsale, WhitelistedCrowdsale, CrowdsaleFromOtherSource, ETHRateAgents {
  using SafeMath for uint256;

  // minimum amount of funds to be raised in weis
  //uint256 public goal;

  // minimum contribution
  uint256 public minContribution;

  mapping(address => uint256) public balances;
  
  event DeliverTokens(address indexed sender, address indexed beneficiary, uint256 value);
  event UpdateRate(address indexed sender, uint256 rate);
  
  event AllocateTokensFromOtherSource(string indexed coinType, address indexed beneficiary, uint256 value, uint256 amount);


  /**
   * @dev Constructor, sets goal, additionalTokenMultiplier and minContribution
   * @param _minContribution : minimum contribution
   */
  constructor(uint256 _minContribution) public {
    require(_minContribution > 0);
    minContribution = _minContribution;
  }

  /**
   * @dev investors can get their tokens using this method.
   */
  function withdrawTokensByInvestors() external isWhitelisted(msg.sender) {
    _sendTokens(msg.sender);
  }

  /**
   * @dev used by owner to send tokens to investors, calls the sendtokens function
   */
  function sendTokensToInvestors(address _beneficiary) external onlyOwner isWhitelisted(_beneficiary) {
    _sendTokens(_beneficiary);
  }

  /**
   * @dev Withdraw tokens only after crowdsale ends and only if the goal is reached.
   */
  function _sendTokens(address _beneficiary) internal {
    require(hasClosed());
    uint256 amount = balances[_beneficiary];
    require(amount > 0);
    balances[_beneficiary] = 0;
    _deliverTokens(_beneficiary, amount);
    
    emit DeliverTokens(
        msg.sender,
        _beneficiary,
        amount
    );
  }
  
  /**
   * @dev Overrides parent by storing balances instead of issuing tokens right away and adds bonus tokens if applicable.
   * @param _beneficiary Token purchaser
   * @param _tokenAmount Amount of tokens purchased
   */
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    balances[_beneficiary] = balances[_beneficiary].add(_tokenAmount);
  }
  
  /**
   * @dev Overrides delivery by minting tokens upon purchase.
   * @param _beneficiary Token purchaser
   * @param _tokenAmount Number of tokens to be minted
   */
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    require(ODXToken(token).mint(_beneficiary, _tokenAmount));
    tokensToBeMinted = tokensToBeMinted.sub(_tokenAmount);
    //require(MintableToken(token).mint(wallet, _tokenAmount));
  }
  
  /**
   * @dev Extend parent behavior requiring to be within contributing period
   * @param _beneficiary Token purchaser
   * @param _weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount, uint256 _tokensToBeMinted) internal onlyWhileOpen isWhitelisted(_beneficiary) {
    require(_weiAmount >= minContribution);
    //require(weiRaised.add(_weiAmount) <= cap);
    require(tokensToBeMinted.add(_tokensToBeMinted) <= tokenCap);
    super._preValidatePurchase(_beneficiary, _weiAmount, _tokensToBeMinted);
  }


  /**
   * @dev change rate value
   * @param _newrate new token conversion rate
   */
  function updateRate(uint256 _newrate) external onlyETHRateAgent() {
    require(_newrate > 0);
    rate = _newrate;
    
    emit UpdateRate(
        msg.sender,
        _newrate
    );
  }


  /**
   * @dev Extend parent behavior requiring to be within contributing period
   * @param _beneficiary Token purchaser
   * @param _tokensToBeMinted tokens to be minted
   */
  function addPurchaseFromOtherSource(address _beneficiary, string _coinType, uint256 _amount, uint256 _tokensToBeMinted) public onlyWhileOpen isWhitelisted(_beneficiary) onlyAllowedAgentForOtherSource() {
    require(_amount >= 0);
    require(_tokensToBeMinted >= 0);
    require(validOtherSource(_coinType));
    require(tokensToBeMinted.add(_tokensToBeMinted) <= tokenCap);
    
    tokensToBeMinted = tokensToBeMinted.add(_tokensToBeMinted);
    balances[_beneficiary] = balances[_beneficiary].add(_tokensToBeMinted);
    emit AllocateTokensFromOtherSource(_coinType, _beneficiary, _amount, _tokensToBeMinted);
    raisedAmount[_coinType] = raisedAmount[_coinType] + _amount;
    
  }
}
/**************************************************************************/

/**
 * @title ODXCrowdsale
 * @dev This is a crowdsale that is capped, timed, token are delivered after the crowdsale to all whitelisted addresses (kyc)
 * crowdsale will run for xx days.
 * Added minimum contribution.
 */
contract ODXCrowdsale is CrowdsaleNewRules {
  constructor(
    uint256 _rate,
    address _wallet,
    uint256 _cap,
    uint256 _tokenCap,
    ODXToken _token,
    uint256 _minContribution,
    uint256 _openingTime
  )
    public
    Crowdsale(_rate, _wallet, _token)
    CappedCrowdsale(_cap, _tokenCap)
    CrowdsaleNewRules(_minContribution)
    TimedCrowdsale(_openingTime, now + 5 days)
    //TimedCrowdsale(now, now + 1 hours)
    CrowdsaleFromOtherSource()
  {
    require(_rate > 0);
  }
  
}