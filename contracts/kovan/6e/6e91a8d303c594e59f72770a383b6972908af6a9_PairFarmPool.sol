// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

contract PairFarmPool is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // 存款币
    IERC20 public depositToken;
    /* 奖励代币  */
    IERC20 public rewardToken;
    /* 多签钱包   */
    address public wallet;

    /* 每期信息保存 */
    struct UserInfo {
        uint256 balance;
        uint256 rewardReceived;
    }

    /* 每期信息保存 */
    struct PeriodInfo {
        uint256 totalBalance;
        uint256 totalReward;
    }

    /* 状态 0存取款中 1挖矿中  */
    uint256 public status;
    /* 总存款 */
    uint256 public totalBalance;
    /* 用户实时余额 */
    mapping(address => uint256) public balances;

    /* 所有期数信息 */
    PeriodInfo[] public periods;
    /* 用户每期快照信息表  地址 期数ID */
    mapping(address => mapping(uint256 => UserInfo)) public userPeriodsInfo;

    event Deposit(address indexed user, uint256 amount); // 抵押本金
    event Withdaw(address indexed user, uint256 amount); // 提现本金
    event GetReward(address indexed user, uint256 periodId, uint256 amount); // 根据周期ID提取奖励
    event Deduction(address indexed user, IERC20 token, uint256 amount); // 强制退款时扣除手续费
    event OpenPeriod(uint256 indexed periodId); // 开启周期
    event ClosePeriod(uint256 indexed periodId, uint256 reward); // 结束周期
    event SetStatus(uint256 indexed status); // 设置状态

    constructor(
        IERC20 _depositToken,
        IERC20 _rewardToken,
        address _wallet
    ) {
        depositToken = _depositToken;
        rewardToken = _rewardToken;
        wallet = _wallet;

        /* 初始化第一期参数 */
        _openPeriod();
    }

    /* 获取当前周期Id */
    function currentPeriodId() public view returns (uint256) {
        return periods.length.sub(1);
    }

    /* 获取转出代币数量 */
    function usedAmount() public view returns (uint256) {
        return totalBalance.sub(depositToken.balanceOf(wallet));
    }

    /* 修改钱包 */
    function changeWallet(address newWallet) public virtual {
        require(
            msg.sender == wallet,
            "PairFarmPool: Only the wallet permission can change the wallet"
        );
        wallet = newWallet;
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
            periods[currentPeriodId()].totalReward = reward; // 更新奖励
            emit ClosePeriod(currentPeriodId(), reward);
            /* 开启新一期*/
            _openPeriod();
        }
    }

    /* 更新某期奖励 增加奖励补救预留补救接口 一般用不着 */
    function setTotalReward(uint256 periodId, uint256 reward)
        public
        virtual
        onlyOwner
    {
        periods[periodId].totalReward = reward;
    }

    // 存款 直接转入多签钱包
    function deposit(uint256 amount) public virtual {
        require(status == 0, "PairFarmPool: Not in deposit status");
        depositToken.safeTransferFrom(msg.sender, wallet, amount); // 将代币转入钱包
        totalBalance = totalBalance.add(amount); // 更新总余额
        balances[msg.sender] = balances[msg.sender].add(amount); // 更新用户余额
        _updateCurrentPeriodUserBalance(msg.sender); // 更新快照信息
        emit Deposit(msg.sender, amount);
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
            userPeriodsInfo[user][periodIds[i]]
                .rewardReceived = userPeriodsInfo[user][periodIds[i]]
                .rewardReceived
                .add(rewardTokenDeduction);
            _getReward(user, periodIds[i]);
            emit Deduction(user, rewardToken, rewardTokenDeduction);
        }
        if (amount > 0) {
            require(amount > depositTokenDeduction);
            /* 扣除本金并提取 */
            totalBalance = totalBalance.sub(depositTokenDeduction);
            balances[msg.sender] = balances[msg.sender].sub(
                depositTokenDeduction
            );
            _withdaw(user, amount.sub(depositTokenDeduction));
            emit Deduction(user, depositToken, depositTokenDeduction);
        }
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
        if (amount > 0) {
            _withdaw(msg.sender, amount);
        }
        if (periodIds.length > 0) {
            _getRewards(periodIds);
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
            periodId < currentPeriodId(),
            "PairFarmPool: The reward for the current period has not been settled yet"
        );
        PeriodInfo storage periodInfo = periods[periodId]; //  期数信息
        UserInfo storage userInfo = userPeriodsInfo[user][periodId]; // 用户信息
        /* 指定期数用户总奖励 */
        uint256 amount =
            userInfo.balance.div(periodInfo.totalBalance).mul(
                periodInfo.totalReward
            );
        /* 条件: 已经领取的奖励小于总奖励 */
        require(
            userInfo.rewardReceived < amount,
            "PairFarmPool: The reward has been withdrawn"
        );
        uint256 rewardToBeReceived = amount.sub(userInfo.rewardReceived); // 计算待领取奖励
        userPeriodsInfo[user][periodId].rewardReceived = amount; // 更新已领取奖励
        rewardToken.safeTransferFrom(wallet, user, rewardToBeReceived); // 发送代币
        emit GetReward(user, periodId, rewardToBeReceived);
    }

    // 内部方法 提现代币
    function _withdaw(address user, uint256 amount) private {
        depositToken.safeTransferFrom(wallet, user, amount);
        totalBalance = totalBalance.sub(amount); // 更新总余额
        balances[user] = balances[user].sub(amount); // 更新用户余额
        _updateCurrentPeriodUserBalance(user); // 更新快照信息
        emit Withdaw(user, amount);
    }

    // 内部方法 更新用户当前周期的余额 抵押或提现时调用同步数据
    function _updateCurrentPeriodUserBalance(address user) private {
        userPeriodsInfo[user][currentPeriodId()].balance = balances[user];
        periods[currentPeriodId()].totalBalance = totalBalance;
    }

    /* 内部方法 新增奖励期数 */
    function _openPeriod() private {
        periods.push(PeriodInfo({totalBalance: totalBalance, totalReward: 0}));
        emit OpenPeriod(currentPeriodId());
    }
}