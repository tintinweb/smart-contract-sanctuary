/**
 *Submitted for verification at BscScan.com on 2021-07-13
*/

pragma solidity ^0.4.26;

//import "./tokenbnb.sol";



library SafeMath {


  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    assert(c / _a == _b);

    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    assert(c >= _a);

    return c;
  }
}


/**
 * @title IBEP20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract IBEP20 {
  function totalSupply() public view returns (uint256);

  function balanceOf(address _who) public view returns (uint256);

  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transfer(address _to, uint256 _value) public returns (bool);

  function approve(address _spender, uint256 _value)
    public returns (bool);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


/**
 * @title Standard IBEP20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is IBEP20 {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  mapping (address => mapping (address => uint256)) internal allowed;

  uint256 totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
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


  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }


  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

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
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }


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


  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}



library SafeIBEP20 {
  function safeTransfer(
    IBEP20 _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    IBEP20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    IBEP20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}



/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conform
 * the base architecture for crowdsales. They are *not* intended to be modified / overridden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using 'super' where appropriate to concatenate
 * behavior.
 */
contract Crowdsale {
  using SafeMath for uint256;
  using SafeIBEP20 for IBEP20;

  // The token being sold
  IBEP20 public token;
  

  // Address where funds are collected
  address public wallet;

  // How many token units a buyer gets per wei.
  // The rate is the conversion between wei and the smallest and indivisible token unit.
  // So, if you are using a rate of 1 with a  token with 3 decimals called TOK
  // 1 wei will give you 1 unit, or 0.001 TOK.
  uint256 public rate;
    uint256 public maxpurchase;


  // Amount of wei raised
  uint256 public weiRaised;
  bool public isFunding;



  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );


  constructor(uint256 _rate, uint256 _maxpurchase, address _wallet, IBEP20 _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));
    
    
    rate = _rate;
    wallet = _wallet;
    token = _token;
    isFunding = true;
    maxpurchase= _maxpurchase;
    
  }

  
  function () external payable {
    buyTokens(msg.sender);
  }


//Change the rate


    // update the ETH/COIN rate
    function updateRate(uint256 Newrate) external {
        require(msg.sender==wallet);
        require(isFunding);
        rate = Newrate;
    }


    function updateMaxPurchase (uint256 _newMaxPurchase) external {
        require(msg.sender==wallet);
        require(isFunding);
        maxpurchase = _newMaxPurchase;
    }
    
    
function closeSale() external {
      require(msg.sender==wallet);
     isFunding= false;
     
    }



//Close the Sale



  function buyTokens(address _beneficiary) public payable {

    require(isFunding==true);


//Anti Whale mechamism

require(token.balanceOf(msg.sender)<= maxpurchase*1000000000000000000);



//New

    uint256 weiAmount = msg.value;
    
    require(weiAmount <= maxpurchase*1000000000000000000);

    
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

  //  _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
//    _postValidatePurchase(_beneficiary, weiAmount);
  }




  function _preValidatePurchase (
    address _beneficiary,
    uint256 _weiAmount
    
  ) pure
    internal
  {
      

    require(_beneficiary != address(0));
    require(_weiAmount != 0);
    

  }




  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    token.safeTransfer(_beneficiary, _tokenAmount);
  }

  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    _deliverTokens(_beneficiary, _tokenAmount);
  }


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


contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public openingTime;
  uint256 public closingTime;

  modifier onlyWhileOpen {
    // solium-disable-next-line security/no-block-members
    require(block.timestamp >= openingTime && block.timestamp <= closingTime);
    _;
  }

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


}


contract AllowanceCrowdsale is Crowdsale {
  using SafeMath for uint256;
  using SafeIBEP20 for IBEP20;

  address public tokenWallet;


  constructor(address _tokenWallet) public {
    require(_tokenWallet != address(0));
    tokenWallet = _tokenWallet;
  }


  function remainingTokens() public view returns (uint256) {
    return token.allowance(tokenWallet, this);
  }

  
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    token.safeTransferFrom(tokenWallet, _beneficiary, _tokenAmount);
  }
}



contract IncreasingPriceCrowdsale is TimedCrowdsale {
  using SafeMath for uint256;

  uint256 public initialRate;
  uint256 public finalRate;

  constructor(uint256 _initialRate, uint256 _finalRate) public {
    require(_initialRate >= _finalRate);
    require(_finalRate > 0);
    initialRate = _initialRate;
    finalRate = _finalRate;
  }

  function getCurrentRate() public view returns (uint256) {
    // solium-disable-next-line security/no-block-members
    uint256 elapsedTime = block.timestamp.sub(openingTime);
    uint256 timeRange = closingTime.sub(openingTime);
    uint256 rateRange = initialRate.sub(finalRate);
    return initialRate.sub(elapsedTime.mul(rateRange).div(timeRange));
  }

  function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256)
  {
    uint256 currentRate = getCurrentRate();
    return currentRate.mul(_weiAmount);
  }

}



contract SBTCrowdsale is AllowanceCrowdsale, IncreasingPriceCrowdsale {

  event CrowdsaleCreated(address owner, uint256 openingTime, uint256 closingTime, uint256 rate);

  constructor(
    uint256 _openingTime,
    uint256 _closingTime,
    uint256 _rate,
    uint256 _maxpurchase,
    uint256 _ratePublic,
    address _wallet,
    StandardToken _token,
    address _tokenHolderWallet
  )
    public
    Crowdsale(_rate, _maxpurchase, _wallet, _token)
    AllowanceCrowdsale(_tokenHolderWallet)
    TimedCrowdsale(_openingTime, _closingTime)
    IncreasingPriceCrowdsale(_rate, _ratePublic)
  {
    emit CrowdsaleCreated(
      msg.sender, 
      _openingTime, 
      _closingTime, 
      _rate);
  }

  function getCurrentRate() public view returns (uint256) {
    // solium-disable-next-line security/no-block-members
    uint256 elapsedTime = block.timestamp.sub(openingTime);
    uint256 timeRange = closingTime.sub(openingTime);
    if (elapsedTime < timeRange.div(2)) {
      return initialRate;
    } else {
      return finalRate;
    }
  }
}