pragma solidity ^0.4.13;

/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint a, uint b) internal constant returns (uint) {
    return a >= b ? a : b;
  }

  function min256(uint a, uint b) internal constant returns (uint) {
    return a < b ? a : b;
  }
}

/**
 * Interface for defining crowdsale ceiling.
 */
contract CeilingStrategy {

  /** Interface declaration. */
  function isCeilingStrategy() public constant returns (bool) {
    return true;
  }

  /**
   * When somebody tries to buy tokens for X wei, calculate how many weis they are allowed to use.
   *
   *
   * @param _value - What is the value of the transaction sent in as wei.
   * @param _weiRaised - How much money has been raised so far.
   * @param _weiInvestedBySender - the investment made by the address that is sending the transaction.
   * @param _weiFundingCap - the caller&#39;s declared total cap. May be reinterpreted by the implementation of the CeilingStrategy.
   * @return Amount of wei the crowdsale can receive.
   */
  function weiAllowedToReceive(uint _value, uint _weiRaised, uint _weiInvestedBySender, uint _weiFundingCap) public constant returns (uint amount);

  function isCrowdsaleFull(uint _weiRaised, uint _weiFundingCap) public constant returns (bool);

  /**
   * Calculate a new cap if the provided one is not above the amount already raised.
   *
   *
   * @param _newCap - The potential new cap.
   * @param _weiRaised - How much money has been raised so far.
   * @return The adjusted cap.
   */
  function relaxFundingCap(uint _newCap, uint _weiRaised) public constant returns (uint);

}

/**
 * Fixed cap investment per address and crowdsale
 */
contract FixedCeiling is CeilingStrategy {
    using SafeMath for uint;

    /* When relaxing a cap is necessary, we use this multiple to determine the relaxed cap */
    uint public chunkedWeiMultiple;
    /* The limit an individual address can invest */
    uint public weiLimitPerAddress;

    function FixedCeiling(uint multiple, uint limit) {
        chunkedWeiMultiple = multiple;
        weiLimitPerAddress = limit;
    }

    function weiAllowedToReceive(uint tentativeAmount, uint weiRaised, uint weiInvestedBySender, uint weiFundingCap) public constant returns (uint) {
        // First, we limit per address investment
        uint totalOfSender = tentativeAmount.add(weiInvestedBySender);
        if (totalOfSender > weiLimitPerAddress) tentativeAmount = weiLimitPerAddress.sub(weiInvestedBySender);
        // Then, we check the funding cap
        if (weiFundingCap == 0) return tentativeAmount;
        uint total = tentativeAmount.add(weiRaised);
        if (total < weiFundingCap) return tentativeAmount;
        else return weiFundingCap.sub(weiRaised);
    }

    function isCrowdsaleFull(uint weiRaised, uint weiFundingCap) public constant returns (bool) {
        return weiFundingCap > 0 && weiRaised >= weiFundingCap;
    }

    /* If the new target cap has not been reached yet, it&#39;s fine as it is */
    function relaxFundingCap(uint newCap, uint weiRaised) public constant returns (uint) {
        if (newCap > weiRaised) return newCap;
        else return weiRaised.div(chunkedWeiMultiple).add(1).mul(chunkedWeiMultiple);
    }

}