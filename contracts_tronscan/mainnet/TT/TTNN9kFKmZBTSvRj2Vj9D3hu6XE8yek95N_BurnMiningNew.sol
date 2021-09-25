//SourceUnit: BurnMiningTest.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
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
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(address _to, uint256 _amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface IOracle {
    function consultAveragePrice(address token, uint256 interval) external view returns (uint256);
}

// txToken: 0x7BACABB0B39C29B890CD9DB2DF9F9450972B7B89
// genesisUser: 0xB3DDBE2A15E722D56FEC480AABB65AD15BE053FE
// BurnMiningNew: 0x52EDF0178C4F87150FED4FD95C4F200A43C0AEE5/0xBEDB57E2850130BC58A14083722B8D508619540A
// Lands: 0xD46C1BB0410EDDEC4E11BA7C8AAF2C73B3A322A6
contract BurnMiningNew is Ownable {
    using SafeMath for uint256;

    enum Level { BORN, PEOPLE, LAND, SKY }

    // 燃烧增加算力：用户地址、燃烧价值、燃烧token数量、燃烧获得的产币额度、燃烧获得的个人算力、24h均价、推荐人地址
    event BurnAddPower(address user, uint256 value, uint256 tokenValue, uint256 burnedToUSDT, uint256 burnPower, uint256 price, address referrer);
    // 注册事件：用户地址、推荐人地址
    event Registration(address user, address referer);
    // 用户等级变动
    event ChangeLevel(address user, Level oldLevel, Level newLevel);
    // 开始清算
    event StartSettling(uint256 blockNum, uint256 price);
    // 结束清算
    event EndSettling(uint256 blockNum);
    // 分配奖励减少算力和额度：用户地址、减少的产币额度、减少的产币算力、分配的token数量、扣减后的token数量、
    event DistributeReward(address user, uint256 costBurnedToUSDT, uint256 costBurnedToPower, uint256 rewardNum, uint256 newRewardNum, uint256 poolReward, uint256 rankReward, uint256 publicityReward, uint256 teamReward);
    // 领取奖励
    event ClaimReward(address user, uint256 userReward);
    // 领取池子奖励
    event ClaimPoolReward(address user, uint256 reward);
    // 领取宣发奖励
    event ClaimPublicityReward(address user, uint256 reward);
    // 领取团队奖励
    event ClaimTeamReward(address user, uint256 reward);

    struct UserInfo {
        // 用户地址
        address user;
        // 是否注册
        bool isExisted;
        // 用户id
        uint256 id;
        // 上次燃烧时间
        uint256 lastBurnedTimestamp;

        // 产币额度（以U计算）
        uint256 burnedToUSDT;

        // 产币算力（以U计算）= 个人算力 + 直推算力
        uint256 mintTokenPower;

        // 上次燃烧价值（以U计算）
        uint256 lastBurnedValue;
        // 推荐人
        address referrer;
        // 等级
        Level level;
        // 待领取Token数量
        uint256 pendingReward;
    }


    // ************************ Config ************************
    // 出块基数
    uint256 public epochAmount;
    // 挖矿倍数
    uint256 public miningMultiple = 3;
    // 算力倍数
    uint256 public powerMultiple = 2;
    // Oracle
    IOracle public oracle;
    // txToken
    IERC20 public txToken;
    // 创世用户
    address public genesisUser;

    // 池子收益账户待领取token
    uint256 public pendingPoolReward;
    // 池子收益账户
    address public feeToPool;
    // 宣发收益账户待领取token
    uint256 public pendingPublicityReward;
    // 宣发收益账户
    address public feeToPublicity;
    // 团队收益账户待领取奖励
    uint256 public pendingTeamReward;
    // 团队收益账户
    address public feeToTeam;
    // 排行收益账户待领取奖励
    uint256 public pendingRankReward;

    // ************************ State ************************
    // 全网总算力
    uint256 public totalPower;
    // 所有用户地址
    address[] public allUser;
    // 暂停存取，开始结算
    bool public isSettling;
    // 清算时的价格
    uint256 public settlingPrice;
    // 上次奖励区块号
    uint256 public lastBlockNum;
    // 燃烧间隔时间
    uint256 public burnedInterval = 24 hours;

    // 用户信息
    mapping(address => UserInfo) public addressUserInfo;
    // 用户id => 用户address
    mapping(uint256 => address) public userIdAddress;
    // 等级 => 倍数
    mapping(Level => uint256) public levelMultiple;


    modifier running() {
        require(!isSettling, "BurnMing: IS_SETTLING");
        _;
    }

    modifier settling() {
        require(isSettling, "BurnMing: IS_RUNNING");
        _;
    }

    constructor(
        IERC20 _txToken,
        IOracle _oracle,
        address _genesisUser
    ) public {
        require(address(_txToken) != address(0), "BurnMing: TOKEN_ZERO_ADDRESS");
        require(address(_oracle) != address(0), "BurnMing: ORACLE_ZERO_ADDRESS");
        require(address(_genesisUser) != address(0), "BurnMing: FIRST_USER_ZERO_ADDRESS");
        txToken = _txToken;
        oracle = _oracle;
        genesisUser = _genesisUser;

        // 添加初始用户
        UserInfo storage userInfo = addressUserInfo[_genesisUser];
        userInfo.user = _genesisUser;
        userInfo.isExisted = true;
        userInfo.level = Level.BORN;
        userInfo.id = allUser.length;
        userIdAddress[userInfo.id] = genesisUser;
        allUser.push(genesisUser);

        // 初始化等级倍数 2/3/5/10
        levelMultiple[Level.BORN] = uint256(2);
        levelMultiple[Level.PEOPLE] = uint256(3);
        levelMultiple[Level.LAND] = uint256(5);
        levelMultiple[Level.SKY] = uint256(10);

        // 初次设定上次奖励区块为当前区块
        lastBlockNum = block.number;
    }

    /**
    * @notice 获取Token 24h平均价格，以usdt计价，精度为usdt精度
    * @return 价格
    */
    function getTokenAveragePrice() public pure returns (uint256) {
        // uint256 price = oracle.consultAveragePrice(address(txToken), 24 hours);
        uint256 price = 500000;
        return price;
    }

    // 注册，内部方法
    function _register(address _referrer) internal returns (bool success) {
        if (msg.sender == genesisUser) {
            return true;
        }
        // 检查推荐人不能为0
        require(_referrer != address(0), "BurnMing：ZERO_ADDRESS");
        // 检查推荐人不能为自己
        require(msg.sender != _referrer, "BurnMing：CALLER_NOT_SAME_AS_REFERER");

        // 获取推荐人信息
        UserInfo storage refererInfo = addressUserInfo[_referrer];
        // 获取当前用户信息
        UserInfo storage userInfo = addressUserInfo[msg.sender];
        // 检查推荐人是否存在
        require(refererInfo.isExisted, "BurnMing：REFERER_NOT_REGISTRATION");
        // 如果用户未注册，则进行注册
        if(!userInfo.isExisted) {
            userInfo.user = msg.sender;
            // 设置注册标识为已注册
            userInfo.isExisted = true;
            // 记录推荐人
            userInfo.referrer = _referrer;
            // 等级为初生
            userInfo.level = Level.BORN;
            // 分配id，从0开始计数
            userInfo.id = allUser.length;
            // 记录用户id与地址关联关系
            userIdAddress[userInfo.id] = msg.sender;
            // 添加用户地址
            allUser.push(msg.sender);

            // 触发注册事件
            emit Registration(msg.sender, _referrer);
        }
        return true;
    }

    /**
    * @notice 燃烧增加算力
    * @param userInfo 用户信息
    * @param _value 燃烧数量（以U计价）
    * @return 燃烧增加的算力
    */
    function _burnAddPower(UserInfo storage userInfo, uint256 _value) internal returns(uint256, uint256) {
        // 检查燃烧价值是否大于上次燃烧价值
        require(_value > userInfo.lastBurnedValue, "BurnMing: BURN_MUST_BE_BIGGER_THEN_LAST");
        // 检查燃烧时间大于燃烧时间间隔
        require(block.timestamp.sub(burnedInterval) >= userInfo.lastBurnedTimestamp, "BurnMing: MUST_BIGGER_THEN_INTERVAL");

        // 更新用户最近一次燃烧价值
        userInfo.lastBurnedValue = _value;
        // 更新用户最近一次燃烧时间
        userInfo.lastBurnedTimestamp = block.timestamp;

        // 计算产币额度 = 燃烧价值 * 燃烧产币倍数(3)
        uint256 _burnedToUSDT = _value.mul(miningMultiple);
        // 更新用户产币额度 += 产币额度
        userInfo.burnedToUSDT = userInfo.burnedToUSDT.add(_burnedToUSDT);

        // 计算燃烧算力 = 燃烧价值 * 燃烧算力倍数(2)
        uint256 _burnPower = _value.mul(powerMultiple);
        // 更新用户产币算力 += 个人算力
        userInfo.mintTokenPower = userInfo.mintTokenPower.add(_burnPower);
        // 更新全网算力
        totalPower = totalPower.add(_burnPower);

        return (_burnedToUSDT, _burnPower);
    }

    /**
    * @notice 更新推荐人算力
    * @param refererInfo 推荐人信息
    * @param _value 用户燃烧价值
    * @return 推荐人增加的算力
    */
    function _updateRefererPower(
        UserInfo storage refererInfo,
        uint256 _value
    ) internal returns(uint256) {
        // 推荐人增加的直推算力
        uint256 refererAddedPower = _value.mul(levelMultiple[refererInfo.level]) > refererInfo.burnedToUSDT ?
        refererInfo.burnedToUSDT: _value.mul(levelMultiple[refererInfo.level]);

        // 更新推荐人产币算力 += 直推算力
        refererInfo.mintTokenPower = refererInfo.mintTokenPower.add(refererAddedPower);
        // 更新全网算力
        totalPower = totalPower.add(refererAddedPower);

        return refererAddedPower;
    }

    /**
    * @notice 判断用户是否可以燃烧
    * @param user 用户地址
    * @return 是否可以燃烧
    */
    function canBurn(address user) public view returns(bool) {
        // 获取当前用户信息
        UserInfo storage userInfo = addressUserInfo[user];
        require(userInfo.isExisted, "BurnMing: NOT_REGISTER");

        // 检查燃烧时间大于燃烧时间间隔
        if (block.timestamp.sub(burnedInterval) >= userInfo.lastBurnedTimestamp) {
            return true;
        } else {
            return false;
        }
    }

    /**
    * @notice 燃烧
    * @param _value 燃烧数量（以U计价）
    * @param _referer 推荐人地址
    * @return success
    */
    function burn(uint256 _value, address _referer) public running returns (bool success) {
        // 检查燃烧值大于100u
        require(_value > 100 * 1e6, "BurnMing: VALUE_MUST_BE_BIGGER_THEN_ONE_HUNDRED");

        // 1、检查用户是否已注册，如未注册，进行注册
        _register(_referer);

        // 2、将用户token转移到当前合约中
        // 获取平均价格
        uint256 price = getTokenAveragePrice();
        // 计算所需token数量
        uint256 tokenValue = _value.mul(1e20).div(price).div(1e12);
        // 检查余额
        require(txToken.balanceOf(msg.sender) >= tokenValue, "BurnMing: INSUFFICIENT_BALANCE");
        // 转账
        txToken.transferFrom(msg.sender, address(this), tokenValue);

        // 3、燃烧token，增加用户产币额度及个人算力
        UserInfo storage userInfo = addressUserInfo[msg.sender];
        (uint256 burnedToUSDT, uint256 burnPower) = _burnAddPower(userInfo, _value);

        // 检查当前用户不是创世推荐人
        if(msg.sender != genesisUser) {
            UserInfo storage refererInfo = addressUserInfo[userInfo.referrer];
            // 4、更新推荐人算力
            _updateRefererPower(refererInfo, _value);
        }

        // 5、触发燃烧获得算力事件
        emit BurnAddPower(msg.sender, _value, tokenValue, burnedToUSDT, burnPower, price, userInfo.referrer);

        return true;
    }

    /**
    * @notice 用户领取奖励
    */
    function claimReward() public running {
        // 获取用户信息
        UserInfo storage userInfo = addressUserInfo[msg.sender];
        require(userInfo.isExisted, "BurnMing: NOT_REGISTER");

        // 记录用户待领取奖励数量
        uint256 rewardNum = userInfo.pendingReward;
        require(rewardNum > uint256(0), "BurnMing: ZERO_REWARD");
        // 用户待领取奖励清零
        userInfo.pendingReward = 0;
        // 用户领取奖励
        txToken.transfer(msg.sender, rewardNum);
        // 触发领取奖励事件，用户领取奖励
        emit ClaimReward(msg.sender, rewardNum);
    }

    /**
    * @notice 提取手续费奖励
    */
    function claimFeeReward() public running {
        if (msg.sender == feeToPool) {
            txToken.transfer(msg.sender, pendingPoolReward);
            emit ClaimPoolReward(msg.sender, pendingPoolReward);
            pendingPoolReward = 0;
        } else if (msg.sender == feeToTeam) {
            txToken.transfer(msg.sender, pendingTeamReward);
            emit ClaimTeamReward(msg.sender, pendingTeamReward);
            pendingTeamReward = 0;
        } else if (msg.sender == feeToPublicity) {
            txToken.transfer(msg.sender, pendingPublicityReward);
            emit ClaimPublicityReward(msg.sender, pendingPublicityReward);
            pendingPublicityReward = 0;
        }
    }

    /**
    * @notice 批量发送奖励token给排行
    */
    function multiTransferRanking(address[] memory users, uint256[] memory rewards) public running onlyOwner {
        require(users.length == rewards.length, "BurnMing: NOT_SAME");
        uint256 _pendingRankReward = pendingRankReward;
        for(uint256 i; i < users.length; i++) {
            txToken.transfer(users[i], rewards[i]);
            _pendingRankReward = _pendingRankReward.sub(rewards[i]);
        }
        pendingRankReward = _pendingRankReward;
    }

    // ****************** Owner ******************

    /**
    * @notice 更新用户等级
    * @param user 用户地址
    * @param newLevel 新等级
    */
    function changeLevel(address user, Level newLevel) public onlyOwner {
        require(levelMultiple[newLevel] > uint256(0), "BurnMing: LEVEL_NOT_EXIST");
        // 获取当前用户信息
        UserInfo storage userInfo = addressUserInfo[user];
        require(userInfo.isExisted, "BurnMing: NOT_REGISTER");

        // 更新用户等级
        Level oldLevel = userInfo.level;
        userInfo.level = newLevel;

        emit ChangeLevel(user, oldLevel, newLevel);
    }

    /**
    * @notice 设置暂停/运行状态，开始清结算
    * @param _isSettling 状态
    */
    function setSettling(bool _isSettling) public onlyOwner {
        if(isSettling != _isSettling) {
            isSettling = _isSettling;
            // 如果进入清算阶段，记录当前24h均价
            if(_isSettling) {
                // 获取最新24h均价
                uint256 _price = getTokenAveragePrice();
                // 作为清算时的价格
                settlingPrice = _price;
                emit StartSettling(block.number, _price);
            } else {
                // 更新下次清算周期的奖励开始区块号
                lastBlockNum = block.number;
                emit EndSettling(block.number);
            }
        }
    }

    function _distributeFeeReward(uint256 rewardNum) internal returns(uint256, uint256, uint256, uint256, uint256) {
        // 分配给池子奖励
        uint256 poolReward = rewardNum.mul(30).div(1000);
        // 分配给排名奖励
        uint256 rankReward = rewardNum.mul(12).div(1000);
        // 分配给宣发奖励
        uint256 publicityReward = rewardNum.mul(6).div(1000);
        // 分配给团队奖励
        uint256 teamReward = rewardNum.mul(2).div(1000);

        pendingPoolReward = pendingPoolReward.add(poolReward);
        pendingRankReward = pendingRankReward.add(rankReward);
        pendingPublicityReward = pendingPublicityReward.add(publicityReward);
        pendingTeamReward = pendingTeamReward.add(teamReward);

        // avoid stack too deep
        rewardNum = rewardNum.sub(pendingPoolReward);
        rewardNum = rewardNum.sub(pendingRankReward);
        rewardNum = rewardNum.sub(pendingPublicityReward);
        rewardNum = rewardNum.sub(pendingTeamReward);

        return (rewardNum, poolReward, rankReward, publicityReward, teamReward);
    }

    /**
    * @notice 分发奖励
    * @param user 用户地址
    * @param costBurnedToUSDT 消耗的产币额度
    * @param costBurnedToPower 消耗的算力
    * @param rewardNum 奖励token数量
    */
    // 算力足够，产币额度不足，算力直接扣，产币额度判断用户是否有足够U
    function distributeReward(address user, uint256 costBurnedToUSDT, uint256 costBurnedToPower, uint256 rewardNum) public settling onlyOwner {
        // 获取当前用户信息
        UserInfo storage userInfo = addressUserInfo[user];
        require(userInfo.isExisted, "BurnMing: NOT_REGISTER");

        // 判断用户产币额度是否足够
        if(costBurnedToUSDT > userInfo.burnedToUSDT){
            costBurnedToUSDT = userInfo.burnedToUSDT;
        }
        // 用户的产币额度减少
        userInfo.burnedToUSDT = userInfo.burnedToUSDT.sub(costBurnedToUSDT);
        // 用户的产币算力减少
        userInfo.mintTokenPower = userInfo.mintTokenPower.sub(costBurnedToPower);

        (uint256 newRewardNum, uint256 poolReward, uint256 rankReward, uint256 publicityReward, uint256 teamReward) = _distributeFeeReward(rewardNum);
        // 用户的待领取token数量增加
        userInfo.pendingReward = userInfo.pendingReward.add(newRewardNum);

        // 总算力减少
        totalPower = totalPower.sub(costBurnedToPower);
        emit DistributeReward(user, costBurnedToUSDT, costBurnedToPower, rewardNum, newRewardNum, poolReward, rankReward, publicityReward, teamReward);
    }

    // 设置等级对应的倍数
    function setLevelMultiple(Level level, uint256 multiple) public onlyOwner {
        require(multiple > uint256(0), "BurnMing: MULTIPLE_MUST_BE_BIGGER_THEN_ZERO");
        levelMultiple[level] = multiple;
    }

    // 设置oracle
    function setOracle(IOracle _oracle) public onlyOwner {
        require(address(_oracle) != address(0), "BurnMing: ZERO_ADDRESS");
        oracle = _oracle;
    }

    // 设置TxToken
    function setTxToken(IERC20 _txToken) public onlyOwner {
        require(address(_txToken) != address(0), "BurnMing: ZERO_ADDRESS");
        txToken = _txToken;
    }

    // 设置池子收益账户
    function setFeeToPool(address _feeToPool) public onlyOwner {
        require(_feeToPool != address(0), "BurnMing: ZERO_ADDRESS");
        feeToPool = _feeToPool;
    }

    // 设置宣发收益账户
    function setFeeToPublicity(address _feeToPublicity) public onlyOwner {
        require(_feeToPublicity != address(0), "BurnMing: ZERO_ADDRESS");
        feeToPublicity = _feeToPublicity;
    }

    // 设置团队收益账户
    function setFeeToTeam(address _feeToTeam) public onlyOwner {
        require(_feeToTeam != address(0), "BurnMing: ZERO_ADDRESS");
        feeToTeam = _feeToTeam;
    }

    // 设置每块基础奖励数量
    function setEpochAmount(uint256 _epochAmount) public onlyOwner {
        require(_epochAmount > uint256(0), "BurnMing: AMOUNT_MUST_BE_BIGGER_THEN_ZERO");
        epochAmount = _epochAmount;
    }

    // 设置燃烧产币倍数
    function setMiningMultiple(uint256 _miningMultiple) public onlyOwner {
        require(_miningMultiple > uint256(0), "BurnMing: MULTIPLE_MUST_BE_BIGGER_THEN_ZERO");
        miningMultiple = _miningMultiple;
    }

    // 设置燃烧算力倍数
    function setPowerMultiple(uint256 _powerMultiple) public onlyOwner {
        require(_powerMultiple > uint256(0), "BurnMing: POWER_MULTIPLE_MUST_BE_BIGGER_THEN_ZERO");
        powerMultiple = _powerMultiple;
    }

    // 设置燃烧时间间隔
    function setBurnedInterval(uint256 _burnedInterval) public onlyOwner {
        burnedInterval = _burnedInterval;
    }

    // 紧急提币
    function emergencyWithdraw(address _token) public onlyOwner {
        require(IERC20(_token).balanceOf(address(this)) > 0, "BurnMing: INSUFFICIENT_BALANCE");
        IERC20(_token).transfer(msg.sender, IERC20(_token).balanceOf(address(this)));
    }
}