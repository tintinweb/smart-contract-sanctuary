/**
 *Submitted for verification at Etherscan.io on 2021-08-10
*/

pragma solidity ^0.8.5;

contract Test {
  error SomeCustomError(address addr, uint256 balance);

  function AlwaysThrow(address _addr, uint256 _value) external {
    revert SomeCustomError(_addr, _value);
  }
    
}