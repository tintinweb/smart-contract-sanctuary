/*
/// @title Test Calculator
/// @author MarkCTest
/// @notice Made the add function payable
/// @param C is used for all return values
*/

pragma solidity ^0.4.18;

contract SimpleMathTest003 {
    
    uint calculationFee = 0.001 ether;

  modifier payForResults() {
      require(msg.value == calculationFee);
    _;
  }
  

  function add(uint a, uint b) public payForResults payable returns(uint) {
    uint c = a + b;
    return c;
  }
  
  function mul(uint a, uint b) public pure returns (uint) {
    uint c = a * b;
    return c;
  }
  
  function div(uint a, uint b) public pure returns(uint) {
    uint c = a / b;
    return c;
    // @dev Doesn&#39;t address divide by zero errors
  }
  
  function sub(uint a, uint b) public pure returns(uint) {
    uint c = a - b;
    return c;
    // @dev Doesn&#39;t address if we get a negative number
  }

}