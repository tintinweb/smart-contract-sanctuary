// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

import "./IERC677.sol";
import "./ISweeper.sol";

/**
 * @title Keep3rSweeper
 * @dev Handles withdrawing of node rewards from Chainlink contracts.
 */
contract Keep3rSweeper is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC677;

    address[] public sweepers;

    address public rewardsWallet;
    IERC677 public rewardsToken;

    uint256 public minRewardsForPayment;
    uint256 public batchSize;

    event Withdraw(address indexed sender, uint256 amount);

    constructor(
        address _rewardsToken,
        address _rewardsWallet,
        uint256 _minRewardsForPayment,
        uint256 _batchSize
    ) {
        rewardsToken = IERC677(_rewardsToken);
        rewardsWallet = _rewardsWallet;
        minRewardsForPayment = _minRewardsForPayment;
        batchSize = _batchSize;
    }

    /**
     * @dev returns whether or not rewards should be withdrawn and the indexes to withdraw from
     * @return whether to perform upkeep and calldata to use
     **/
    function checkUpkeep(bytes calldata _checkData) external view returns (bool, bytes memory) {
        uint256[][] memory performData = new uint256[][](sweepers.length);
        uint256 totalRewards;
        uint256 batch = 0;

        for (uint i = 0; i < sweepers.length && batch < batchSize; i++) {
            ISweeper sweeper = ISweeper(sweepers[i]);
            uint256 minToWithdraw = sweeper.minToWithdraw();
            uint256[] memory canWithdraw = sweeper.withdrawable();

            uint256 canWithdrawCount;
            for (uint j = 0; j < canWithdraw.length && batch < batchSize; j++) {
                if (canWithdraw[j] >= minToWithdraw) {
                    canWithdrawCount++;
                    batch++;
                }
            }

            performData[i] = new uint256[](canWithdrawCount);

            uint256 addedCount;
            for (uint j = 0; j < canWithdraw.length && addedCount < canWithdrawCount; j++) {
                if (canWithdraw[j] >= minToWithdraw) {
                    totalRewards = totalRewards.add(canWithdraw[j]);
                    performData[i][addedCount++] = j;
                }
            }
        }

        return (totalRewards >= minRewardsForPayment, abi.encode(performData));
    }

    /**
     * @dev withdraw rewards for selected contracts if rewards >= minRewardsForPayment
     * @param _performData indexes of the contracts
     **/
    function performUpkeep(bytes calldata _performData) external {
        _withdraw(_performData);

        uint256 rewards = rewardsToken.balanceOf(address(this));
        require(rewards >= minRewardsForPayment, "Rewards must be >= minRewardsForPayment");

        rewardsToken.transferAndCall(rewardsWallet, rewards, "0x00");
        emit Withdraw(msg.sender, rewards);
    }

    /**
     * @dev withdraw rewards for selected contracts
     * @param _sweeperIdxs indexes of the contracts
     **/
    function withdraw(uint256[][] calldata _sweeperIdxs) external {
        _withdraw(abi.encode(_sweeperIdxs));

        uint256 rewards = rewardsToken.balanceOf(address(this));
        require(rewards > 0, "Rewards must be > 0");

        rewardsToken.transferAndCall(rewardsWallet, rewards, "0x00");
        emit Withdraw(msg.sender, rewards);
    }

    /**
     * @dev withdrawable amount from oracles
     * @return total withdrawable balance
     **/
    function withdrawable() external view returns (uint256[][] memory) {
        uint256[][] memory _withdrawable = new uint256[][](sweepers.length);
        for (uint i = 0; i < sweepers.length; i++) {
            _withdrawable[i] = ISweeper(sweepers[i]).withdrawable();
        }
        return _withdrawable;
    }

    /**
     * @dev adds sweeper address
     * @param _sweeper address to add
     **/
    function addSweeper(address _sweeper) external onlyOwner() {
        sweepers.push(_sweeper);
    }

    /**
     * @dev removes sweeper address
     * @param _index index of sweeper to remove
     **/
    function removeSweeper(uint256 _index) external onlyOwner() {
        require(_index < sweepers.length, "Sweeper does not exist");
        sweepers[_index] = sweepers[sweepers.length - 1];
        delete sweepers[sweepers.length - 1];
    }

    /**
     * @dev sets minimum amount of rewards needed to receive payment on withdraw
     * @param _minRewardsForPayment amount to set
     **/
    function setMinRewardsForPayment(uint256 _minRewardsForPayment) external onlyOwner() {
        minRewardsForPayment = _minRewardsForPayment;
    }

    /**
     * @dev sets maximum batch size for withdrawals
     * @param _batchSize amount to set
     **/
    function setBatchSize(uint256 _batchSize) external onlyOwner() {
        batchSize = _batchSize;
    }

    /**
     * @dev withdraw rewards for selected contracts
     * @param _sweeperIdxs indexes of the contracts
     **/
    function _withdraw(bytes memory _sweeperIdxs) private {
        uint256[][] memory sweeperIdxs = abi.decode(_sweeperIdxs, (uint256[][]));
        require(sweeperIdxs.length <= sweepers.length, "SweeperIdxs must be <= sweepers length");

        for (uint i = 0; i < sweeperIdxs.length; i++) {
            if (sweeperIdxs[i].length > 0) {
                ISweeper(sweepers[i]).withdraw(sweeperIdxs[i]);
            }
        }
    }
}