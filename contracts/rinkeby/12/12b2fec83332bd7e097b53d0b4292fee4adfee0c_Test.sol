/**
 *Submitted for verification at Etherscan.io on 2021-09-23
*/

pragma solidity ^0.8.7;
pragma abicoder v2;

contract Test {
  error OffchainLookup(string url);

  function addr() external view returns(address) {
    revert OffchainLookup("hello");
    return(msg.sender);
  }
}