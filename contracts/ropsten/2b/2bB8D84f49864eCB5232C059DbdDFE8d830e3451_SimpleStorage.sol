/**
 *Submitted for verification at Etherscan.io on 2021-07-01
*/

pragma solidity 0.8.3;

contract SimpleStorage {
  uint256 data;
  string ipfsHash;

  event DataSet(address from, uint256 data);
  event HashSet(address from, string ipfsHash);

  function set(uint256 x) public {
    data = x;
    emit DataSet(msg.sender, x);
  }

  function get() public view returns (uint256) {
    return data;
  }

  function setHash(string calldata x) public {
    ipfsHash = x;
    emit HashSet(msg.sender, x);
  }

  function getHash() public view returns (string memory) {
    return ipfsHash;
  }
}