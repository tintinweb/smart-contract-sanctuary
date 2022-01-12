/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// Sources flattened with hardhat v2.6.8 https://hardhat.org

// File contracts/interfaces/IStakingPoolRewarder.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IStakingPoolRewarder {
    function onReward(
        uint256 poolId,
        address user,
        uint256 amount
    ) external;
}


// File contracts/DirectPayoutRewarder.sol


pragma solidity ^0.7.6;

contract DirectPayoutRewarder is IStakingPoolRewarder {

    address public stakingPool;
    address public rewardToken;
    address public rewardDispatcher;

    modifier onlyStakingPool() {
        require(stakingPool == msg.sender, "StakingPoolRewarder: only stakingPool can call");
        _;
    }
    event OnRewardRedeemded(uint256 indexed poolId, address user, uint256 amount);

    constructor(
        address _stakingPool,
        address _rewardToken,
        address _rewardDispatcher
    ) public {
        stakingPool = _stakingPool;
        rewardToken = _rewardToken;
        rewardDispatcher = _rewardDispatcher;
    }

    function onReward(
        uint256 poolId,
        address user,
        uint256 amount
    ) external override onlyStakingPool() {
        require(amount > 0, "StakingPoolRewarder: zero amount to reward");
        safeTransferFrom(rewardToken, rewardDispatcher, user, amount);
        emit OnRewardRedeemded(poolId, user, amount);
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

}