/**
 *Submitted for verification at polygonscan.com on 2021-11-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWETH {
  function approve(address, uint256) external;

  function deposit() external payable;

  function withdraw(uint256) external;
}


contract WMATICUnwrapper {
  address constant wftm = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

  receive() external payable {}

  /**
   * @notice Convert WMATIC to MATIC and transfer to msg.sender
   * @dev msg.sender needs to send WMATIC before calling this withdraw
   * @param _amount amount to withdraw.
   */
  function withdraw(uint256 _amount) external {
    IWETH(wftm).withdraw(_amount);
    (bool sent, ) = msg.sender.call{ value: _amount }("");
    require(sent, "Failed to send MATIC");
  }
}