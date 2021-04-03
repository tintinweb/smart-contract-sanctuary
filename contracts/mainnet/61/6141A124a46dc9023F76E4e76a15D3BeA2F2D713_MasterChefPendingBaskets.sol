// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./MasterChef.sol";

contract MasterChefPendingBaskets {
    using SafeMath for uint256;

    MasterChef public immutable masterchef;

    constructor(address _masterchef) {
        masterchef = MasterChef(_masterchef);
    }

    // Fixed helper function to calculate pending baskets
    function pendingBasket(uint256 _pid, address _user) external view returns (uint256) {
        if (_pid >= masterchef.poolLength()) {
            return 0;
        }

        (IERC20 lpToken, uint256 allocPoint, uint256 lastRewardBlock, uint256 accBasketPerShare) =
            masterchef.poolInfo(_pid);
        (uint256 amount, uint256 rewardDebt) = masterchef.userInfo(_pid, _user);

        uint256 lpSupply = lpToken.balanceOf(address(masterchef));

        if (block.number > lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = masterchef.getMultiplier(lastRewardBlock, block.number);
            uint256 basketReward =
                multiplier.mul(masterchef.basketPerBlock()).mul(allocPoint).div(masterchef.totalAllocPoint());

            uint256 devAlloc = basketReward.mul(masterchef.devFundRate()).div(masterchef.divRate());
            uint256 treasuryAlloc = basketReward.mul(masterchef.treasuryRate()).div(masterchef.divRate());

            uint256 basketWithoutDevAndTreasury = basketReward.sub(devAlloc).sub(treasuryAlloc);

            accBasketPerShare = accBasketPerShare.add(basketWithoutDevAndTreasury.mul(1e12).div(lpSupply));
        }
        return amount.mul(accBasketPerShare).div(1e12).sub(rewardDebt);
    }
}