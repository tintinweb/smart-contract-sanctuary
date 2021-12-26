/**
 *Submitted for verification at Etherscan.io on 2021-12-26
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract batchTransfer {
  function transfer(uint256 amount, address payable[] memory receiver, address token) external {
    IERC20(token).transferFrom(msg.sender, address(this), amount);

    uint amount_single = amount / receiver.length;

    for (uint i = 0; i < receiver.length; i++) {
        IERC20(token).transfer(receiver[i], amount_single);
    }
  }
}