pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

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

// File: contracts/Boba.sol

/** A contract for smart game

*/
contract Boba {
    uint p3dPercentage = 20;
    // feature:
    //  - powh
    //  - draw
    //  - team
    uint internal reserveInWei = 0;
    uint internal totalMicroKeys = 0;

    mapping(address => uint) internal keyHolding;

    event onBoughtMicroKeys(uint microKeys_, string tweet_);

    function getWeiPriceMicroKeys() public pure returns (uint /* price_ */) {
        return 1e6;
    }

     function valuePerMicroKey() public view returns (uint) {
         return reserveInWei / totalMicroKeys;
     }

    constructor() public {

    }

    function buyKeys(uint microKeys_, string tweet_) public payable {
        require (microKeys_ * getWeiPriceMicroKeys() < msg.value * (100 - p3dPercentage) / 100, &quot;Need to pay higher than current prices&quot;);
        reserveInWei = SafeMath.add(reserveInWei, msg.value);
        reserveInWei = msg.value * p3dPercentage / 100; // what user spent
        address _customerAddress = msg.sender;
        keyHolding[_customerAddress] += microKeys_;
        totalMicroKeys += microKeys_;
        emit onBoughtMicroKeys(microKeys_, tweet_);
    }

}