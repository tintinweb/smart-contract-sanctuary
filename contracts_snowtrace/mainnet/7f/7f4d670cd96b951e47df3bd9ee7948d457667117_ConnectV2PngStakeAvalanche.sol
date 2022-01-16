pragma solidity ^0.7.0;

/**
 * @title Pangolin.
 * @dev Decentralized Exchange.
 */

import { TokenInterface } from "./interfaces.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";

abstract contract PangolinStakeResolver is Helpers, Events {

    // LP Staking
    /**
    * @notice Deposit LP token in MiniChefV2
    * @dev Use the Pangolin Stake resolver to get the pid
    * @param pid The index of the LP token in MiniChefV2.
    * @param amount The amount of the LP token to deposit.
    * @param getId ID to retrieve sellAmt.
    * @param setId ID stores the amount of token brought.
    */
    function depositLpStake(
        uint pid,
        uint amount,
        uint256 getId,
        uint256 setId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amount);

        address lpTokenAddr = _depositLPStake(pid, _amt);

        setUint(setId, _amt);
        _eventName = "LogDepositLpStake(address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(lpTokenAddr, pid, _amt, getId, setId);
    }

    /**
    * @notice Withdraw LP token from MiniChefV2
    * @dev Use the Pangolin Stake resolver to get the pid
    * @param pid The index of the LP token in MiniChefV2.
    * @param amount The amount of the LP token to withdraw.
    * @param getId ID to retrieve sellAmt.
    * @param setId ID stores the amount of token brought.
    */
    function withdrawLpStake(
        uint pid,
        uint amount,
        uint256 getId,
        uint256 setId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amount);

        address lpTokenAddr = _withdraw_LP_Stake(pid, _amt);

        setUint(setId, _amt);

        _eventName = "LogWithdrawLpStake(address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(lpTokenAddr, pid, _amt, getId, setId);
    }

    /**
    * @notice Withdraw LP token staked and claim rewards from MiniChefV2
    * @dev Use the Pangolin Stake resolver to get the pid
    * @param pid The index of the LP token in MiniChefV2.
    * @param amount The amount of the LP token to withdraw.
    * @param getId ID to retrieve sellAmt.
    * @param setId ID stores the amount of token brought.
    */
    function withdrawAndClaimLpRewards(
        uint pid,
        uint amount,
        uint256 getId,
        uint256 setId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amount);

        (uint256 rewardAmount, address lpTokenAddr) = _withdraw_and_getRewards_LP_Stake(pid, _amt);

        setUint(setId, _amt);

        _eventName = "LogWithdrawLpAndClaim(address,uint256,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(lpTokenAddr, pid, _amt, rewardAmount, getId, setId);
    }

    /**
    * @notice Claim rewards from MiniChefV2
    * @dev Use the Pangolin Stake resolver to get the pid
    * @param pid The index of the LP token in MiniChefV2.
    */
    function claimLpRewards(
        uint pid
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        (uint256 rewardAmount, address lpTokenAddr) = _getLPStakeReward(pid);

        _eventName = "LogClaimLpReward(address,uint256,uint256)";
        _eventParam = abi.encode(lpTokenAddr, pid, rewardAmount);
    }

    /**
    * @notice Emergency withdraw all LP token staked from MiniChefV2
    * @dev Use the Pangolin Stake resolver to get the pid
    * @param pid The index of the LP token in MiniChefV2.
    */
    function emergencyWithdrawLpStake(
        uint pid
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        (uint amount, address lpTokenAddr) = _emergencyWithdraw_LP_Stake(pid);

        _eventName = "LogEmergencyWithdrawLpStake(address,uint256,uint256)";
        _eventParam = abi.encode(lpTokenAddr, pid, amount);
    }

    // PNG Staking
    /**
    * @notice Deposit PNG in staking contract
    * @param stakingContract The address of the single PNG staking contract
    * @param amount The amount of the PNG to deposit.
    * @param getId ID to retrieve sellAmt.
    * @param setId ID stores the amount of token brought.
    */
    function depositPNGStake(
        address stakingContract,
        uint256 amount,
        uint256 getId,
        uint256 setId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amount);

        _depositPNGStake(stakingContract, _amt);

        setUint(setId, _amt);

        _eventName = "LogDepositPNGStake(address,uint256,uint256,uint256)";
        _eventParam = abi.encode(stakingContract, _amt, getId, setId);
    }

    /**
    * @notice Withdraw PNG staked from staking contract
    * @param stakingContract The address of the single PNG staking contract
    * @param amount The amount of the PNG to withdraw.
    * @param getId ID to retrieve sellAmt.
    * @param setId ID stores the amount of token brought.
    */
    function withdrawPNGStake(
        address stakingContract,
        uint256 amount,
        uint256 getId,
        uint256 setId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amount);

        _withdrawPNGStake(stakingContract, _amt);

        setUint(setId, _amt);

        _eventName = "LogWithdrawPNGStake(address,uint256,uint256,uint256)";
        _eventParam = abi.encode(stakingContract, _amt, getId, setId);
    }

    /**
    * @notice Withdraw all PNG staked from staking contract
    * @param stakingContract The address of the single PNG staking contract
    */
    function exitPNGStake(
        address stakingContract
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        (uint256 exitAmount, uint256 rewardAmount, address rewardToken) = _exitPNGStake(stakingContract);

        _eventName = "LogExitPNGStake(address,uint256,uint256,address)";
        _eventParam = abi.encode(stakingContract, exitAmount, rewardAmount, rewardToken);
    }

    /**
    * @notice Claim rewards from staking contract
    * @param stakingContract The address of the single PNG staking contract
    */
    function claimPNGStakeReward(
        address stakingContract
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        (uint256 rewardAmount, address rewardToken) = _claimPNGStakeReward(stakingContract);

        _eventName = "LogClaimPNGStakeReward(address,uint256,address)";
        _eventParam = abi.encode(stakingContract, rewardAmount, rewardToken);
    }
}

contract ConnectV2PngStakeAvalanche is PangolinStakeResolver {
    string public constant name = "Pangolin-Stake-v1";
}