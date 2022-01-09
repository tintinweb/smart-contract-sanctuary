// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract DumbIdeasV4 {
  uint[] ids;
  uint[] drawn;

  function initIDS(uint number) public {
    for (uint x = 0; x < number; x++) {
      ids.push(x);
    }
  }

  function wipeIDS() public {
    delete ids;
  }

  function pullRandomID() public {
    uint picker = uint(keccak256(abi.encodePacked(block.timestamp,
msg.sender))) % ids.length;
    drawn.push(ids[picker]);
    uint last = ids[ids.length - 1];
    ids[picker] = last;
    ids.pop();
  }

  function setIDS(uint[] memory data) public {
    ids = data;
  }

  function drawnLength() external view returns (uint) {
    return drawn.length;
  }

  function drawnIDS() external view returns (uint[] memory) {
    return drawn;
  }

  function idsLength() external view returns (uint) {
    return ids.length;
  }

  function showIDS() external view returns (uint[] memory) {
    return ids;
  }
}