pragma solidity ^0.4.25;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

/**
 * @title TestSafeMath
 * @dev Math operations with library SafeMath
*/
contract TestSafeMath {
    using SafeMath for uint256;
    
    address private owner;
    uint256 private x;
    
    event ChangeX(uint256 _x);
    
    modifier ownerOnly {
        require(msg.sender == owner);
        _;
    }
    
    constructor() public {
        owner = msg.sender;
        x = 1024;
    }
     
    function divX(uint256 _a) public ownerOnly returns (uint256) {
        x = x.div(_a);
        return x;
    }
    
    function modX(uint256 _a) public ownerOnly returns (uint256) {
        x = x.mod(_a);
        return x;
    }
    
    function mulX(uint256 _a) public ownerOnly returns (uint256) {
        x = x.mul(_a);
        return x;
    }
    
    function downX(uint256 _a) public ownerOnly returns (uint256) {
        x = x.sub(_a);
        return x;
    }
    
    function upX(uint256 _a) public ownerOnly returns (uint256) {
        x = x.add(_a);
        emit ChangeX(x);
        return x;
    }
    
}