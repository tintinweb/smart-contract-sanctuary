// SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */
pragma solidity 0.7.6;

import "./SafeMath.sol";
import "./Permissions.sol";
import "./Withdrawable.sol";
import "./IPENDLE.sol";
import "./IPendleTokenDistribution.sol";

// There will be two instances of this contract to be deployed to be
// the pendleTeamTokens and pendleEcosystemFund (for PENDLE.sol constructor arguments)
contract PendleTokenDistribution is Permissions, IPendleTokenDistribution {
    using SafeMath for uint256;

    IPENDLE public override pendleToken;

    uint256[] public timeDurations;
    uint256[] public claimableFunds;
    mapping(uint256 => bool) public claimed;
    uint256 public numberOfDurations;

    constructor(
        address _governance,
        uint256[] memory _timeDurations,
        uint256[] memory _claimableFunds
    ) Permissions(_governance) {
        require(_timeDurations.length == _claimableFunds.length, "MISMATCH_ARRAY_LENGTH");
        numberOfDurations = _timeDurations.length;
        for (uint256 i = 0; i < numberOfDurations; i++) {
            timeDurations.push(_timeDurations[i]);
            claimableFunds.push(_claimableFunds[i]);
        }
    }

    function initialize(IPENDLE _pendleToken) external {
        require(msg.sender == initializer, "FORBIDDEN");
        require(address(_pendleToken) != address(0), "ZERO_ADDRESS");
        require(_pendleToken.isPendleToken(), "INVALID_PENDLE_TOKEN");
        require(_pendleToken.balanceOf(address(this)) > 0, "UNDISTRIBUTED_PENDLE_TOKEN");
        pendleToken = _pendleToken;
        initializer = address(0);
    }

    function claimTokens(uint256 timeDurationIndex) public onlyGovernance {
        require(timeDurationIndex < numberOfDurations, "INVALID_INDEX");
        require(!claimed[timeDurationIndex], "ALREADY_CLAIMED");
        claimed[timeDurationIndex] = true;

        uint256 claimableTimestamp = pendleToken.startTime().add(timeDurations[timeDurationIndex]);
        require(block.timestamp >= claimableTimestamp, "NOT_CLAIMABLE_YET");
        uint256 currentPendleBalance = pendleToken.balanceOf(address(this));

        uint256 amount =
            claimableFunds[timeDurationIndex] < currentPendleBalance
                ? claimableFunds[timeDurationIndex]
                : currentPendleBalance;
        require(pendleToken.transfer(governance, amount), "FAIL_PENDLE_TRANSFER");
        emit ClaimedTokens(
            governance,
            timeDurations[timeDurationIndex],
            claimableFunds[timeDurationIndex],
            amount
        );
    }
}