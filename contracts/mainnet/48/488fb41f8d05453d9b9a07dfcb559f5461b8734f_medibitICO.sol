contract Ownable {
  address public owner;



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


}

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

contract medibitICO is Pausable {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

mapping (address => mapping (address => uint256)) internal allowed;


  //Gas/GWei
  uint constant public minPublicContribAmount = 1 ether;
  

  // The token being sold
  medibitToken public token;
  uint256 constant public tokenDecimals = 18;


  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime; 
  uint256 public endTime; 


  // need to be enabled to allow investor to participate in the ico
  bool public icoEnabled;

  // address where funds are collected
  address public walletOne;

  // amount of raised money in wei
  uint256 public weiRaised;

  // totalSupply
  uint256 public totalSupply = 50000000000 * (10 ** tokenDecimals);
  uint256 constant public toekensForBTCandBonus = 12500000000 * (10 ** tokenDecimals);
  uint256 constant public toekensForTeam = 5000000000 * (10 ** tokenDecimals);
  uint256 constant public toekensForOthers = 22500000000 * (10 ** tokenDecimals);


  //ICO tokens
  //Is calcluated as: initialICOCap + preSaleCap
  uint256 public icoCap;
  uint256 public icoSoldTokens;
  bool public icoEnded = false;

  address constant public walletTwo = 0x938Ee925D9EFf6698472a19EbAc780667999857B;
  address constant public walletThree = 0x09E72590206d652BD1aCDB3A8e358AeB3f21513A;

  //Sale rates

  uint256 constant public STANDARD_RATE = 1500000;

  event Burn(address indexed from, uint256 value);


  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);



  function medibitICO(address _walletOne) public {
    require(_walletOne != address(0));
    token = createTokenContract();
    
    //send all dao tokens to multiwallet
    uint256 tokensToWallet1 = toekensForBTCandBonus;
    uint256 tokensToWallet2 = toekensForTeam;
    uint256 tokensToWallet3 = toekensForOthers;
    
    walletOne = _walletOne;
    
    token.transfer(walletOne, tokensToWallet1);
    token.transfer(walletTwo, tokensToWallet2);
    token.transfer(walletThree, tokensToWallet3);
  }


  //
  // Token related operations
  //

  // creates the token to be sold.
  // override this method to have crowdsale of a specific mintable token.
  function createTokenContract() internal returns (medibitToken) {
    return new medibitToken();
  }


  // enable token tranferability
  function enableTokenTransferability() external onlyOwner {
    require(token != address(0));
    token.unpause();
  }

  // disable token tranferability
  function disableTokenTransferability() external onlyOwner {
    require(token != address(0));
    token.pause();
  }

  // transfer token to owner account for burn
   function transferUnsoldIcoTokens() external onlyOwner {
    require(token != address(0));
    uint256 unsoldTokens = icoCap.sub(icoSoldTokens);
    token.transfer(walletOne, unsoldTokens);
   }

  //
  // ICO related operations
  //

  // set multisign wallet
  function setwalletOne(address _walletOne) external onlyOwner{
    // need to be set before the ico start
    require(!icoEnabled || now < startTime);
    require(_walletOne != address(0));
    walletOne = _walletOne;
  }


  // set contribution dates
  function setContributionDates(uint64 _startTime, uint64 _endTime) external onlyOwner{
    require(!icoEnabled);
    require(_startTime >= now);
    require(_endTime >= _startTime);
    startTime = _startTime;
    endTime = _endTime;
  }


  // enable ICO, need to be true to actually start ico
  // multisign wallet need to be set, because once ico started, invested funds is transfered to this address
  // once ico is enabled, following parameters can not be changed anymore:
  // startTime, endTime, soldPreSaleTokens
  function enableICO() external onlyOwner{
    icoEnabled = true;
    icoCap = totalSupply;
  }

  // fallback function can be used to buy tokens
  function () payable whenNotPaused public {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) public payable whenNotPaused {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;
    uint256 returnWeiAmount;

    // calculate token amount to be created
    uint rate = getRate();
    assert(rate > 0);
    uint256 tokens = weiAmount.mul(rate);

    uint256 newIcoSoldTokens = icoSoldTokens.add(tokens);

    if (newIcoSoldTokens > icoCap) {
        newIcoSoldTokens = icoCap;
        tokens = icoCap.sub(icoSoldTokens);
        uint256 newWeiAmount = tokens.div(rate);
        returnWeiAmount = weiAmount.sub(newWeiAmount);
        weiAmount = newWeiAmount;
    }

    // update state
    weiRaised = weiRaised.add(weiAmount);

    token.transfer(beneficiary, tokens);
    icoSoldTokens = newIcoSoldTokens;
    if (returnWeiAmount > 0){
        msg.sender.transfer(returnWeiAmount);
    }

    emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    walletOne.transfer(address(this).balance);
  }



  // @return true if the transaction can buy tokens
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonMinimumPurchase;
    bool icoTokensAvailable = icoSoldTokens < icoCap;
 
    nonMinimumPurchase = msg.value >= minPublicContribAmount;
    

    return !icoEnded && icoEnabled && withinPeriod && nonMinimumPurchase && icoTokensAvailable;
  }



  // end ico by owner, not really needed in normal situation
  function endIco() external onlyOwner {
    icoEnded = true;
    // send unsold tokens to multi-sign wallet
    uint256 unsoldTokens = icoCap.sub(icoSoldTokens);
    token.transfer(walletOne, unsoldTokens);
  }

  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    return (icoEnded || icoSoldTokens >= icoCap || now > endTime);
  }


  function getRate() public constant returns(uint){
    require(now >= startTime);
      return STANDARD_RATE;

  }

  // drain all eth for owner in an emergency situation
  function drain() external onlyOwner {
    owner.transfer(address(this).balance);
  }

}







contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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



contract PausableToken is StandardToken, Pausable {
  /**
   * @dev modifier to allow actions only when the contract is not paused or
   * the sender is the owner of the contract
   */
  modifier whenNotPausedOrOwner() {
    require(msg.sender == owner || !paused);
    _;
  }

  function transfer(address _to, uint256 _value) public whenNotPausedOrOwner returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPausedOrOwner returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPausedOrOwner returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPausedOrOwner returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPausedOrOwner returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }

}

contract medibitToken is PausableToken {
  string constant public name = "MEDIBIT";
  string constant public symbol = "MEDIBIT";
  uint256 constant public decimals = 18;
  uint256 constant TOKEN_UNIT = 10 ** uint256(decimals);
  uint256 constant INITIAL_SUPPLY = 50000000000 * TOKEN_UNIT;


  function medibitToken() public {
    // Set untransferable by default to the token
    paused = true;
    // asign all tokens to the contract creator
    totalSupply = INITIAL_SUPPLY;
    emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    balances[msg.sender] = INITIAL_SUPPLY;
  }

}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}