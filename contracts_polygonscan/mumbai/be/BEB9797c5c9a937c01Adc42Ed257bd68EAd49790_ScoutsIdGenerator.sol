pragma solidity ^0.8.0;
// SPDX-License-Identifier: (CC-BY-NC-ND-3.0)
// Code and docs are CC-BY-NC-ND-3.0


contract ScoutsIdGenerator {

  function getScoutId(string memory _generator, uint256 _tokenId) public pure returns (uint256) {
    bytes32 encodedGenerator = keccak256(abi.encodePacked(_generator)); 
    if (encodedGenerator == keccak256(abi.encodePacked("Ticket"))) {
      // First 4699 scouts reserved for Pioneers
      require(_tokenId < 4700, "Only 4700 Pioneers should be available");
      return(_tokenId);
    } else if (encodedGenerator == keccak256(abi.encodePacked("LootBox"))) {
      // Scouts from LootBoxes shouldn't have an id below 4700
      return(_tokenId + 4700);
    } else {
      revert('invalid input');
    }
  }

}