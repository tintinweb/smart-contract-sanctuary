// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Vesting.sol";

contract Strategic is Vesting {
    // TGE+60 day unlock 3%, lock 120 days, vest linearly over 30 months
    constructor(
        address _token,
        address _owner,
        uint256 _vestingStartAt
    )
        Vesting(
            _token,
            _owner,
            (_vestingStartAt + 5184000 + 7776000), // After fist claim + 90 days (claimed beginning of the each month)
            30, // lasting 30 months
            (_vestingStartAt + 5184000), // TGE + 60days
            3, // 3% for fist claim
            Frequently.MONTH
        )
    {}
}