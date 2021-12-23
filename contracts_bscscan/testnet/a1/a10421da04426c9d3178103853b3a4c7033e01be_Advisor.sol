// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./Vesting.sol";
/**
 * @dev Lock 12 months, vest linearly over 36 months
 */
contract Advisor is Vesting {
    constructor(
        address _token,
        address _owner,
        uint256 _vestingStartAt
    )
        Vesting(
            _token,
            _owner,
            (_vestingStartAt + 28944000), // Lock 335 days (claimed beginning of the each month)
            36, // lasting in 36 months
            0,
            0,
            Frequently.MONTH
        )
    {}
}