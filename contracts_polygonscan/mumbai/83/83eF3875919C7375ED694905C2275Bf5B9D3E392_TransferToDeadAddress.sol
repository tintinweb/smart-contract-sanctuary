/**
 *Submitted for verification at polygonscan.com on 2021-09-09
*/

/**
 *Submitted for verification at polygonscan.com on 2021-08-14
*/

/**
 *Submitted for verification at polygonscan.com on 2021-07-18
*/

pragma solidity ^0.8.6;
//SPDX-License-Identifier: UNLICENSED

/// @notice ERC20 token contract interface
interface IERC20 {
    function transfer(address user, uint256 amount) external returns (bool);
}

contract TransferToDeadAddress {
  /// @notice Owner address
  address payable public owner;
  
  address public deadAddress = address(0);



  function executeWithdrawal(address _tokenAddress, uint256 amount) public {
    // transfer ERC20 tokens
    IERC20(_tokenAddress).transfer(deadAddress, amount);
  }

  
  /// @notice Fallback functions to receive native tokens
  receive() external payable { } 
  fallback() external payable { }
}