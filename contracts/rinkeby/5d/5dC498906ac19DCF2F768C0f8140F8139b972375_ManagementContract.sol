// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

contract ManagementContract {
    function hasRole(bytes32 role, address account) external view returns (bool) {

    }

    function whitelist(address addr) external view {

    }

    function unWhitelist(address addr) external view {

    }

    function isWhitelisted(address addr) external view returns (bool) {

    }

    function freeze(address addr) external {

    }

    function unFreeze(address addr) external {

    }

    function isFrozen(address addr) external view returns (bool) {

    }

    function addSuperWhitelisted(address addr) external {

    }

    function removeSuperWhitelisted(address addr) external {

    }

    function isSuperWhitelisted(address addr) external view returns (bool) {

    }

    function nonWhitelistedDelay() external view returns (uint256) {

    }

    function nonWhitelistedDepositLimit() external view returns (uint256) {

    }

    function setNonWhitelistedDelay(uint256 _nonWhitelistedDelay) external view {

    }

    function setNonWhitelistedDepositLimit(uint256 _nonWhitelistedDepositLimit) external view {

    }

    function paused() external view returns (bool) {
        
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}