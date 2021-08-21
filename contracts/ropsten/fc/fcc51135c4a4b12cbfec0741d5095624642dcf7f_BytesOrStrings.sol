/**
 *Submitted for verification at Etherscan.io on 2021-08-21
*/

pragma solidity ^0.4.19;

contract BytesOrStrings {
  string constant _string = "cryptopus.co Medium";
  bytes32 constant _bytes = "cryptopus.co Medium";
  function  getAsString() public returns(string) {
    return _string;
  }

  function  getAsBytes() public returns(bytes32) {
    return _bytes;
  }
}