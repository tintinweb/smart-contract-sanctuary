// SPDX-License-Identifier: MIT

pragma solidity ^0.5.5;

import "Crowdsale.sol";
import "CappedCrowdsale.sol";
import "TimedCrowdsale.sol";

/**
 * @title ExmplCrowdsale.
 * @dev Formed and tested crowdsale.
 */

contract ExmplCrowdsale is Crowdsale, CappedCrowdsale, TimedCrowdsale {
    constructor (
        uint256 rate,
        address payable wallet,
        IERC20 token,
        uint256 cap,             // total cap, in wei
        uint256 openingTime,     // opening time in unix epoch seconds
        uint256 closingTime      // closing time in unix epoch seconds
    )
        public
        Crowdsale(rate, wallet, token)
        CappedCrowdsale(cap)
        TimedCrowdsale(openingTime, closingTime) {
    }
}