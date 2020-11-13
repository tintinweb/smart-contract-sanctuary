// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.7.0;

library UInt256Array {
  function remove(uint256[] storage self, uint256 index) internal {
    require(index < self.length, "UInt256Array/unknown-index");
    self[index] = self[self.length-1];
    delete self[self.length-1];
    self.pop();
  }
}