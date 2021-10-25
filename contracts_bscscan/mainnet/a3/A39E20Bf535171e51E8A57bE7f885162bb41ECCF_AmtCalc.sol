// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import './StakingB.sol';

contract AmtCalc {
    Staking public STK;

    function getAmts() public view returns (uint256 balance, uint256 withdrawable) {
        Staking.Stake[] memory s = STK.stakesInfoAll();
        balance = IERC20(STK.TKN()).balanceOf(address(STK));
        for (uint256 i = 0; i < s.length; i++) if (!s[i].unstaked) withdrawable += s[i].finalAmount;
    }

    constructor(Staking _STK) {
        STK = _STK;
    }
}