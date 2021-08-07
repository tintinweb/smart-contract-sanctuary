// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CappedERC20.sol";
import "./Ownable.sol";

/**
 * MULTI TOKEN for PolyDefi.io
 * Ownable has been added in case we need to set something like a Masterchef as owner or renounce the ownership itself.
 */
contract PROF is CappedERC20, Ownable {
    constructor(uint256 initialSuply, string memory name, string memory symbol) CappedERC20(initialSuply,name,symbol){}
}