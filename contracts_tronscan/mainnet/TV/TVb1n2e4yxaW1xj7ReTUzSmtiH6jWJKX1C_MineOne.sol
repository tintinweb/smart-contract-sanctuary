//SourceUnit: MineIERC20.sol

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface MineIERC20 {
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
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view returns (uint8);

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


//SourceUnit: MineOne.sol

// 0.5.1-c8a2
// Enable optimization
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import "./MineIERC20.sol";
import "./MineSafeMath.sol";

/**
 * @title SimpleToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */
contract MineOne {

    using MineSafeMath for uint256;

    // 首页基础数据
    struct BaseData {
        uint8 stage; // 当前期数（取值为：1,2,3,4）
        uint256 pledgeAmount; // 质押总量
        uint256 nextMineAmount; // 下次挖矿总量
        uint256 ownerPledgeAmount; // 我的质押
        uint256 ownerNextReward; // 我的下次挖到收益
        uint256 ownerMineReward; // 挖矿未领取奖励
        uint256 ownerMineDrawAmount; // 挖矿已领取奖励
        address ownerSuperior; // 用户的上级
        uint256 ownerInviteReward; // 邀请未领取奖励
        uint256 ownerInviteDrawAmount; // 邀请已领取奖励
        string debSymbol; // DEB符号
        uint256 debDecimals; // DEB精度
        string dBossSymbol; // DBOSS符号
        uint256 dBossDecimals; // DBOSS精度
    }

    // 质押数据
    struct PledgeData {
        address owner; // 拥有者
        uint256 timestamp; // 质押时间
        uint256 amount; // 质押数量
        uint256 redeemTimestamp; // 赎回时间（为0表示未赎回）
        bool status; // 是否质押中
        uint256 diffTime; // 剩余赎回的时间（为0表示可以赎回）
    }

    // 挖矿提取数据
    struct MineDrawLog {
        uint256 timestamp; // 时间
        uint8 cate; // 分类（0：提取，1：产矿）
        uint256 amount; // 数量
    }

    // 邀请奖励提取数据
    struct InviteDrawLog {
        uint256 timestamp; // 时间
        address from; // 来自哪个用户，为空表示提取
        uint256 amount; // 数量
    }

    // 邀请数据
    struct Invite {
        address user; // 邀请的哪个用户
        uint256 timestamp; // 时间
    }

    // 挖矿数据
    struct MineData {
        address owner; // 挖矿者
        uint256 lastMineTime; // 最后一次挖矿时间
    }

    // 地址质押的列表
    mapping(address => PledgeData[]) private _addressPledges;

    // 地址质押的总量
    mapping(address => uint256) private _addressPledgeAmounts;

    // 地址挖矿未领取收益
    mapping(address => uint256) private _addressMineRewards;

    // 地址挖矿已领取收益
    mapping(address => uint256) private _addressMineDrawAmounts;

    // 挖矿提取明细
    mapping(address => MineDrawLog[]) private _addressMineDrawLogs;

    // 邀请关系
    mapping(address => Invite[]) private _invites;

    // 注册列表,存放上级地址
    mapping(address => address) private _registers;

    // 注册用户,存放已注册用户
    mapping(address => bool) private _users;

    // 根用户
    address root;

    // 地址邀请未领取收益
    mapping(address => uint256) private _addressInviteRewards;

    // 地址邀请已领取收益
    mapping(address => uint256) private _addressInviteDrawAmounts;

    // 奖励提取明细
    mapping(address => InviteDrawLog[]) private _addressInviteDrawLogs;

    // 最后一次挖矿的时间
    MineData[] _mines;

    // 质押总量
    uint256 private _pledgeAmount;

    // 质押增长ID
    uint256 private _pledgeNum;

    // 赎回天数
    uint256 _redeemDay = 90;

    // 当前阶段
    uint8 _stage = 1;

    // 最大阶段
    uint8 _maxStage = 4;

    // 阶段1挖矿占比
    uint8 _stage1 = 30;

    // 阶段2挖矿占比
    uint8 _stage2 = 25;

    // 阶段3挖矿占比
    uint8 _stage3 = 20;

    // 阶段4挖矿占比
    uint8 _stage4 = 25;

    // 邀请奖励的比例
    uint8 _inviteRewardRate = 15;

    // 挖矿总量
    uint256 mineAmount;

    // 挖矿状态
    bool _mineStatus;

    // 邀请奖励总量
    uint256 inviteAmount;

    MineIERC20 private _deb;

    MineIERC20 private _dBoss;

    address private _owner;

    //  是否初始化
    bool isInit = false;

    // 初始化时间，当天的零点
    uint256 initTime;

    // 质押事件
    event Pledge(address owner, uint256 amount);

    // 赎回事件
    event Redeem(address owner, uint256 amount);

    // 挖矿事件
    event MineLog(address owner, uint256 amount, address superior, uint256 reward);

    // 领取挖矿奖励事件
    event MineDraw(address owner, uint256 amount);

    // 领取邀请奖励事件
    event InviteDraw(address owner, uint256 amount);

    // 绑定上级事件
    event BindSuperior(address owner, address superior);

    modifier onlyOwner{
        require(msg.sender == _owner);
        _;
    }

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor (address debAddress, address dDossAddress){
        _deb = MineIERC20(debAddress);
        _dBoss = MineIERC20(dDossAddress);
        _owner = msg.sender;
        mineAmount = 14700 * (10 ** _dBoss.decimals());
        inviteAmount = 1470 * (10 ** _dBoss.decimals());
    }

    /**
     * @dev 初始化
     */
    function init(address rootAddress) external {
        require(!isInit, "Cannot be re-initialized");

        uint256 amount = mineAmount.add(inviteAmount);
        // 转入挖矿和邀请奖励的数量
        _dBoss.transferFrom(msg.sender, address(this), amount);
        isInit = true;
        root = rootAddress;
        // 设置根用户
        // 当前时间的零点 = 当前时间减去对 86400 取模，再减去一个 8小时（28800）
        initTime = block.timestamp.sub(block.timestamp.mod(86400)).sub(28800);
    }

    /**
    *  @dev 质押
    */
    function pledge(uint256 amount) external returns (bool) {

        require(!_mineStatus, "During mining, cannot be pledged for the time being");

        require(isInit, "First initialize");

        // 判断是否注册过
        require(_registers[msg.sender] != address(0), "Please register first");

        _deb.transferFrom(msg.sender, address(this), amount);

        PledgeData memory pData;

        pData.owner = msg.sender;
        pData.amount = amount;
        pData.timestamp = block.timestamp;
        pData.status = false;
        pData.diffTime = 0;
        pData.redeemTimestamp = 0;
        _addressPledges[msg.sender].push(pData);

        _addressPledgeAmounts[msg.sender] = _addressPledgeAmounts[msg.sender].add(amount);
        //修改用户的个人质押总量

        _pledgeAmount = _pledgeAmount.add(amount);

        _pledgeNum++;

        emit Pledge(msg.sender, amount);
        return true;
    }

    /**
    *  @dev 一键质押时，获取预计收益
    */
    function predict(uint256 amount) public view returns (uint256) {

        return _calculateReward(amount, _pledgeAmount.add(amount));

    }

    /**
    *  @dev 计算收益
    */
    function _calculateReward(uint256 amount, uint256 sumAmount) internal view returns (uint256) {

        if (sumAmount == 0) {
            return 0;
        }

        uint256 sum = _mineSumAmount();

        return sum.div(_redeemDay).mul(amount).div(sumAmount);

    }

    /**
    *  @dev 获取当前期的挖矿总量
    */
    function _mineSumAmount() internal view returns (uint256) {

        uint256 rewardRate;
        if (_stage == 1) {
            // 阶段1
            rewardRate = _stage1;
        } else if (_stage == 2) {
            // 阶段2
            rewardRate = _stage2;
        } else if (_stage == 3) {
            // 阶段3
            rewardRate = _stage3;
        } else if (_stage == 4) {
            // 阶段4
            rewardRate = _stage4;
        } else {
            return 0;
        }

        return mineAmount.mul(rewardRate).div(100);

    }

    /**
    *  @dev 赎回
    */
    function redeem(uint256 index) external returns (bool) {

        require(isInit, "First initialize");

        PledgeData memory pData;
        pData = _addressPledges[msg.sender][index];
        if (pData.status == true) {
            return true;
        }

        require(block.timestamp.sub(pData.timestamp) > _redeemDay.mul(86400), "The pledge time must exceed 90 days");
        uint256 amount = pData.amount;
        pData.status = true;
        pData.redeemTimestamp = block.timestamp;
        _addressPledges[msg.sender][index] = pData;
        _pledgeAmount = _pledgeAmount.sub(amount);
        //修改用户质押总量
        _addressPledgeAmounts[msg.sender] = _addressPledgeAmounts[msg.sender].sub(amount);
        //修改用户的个人质押总量
        emit Redeem(msg.sender, amount);

        _deb.transfer(msg.sender, amount);

        return true;
    }

    /**
    *  @dev 验证是否可以赎回
    */
    function CheckRedeem(uint256 index) external view returns (bool) {

        PledgeData memory pData;
        pData = _addressPledges[msg.sender][index];
        if (pData.status == true) {
            return false;
        }

        return block.timestamp.sub(pData.timestamp) > _redeemDay.mul(86400);
    }

    /**
    *  @dev 获取当前地址的质押次数
    */
    function addressPledgeLen() external view returns (uint256) {
        return _addressPledges[msg.sender].length;
    }

    /**
    *  @dev 分页返回质押列表
    */
    function pledges(uint256 page, uint256 pageSize) external view returns (PledgeData[] memory) {

        uint256 start = (page - 1) * pageSize;
        uint256 end = (page) * pageSize;

        address owner = msg.sender;

        if (start >= _addressPledges[owner].length) {
            return new PledgeData[](0);
        }
        if (end > _addressPledges[owner].length) {
            end = _addressPledges[owner].length;
        }
        PledgeData[] memory result = new PledgeData[](end - start);
        uint256 resultIndex = 0;
        for (uint256 i = start; i < end; i++) {
            result[resultIndex] = _addressPledges[owner][i];
            // 判断剩余赎回时间
            uint256 diff = block.timestamp.sub(result[resultIndex].timestamp);
            if (diff <= _redeemDay.mul(86400)) {
                result[resultIndex].diffTime = _redeemDay.mul(86400).sub(diff);
            }
            resultIndex++;
        }
        return result;
    }

    /**
    *  @dev 领取挖矿收益
    */
    function addressMineDraw() external returns (bool) {

        uint256 reward = _addressMineRewards[msg.sender];

        require(reward > 0, "There are currently no available");

        _addressMineRewards[msg.sender] = 0;

        MineDrawLog memory mineDrawLog;
        mineDrawLog.timestamp = block.timestamp;
        mineDrawLog.cate = 0;
        mineDrawLog.amount = reward;
        _addressMineDrawLogs[msg.sender].push(mineDrawLog);
        _addressMineDrawAmounts[msg.sender] = _addressMineDrawAmounts[msg.sender].add(reward);

        _dBoss.transfer(msg.sender, reward);

        emit MineDraw(msg.sender, reward);
        return true;
    }

    /**
    *  @dev 获取已领取的挖矿收益明细的次数
    */
    function addressMineDrawLogLen() public view returns (uint256) {
        return _addressMineDrawLogs[msg.sender].length;
    }

    /**
    *  @dev 分页返回挖矿奖励明细
    */
    function addressMineDrawLogs(uint256 page, uint256 pageSize) external view returns (MineDrawLog[] memory) {

        uint256 start = (page - 1) * pageSize;
        uint256 end = (page) * pageSize;

        address owner = msg.sender;

        if (start >= _addressMineDrawLogs[owner].length) {
            return new MineDrawLog[](0);
        }
        if (end > _addressMineDrawLogs[owner].length) {
            end = _addressMineDrawLogs[owner].length;
        }
        MineDrawLog[] memory result = new MineDrawLog[](end - start);
        uint256 resultIndex = 0;
        for (uint256 i = start; i < end; i++) {
            result[resultIndex] = _addressMineDrawLogs[owner][i];
            resultIndex++;
        }
        return result;
    }

    /**
    *  @dev 领取邀请收益
    */
    function addressInviteDraw() external returns (bool) {

        uint256 reward = _addressInviteRewards[msg.sender];

        require(reward > 0, "There are currently no available");

        _addressInviteRewards[msg.sender] = 0;

        InviteDrawLog memory inviteDrawLog;
        inviteDrawLog.timestamp = block.timestamp;
        inviteDrawLog.from = address(0);
        inviteDrawLog.amount = reward;
        _addressInviteDrawLogs[msg.sender].push(inviteDrawLog);
        _addressInviteDrawAmounts[msg.sender] = _addressInviteDrawAmounts[msg.sender].add(reward);

        _dBoss.transfer(msg.sender, reward);

        emit InviteDraw(msg.sender, reward);
        return true;
    }

    /**
    *  @dev 获取已领取的邀请收益明细的次数
    */
    function addressInviteDrawLogLen() public view returns (uint256) {
        return _addressInviteDrawLogs[msg.sender].length;
    }

    /**
    *  @dev 分页返回邀请奖励领取明细
    */
    function addressInviteDrawLogs(uint256 page, uint256 pageSize) external view returns (InviteDrawLog[] memory) {

        uint256 start = (page - 1) * pageSize;
        uint256 end = (page) * pageSize;

        address owner = msg.sender;

        if (start >= _addressInviteDrawLogs[owner].length) {
            return new InviteDrawLog[](0);
        }
        if (end > _addressInviteDrawLogs[owner].length) {
            end = _addressInviteDrawLogs[owner].length;
        }
        InviteDrawLog[] memory result = new InviteDrawLog[](end - start);
        uint256 resultIndex = 0;
        for (uint256 i = start; i < end; i++) {
            result[resultIndex] = _addressInviteDrawLogs[owner][i];
            resultIndex++;
        }
        return result;
    }


    /**
    *  @dev 注册
    */
    function register(address superior) external returns (bool) {

        if (_registers[msg.sender] != address(0)) {
            return true;
        }
        // 上级不能是自己
        require(superior != msg.sender, "The superior cannot be himself ");
        // 上级必须已存在或者为根账户
        require(_users[superior] || superior == root, "superior does not exist");
        _users[msg.sender] = true;

        _registers[msg.sender] = superior;
        Invite memory invite;
        invite.user = msg.sender;
        invite.timestamp = block.timestamp;
        _invites[superior].push(invite);

        MineData memory mineData;
        mineData.owner = msg.sender;
        mineData.lastMineTime = block.timestamp.sub(block.timestamp.mod(86400)).sub(28800).sub(86400);
        // 最后挖矿时间设置成昨天
        _mines.push(mineData);


        emit BindSuperior(msg.sender, superior);
        return true;
    }

    /**
    *  @dev 分页返回邀请列表
    */
    function invites(uint256 page, uint256 pageSize) external view returns (Invite[] memory) {

        uint256 start = (page - 1) * pageSize;
        uint256 end = (page) * pageSize;

        address owner = msg.sender;

        if (start >= _invites[owner].length) {
            return new Invite[](0);
        }
        if (end > _invites[owner].length) {
            end = _invites[owner].length;
        }
        Invite[] memory result = new Invite[](end - start);
        uint256 resultIndex = 0;
        for (uint256 i = start; i < end; i++) {
            result[resultIndex] = _invites[owner][i];
            resultIndex++;
        }
        return result;
    }

    /**
    *  @dev 返回基础数据
    */
    function base() external view returns (BaseData memory) {

        BaseData memory baseData;
        baseData.stage = _stage;
        baseData.pledgeAmount = _pledgeAmount;
        baseData.nextMineAmount = _mineSumAmount().div(_redeemDay);
        baseData.ownerPledgeAmount = _addressPledgeAmounts[msg.sender];
        baseData.ownerNextReward = _calculateReward(baseData.ownerPledgeAmount, _pledgeAmount);
        baseData.ownerMineReward = _addressMineRewards[msg.sender];
        baseData.ownerMineDrawAmount = _addressMineDrawAmounts[msg.sender];
        baseData.ownerSuperior = _registers[msg.sender];
        baseData.ownerInviteReward = _addressInviteRewards[msg.sender];
        baseData.ownerInviteDrawAmount = _addressInviteDrawAmounts[msg.sender];
        baseData.debSymbol = _deb.symbol();
        baseData.debDecimals = _deb.decimals();
        baseData.dBossSymbol = _dBoss.symbol();
        baseData.dBossDecimals = _dBoss.decimals();
        return baseData;
    }


    /**
    *  @dev 分页挖矿，返回挖矿数量，0表示没有可挖
    */
    function mine(uint256 page, uint256 pageSize) external onlyOwner returns (uint256) {

        pageSize = pageSize > 100 ? 100 : pageSize;

        uint256 start = (page - 1) * pageSize;
        uint256 end = (page) * pageSize;

        uint256 mineNum = 0;

        if (start >= _mines.length) {
            return mineNum;
        }
        if (end > _mines.length) {
            end = _mines.length;
        }

        // 当前时间的零点
        uint256 time0 = block.timestamp.sub(block.timestamp.mod(86400)).sub(28800);

        // 上次挖矿时间的零点
        uint256 lastTime = time0.sub(86400);

        uint256 tmpStage = time0.sub(initTime).div(86400);

        if (tmpStage <= _redeemDay) {
            _stage = 1;
        } else if (tmpStage <= _redeemDay.mul(2)) {
            _stage = 2;
        } else if (tmpStage <= _redeemDay.mul(3)) {
            _stage = 3;
        } else if (tmpStage <= _redeemDay.mul(4)) {
            _stage = 4;
        }

        require(_stage <= _maxStage, "The number of mining periods exceeds the maximum number of periods");

        if (!_mineStatus) {
            _mineStatus = true;
        }

        for (uint256 i = start; i < end; i++) {
            MineData memory mineData;
            mineData = _mines[i];
            // 上次挖矿时间不对
            if (mineData.lastMineTime != lastTime) {
                continue;
            }
            /* ########## 挖矿 ########### */
            // 获取质押总量
            uint256 minePledge = _addressPledgeAmounts[mineData.owner];

            // 生成奖励
            uint256 reward = _calculateReward(minePledge, _pledgeAmount);

            if (reward > 0) {
                _addressMineRewards[mineData.owner] = _addressMineRewards[mineData.owner].add(reward);
                MineDrawLog memory mineDrawLog;
                mineDrawLog.timestamp = block.timestamp;
                mineDrawLog.cate = 1;
                mineDrawLog.amount = reward;
                _addressMineDrawLogs[mineData.owner].push(mineDrawLog);

                // 如果有上级计算层级奖励
                address superior = _registers[mineData.owner];
                uint256 superiorReward = 0;
                if (superior != address(0)) {
                    superiorReward = reward.mul(_inviteRewardRate).div(100);
                    if (superiorReward > 0) {
                        _addressInviteRewards[superior] = _addressInviteRewards[superior].add(superiorReward);
                        InviteDrawLog memory inviteDrawLog;
                        inviteDrawLog.timestamp = block.timestamp;
                        inviteDrawLog.from = mineData.owner;
                        inviteDrawLog.amount = superiorReward;
                        _addressInviteDrawLogs[superior].push(inviteDrawLog);
                    }
                }

                emit MineLog(mineData.owner, reward, superior, superiorReward);

            }
            mineData.lastMineTime = mineData.lastMineTime.add(86400);
            _mines[i] = mineData;
            mineNum++;
        }

        if (mineNum == 0) {
            _mineStatus = false;
        }

        return mineNum;
    }

}

//SourceUnit: MineSafeMath.sol

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library MineSafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}