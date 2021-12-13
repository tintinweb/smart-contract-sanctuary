/*
Pool

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.4;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

import "./IPool.sol";
import "./IPoolFactory.sol";
import "./IStakingModule.sol";
import "./IRewardModule.sol";
import "./IEvents.sol";
import "./OwnerController.sol";

/**
 * @title Pool
 *
 * @notice this implements the GYSR core Pool contract. It supports generalized
 * incentive mechanisms through a modular architecture, where
 * staking and reward logic is contained in child contracts.
 */
contract Pool is IPool, IEvents, ReentrancyGuard, OwnerController {
    using SafeERC20 for IERC20;

    // constants
    uint256 public constant DECIMALS = 18;

    // modules
    IStakingModule private immutable _staking;
    IRewardModule private immutable _reward;

    // gysr fields
    IERC20 private immutable _gysr;
    IPoolFactory private immutable _factory;
    uint256 private _gysrVested;

    /**
     * @param staking_ the staking module address
     * @param reward_ the reward module address
     * @param gysr_ address for GYSR token
     * @param factory_ address for parent factory
     */
    constructor(
        address staking_,
        address reward_,
        address gysr_,
        address factory_
    ) {
        _staking = IStakingModule(staking_);
        _reward = IRewardModule(reward_);
        _gysr = IERC20(gysr_);
        _factory = IPoolFactory(factory_);
    }

    // -- IPool --------------------------------------------------------------

    /**
     * @inheritdoc IPool
     */
    function stakingTokens() external view override returns (address[] memory) {
        return _staking.tokens();
    }

    /**
     * @inheritdoc IPool
     */
    function rewardTokens() external view override returns (address[] memory) {
        return _reward.tokens();
    }

    /**
     * @inheritdoc IPool
     */
    function stakingBalances(address user)
        external
        view
        override
        returns (uint256[] memory)
    {
        return _staking.balances(user);
    }

    /**
     * @inheritdoc IPool
     */
    function stakingTotals() external view override returns (uint256[] memory) {
        return _staking.totals();
    }

    /**
     * @inheritdoc IPool
     */
    function rewardBalances()
        external
        view
        override
        returns (uint256[] memory)
    {
        return _reward.balances();
    }

    /**
     * @inheritdoc IPool
     */
    function usage() external view override returns (uint256) {
        return _reward.usage();
    }

    /**
     * @inheritdoc IPool
     */
    function stakingModule() external view override returns (address) {
        return address(_staking);
    }

    /**
     * @inheritdoc IPool
     */
    function rewardModule() external view override returns (address) {
        return address(_reward);
    }

    /**
     * @inheritdoc IPool
     */
    function stake(
        uint256 amount,
        bytes calldata stakingdata,
        bytes calldata rewarddata
    ) external override nonReentrant {
        (address account, uint256 shares) =
            _staking.stake(msg.sender, amount, stakingdata);
        (uint256 spent, uint256 vested) =
            _reward.stake(account, msg.sender, shares, rewarddata);
        _processGysr(spent, vested);
    }

    /**
     * @inheritdoc IPool
     */
    function unstake(
        uint256 amount,
        bytes calldata stakingdata,
        bytes calldata rewarddata
    ) external override nonReentrant {
        (address account, uint256 shares) =
            _staking.unstake(msg.sender, amount, stakingdata);
        (uint256 spent, uint256 vested) =
            _reward.unstake(account, msg.sender, shares, rewarddata);
        _processGysr(spent, vested);
    }

    /**
     * @inheritdoc IPool
     */
    function claim(
        uint256 amount,
        bytes calldata stakingdata,
        bytes calldata rewarddata
    ) external override nonReentrant {
        (address account, uint256 shares) =
            _staking.claim(msg.sender, amount, stakingdata);
        (uint256 spent, uint256 vested) =
            _reward.claim(account, msg.sender, shares, rewarddata);
        _processGysr(spent, vested);
    }

    /**
     * @inheritdoc IPool
     */
    function update() external override nonReentrant {
        _staking.update(msg.sender);
        _reward.update(msg.sender);
    }

    /**
     * @inheritdoc IPool
     */
    function clean() external override nonReentrant {
        requireController();
        _staking.clean();
        _reward.clean();
    }

    /**
     * @inheritdoc IPool
     */
    function gysrBalance() external view override returns (uint256) {
        return _gysrVested;
    }

    /**
     * @inheritdoc IPool
     */
    function withdraw(uint256 amount) external override {
        requireController();
        require(amount > 0, "p1");
        require(amount <= _gysrVested, "p2");

        // do transfer
        _gysr.safeTransfer(msg.sender, amount);

        _gysrVested = _gysrVested - amount;

        emit GysrWithdrawn(amount);
    }

    /**
     * @notice transfer control of the Pool and modules to another account
     * @param newController address of new controller
     */
    function transferControl(address newController) public override {
        super.transferControl(newController);
        _staking.transferControl(newController);
        _reward.transferControl(newController);
    }

    // -- Pool internal -----------------------------------------------------

    /**
     * @dev private method to process GYSR spending and vesting
     * @param spent number of tokens to unstake
     * @param vested data passed to staking module
     */
    function _processGysr(uint256 spent, uint256 vested) private {
        // spending
        if (spent > 0) {
            _gysr.safeTransferFrom(msg.sender, address(this), spent);
        }

        // vesting
        if (vested > 0) {
            uint256 fee = (vested * _factory.fee()) / 10**DECIMALS;
            if (fee > 0) {
                _gysr.safeTransfer(_factory.treasury(), fee);
            }
            _gysrVested = _gysrVested + vested - fee;
        }
    }
}