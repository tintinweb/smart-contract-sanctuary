pragma solidity ^0.4.23;

contract ZethrUtils {
  using SafeMath for uint;

  Zethr constant internal              ZETHR = Zethr(0xD48B633045af65fF636F3c6edd744748351E020D);

  /*=====================================
  =            CONSTANTS                =
  =====================================*/

  uint8 constant public                decimals              = 18;

  uint constant internal               tokenPriceInitial_    = 0.000653 ether;
  uint constant internal               magnitude             = 2**64;

  uint constant internal               icoHardCap            = 250 ether;
  uint constant internal               addressICOLimit       = 1   ether;
  uint constant internal               icoMinBuyIn           = 0.1 finney;
  uint constant internal               icoMaxGasPrice        = 50000000000 wei;

  uint constant internal               MULTIPLIER            = 9615;

  uint constant internal               MIN_ETH_BUYIN         = 0.0001 ether;
  uint constant internal               MIN_TOKEN_SELL_AMOUNT = 0.0001 ether;
  uint constant internal               MIN_TOKEN_TRANSFER    = 1e10;
  uint constant internal               referrer_percentage   = 25;

  /*=======================================
  =            PUBLIC FUNCTIONS           =
  =======================================*/

  function tokensToEthereum_1(uint _tokens, uint tokenSupply)
  public
  view
  returns(uint, uint)
  {
    // First, separate out the sell into two segments:
    //  1) the amount of tokens selling at the ICO price.
    //  2) the amount of tokens selling at the variable (pyramid) price
    uint tokensToSellAtICOPrice = 0;
    uint tokensToSellAtVariablePrice = 0;

    uint tokensMintedDuringICO = ZETHR.tokensMintedDuringICO();

    if (tokenSupply <= tokensMintedDuringICO) {
      // Option One: All the tokens sell at the ICO price.
      tokensToSellAtICOPrice = _tokens;

    } else if (tokenSupply > tokensMintedDuringICO && tokenSupply - _tokens >= tokensMintedDuringICO) {
      // Option Two: All the tokens sell at the variable price.
      tokensToSellAtVariablePrice = _tokens;

    } else if (tokenSupply > tokensMintedDuringICO && tokenSupply - _tokens < tokensMintedDuringICO) {
      // Option Three: Some tokens sell at the ICO price, and some sell at the variable price.
      tokensToSellAtVariablePrice = tokenSupply.sub(tokensMintedDuringICO);
      tokensToSellAtICOPrice      = _tokens.sub(tokensToSellAtVariablePrice);

    } else {
      // Option Four: Should be impossible, and the compiler should optimize it out of existence.
      revert();
    }

    // Sanity check:
    assert(tokensToSellAtVariablePrice + tokensToSellAtICOPrice == _tokens);

    return (tokensToSellAtICOPrice, tokensToSellAtVariablePrice);
  }

  function tokensToEthereum_2(uint tokensToSellAtICOPrice)
  public
  pure
  returns(uint)
  {
    // Track how much Ether we get from selling at each price function:
    uint ethFromICOPriceTokens = 0;

    // Now, actually calculate:

    if (tokensToSellAtICOPrice != 0) {

      /* Here, unlike the sister equation in ethereumToTokens, we DON&#39;T need to multiply by 1e18, since
         we will be passed in an amount of tokens to sell that&#39;s already at the 18-decimal precision.
         We need to divide by 1e18 or we&#39;ll have too much Ether. */

      ethFromICOPriceTokens = tokensToSellAtICOPrice.mul(tokenPriceInitial_).div(1e18);
    }

    return ethFromICOPriceTokens;
  }

  function tokensToEthereum_3(uint tokensToSellAtVariablePrice, uint tokenSupply)
  public
  pure
  returns(uint)
  {
    // Track how much Ether we get from selling at each price function:
    uint ethFromVarPriceTokens = 0;

    // Now, actually calculate:

    if (tokensToSellAtVariablePrice != 0) {

      /* Note: Unlike the sister function in ethereumToTokens, we don&#39;t have to calculate any "virtual" token count.
         This is because in sells, we sell the variable price tokens **first**, and then we sell the ICO-price tokens.
         Thus there isn&#39;t any weird stuff going on with the token supply.

         We have the equations for total investment above; note that this is for TOTAL.
         To get the eth received from this sell, we calculate the new total investment after this sell.
         Note that we divide by 1e6 here as the inverse of multiplying by 1e6 in ethereumToTokens. */

      uint investmentBefore = toPowerOfThreeHalves(tokenSupply.div(MULTIPLIER * 1e6)).mul(2).div(3);
      uint investmentAfter  = toPowerOfThreeHalves((tokenSupply - tokensToSellAtVariablePrice).div(MULTIPLIER * 1e6)).mul(2).div(3);

      ethFromVarPriceTokens = investmentBefore.sub(investmentAfter);
    }

    return ethFromVarPriceTokens;
  }

  // How much Ether we get from selling N tokens
  function tokensToEthereum_(uint _tokens, uint tokenSupply)
  public
  view
  returns(uint)
  {
    require (_tokens >= MIN_TOKEN_SELL_AMOUNT, "Tried to sell too few tokens.");

    /*
     *  i = investment, p = price, t = number of tokens
     *
     *  i_current = p_initial * t_current                   (for t_current <= t_initial)
     *  i_current = i_initial + (2/3)(t_current)^(3/2)      (for t_current >  t_initial)
     *
     *  t_current = i_current / p_initial                   (for i_current <= i_initial)
     *  t_current = t_initial + ((3/2)(i_current))^(2/3)    (for i_current >  i_initial)
     */

    uint tokensToSellAtICOPrice;
    uint tokensToSellAtVariablePrice;

    (tokensToSellAtICOPrice, tokensToSellAtVariablePrice) = tokensToEthereum_1(_tokens, tokenSupply);

    uint ethFromICOPriceTokens = tokensToEthereum_2(tokensToSellAtICOPrice);
    uint ethFromVarPriceTokens = tokensToEthereum_3(tokensToSellAtVariablePrice, tokenSupply);

    uint totalEthReceived = ethFromVarPriceTokens + ethFromICOPriceTokens;

    assert(totalEthReceived > 0);
    return totalEthReceived;
  }

  /*=======================
   =   MATHS FUNCTIONS    =
   ======================*/

  function toPowerOfThreeHalves(uint x) public pure returns (uint) {
    // m = 3, n = 2
    // sqrt(x^3)
    return sqrt(x**3);
  }

  function toPowerOfTwoThirds(uint x) public pure returns (uint) {
    // m = 2, n = 3
    // cbrt(x^2)
    return cbrt(x**2);
  }

  function sqrt(uint x) public pure returns (uint y) {
    uint z = (x + 1) / 2;
    y = x;
    while (z < y) {
      y = z;
      z = (x / z + z) / 2;
    }
  }

  function cbrt(uint x) public pure returns (uint y) {
    uint z = (x + 1) / 3;
    y = x;
    while (z < y) {
      y = z;
      z = (x / (z*z) + 2 * z) / 3;
    }
  }
}

/*=======================
 =     INTERFACES       =
 ======================*/

contract Zethr {
  uint public                          stakingRequirement;
  uint public                          tokensMintedDuringICO;
}

// Think it&#39;s safe to say y&#39;all know what this is.

library SafeMath {

  function mul(uint a, uint b) internal pure returns (uint) {
    if (a == 0) {
      return 0;
    }
    uint c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}