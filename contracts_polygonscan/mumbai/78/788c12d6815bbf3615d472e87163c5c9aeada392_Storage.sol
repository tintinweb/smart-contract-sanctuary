/**
 *Submitted for verification at polygonscan.com on 2021-07-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
      _reserve0 = 347659420039623496041057;
      _reserve1 = 287717200998;
      _blockTimestampLast = 1626436331;
  }
}