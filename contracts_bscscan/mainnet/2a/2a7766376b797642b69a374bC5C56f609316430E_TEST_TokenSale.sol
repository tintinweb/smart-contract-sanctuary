/**
 *Submitted for verification at BscScan.com on 2021-11-09
*/

// Squirt Game - Official Pre-sale Token Contract
// 09.11.21
//
// Any unsold tokens can be sent directly to the TokenBurn Contract
// by anybody once the Token Sale is complete - 
// this is a PUBLIC function that anyone can call!!
//
//
// All unsold pre-sale SQUIRT will be burned
//
// Total minted supply 1 quadrillion - 1,000,000,000,000,000
// Total tokens available for pre-sale - 40% - 400,000,000,000,000
//
// Max tokens available for Sushiswap LP - 40% - 400,000,000,000,000
//
// All Pancake LP will be burned to remove any concern over rug-pulls
//
//
// Pre-sale pricing: 
// Day 1: 0.0016 BNB = 1,000,000,000 (1 billion) SQUIRT 
// Day 2: 0.0020 BNB = 1,000,000,000 (1 billion) SQUIRT 
// Day 3: 0.0024 BNB = 1,000,000,000 (1 billion) SQUIRT 
// Day 4: 0.0028 BNB = 1,000,000,000 (1 billion) SQUIRT 
// Day 5: 0.0032 BNB = 1,000,000,000 (1 billion) SQUIRT 
// Pancake LP opening: 0.0036 BNB = 1,000,000,000 (1 billion) SQUIRT


pragma solidity ^0.5.6;

///////////////////////////////////////////////////////////////////////////////
// SafeMath Library 
///////////////////////////////////////////////////////////////////////////////
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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
// Imported SQUIRT Token Contract functions
// ----------------------------------------------------------------------------

contract SQUIRT_Token {
    function thisContractAddress() public pure returns (address) {}
    function balanceOf(address) public pure returns (uint256) {}
    function transfer(address, uint) public {}
}



// ----------------------------------------------------------------------------
// Imported BUSD Token Contract functions
// ----------------------------------------------------------------------------
//
//contract BUSD_Token {
//    function thisContractAddress() public pure returns (address) {}
//    function balanceOf(address) public pure returns (uint256) {}
//    function transfer(address, uint) public {}
//    function approve(address, uint256) public {}
//}





// ----------------------------------------------------------------------------
// Main Contract
// ----------------------------------------------------------------------------

