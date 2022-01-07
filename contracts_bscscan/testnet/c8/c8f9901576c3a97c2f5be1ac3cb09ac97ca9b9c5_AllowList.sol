// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import {Ownable} from "./Ownable.sol";

/**
 * @title AllowList
 * @author Anna Carroll
 */
contract AllowList is Ownable {
    // address => true if address is allowed
    mapping(address => bool) public allowed;

    // ======== External Functions =========

    function setAllowed(address _addr, bool _bool) external onlyOwner {
        allowed[_addr] = _bool;
    }
}