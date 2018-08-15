pragma solidity 0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  // it is recommended to define functions which can neither read the state of blockchain nor write in it as pure instead of constant

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
    address public creater;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    function Ownable(address _owner) public {
        creater = msg.sender;
        if (_owner != 0) {
            owner = _owner;

        }
        else {
            owner = creater;
        }

    }
    /**
    * @dev Throws if called by any account other than the owner.
    */

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier isCreator() {
        require(msg.sender == creater);
        _;
    }

   

}


contract TravelHelperToken {
    function transfer (address, uint) public pure { }
    function burnTokensForSale() public returns (bool);
    function saleTransfer(address _to, uint256 _value) public returns (bool) {}
    function finalize() public pure { }
}

contract Crowdsale is Ownable {
  using SafeMath for uint256;

  // The token being sold
  TravelHelperToken public token;
  
  uint public ethPrice;

  // Address where funds are collected
  address public wallet;

  // Amount of wei raised
  uint256 public weiRaised;
  bool public crowdsaleStarted = false;
  uint256 public preIcoCap = uint256(1000000000).mul(1 ether);
  uint256 public icoCap = uint256(1500000000).mul(1 ether);
  uint256 public preIcoTokensSold = 0;
  uint256 public discountedIcoTokensSold = 0;
  uint256 public icoTokensSold = 0;
  
  
  uint256 public mainTokensPerDollar = 400 * 1 ether;
  
  uint256 public totalRaisedInCents;
  uint256 public presaleTokensPerDollar = 533.3333 * 1 ether;
  uint256 public discountedTokensPerDollar = 444.4444 * 1 ether;
  uint256 public hardCapInCents = 525000000;
  uint256 public preIcoStartBlock;
  uint256 public discountedIcoStartBlock;
  uint256 public mainIcoStartBlock;
  uint256 public mainIcoEndBlock;
  uint public preSaleDuration =  (7 days)/(15);
  uint public discountedSaleDuration = (15 days)/(15); 
  uint public mainSaleDuration = (15 days)/(15); 
  
  
  modifier CrowdsaleStarted(){
      require(crowdsaleStarted);
      _;
  }
 
  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  /**
   * @param _newOwner Address who has special power to change the ether price in cents according to the market price
   * @param _wallet Address where collected funds will be forwarded to
   * @param _token Address of the token being sold
   *  @param _ethPriceInCents ether price in cents
   */
  function Crowdsale(address _newOwner, address _wallet, TravelHelperToken _token,uint256 _ethPriceInCents) Ownable(_newOwner) public {
    require(_wallet != address(0));
    require(_token != address(0));
    require(_ethPriceInCents > 0);
    wallet = _wallet;
    owner = _newOwner;
    token = _token;
    ethPrice = _ethPriceInCents; //ethPrice in cents
  }

  function startCrowdsale() onlyOwner public returns (bool) {
      require(!crowdsaleStarted);
      crowdsaleStarted = true;
      preIcoStartBlock = block.number;
      discountedIcoStartBlock = block.number + preSaleDuration;
      mainIcoStartBlock = block.number + preSaleDuration + discountedSaleDuration;
      mainIcoEndBlock = block.number + preSaleDuration + discountedSaleDuration + mainSaleDuration;
      
  }
  
  // -----------------------------------------
  // Crowdsale external interface
  // -----------------------------------------

  /**
   * @dev fallback function ***DO NOT OVERRIDE***
   */
  function () external payable {
    require(msg.sender != owner);
     buyTokens(msg.sender);
  }

  /**
   * @param _beneficiary Address performing the token purchase
   */
  function buyTokens(address _beneficiary) CrowdsaleStarted public payable {
    uint256 weiAmount = msg.value;
    require(weiAmount > 0);
    require(ethPrice > 0);
    uint256 usdCents = weiAmount.mul(ethPrice).div(1 ether); 

    // calculate token amount to be created
    uint256 tokens = _getTokenAmount(usdCents);

    _validateTokensLimits(tokens);

    // update state
    weiRaised = weiRaised.add(weiAmount);
    totalRaisedInCents = totalRaisedInCents.add(usdCents);
    _processPurchase(_beneficiary,tokens);
     emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
    _forwardFunds();
  }
  
 
   /**
   * @dev sets the value of ether price in cents.Can be called only by the owner account.
   * @param _ethPriceInCents price in cents .
   */
 function setEthPriceInDollar(uint _ethPriceInCents) onlyOwner public returns(bool) {
      ethPrice = _ethPriceInCents;
      return true;
  }

  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------


  /**
   * @dev Validation of the capped restrictions.
   * @param _tokens tokens amount
   */
  function _validateTokensLimits(uint256 _tokens) internal {
    if (block.number > preIcoStartBlock && block.number < discountedIcoStartBlock) {
      preIcoTokensSold = preIcoTokensSold.add(_tokens);
      require(preIcoTokensSold <= preIcoCap && totalRaisedInCents <= hardCapInCents);
    } else if(block.number >= discountedIcoStartBlock && block.number < mainIcoStartBlock ) {
       require(discountedIcoTokensSold <= icoCap && totalRaisedInCents <= hardCapInCents);
    } else if(block.number >= mainIcoStartBlock && block.number < mainIcoEndBlock ) {
      icoTokensSold = icoTokensSold.add(_tokens);
      require(icoTokensSold <= icoCap && totalRaisedInCents < hardCapInCents);
    } else {
      revert();
    }
  }

  /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param _beneficiary Address performing the token purchase
   * @param _tokenAmount Number of tokens to be emitted
   */
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    require(token.saleTransfer(_beneficiary, _tokenAmount));
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
   * @param _usdCents Value in usd cents to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _usdCents
   */
  function _getTokenAmount(uint256 _usdCents) CrowdsaleStarted public view returns (uint256) {
    uint256 tokens;
    
    if (block.number > preIcoStartBlock && block.number < discountedIcoStartBlock ) tokens = _usdCents.div(100).mul(presaleTokensPerDollar);
    if (block.number >= discountedIcoStartBlock && block.number < mainIcoStartBlock )  tokens = _usdCents.div(100).mul(discountedTokensPerDollar);
    if (block.number >= mainIcoStartBlock && block.number < mainIcoEndBlock )  tokens = _usdCents.div(100).mul(mainTokensPerDollar);
    

    return tokens;
  }
  
   /**
   * @return returns the current stage of sale
   */
    function getStage() public view returns (string) {
        if(!crowdsaleStarted){
            return &#39;Crowdsale not started yet&#39;;
        }
        if (block.number > preIcoStartBlock && block.number < discountedIcoStartBlock )
        {
            return &#39;Presale&#39;;
        }
        else if (block.number >= discountedIcoStartBlock  && block.number < mainIcoStartBlock ) {
            return &#39;Discounted sale&#39;;
        }
        else if (block.number >= mainIcoStartBlock && block.number < mainIcoEndBlock )
        {
            return &#39;Crowdsale&#39;;
        }
        else if(block.number > mainIcoEndBlock)
        {
            return &#39;Sale ended&#39;;
        }
      
     }
      
    /**
       * @dev burn the unsold tokens.
       
       */
     function burnTokens() public onlyOwner {
        require(block.number > mainIcoEndBlock);
        require(token.burnTokensForSale());
      }
        
  /**
   * @dev finalize the crowdsale.After finalizing ,tokens transfer can be done.
   */
  function finalizeSale() public onlyOwner {
    require(block.number > mainIcoEndBlock);
    token.finalize();
  }
  
  
  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}