contract TEST_TokenSale {
  using SafeMath for uint256;
  
  SQUIRT_Token public token;
//  BUSD_Token public busd;

  address public admin;
  address public thisContractAddress;

  //////////////////////////////////////////////////////////////////////////////////
  // address of the SQUIRT Token smart contract
  address public tokenContractAddress = 0x35aF3C2560A4b3575770cE7717a4e5A2265585EF;
  //
  //////////////////////////////////////////////////////////////////////////////////
  
  ////////////////////////////////////////////////////////////////////////////////////
  // address of BUSD token
  //
  //address payable public busdFundAddress = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
  //
  /////////////////////////////////////////////////////////////////////////////////////
  
 
  /////////////////////////////////////////////////////////////////////////////////////
  // address of TokenBurn contract to "burn" unsold tokens
  // for further details, review the TokenBurn contract and verify code on Blockscout
  address payable public tokenBurnAddress = 0x14F92fAE820B8c55987E51E096271F9E47FFF1C9;
  //
  /////////////////////////////////////////////////////////////////////////////////////
  
  ////////////////////////////////////////////////////////////////////////////////////
  // address of liquidity wallet, that will be used to fund Sushi LP
  //
  address payable public liquidityFundAddress = 0xbF8e55Fb88A92652b232acCbB79309c81637Bc89;
  //
  /////////////////////////////////////////////////////////////////////////////////////
  
  ////////////////////////////////////////////////////////////////////////////////////
  // address of investment fund wallet, that will be used to distribute funds 
  // raised by the token sale. Added as "wallet address"
  //
  address payable public investmentFundAddress = 0x47d6b2906EcdFA615419931e50b46b8B5901858a;
  //
  /////////////////////////////////////////////////////////////////////////////////////
  
  
//  uint256 public approvedAmount;
  

  // starting time and closing time of Squirt token sale
  // scheduled start on Friday, November 12th 2021 at 10:00am GMT
  // shown as epoch time (1636711200) - See https://www.epochconverter.com/
  
  // NOTE: For testing the time will be set to start at:
  // Tuesday, November 9th 2021 at 21:00pm GMT (1636491600)
  uint public openingTime = 1636491600;
  
  // NOTE: the closing time will be opening time + 5 days - commented out for testing
  // Instead we will end after 5 hours (18000 seconds)
  // uint public closingTime = openingTime.add(5 days);
  uint public closingTime = openingTime + 18000;
  
  
  uint public preIcoPhaseCountdown;       // used for website tokensale tracking
  uint public icoPhaseCountdown;          // used for website tokensale tracking
  uint public postIcoPhaseCountdown;      // used for website tokensale tracking
  
  // pause token sale in an emergency [true/false]
  bool public tokenSaleIsPaused;
  
  // note the pause time to allow special function to extend closingTime
  uint public tokenSalePausedTime;
  
  // note the resume time 
  uint public tokenSaleResumedTime;
  
  // The time (in seconds) that needs to be added on to the closing time 
  // in the event of an emergency pause of the token sale
  uint public tokenSalePausedDuration;
  
  // Amount of BNB raised, expressed as Wei
  uint256 public weiRaised;
  
  // maximum xDai that could sell (400,000,000,000,000 SQUIRT == 640 BNB)
  uint public maxBNBRaised = 640;
  
  // Maximum amount of Wei that can be raised
  // e.g. 400,000,000,000,000 SQUIRT tokens for sale with 1,000,000,000 squirt per 0.0016 BNB
  // means maximum Wei raised would be maxxDaiRaised * 1000000000000000000
  uint public maxWeiRaised = maxBNBRaised.mul(1000000000000000000);


  
  // used as a divider so that 1 BNB will buy 625,000,000,000 squirt tokens
  uint public rate = 625000000000;
  
  // rate reducer, used to increase the value of SQUIRT after each 24 hour period of the Pre-sale
  // this number will be deducted from the rate after each 24 hours
  uint public rateReducer = 62500000000;
  
  // time period for each rate reduction (24 hours = 86400 seconds)
  // will use 60 minutes (3600 seconds) for testing
  uint public ratePeriod = 3600;
  
  uint public currentRate = 1;
  
  // minimum and maximum spend of BNB per transaction, expressed as wei
  // uint public minSpend = 10000000000000000;    // 0.01 BNB = $6.30
  
  // smaller amount for testing
     uint public minSpend = 100000000000000;    // 0.0001 BNB = $0.063
  
  uint public maxSpend = 1000000000000000000000; // 1000 BNB
  
  bool public mutex;

  
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
 
  constructor() public {
    
    admin = msg.sender;
    thisContractAddress = address(this);

    token = SQUIRT_Token(tokenContractAddress);
    
//    busd = BUSD_Token(busdFundAddress);
    
    require(tokenContractAddress != address(0));
    require(tokenBurnAddress != address(0));
    require(liquidityFundAddress != address(0));

    preIcoPhaseCountdown = openingTime;
    icoPhaseCountdown = closingTime;
    

    emit Deployed("SQUIRT Token Sale contract deployed", now);
  }
  
  
  
  // check balance of THIS smart contract in wei (18 decimals)
  function tokenSaleTokenBalanceinWei() public view returns(uint) {
      return token.balanceOf(thisContractAddress);
  }
  
    // check SQUIRT balance of this smart contract
  function tokenSaleSquirtRemaining() public view returns(uint) {
      return tokenSaleTokenBalanceinWei().div(1000000000000000000);
  }
  
  // check the token balance of any BSC Wallet address  
  function getAnyAddressTokenBalance(address _address) public view returns(uint) {
      return token.balanceOf(_address);
  }
  
  // confirm if The Token Sale has finished
  function tokenSaleHasFinished() public view returns (bool) {
    return block.timestamp > closingTime;
  }
  
  // this function will send any unsold tokens to the null TokenBurn contract address
  // once the token sale is finished, ANYONE can publicly call this function!
  function burnUnsoldTokens() public {
      require(tokenSaleIsPaused == false);
      // can only be called after the close time
      require(tokenSaleHasFinished() == true);
      token.transfer(tokenBurnAddress, tokenSaleTokenBalanceinWei());
      emit TokensBurned("tokens sent to TokenBurn contract", now);
  }



  // function to temporarily pause the token sale if needed
  function pauseTokenSale() onlyAdmin public {
      // confirm the token sale hasn't already completed
      require(tokenSaleHasFinished() == false);
      
      // confirm the token sale isn't already paused
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
      
      // now resume the token sale
      tokenSaleIsPaused = false;
      emit SaleResumed("token sale has now resumed", now);
  }
  

// ----------------------------------------------------------------------------
// Event for token purchase logging
// purchaser = the contract address that paid for the tokens
// beneficiary = the address who got the tokens
// value = the amount of xDai (in Wei) paid for purchase
// amount = the amount of tokens purchased
// ----------------------------------------------------------------------------
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );



// ----------------------------------------------------------------------------
// fallback function ***DO NOT OVERRIDE***
// allows purchase of SQUIRT tokens directly from wallet apps, Metamask, TokenIM and other wallets
// will conform to require statements set out in buyTokens() function
// ----------------------------------------------------------------------------
   
