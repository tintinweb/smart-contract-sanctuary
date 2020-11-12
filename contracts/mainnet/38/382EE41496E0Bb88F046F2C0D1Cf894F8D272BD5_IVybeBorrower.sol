// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IVybeBorrower {
  function loaned(uint256 amount, uint256 owed) external;
}
