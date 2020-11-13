// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.5.17;

import "@openzeppelin/contracts/access/roles/SignerRole.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./imports/OneSplitAudit.sol";
import "../IRewards.sol";

contract OneSplitDumper is SignerRole {
    using SafeERC20 for IERC20;

    OneSplitAudit public oneSplit;
    IRewards public rewards;
    IERC20 public rewardToken;

    constructor(
        address _oneSplit,
        address _rewards,
        address _rewardToken
    ) public {
        oneSplit = OneSplitAudit(_oneSplit);
        rewards = IRewards(_rewards);
        rewardToken = IERC20(_rewardToken);
    }

    function getDumpParams(address tokenAddress, uint256 parts)
        external
        view
        returns (uint256 returnAmount, uint256[] memory distribution)
    {
        IERC20 token = IERC20(tokenAddress);
        uint256 tokenBalance = token.balanceOf(address(this));
        (returnAmount, distribution) = oneSplit.getExpectedReturn(
            tokenAddress,
            address(rewardToken),
            tokenBalance,
            parts,
            0
        );
    }

    function dump(
        address tokenAddress,
        uint256 returnAmount,
        uint256[] calldata distribution
    ) external onlySigner {
        // dump token for rewardToken
        IERC20 token = IERC20(tokenAddress);
        uint256 tokenBalance = token.balanceOf(address(this));
        token.safeIncreaseAllowance(address(oneSplit), tokenBalance);

        uint256 receivedRewardTokenAmount = oneSplit.swap(
            tokenAddress,
            address(rewardToken),
            tokenBalance,
            returnAmount,
            distribution,
            0
        );
        require(
            receivedRewardTokenAmount > 0,
            "OneSplitDumper: receivedRewardTokenAmount == 0"
        );
    }

    function notify() external onlySigner {
        uint256 balance = rewardToken.balanceOf(address(this));
        rewardToken.safeTransfer(address(rewards), balance);
        rewards.notifyRewardAmount(balance);
    }
}
