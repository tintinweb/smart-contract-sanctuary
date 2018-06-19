pragma solidity ^0.4.21;

// File: zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
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

// File: contracts/BonusStrategy.sol

contract BonusStrategy {
    using SafeMath for uint;

    uint public defaultAmount = 1*10**18;
    uint public limit = 300*1000*10**18; // 300.000  DCNT
    uint public currentAmount = 0;
    uint[] public startTimes;
    uint[] public endTimes;
    uint[] public amounts;

    constructor(
        uint[] _startTimes,
        uint[] _endTimes,
        uint[] _amounts
        ) public 
    {
        require(_startTimes.length == _endTimes.length && _endTimes.length == _amounts.length);
        startTimes = _startTimes;
        endTimes = _endTimes;
        amounts = _amounts;
    }

    function isStrategy() external pure returns (bool) {
        return true;
    }

    function getCurrentBonus() public view returns (uint bonus) {
        if (currentAmount >= limit) {
            currentAmount = currentAmount.add(defaultAmount);
            return defaultAmount;
        }
        for (uint8 i = 0; i < amounts.length; i++) {
            if (now >= startTimes[i] && now <= endTimes[i]) {
                bonus = amounts[i];
                currentAmount = currentAmount.add(bonus);
                return bonus;
            }
        }
        currentAmount = currentAmount.add(defaultAmount);
        return defaultAmount;
    }

}