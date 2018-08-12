// Ethertote - Official Token Sale Contract
// 06.08.18
//
// Any unsold tokens can be sent directly to the TokenBurn Contract
// by anyone once the Token Sale is complete - 
// this is a PUBLIC function that anyone can call!!
//
// All Eth raised during the token sale is automatically sent to the 
// EthRaised smart contract for distribution


pragma solidity ^0.4.24;

///////////////////////////////////////////////////////////////////////////////
// SafeMath Library 
///////////////////////////////////////////////////////////////////////////////
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



// ----------------------------------------------------------------------------
// Imported Token Contract functions
// ----------------------------------------------------------------------------

contract EthertoteToken {
    function thisContractAddress() public pure returns (address) {}
    function balanceOf(address) public pure returns (uint256) {}
    function transfer(address, uint) public {}
}


// ----------------------------------------------------------------------------
// Main Contract
// ----------------------------------------------------------------------------

contract TokenSale {
  using SafeMath for uint256;
  
  EthertoteToken public token;

  address public admin;
  address public thisContractAddress;

  // address of the TOTE token original smart contract
  address public tokenContractAddress = 0x42be9831FFF77972c1D0E1eC0aA9bdb3CaA04D47;
  
  // address of TokenBurn contract to "burn" unsold tokens
  // for further details, review the TokenBurn contract and verify code on Etherscan
  address public tokenBurnAddress = 0xadCa18DC9489C5FE5BdDf1A8a8C2623B66029198;
  
  // address of EthRaised contract, that will be used to distribute funds 
  // raised by the token sale. Added as "wallet address"
  address public ethRaisedAddress = 0x9F73D808807c71Af185FEA0c1cE205002c74123C;
  
  uint public preIcoPhaseCountdown;       // used for website tokensale
  uint public icoPhaseCountdown;          // used for website tokensale
  uint public postIcoPhaseCountdown;      // used for website tokensale
  
  // pause token sale in an emergency [true/false]
  bool public tokenSaleIsPaused;
  
  // note the pause time to allow special function to extend closingTime
  uint public tokenSalePausedTime;
  
  // note the resume time 
  uint public tokenSaleResumedTime;
  
  // The time (in seconds) that needs to be added on to the closing time 
  // in the event of an emergency pause of the token sale
  uint public tokenSalePausedDuration;
  
  // Amount of wei raised
  uint256 public weiRaised;
  
  // 1000 tokens per Eth - 9,000,000 tokens for sale
  uint public maxEthRaised = 9000;
  
  // Maximum amount of Wei that can be raised
  // e.g. 9,000,000 tokens for sale with 1000 tokens per 1 eth
  // means maximum Wei raised would be maxEthRaised * 1000000000000000000
  uint public maxWeiRaised = maxEthRaised.mul(1000000000000000000);

  // starting time and closing time of Crowdsale
  // scheduled start on Monday, August 27th 2018 at 5:00pm GMT+1
  uint public openingTime = 1535990400;
  uint public closingTime = openingTime.add(7 days);
  
  // used as a divider so that 1 eth will buy 1000 tokens
  // set rate to 1,000,000,000,000,000
  uint public rate = 1000000000000000;
  
  // minimum and maximum spend of eth per transaction
  uint public minSpend = 100000000000000000;    // 0.1 Eth
  uint public maxSpend = 100000000000000000000; // 100 Eth 

  
  // MODIFIERS
  modifier onlyAdmin { 
        require(msg.sender == admin
        ); 
        _; 
  }
  
  // EVENTS
  event Deployed(string, uint);
  event SalePaused(string, uint);
  event SaleResumed(string, uint);
  event TokensBurned(string, uint);
  
 // ---------------------------------------------------------------------------
 // Constructor function
 // _ethRaisedContract = Address where collected funds will be forwarded to
 // _tokenContractAddress = Address of the original token contract being sold
 // ---------------------------------------------------------------------------
 
  constructor() public {
    
    admin = msg.sender;
    thisContractAddress = address(this);

    token = EthertoteToken(tokenContractAddress);
    

    require(ethRaisedAddress != address(0));
    require(tokenContractAddress != address(0));
    require(tokenBurnAddress != address(0));

    preIcoPhaseCountdown = openingTime;
    icoPhaseCountdown = closingTime;
    
    // after 14 days the "post-tokensale" header section of the homepage 
    // on the website will be removed based on this time
    postIcoPhaseCountdown = closingTime.add(14 days);
    
    emit Deployed("Ethertote Token Sale contract deployed", now);
  }
  
  
  
  // check balance of this smart contract
  function tokenSaleTokenBalance() public view returns(uint) {
      return token.balanceOf(thisContractAddress);
  }
  
  // check the token balance of any ethereum address  
  function getAnyAddressTokenBalance(address _address) public view returns(uint) {
      return token.balanceOf(_address);
  }
  
  // confirm if The Token Sale has finished
  function tokenSaleHasFinished() public view returns (bool) {
    return now > closingTime;
  }
  
  // this function will send any unsold tokens to the null TokenBurn contract address
  // once the crowdsale is finished, anyone can publicly call this function!
  function burnUnsoldTokens() public {
      require(tokenSaleIsPaused == false);
      require(tokenSaleHasFinished() == true);
      token.transfer(tokenBurnAddress, tokenSaleTokenBalance());
      emit TokensBurned("tokens sent to TokenBurn contract", now);
  }



  // function to temporarily pause token sale if needed
  function pauseTokenSale() onlyAdmin public {
      // confirm the token sale hasn&#39;t already completed
      require(tokenSaleHasFinished() == false);
      
      // confirm the token sale isn&#39;t already paused
      require(tokenSaleIsPaused == false);
      
      // pause the sale and note the time of the pause
      tokenSaleIsPaused = true;
      tokenSalePausedTime = now;
      emit SalePaused("token sale has been paused", now);
  }
  
    // function to resume token sale
  function resumeTokenSale() onlyAdmin public {
      
      // confirm the token sale is currently paused
      require(tokenSaleIsPaused == true);
      
      tokenSaleResumedTime = now;
      
      // now calculate the difference in time between the pause time
      // and the resume time, to establish how long the sale was
      // paused for. This time now needs to be added to the closingTime.
      
      // Note: if the token sale was paused whilst the sale was live and was
      // paused before the sale ended, then the value of tokenSalePausedTime
      // will always be less than the value of tokenSaleResumedTime
      
      tokenSalePausedDuration = tokenSaleResumedTime.sub(tokenSalePausedTime);
      
      // add the total pause time to the closing time.
      
      closingTime = closingTime.add(tokenSalePausedDuration);
      
      // extend post ICO countdown for the web-site
      postIcoPhaseCountdown = closingTime.add(14 days);
      // now resume the token sale
      tokenSaleIsPaused = false;
      emit SaleResumed("token sale has now resumed", now);
  }
  

// ----------------------------------------------------------------------------
// Event for token purchase logging
// purchaser = the contract address that paid for the tokens
// beneficiary = the address who got the tokens
// value = the amount (in Wei) paid for purchase
// amount = the amount of tokens purchased
// ----------------------------------------------------------------------------
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );



