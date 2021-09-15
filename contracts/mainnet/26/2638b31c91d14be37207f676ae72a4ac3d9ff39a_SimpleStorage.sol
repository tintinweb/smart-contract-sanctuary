/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

pragma solidity 0.4.24;

contract SimpleStorage {
  string ipfsHash;

  function set(string x) public {
    ipfsHash = x;
  }

  function get() public view returns (string) {
    return ipfsHash;
  }
}