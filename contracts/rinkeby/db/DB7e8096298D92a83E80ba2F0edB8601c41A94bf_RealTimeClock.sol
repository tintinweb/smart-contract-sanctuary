// Copyright 2019 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.



/// @title RealTimeClock
pragma solidity ^0.7.0;

/// @title RealTimeClock
/// @author Felipe Argento
/// @notice Real Time clock simulator
library RealTimeClock {
    uint64 constant RTC_FREQ_DIV = 100;
    
    /// @notice Converts from cycle count to time count
    /// @param cycle Cycle count
    /// @return Time count
    function rtcCycleToTime(uint64 cycle) public pure returns (uint64) {
        return cycle / RTC_FREQ_DIV;
    }

    /// @notice Converts from time count to cycle count
    /// @param  time Time count
    /// @return Cycle count
    function rtcTimeToCycle(uint64 time) public pure returns (uint64) {
        return time * RTC_FREQ_DIV;
    }
}