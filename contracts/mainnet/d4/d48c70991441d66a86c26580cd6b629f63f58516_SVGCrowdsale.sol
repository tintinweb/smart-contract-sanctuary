pragma solidity ^0.4.24;


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


/**
 * @title SVGCrowdsale
 * @dev SVGCrowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conform
 * the base architecture for crowdsales. They are *not* intended to be modified / overriden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using &#39;super&#39; where appropiate to concatenate
 * behavior.
 */
contract SVGCrowdsale {
    
  using SafeMath for uint256;

  // The token being sold
  ERC20 public token;

  // Address where funds are collected
  address public wallet;

  // Amount of wei raised
  uint256 public weiRaised;
  
  //current round total
  uint256 public currentRound;
  
  //block-time when it was deployed
  uint startTime = now;
  
  //Time Crowdsale completed
  uint256 public completedAt;
  
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
  
  event LogFundingSuccessful(
      uint _totalRaised
    );

  /**
   * @param _wallet Address where collected funds will be forwarded to
   * @param _token Address of the token being sold
   */
  constructor(address _wallet, ERC20 _token) public {
    require(_wallet != address(0));
    require(_token != address(0));

    wallet = _wallet;
    token = _token;
  }
  
  //rate
    uint[5] tablePrices = [
        13334,
        11429,
        10000,
        9091,
        8000
    ];  
  
  //caps
    uint256[5] caps = [
        10000500e18,
        10000375e18,
        10000000e18,
        10000100e18,
        10000000e18
    ];  
  
  //5 tranches
  enum Tranches {
        Round1,
        Round2,
        Round3,
        Round4,
        Round5,
        Successful
  }
  
  Tranches public tranches = Tranches.Round1; //Set Private stage
  

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
    uint256 tokens = getTokenAmount(weiAmount);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    processPurchase(_beneficiary, tokens);
    
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    updatePurchasingState(_beneficiary, weiAmount);

    forwardFunds();
    
    checkIfFundingCompleteOrExpired();
    
    postValidatePurchase(_beneficiary, weiAmount);
  }
  
  /**
   *  @dev This method update the current state of tranches and currentRound.
   */
  
  function checkIfFundingCompleteOrExpired() internal {
      
    if(tranches != Tranches.Successful){
        
        if(currentRound > caps[0] && tranches == Tranches.Round1){//plus 8weeks
            tranches = Tranches.Round2;
            currentRound = 0;    
        }
        else if(currentRound > caps[1] && tranches == Tranches.Round2){ //plus 4weeks
            tranches = Tranches.Round3;
            currentRound = 0;    
        }
        else if(currentRound > caps[2] && tranches == Tranches.Round3){ //plus 3weeks
            tranches = Tranches.Round4;
            currentRound = 0;    
        }
        else if(currentRound > caps[3] && tranches == Tranches.Round4){ //plus 3weeks
            tranches = Tranches.Round5;
            currentRound = 0; 
        }
    }
    else {
        tranches = Tranches.Successful;
        completedAt = now;
    }
      
  }

  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

  /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

  /**
   * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal{
    // optional override
  }

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
  function processPurchase(address _beneficiary, uint256 _tokenAmount )internal{
    _deliverTokens(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
   * @param _beneficiary Address receiving the tokens
   * @param _weiAmount Value in wei involved in the purchase
   */
  function updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
    // optional override
  }

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    
    uint256 tokenBought;
    
    if(tranches == Tranches.Round1){
        
        tokenBought = _weiAmount.mul(tablePrices[0]);
        require(SafeMath.add(currentRound, tokenBought) <= caps[0]);
        
    }else if(tranches == Tranches.Round2){
        
        tokenBought = _weiAmount.mul(tablePrices[1]);
        require(SafeMath.add(currentRound, tokenBought) <= caps[1]);            
        
    }else if(tranches == Tranches.Round3){
        
        tokenBought = _weiAmount.mul(tablePrices[2]);
        require(SafeMath.add(currentRound, tokenBought) <= caps[2]);
        
    }else if(tranches == Tranches.Round4){
        
        tokenBought = _weiAmount.mul(tablePrices[3]);
        require(SafeMath.add(currentRound, tokenBought) <= caps[3]);
        
    }else if(tranches == Tranches.Round5){
        
        tokenBought = _weiAmount.mul(tablePrices[4]);
        require(SafeMath.add(currentRound, tokenBought) <= caps[4]); 
        
    }else{
        revert();
    }
    
    return tokenBought;    
    
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }
  
}