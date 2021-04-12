// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./library.sol";

/**
 * @notice do nothing
 */
contract DummyBuyBack is IBIMBuyBack {
    function burn() external override {
    }
}