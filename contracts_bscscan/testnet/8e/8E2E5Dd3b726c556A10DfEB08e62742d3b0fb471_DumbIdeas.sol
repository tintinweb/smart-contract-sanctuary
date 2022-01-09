// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract DumbIdeas {
  uint[] ids;

  function initIDS(uint number) public {
    for (uint x = 0; x < number; x++) {
      ids.push(x);
    }
  }

  function wipeIDS() public {
    delete ids;
  }

  function idsLength() external view returns (uint) {
    return ids.length;
  }

  function showIDS() external view returns (uint[] memory) {
    return ids;
  }
}