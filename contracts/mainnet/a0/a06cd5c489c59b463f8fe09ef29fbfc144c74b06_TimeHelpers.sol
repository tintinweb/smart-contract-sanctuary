// SPDX-License-Identifier: AGPL-3.0-only

/*
    TimeHelpers.sol - SKALE Manager
    Copyright (C) 2019-Present SKALE Labs
    @author Dmytro Stebaiev

    SKALE Manager is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity 0.6.10;

import "./SafeMath.sol";

import "./BokkyPooBahsDateTimeLibrary.sol";

/**
 * @title TimeHelpers
 * @dev The contract performs time operations.
 *
 * These functions are used to calculate monthly and Proof of Use epochs.
 */
contract TimeHelpers {
    using SafeMath for uint;

    uint constant private _ZERO_YEAR = 2020;

    function calculateProofOfUseLockEndTime(uint month, uint lockUpPeriodDays) external view returns (uint timestamp) {
        timestamp = BokkyPooBahsDateTimeLibrary.addDays(monthToTimestamp(month), lockUpPeriodDays);
    }

    function addDays(uint fromTimestamp, uint n) external pure returns (uint) {
        return BokkyPooBahsDateTimeLibrary.addDays(fromTimestamp, n);
    }

    function addMonths(uint fromTimestamp, uint n) external pure returns (uint) {
        return BokkyPooBahsDateTimeLibrary.addMonths(fromTimestamp, n);
    }

    function addYears(uint fromTimestamp, uint n) external pure returns (uint) {
        return BokkyPooBahsDateTimeLibrary.addYears(fromTimestamp, n);
    }

    function getCurrentMonth() external view virtual returns (uint) {
        return timestampToMonth(now);
    }

    function timestampToDay(uint timestamp) external view returns (uint) {
        uint wholeDays = timestamp / BokkyPooBahsDateTimeLibrary.SECONDS_PER_DAY;
        uint zeroDay = BokkyPooBahsDateTimeLibrary.timestampFromDate(_ZERO_YEAR, 1, 1) /
            BokkyPooBahsDateTimeLibrary.SECONDS_PER_DAY;
        require(wholeDays >= zeroDay, "Timestamp is too far in the past");
        return wholeDays - zeroDay;
    }

    function timestampToYear(uint timestamp) external view virtual returns (uint) {
        uint year;
        (year, , ) = BokkyPooBahsDateTimeLibrary.timestampToDate(timestamp);
        require(year >= _ZERO_YEAR, "Timestamp is too far in the past");
        return year - _ZERO_YEAR;
    }

    function timestampToMonth(uint timestamp) public view virtual returns (uint) {
        uint year;
        uint month;
        (year, month, ) = BokkyPooBahsDateTimeLibrary.timestampToDate(timestamp);
        require(year >= _ZERO_YEAR, "Timestamp is too far in the past");
        month = month.sub(1).add(year.sub(_ZERO_YEAR).mul(12));
        require(month > 0, "Timestamp is too far in the past");
        return month;
    }

    function monthToTimestamp(uint month) public view virtual returns (uint timestamp) {
        uint year = _ZERO_YEAR;
        uint _month = month;
        year = year.add(_month.div(12));
        _month = _month.mod(12);
        _month = _month.add(1);
        return BokkyPooBahsDateTimeLibrary.timestampFromDate(year, _month, 1);
    }
}
