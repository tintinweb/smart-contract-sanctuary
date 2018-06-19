pragma solidity 0.4.23;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0); // Solidity automatically throws when dividing by 0
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

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint256);
    function balanceOf(address tokenOwner) public constant returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);

    function mint(address _to, uint256 _amount) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        require(owner == msg.sender);
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

/**
 * @title AllstocksCrowdsale
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

contract AllstocksCrowdsale is Owned {
  using SafeMath for uint256;

  // The token being sold
  //ERC20Interface public token;
  address public token;

  // Address where funds are collected
  address public ethFundDeposit; 

  // How many token units a buyer gets per wei // starts with 625 Allstocks tokens per 1 ETH
  uint256 public tokenExchangeRate = 625;                         
  
  // 25m hard cap
  uint256 public tokenCreationCap =  25 * (10**6) * 10**18; // 25m maximum; 

  //2.5m softcap
  uint256 public tokenCreationMin =  25 * (10**5) * 10**18; // 2.5m minimum

  // Amount of wei raised
  uint256 public _raised = 0;
  
  // switched to true in after setup
  bool public isActive = false;                 
 
  //start time 
  uint256 public fundingStartTime = 0;
   
  //end time
  uint256 public fundingEndTime = 0;

  // switched to true in operational state
  bool public isFinalized = false; 
  
  //refund list - will hold a list of all contributers 
  mapping(address => uint256) public refunds;

  /**
   * Event for token Allocate logging
   * @param allocator for the tokens
   * @param beneficiary who got the tokens
   * @param amount amount of tokens purchased
   */
  event TokenAllocated(address indexed allocator, address indexed beneficiary, uint256 amount);

  event LogRefund(address indexed _to, uint256 _value);

  constructor() public {
      tokenExchangeRate = 625;
  }

  function setup (uint256 _fundingStartTime, uint256 _fundingEndTime, address _token) onlyOwner external {
    require (isActive == false); 
    require (isFinalized == false); 			        	   
    require (msg.sender == owner);                // locks finalize to the ultimate ETH owner
    require(_fundingStartTime > 0);
    require(_fundingEndTime > 0 && _fundingEndTime > _fundingStartTime);
    require(_token != address(0));

    isFinalized = false;                          // controls pre through crowdsale state
    isActive = true;                              // set sale status to be true
    ethFundDeposit = owner;                       // set ETH wallet owner 
    fundingStartTime = _fundingStartTime;
    fundingEndTime = _fundingEndTime;
    //set token
    token = _token;
  }

  /// @dev send funding to safe wallet if minimum is reached 
  function vaultFunds() public onlyOwner {
    require(msg.sender == owner);                    // Allstocks double chack
    require(_raised >= tokenCreationMin);            // have to sell minimum to move to operational 
    ethFundDeposit.transfer(address(this).balance);  // send the eth to Allstocks
  }  

  // -----------------------------------------
  // Crowdsale external interface
  // -----------------------------------------

  /**
   * @dev fallback function ***DO NOT OVERRIDE***
   */
  function () external payable {
    buyTokens(msg.sender, msg.value);
  }

  /**
   * @dev low level token purchase ***DO NOT OVERRIDE***
   * @param _beneficiary Address performing the token purchase
   */
  function buyTokens(address _beneficiary, uint256 _value) internal {
    _preValidatePurchase(_beneficiary, _value);
    // calculate token amount to be created
    uint256 tokens = _getTokenAmount(_value);
    // update state
    uint256 checkedSupply = _raised.add(tokens);
    //check that we are not over cap
    require(checkedSupply <= tokenCreationCap);
    _raised = checkedSupply;
    bool mined = ERC20Interface(token).mint(_beneficiary, tokens);
    require(mined);
    //add sent eth to refunds list
    refunds[_beneficiary] = _value.add(refunds[_beneficiary]);  // safeAdd 
    emit TokenAllocated(this, _beneficiary, tokens); // log it
    //forward funds to deposite only in minimum was reached
    if(_raised >= tokenCreationMin) {
      _forwardFunds();
    }
  }

  // @dev method for manageing bonus phases 
	function setRate(uint256 _value) external onlyOwner {
    require (isActive == true);
    require(msg.sender == owner); // Allstocks double check owner   
    // Range is set between 500 to 625, based on the bonus program stated in whitepaper.
    // Upper range is set to 1500 (x3 times margin based on ETH price) .
    require (_value >= 500 && _value <= 1500); 
    tokenExchangeRate = _value;
  }

  // @dev method for allocate tokens to beneficiary account 
  function allocate(address _beneficiary, uint256 _value) public onlyOwner returns (bool success) {
    require (isActive == true);          // sale have to be active
    require (_value > 0);                // value must be greater then 0 
    require (msg.sender == owner);       // Allstocks double chack 
    require(_beneficiary != address(0)); // none empty address
    uint256 checkedSupply = _raised.add(_value); 
    require(checkedSupply <= tokenCreationCap); //check that we dont over cap
    _raised = checkedSupply;
    bool sent = ERC20Interface(token).mint(_beneficiary, _value); // mint using ERC20 interface
    require(sent); 
    emit TokenAllocated(this, _beneficiary, _value); // log it
    return true;
  }

  //claim back token ownership 
  function transferTokenOwnership(address _newTokenOwner) public onlyOwner {
    require(_newTokenOwner != address(0));
    require(owner == msg.sender);
    Owned(token).transferOwnership(_newTokenOwner);
  }

  /// @dev Allows contributors to recover their ether in the case of a failed funding campaign.
  function refund() external {
    require (isFinalized == false);  // prevents refund if operational
    require (isActive == true);      // only if sale is active
    require (now > fundingEndTime);  // prevents refund until sale period is over
    require(_raised < tokenCreationMin);  // no refunds if we sold enough
    require(msg.sender != owner);         // Allstocks not entitled to a refund
    //get contribution amount in eth
    uint256 ethValRefund = refunds[msg.sender];
    //refund should be greater then zero
    require(ethValRefund > 0);
    //zero sender refund balance
    refunds[msg.sender] = 0;
    //check user balance
    uint256 allstocksVal = ERC20Interface(token).balanceOf(msg.sender);
    //substruct from total raised - please notice main assumption is that tokens are not tradeble at this stage.
    _raised = _raised.sub(allstocksVal);               // extra safe
    //send eth back to user
    msg.sender.transfer(ethValRefund);                 // if you&#39;re using a contract; make sure it works with .send gas limits
    emit LogRefund(msg.sender, ethValRefund);          // log it
  }

   /// @dev Ends the funding period and sends the ETH home
  function finalize() external onlyOwner {
    require (isFinalized == false);
    require(msg.sender == owner); // Allstocks double chack  
    require(_raised >= tokenCreationMin);  // have to sell minimum to move to operational
    require(_raised > 0);

    if (now < fundingEndTime) {    //if try to close before end time, check that we reach max cap
      require(_raised >= tokenCreationCap);
    }
    else 
      require(now >= fundingEndTime); //allow finilize only after time ends
    
    //transfer token ownership back to original owner
    transferTokenOwnership(owner);
    // move to operational
    isFinalized = true;
    vaultFunds();  // send the eth to Allstocks
  }

  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

  /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) view internal {
    require(now >= fundingStartTime);
    require(now < fundingEndTime); 
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    return _weiAmount.mul(tokenExchangeRate);
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds() internal {
    ethFundDeposit.transfer(msg.value);
  }
}