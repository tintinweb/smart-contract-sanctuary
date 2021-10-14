// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./BokkyPooBahsDateTimeLibrary.sol";

contract TimeTest {
    function testWeek(uint256 offset) external view returns (uint) {
        uint dow = BokkyPooBahsDateTimeLibrary.getDayOfWeek(block.timestamp);
        uint diff = ((offset > dow) ? 0 : 7) + offset - dow;
        uint timestamp = BokkyPooBahsDateTimeLibrary.addDays(block.timestamp, diff);
        (uint y, uint m , uint d) = BokkyPooBahsDateTimeLibrary.timestampToDate(timestamp); // start day at midnight
        return BokkyPooBahsDateTimeLibrary.timestampFromDate(y, m, d);
    }

    function testMonth(uint256 offset) external view returns (uint) {
        (uint y, uint m, uint d) = BokkyPooBahsDateTimeLibrary.timestampToDate(block.timestamp);
        if (offset < d) {
            (y, m, d) = BokkyPooBahsDateTimeLibrary.timestampToDate(BokkyPooBahsDateTimeLibrary.addMonths(block.timestamp, 1));
        }
        uint dim = BokkyPooBahsDateTimeLibrary._getDaysInMonth(y, m);
        return BokkyPooBahsDateTimeLibrary.timestampFromDate(y, m, offset > dim ? dim : offset);
    }
}