//  function buyingTokens() external payable {
//    buyTokens();
//  }


// ----------------------------------------------------------------------------
// function for front-end token purchase on our website ***DO NOT OVERRIDE***
// buyer = Address of the wallet performing the token purchase
// ----------------------------------------------------------------------------

//   function approveSpend(uint amount) public payable {
//       busd.approve(msg.sender, amount);
//       approvedAmount = amount;
//   }
  
  
 
  
  function buyTokens() public payable {
    require(mutex == false);
    
    // check Tokensale is open (can disable for testing)
    require(openingTime <= block.timestamp);
    require(block.timestamp < closingTime);
    
    // minimum purchase of 1,000 SQUIRT tokens (000000.1 xDai)
    require(msg.value >= minSpend);
    
    // maximum purchase per transaction to allow broader
    // token distribution during tokensale
    require(msg.value <= maxSpend);
    
    // stop sales of tokens if token balance is les than 1 Squirt token
    require(tokenSaleTokenBalanceinWei() > 100000000000);
    
    // stop sales of tokens if Token sale is paused
    require(tokenSaleIsPaused == false);
    
    // check that the amount of xDai being sent by the buyer 
    // does not exceed the equivalent number of tokens remaining
    require(msg.value.mul(rate) <= tokenSaleTokenBalanceinWei());
    
    mutex = true;
    
    // log the amount being sent
    uint256 weiAmount = msg.value;
//    uint256 weiAmount = amountSent;
    
    // calculate token amount to be sold
    uint256 tokens = weiAmount.mul(rate);
    
    address buyer = msg.sender;
    preValidatePurchase(buyer, weiAmount);

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

    // send to wallet for project distribution
    
    // approve the buyers spend of BUSD
    // approveSpend(amountSent);
    
    //now transfer the BUSD onto the liquidity fund and investment fund addresses
   forwardFunds();
//     deliverBusd();
    postValidatePurchase(buyer, weiAmount);
    
    
    // if statement to increment the rate - this means SQUIRT value increases after each 24 hours
    // e.g. Day1 - 0.0016 BNB = 1,000,000,000 SQUIRT
    // Day2 - 0.0020 BNB = 1,000,000,000 SQUIRT
    // etc
    if(block.timestamp> openingTime + ratePeriod) {
        rate = rate - rateReducer;
        currentRate = currentRate + 1;
        ratePeriod = ratePeriod * currentRate;
        
    } 
    
    mutex = false;
  }


// ----------------------------------------------------------------------------
// how Squirt is stored/forwarded on purchases.
// ----------------------------------------------------------------------------
  function forwardFunds() internal {
    liquidityFundAddress.transfer((msg.value.div(100)).mul(80));
    investmentFundAddress.transfer((msg.value.div(100)).mul(20));
  }


//  function deliverBusd() internal {
//    busd.transfer(liquidityFundAddress, (approvedAmount.div(100)).mul(80));
//    busd.transfer(investmentFundAddress, (approvedAmount.div(100)).mul(20));
//  }





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
// Override to extend the way in which xDai is converted to xDoge tokens.
// _weiAmount Value in wei to be converted into tokens
// return Number of tokens that can be purchased with the specified _weiAmount
// ----------------------------------------------------------------------------
  function getTokenAmount(uint256 weiAmount)
    internal view returns (uint256)
  {
    return weiAmount.mul(rate);
  }


  

// functions for tokensale information on the website 

    function maximumRaised() public view returns(uint) {
        return maxBNBRaised;
    }
    
    function BNBRaised() public view returns(uint) {
        return weiRaised.div(1000000000000000000);
    }
  
    function timeComplete() public view returns(uint) {
        return closingTime;
    }
    
    // special function to delay the token sale if necessary
    function delayOpeningTime(uint256 _openingTime) onlyAdmin public {  
    // ensure opening time can only be moved forwards, not backwards
    require(_openingTime > openingTime);
    openingTime = _openingTime;
    closingTime = openingTime.add(5 days);
    preIcoPhaseCountdown = openingTime;
    icoPhaseCountdown = closingTime;
    }
    
        // special function to set token rate
    function setRate(uint256 _rate) onlyAdmin public {  
    rate = _rate;
    }
    
    function setminSpend(uint256 _min) onlyAdmin public payable {
        minSpend = _min;
    }
    
    function setmaxSpend(uint256 _max) onlyAdmin public payable {
        maxSpend = _max;
    }
    
        // check the SQUIRT token balance of THIS contract  
    function getSQUIRTBalance() public view returns(uint) {
        return token.balanceOf(address(this));
    }
  
   // check the BNB balance of THIS contract  
    function getBNBBalance() public view returns(uint) {
        return address(this).balance;
    }
    
  
}