// -----------------------------------------
// Crowdsale external interface
// -----------------------------------------


// ----------------------------------------------------------------------------
// fallback function ***DO NOT OVERRIDE***
// allows purchase of tokens directly from MEW and other wallets
// will conform to require statements set out in buyTokens() function
// ----------------------------------------------------------------------------
   
  function () external payable {
    buyTokens(msg.sender);
  }


// ----------------------------------------------------------------------------
// function for front-end token purchase on our website ***DO NOT OVERRIDE***
// buyer = Address of the wallet performing the token purchase
// ----------------------------------------------------------------------------
  function buyTokens(address buyer) public payable {
    
    // check Crowdsale is open (can disable for testing)
    require(openingTime <= block.timestamp);
    require(block.timestamp < closingTime);
    
    // minimum purchase of 100 tokens (0.1 eth)
    require(msg.value >= minSpend);
    
    // maximum purchase per transaction to allow broader
    // token distribution during tokensale
    require(msg.value <= maxSpend);
    
    // stop sales of tokens if token balance is 0
    require(tokenSaleTokenBalance() > 0);
    
    // stop sales of tokens if Token sale is paused
    require(tokenSaleIsPaused == false);
    
    // log the amount being sent
    uint256 weiAmount = msg.value;
    preValidatePurchase(buyer, weiAmount);

    // calculate token amount to be sold
    uint256 tokens = getTokenAmount(weiAmount);
    
    // check that the amount of eth being sent by the buyer 
    // does not exceed the equivalent number of tokens remaining
    require(tokens <= tokenSaleTokenBalance());

    // update state
    weiRaised = weiRaised.add(weiAmount);

    processPurchase(buyer, tokens);
    emit TokenPurchase(
      msg.sender,
      buyer,
      weiAmount,
      tokens
    );

    updatePurchasingState(buyer, weiAmount);

    forwardFunds();
    postValidatePurchase(buyer, weiAmount);
  }

  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

