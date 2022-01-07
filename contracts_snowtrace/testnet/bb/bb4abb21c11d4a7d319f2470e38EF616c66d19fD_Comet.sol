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
    mapping(address => mapping(address => bool)) public isAllowed;

    constructor(Configuration memory config) {
        // Set configuration variables
        governor = config.governor;
        priceOracle = config.priceOracle;
        baseToken = config.baseToken;
    }

    function allow(address manager, bool _isAllowed) external {
      allowInternal(msg.sender, manager, _isAllowed);
    }

    function allowInternal(address owner, address manager, bool _isAllowed) internal {
      isAllowed[owner][manager] = _isAllowed;
    }
}