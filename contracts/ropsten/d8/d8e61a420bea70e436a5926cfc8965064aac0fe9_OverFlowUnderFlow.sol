/**
 *Submitted for verification at Etherscan.io on 2021-04-16
*/

pragma solidity ^0.8.3;
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

contract OverFlowUnderFlow{
    using SafeMath for uint256;
    
    uint public OverFlowTest = 2**256-1;
    uint public UnderFlowTest;
    uint public OverFlowPrevent = 2**256-1;
    uint public UnderFlowPrevent;
    uint public OverFlowSafe = 2**256-1;
    uint public UnderFlowSafe;
    
    function testOverFlow(uint addFund) public returns(uint){
        OverFlowTest += addFund;
        return OverFlowTest;
    }
    
    
    function testUnderFlow(uint subFund) public returns(uint){
        UnderFlowTest -= subFund;
        return UnderFlowTest;
    }
    
    function preventOverFlow(uint addFund) public returns(uint){
        require(OverFlowPrevent + addFund > OverFlowPrevent, "Failed");
        OverFlowPrevent += addFund;
        return OverFlowPrevent;
    }
    
    function preventUnderFlow(uint subFund) public returns(uint){
        require(UnderFlowPrevent > subFund, "Failed");
        UnderFlowPrevent -= subFund;
        return UnderFlowPrevent;
    }
    
    function preventOverFlowBySafeMath(uint addno) public returns(uint){
        OverFlowSafe = OverFlowSafe.add(addno);
        return OverFlowSafe;
    }
    
    /*
    function preventUnderFlowSafeMath(uint subno) public returns(uint){
        UnderFlowSafe = UnderFlowSafe(subno);
        return UnderFlowSafe;
    }
    */
}