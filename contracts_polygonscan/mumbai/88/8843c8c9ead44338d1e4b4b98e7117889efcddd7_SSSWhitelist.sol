/**
 *Submitted for verification at polygonscan.com on 2022-01-21
*/

// Sources flattened with hardhat v2.8.3 https://hardhat.org

// File contracts/SSSWhitelist.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @title SSS Whitelist Contract
/// @author Specxkal
contract SSSWhitelist {
  mapping(address => bool) isWhitelisted;
  mapping(address => bool) hasParticipated;
  address[] public whitelistedAdds;
  uint256 public totalSlots = 100;
  uint256 whitelistCount;

  /// @notice whitelist function for users to get whitelisted
  function whitelist(address _address) external {
    require(whitelistCount < 100, 'whitelisted count: exceeded amount');
    require(hasParticipated[msg.sender] == false, 'hasParticipated: true');
    require(isWhitelisted[_address] == false, 'whitelisted: true');
    hasParticipated[msg.sender] = true;
    isWhitelisted[_address] = true;
    whitelistedAdds.push(_address);
    whitelistCount++;
  }

  /// @dev get all whitelisted addresses
  function getWhitelistedAdds() external view returns (address[] memory) {
    return whitelistedAdds;
  }

  /// @notice shows remaining available slots for whitelisting
  /// @param remainingSlots represent number of available slots
  function getRemaining() external view returns (uint256 remainingSlots) {
    remainingSlots = totalSlots - whitelistCount;
  }
}