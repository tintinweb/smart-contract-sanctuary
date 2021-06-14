// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./Snapshot.sol";
import "./BasePool.sol";

contract PairFarmPool is BasePool, Snapshot, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* 状态 0开放充提 1关闭充提  */
    uint256 public status;

    event Deposit(address indexed user, uint256 amount); // 抵押本金
    event Withdaw(address indexed user, uint256 amount); // 提现本金
    event GetReward(address indexed user, uint256 periodId, uint256 amount); // 根据周期ID提取奖励
    event Deduction(address indexed user, IERC20 token, uint256 amount); // 强制退款时扣除手续费
    event SetStatus(uint256 indexed status); // 设置状态
    event WithdrawToken(IERC20 token, uint256 amount); // 管理员从合约提现代币

    constructor(IERC20 _depositToken, IERC20 _rewardToken) {
        depositToken = _depositToken;
        rewardToken = _rewardToken;
    }

    /* 设置状态 */
    function setStatus(uint256 _status, uint256 reward)
        public
        virtual
        onlyOwner
    {
        status = _status;
        emit SetStatus(_status);

        /* 开放存取且奖励大于0时结束当期 */
        if (_status == 0 && reward > 0) {
            _snapshot(reward);
        }
    }

    /* 更新某期奖励 增加奖励补救预留补救接口 一般用不着 */
    function setTotalReward(uint256 periodId, uint256 reward)
        public
        virtual
        onlyOwner
    {
        _setTotalReward(periodId, reward);
    }

    /* 管理员提现代币 */
    function withdrawToken(IERC20 token, uint256 amount) public onlyOwner {
        token.safeTransfer(msg.sender, amount);
        emit WithdrawToken(token, amount);
    }

    // 强制提币
    function forceWithdaw(
        address user, // 用户账户
        uint256 amount, // 总金额
        uint256[] memory periodIds, // 期数ID
        uint256 depositTokenDeduction, // 扣除的本金
        uint256 rewardTokenDeduction // 每期扣除的奖励代币
    ) public virtual onlyOwner {
        /* 扣除奖励并提取 */
        for (uint256 i = 0; i < periodIds.length; i++) {
            uint256 rewardReceived = _rewardReceivedAt(user, periodIds[i]);
            _updateRewardReceivedAt(
                user,
                periodIds[i],
                rewardReceived.add(rewardTokenDeduction)
            );
            _getReward(user, periodIds[i]);
            emit Deduction(user, rewardToken, rewardTokenDeduction);
        }
        if (amount > 0) {
            require(amount > depositTokenDeduction);
            /* 扣除本金并提取 */
            _totalSupply = _totalSupply.sub(depositTokenDeduction);
            _balances[msg.sender] = _balances[msg.sender].sub(
                depositTokenDeduction
            );
            _withdaw(user, amount.sub(depositTokenDeduction));
            emit Deduction(user, depositToken, depositTokenDeduction);
        }
    }

    // 存款
    function deposit(uint256 amount) public virtual {
        require(status == 0, "PairFarmPool: Not in deposit status");
        _beforeUpdateUserBalance(msg.sender); // 先更新快照信息
        depositToken.safeTransferFrom(msg.sender, address(this), amount); // 将代币转入钱包
        _totalSupply = _totalSupply.add(amount); // 更新总余额
        _balances[msg.sender] = _balances[msg.sender].add(amount); // 更新用户余额
        emit Deposit(msg.sender, amount);
    }

    // 提现代币 amount 为0则只提取奖励   periodIds 为空数组则只提取本金
    function withdaw(uint256 amount, uint256[] memory periodIds)
        public
        virtual
        nonReentrant
    {
        require(status == 0, "PairFarmPool: Not in withdrawal status");
        require(
            amount > 0 || periodIds.length > 0,
            "PairFarmPool: Withdrawal params is wrong"
        );
        if (periodIds.length > 0) {
            _getRewards(periodIds);
        }
        if (amount > 0) {
            _withdaw(msg.sender, amount);
        }
    }

    /* 一次提取多期奖励 */
    function _getRewards(uint256[] memory periodIds) private {
        for (uint256 i = 0; i < periodIds.length; i++) {
            _getReward(msg.sender, periodIds[i]);
        }
    }

    // 内部方法 提现奖励
    function _getReward(address user, uint256 periodId) private {
        require(
            periodId <= currentSnapshotId(),
            "PairFarmPool: The reward for the current period has not been settled yet"
        );
        (uint256 totalSupply, uint256 totalReward) = snapshotInfoAt(periodId);
        (uint256 balance, uint256 rewardReceived) = _userInfoAt(user, periodId);
        /* 指定期数用户总奖励 */
        uint256 amount = balance.mul(totalReward).div(totalSupply);
        /* 条件: 已经领取的奖励小于总奖励 */
        require(
            rewardReceived < amount,
            "PairFarmPool: The reward has been withdrawn"
        );
        uint256 rewardToBeReceived = amount.sub(rewardReceived); // 计算待领取奖励
        _updateRewardReceivedAt(user, periodId, amount); // 更新已提取奖励
        rewardToken.safeTransfer(user, rewardToBeReceived); // 发送代币
        emit GetReward(user, periodId, rewardToBeReceived);
    }

    // 内部方法 提现代币
    function _withdaw(address user, uint256 amount) private {
        _beforeUpdateUserBalance(user); // 先更新快照信息
        depositToken.safeTransfer(user, amount);
        _totalSupply = _totalSupply.sub(amount); // 更新总余额
        _balances[user] = _balances[user].sub(amount); // 更新用户余额
        emit Withdaw(user, amount);
    }
}