// ----------------------------------------------------------------------------
// Validation of an incoming purchase
// ----------------------------------------------------------------------------
  function preValidatePurchase(
    address buyer,
    uint256 weiAmount
  )
    internal pure
  {
    require(buyer != address(0));
    require(weiAmount != 0);
  }

// ----------------------------------------------------------------------------
// Validation of an executed purchase
// ----------------------------------------------------------------------------
  function postValidatePurchase(
    address,
    uint256
  )
    internal pure
  {
    // optional override
  }

// ----------------------------------------------------------------------------
// Source of tokens
// ----------------------------------------------------------------------------
  function deliverTokens(
    address buyer,
    uint256 tokenAmount
  )
    internal
  {
    token.transfer(buyer, tokenAmount);
  }

// ----------------------------------------------------------------------------
// The following function is executed when a purchase has been validated 
// and is ready to be executed
// ----------------------------------------------------------------------------
  function processPurchase(
    address buyer,
    uint256 tokenAmount
  )
    internal
  {
    deliverTokens(buyer, tokenAmount);
  }

// ----------------------------------------------------------------------------
// Override for extensions that require an internal state to check for 
// validity (current user contributions, etc.)
// ----------------------------------------------------------------------------
  function updatePurchasingState(
    address,
    uint256
  )
    internal pure
  {
    // optional override
  }

// ----------------------------------------------------------------------------
// Override to extend the way in which ether is converted to tokens.
// _weiAmount Value in wei to be converted into tokens
// return Number of tokens that can be purchased with the specified _weiAmount
// ----------------------------------------------------------------------------
  function getTokenAmount(uint256 weiAmount)
    internal view returns (uint256)
  {
    return weiAmount.div(rate);
  }

// ----------------------------------------------------------------------------
// how ETH is stored/forwarded on purchases.
// Sent to the EthRaised Contract
// ----------------------------------------------------------------------------
  function forwardFunds() internal {
    ethRaisedAddress.transfer(msg.value);
  }
  

// functions for tokensale information on the website 

    function maximumRaised() public view returns(uint) {
        return maxWeiRaised;
    }
    
    function amountRaised() public view returns(uint) {
        return weiRaised;
    }
  
    function timeComplete() public view returns(uint) {
        return closingTime;
    }
    
    // special function to delay the token sale if necessary
    function delayOpeningTime(uint256 _openingTime) onlyAdmin public {  
    openingTime = _openingTime;
    closingTime = openingTime.add(7 days);
    preIcoPhaseCountdown = openingTime;
    icoPhaseCountdown = closingTime;
    postIcoPhaseCountdown = closingTime.add(14 days);
    }
    
  
}