/**
 *Submitted for verification at Etherscan.io on 2021-05-16
*/

// SPDX-License-Identifier: UNLICENSED
// ALL RIGHTS RESERVED
// Unicrypt by SDDTech reserves all rights on this code. You may NOT copy these contracts.

pragma solidity ^0.8.0;

// An example TokenBlacklisting contract, the real prouction contract will differ entirely.
interface ITokenBlacklist {
    function checkToken(address _token) external view;
}

contract TokenBlacklist is ITokenBlacklist {
    
  address public blacklisted;
  
  /**
   * @notice set the conditon
   */
  function setBlacklistedToken(address _token) public {
    blacklisted = _token;
  }
  
  function checkToken(address _token) override external view {
      require(_token != blacklisted);
  }
}