// SPDX-License-Identifier: ADD VALID LICENSE
pragma solidity ^0.8.0;

contract Comet {
    struct Configuration {
        address governor;
        address priceOracle;
        address baseToken;
    }

    // Configuration constants
    address public immutable governor;
    address public immutable priceOracle;
    address public immutable baseToken;

    // Storage
    mapping(address => mapping(address => bool)) public isPermitted;

    constructor(Configuration memory config) {
        // Set configuration variables
        governor = config.governor;
        priceOracle = config.priceOracle;
        baseToken = config.baseToken;
    }

    function allow(address manager, bool isAllowed) external {
      allow(msg.sender, manager, isAllowed);
    }

    function allow(address owner, address manager, bool isAllowed) internal {
      require(owner == msg.sender, "Unauthorized");
      isPermitted[owner][manager] = isAllowed;
    }
}