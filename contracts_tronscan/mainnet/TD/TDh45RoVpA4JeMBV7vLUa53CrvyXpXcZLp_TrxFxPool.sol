//SourceUnit: TrxFxPool.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

contract TrxFxPool is Ownable {
    IERC20 public rewardToken;   // FX的token地址
    IERC20 public stakeToken;   // 质押LP地址

    uint256 private _totalSupply;  // 总的质押数量
    mapping(address => uint256) private balances;  // 存储用户质押数量的map

    //365天挖12万
    uint256 public constant DURATION = 365 days;   // 挖矿周期
    uint256 public rewardsPerCycle = 120000 * 1e6;   // 一个周期奖励的FX数量（注意精度）
    uint256 public rewardPerSecond = 0;   // 每秒奖励
    uint256 public rewardPerTokenStored; // 每个LP，已获取的利润

    uint256 public startTime = 1632810248;  // 开始时间（根据需要更新）
    uint256 public endTime = 0;    // 结束时间
    uint256 public lastUpdateTime;   // 上次计算奖励的更新时间

    mapping(address => uint256) public userRewardPerTokenPaid; // 存储用户截止到数据更新是，每个LP获取的奖励
    mapping(address => uint256) public rewards; // 存储用户可提取的奖励

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    constructor() {
        endTime = startTime + DURATION;
        rewardPerSecond = rewardsPerCycle / DURATION;
        // 下面两个地址要替换成真实地址
        /* rewardToken = IERC20(0xc463a785Cb05c6dDd0Fdac9273EdeE973f6e1D79);
        stakeToken = IERC20(0xc463a785Cb05c6dDd0Fdac9273EdeE973f6e1D79); */
    }

    // 检查是否开始挖矿了
    modifier checkStart() {
        require(block.timestamp > startTime, "Not start.");
        _;
    }

    // 检查是否结束
    modifier checkEnd() {
        require(block.timestamp <= endTime, "End");
        _;
    }
    // 每次有LP有变动的时候 更新用户的奖励状态（质押，提取奖励，退出）
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        // 重新计算截止到目前每个token的奖励
        lastUpdateTime = lastTimeRewardApplicable();
        // 更新计算时间
        if (account != address(0)) {
            // 计算用户的奖励并存储起来
            rewards[account] = earned(account);
            //记录用户每个LP已获取的奖励数据
            userRewardPerTokenPaid[account] = rewardPerTokenStored;

        }
        _;
    }



    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    receive() external payable {
    }

    // 用于计算奖励的时间
    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, endTime);
    }

    // 计算每个质押LP，截止到目前可以获取的奖励
    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
        rewardPerTokenStored
        + (lastTimeRewardApplicable() - lastUpdateTime)
        * rewardPerSecond
        * 1e6
        / totalSupply();
    }

    // 查询当前账号转的钱
    function earned(address account) public view returns (uint256) {
        return
        balanceOf(account)
        * (rewardPerToken() - userRewardPerTokenPaid[account])
        / 1e6
        + rewards[account];
    }
    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function stake(uint256 amount) public checkStart updateReward(msg.sender) checkEnd
    {
        require(amount > 0, "Cannot stake 0");
        _totalSupply += amount;
        balances[msg.sender] += amount;
        stakeToken.transferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    // 提取存入的LP
    function withdraw(uint256 amount) public checkStart updateReward(msg.sender) checkEnd
    {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply -= amount;
        balances[msg.sender] -= amount;
        stakeToken.transfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }
    // 获取收益
    function getReward() public checkStart updateReward(msg.sender) checkEnd {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardToken.transfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    // 退出挖矿
    function exit() public {
        withdraw(balanceOf(msg.sender));
        getReward();
    }
    //=========================only owner=======================================
    // 这是开始见
    function setStartTime(uint256 _startTime) public onlyOwner {
        startTime = _startTime;
        endTime = startTime + DURATION;

    }
    // 这是每个周期的奖励数量
    function setRewardsPerCycle(uint256 _rewardsPerCycle) public onlyOwner {
        rewardsPerCycle = _rewardsPerCycle;
        rewardPerSecond = rewardsPerCycle / DURATION;
    }

    // 设置奖励Token的地址
    function setRewardToken(address rewardTokenAddress) public onlyOwner {
        require(rewardTokenAddress != address(0), "Zero Address.");
        rewardToken = IERC20(rewardTokenAddress);
    }

    // 设置质押Token地址
    function setStakeToken(address stakeTokenAddress) public onlyOwner {
        require(stakeTokenAddress != address(0), "Zero Address.");
        stakeToken = IERC20(stakeTokenAddress);
    }

    function renounceOwnership() public override onlyOwner {
    }

    // 销毁函数，请慎用
    function k() public onlyOwner {
        selfdestruct(payable(msg.sender));
    }
}