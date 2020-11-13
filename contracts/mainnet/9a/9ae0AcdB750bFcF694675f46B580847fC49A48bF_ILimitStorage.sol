// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/**
 * @title ILimitStorage
 * @notice LimitStorage interface
 */
interface ILimitStorage {

    struct Limit {
        // the current limit
        uint128 current;
        // the pending limit if any
        uint128 pending;
        // when the pending limit becomes the current limit
        uint64 changeAfter;
    }

    struct DailySpent {
        // The amount already spent during the current period
        uint128 alreadySpent;
        // The end of the current period
        uint64 periodEnd;
    }

    function setLimit(address _wallet, Limit memory _limit) external;

    function getLimit(address _wallet) external view returns (Limit memory _limit);

    function setDailySpent(address _wallet, DailySpent memory _dailySpent) external;

    function getDailySpent(address _wallet) external view returns (DailySpent memory _dailySpent);

    function setLimitAndDailySpent(address _wallet, Limit memory _limit, DailySpent memory _dailySpent) external;

    function getLimitAndDailySpent(address _wallet) external view returns (Limit memory _limit, DailySpent memory _dailySpent);
}