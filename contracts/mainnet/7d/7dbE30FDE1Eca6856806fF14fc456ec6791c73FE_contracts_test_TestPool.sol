// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

import "../Pool.sol";

contract TestPool is Pool {
    function _getNumShares(uint amount, uint multiplier, uint price) public pure returns (uint) {
      return getNumShares(amount, multiplier, price);
    }
}
