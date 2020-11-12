// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import "./TokenTimelock.sol";

contract XMMxDevTimelock is TokenTimelock {
    constructor(IERC20 token, address beneficiary, uint256 releaseTime) public TokenTimelock(token, beneficiary, releaseTime) {}
}
