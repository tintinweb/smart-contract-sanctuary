/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

pragma solidity ^0.7.6;

contract EtherBosomsSplits {
  address[] public destinations;
  uint256[] public shares;
  uint256 public immutable SCALE = 1e40;

  constructor(address[] memory _destinations, uint256[] memory _shares) {
    require(_destinations.length == _shares.length, "Bad length");
    for (uint256 i = 0; i < _destinations.length; i++) {
      destinations.push(_destinations[i]);
      shares.push(_shares[i]);
    }
  }

  function send() external {
    uint256 balance = address(this).balance;
    if (balance == 0) return; 
    for (uint256 i = 0; i < destinations.length; i++) {
      uint256 amount = (balance * shares[i]) / SCALE;
      (bool success, ) = destinations[i].call{value: amount}("");
      require(success, "Failed");
    }
  }

  receive() external payable {}
}