pragma solidity ^0.4.11;

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


contract PricingStrategy {

    using SafeMath for uint;

    uint public newRateTime;
    uint public rate1;
    uint public rate2;
    uint public minimumWeiAmount;

    function PricingStrategy(
        uint _newRateTime,
        uint _rate1,
        uint _rate2,
        uint _minimumWeiAmount
    ) {
        require(_newRateTime > 0);
        require(_rate1 > 0);
        require(_rate2 > 0);
        require(_minimumWeiAmount > 0);

        newRateTime = _newRateTime;
        rate1 = _rate1;
        rate2 = _rate2;
        minimumWeiAmount = _minimumWeiAmount;
    }

    /** Interface declaration. */
    function isPricingStrategy() public constant returns (bool) {
        return true;
    }

    /** Calculate the current price for buy in amount. */
    function calculateTokenAmount(uint weiAmount) public constant returns (uint tokenAmount) {
        uint bonusRate = 0;

        if (weiAmount >= minimumWeiAmount) {
            if (now < newRateTime) {
                bonusRate = rate1;
            } else {
                bonusRate = rate2;
            }
        }

        return weiAmount.mul(bonusRate);
    }
}