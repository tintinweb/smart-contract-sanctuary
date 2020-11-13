// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.5.17;

import "./OneSplitDumper.sol";
import "./withdrawers/CurveLPWithdrawer.sol";
import "./withdrawers/YearnWithdrawer.sol";

contract Dumper is OneSplitDumper, CurveLPWithdrawer, YearnWithdrawer {
    constructor(
        address _oneSplit,
        address _rewards,
        address _rewardToken
    ) public OneSplitDumper(_oneSplit, _rewards, _rewardToken) {}
}
