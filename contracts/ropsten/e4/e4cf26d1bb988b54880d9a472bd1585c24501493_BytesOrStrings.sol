/**
 *Submitted for verification at Etherscan.io on 2021-08-21
*/

pragma solidity ^0.4.19;

contract BytesOrStrings {
  string constant _string = "cryptopus.co Medium";
  bytes32 constant _bytes = "cryptopus.co Medium";
  bytes constant _longBytes = "Long Long Long Long Long Long Long Long Long Long Long cryptopus.co Medium";
  function  getAsString() public pure returns(string) {
    return _string;
  }

  function  getAsBytes() public pure returns(bytes32) {
    return _bytes;
  }
  
  function  getAsLongBytes() public pure returns(bytes memory) {
    return _longBytes;
  }
}