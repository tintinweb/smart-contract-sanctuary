// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IAppData.sol";

import "./Model.sol";

contract AppData is IAppData, Ownable {

    // 比例算力倍数, 0=未知, 1=82比例倍数, 2=73比例倍数, 3=55比例倍数, 4=单币比比例倍数
    mapping(uint8 => uint256) public scaleMultipleMap;
    mapping(uint8 => Model.Level) levelMap;
    Model.Level[] public allLevels;

    // 级别佣金比例,  level => gen => percent
    mapping(uint8 => mapping(uint8 => uint256)) public levelCommissionMap;

    struct Pair {
        address token0;
        string token0Symbol;
        uint8 token0Decimals;
        address token1;
        string token1Symbol;
        uint8 token1Decimals;
        uint8 status;
        string name;
        string imgUrl;
    }

    // 币对池状态, 0=不存在, 1=开启, 2=禁用
    // 所有币对池，token0 -> token1 -> status, 0=不存在, 1=开启, 2=关闭
    mapping(address => mapping(address => Pair)) public allPairMap;

    // 所有币对
    Pair[] allPairs;

    address public coolAddr;
    address public rootInviter;

    uint256 public levelMultiple = 100;
    uint256 public lpMultiple = 210;

    // usdt返佣比例
    uint256 public usdtRebateRate = 70;

    // 1=level, 2=lp, 3=pair
    mapping(uint8 => Model.HashrateConf) hashrateConfMap;

    address public rewardAddr;

    address public burnAddr;

    // 销毁比例千分之999, 根据奖励比例推算销毁比例
    uint256 public burnRate = 999;

    uint256 public quoteDiscount = 95;

    // bsc 3s per block, 86400 / 5
    uint256 public rewardBlockCount = 17280;

    constructor() {
        coolAddr = _msgSender();
        rootInviter = _msgSender();
        rewardAddr = address(0);
        burnAddr = address(0);

        // scale 
        scaleMultipleMap[Model.SCALE_TYPE_82] = 100;
        scaleMultipleMap[Model.SCALE_TYPE_73] = 120;
        scaleMultipleMap[Model.SCALE_TYPE_55] = 150;
        scaleMultipleMap[Model.SCALE_TYPE_100] = 200;

        // hashrate, 1=level, 2=lp, 3=pair
        hashrateConfMap[Model.CATEGORY_LEVEL] = Model.HashrateConf({
            baseAmount: 1000,
            minTotalHashrate: 10000,
            maxTotalHashrate: 5000000,
            maxReward: 5000,
            rebate: 1,
            usdtRebate: 1,
            invited: 1
        });
        hashrateConfMap[Model.CATEGORY_LP] = Model.HashrateConf({
            baseAmount: 1000,
            minTotalHashrate: 10000,
            maxTotalHashrate: 10000000,
            maxReward: 10000,
            rebate: 0,
            usdtRebate: 0,
            invited: 1
        });
        hashrateConfMap[Model.CATEGORY_PAIR] = Model.HashrateConf({
            baseAmount: 1000,
            minTotalHashrate: 10000,
            maxTotalHashrate: 6863000,
            maxReward: 6863,
            rebate: 1,
            usdtRebate: 0,
            invited: 1
        });

        // level
        levelMap[0] = Model.Level({
            name: "V0",
            levelNo: 0,
            commissionGen: 1,
            price: 0
        });
        allLevels.push(levelMap[0]);

        levelMap[1] = Model.Level({
            name: "V1",
            levelNo: 1,
            commissionGen: 2,
            price: 100 * (10 ** 18)
        });
        allLevels.push(levelMap[1]);

        levelMap[2] = Model.Level({
            name: "V2",
            levelNo: 2,
            commissionGen: 4,
            price: 300 * (10 ** 18)
        });
        allLevels.push(levelMap[2]);

        levelMap[3] = Model.Level({
            name: "V3",
            levelNo: 3,
            commissionGen: 6,
            price: 600 * (10 ** 18)
        });
        allLevels.push(levelMap[3]);

        levelMap[4] = Model.Level({
            name: "V4",
            levelNo: 4,
            commissionGen: 8,
            price: 1000 * (10 ** 18)
        });
        allLevels.push(levelMap[4]);

        levelMap[5] = Model.Level({
            name: "V5",
            levelNo: 5,
            commissionGen: 12,
            price: 1400 * (10 ** 18)
        });
        allLevels.push(levelMap[5]);

        levelMap[6] = Model.Level({
            name: "V6",
            levelNo: 6,
            commissionGen: 16,
            price: 1800 * (10 ** 18)
        });
        allLevels.push(levelMap[6]);

        levelMap[7] = Model.Level({
            name: "V7",
            levelNo: 7,
            commissionGen: 20,
            price: 2200 * (10 ** 18)
        });
        allLevels.push(levelMap[7]);

        // gen commission
        levelCommissionMap[0][1] = 10;

        levelCommissionMap[1][1] = 15;
        levelCommissionMap[1][2] = 10;

        levelCommissionMap[2][1] = 16;
        levelCommissionMap[2][2] = 11;
        levelCommissionMap[2][3] = 9;
        levelCommissionMap[2][4] = 7;

        levelCommissionMap[3][1] = 17;
        levelCommissionMap[3][2] = 12;
        levelCommissionMap[3][3] = 10;
        levelCommissionMap[3][4] = 8;
        levelCommissionMap[3][5] = 7;
        levelCommissionMap[3][6] = 3;

        levelCommissionMap[4][1] = 18;
        levelCommissionMap[4][2] = 13;
        levelCommissionMap[4][3] = 11;
        levelCommissionMap[4][4] = 9;
        levelCommissionMap[4][5] = 7;
        levelCommissionMap[4][6] = 3;
        levelCommissionMap[4][7] = 2;
        levelCommissionMap[4][8] = 1;

        levelCommissionMap[5][1] = 20;
        levelCommissionMap[5][2] = 14;
        levelCommissionMap[5][3] = 12;
        levelCommissionMap[5][4] = 10;
        levelCommissionMap[5][5] = 7;
        levelCommissionMap[5][6] = 3;
        levelCommissionMap[5][7] = 2;
        levelCommissionMap[5][8] = 1;
        levelCommissionMap[5][9] = 1;
        levelCommissionMap[5][10] = 1;
        levelCommissionMap[5][11] = 1;
        levelCommissionMap[5][12] = 1;

        levelCommissionMap[6][1] = 22;
        levelCommissionMap[6][2] = 16;
        levelCommissionMap[6][3] = 14;
        levelCommissionMap[6][4] = 12;
        levelCommissionMap[6][5] = 7;
        levelCommissionMap[6][6] = 3;
        levelCommissionMap[6][7] = 2;
        levelCommissionMap[6][8] = 1;
        levelCommissionMap[6][9] = 1;
        levelCommissionMap[6][10] = 1;
        levelCommissionMap[6][11] = 1;
        levelCommissionMap[6][12] = 1;
        levelCommissionMap[6][13] = 1;
        levelCommissionMap[6][14] = 1;
        levelCommissionMap[6][15] = 1;
        levelCommissionMap[6][16] = 1;

        levelCommissionMap[7][1] = 25;
        levelCommissionMap[7][2] = 18;
        levelCommissionMap[7][3] = 16;
        levelCommissionMap[7][4] = 14;
        levelCommissionMap[7][5] = 7;
        levelCommissionMap[7][6] = 3;
        levelCommissionMap[7][7] = 2;
        levelCommissionMap[7][8] = 1;
        levelCommissionMap[7][9] = 1;
        levelCommissionMap[7][10] = 1;
        levelCommissionMap[7][11] = 1;
        levelCommissionMap[7][12] = 1;
        levelCommissionMap[7][13] = 1;
        levelCommissionMap[7][14] = 1;
        levelCommissionMap[7][15] = 1;
        levelCommissionMap[7][16] = 1;
        levelCommissionMap[7][17] = 1;
        levelCommissionMap[7][18] = 1;
        levelCommissionMap[7][19] = 1;
        levelCommissionMap[7][20] = 1;
    }

    // 增加币对, 只能增加不能移除
    function addPair(
        address token0, 
        string memory token0Symbol, 
        uint8 token0Decimals,
        address token1, 
        string memory token1Symbol, 
        uint8 token1Decimals,
        uint8 status, 
        string memory name,
        string memory imgUrl) 
            public onlyOwner {
        require(status == 0 || status == 1, "Pair status invalid");
        require(allPairMap[token0][token1].status == 0, "Pair exists");

        allPairMap[token0][token1] = Pair({
            token0: token0,
            token0Symbol: token0Symbol,
            token0Decimals: token0Decimals,
            token1: token1,
            token1Symbol: token1Symbol,
            token1Decimals: token1Decimals,
            status: status,
            name: name,
            imgUrl: imgUrl
        });
        allPairs.push(allPairMap[token0][token1]);
    }

    // 验证币对
    function validPair(address token0, address token1) public override view returns(bool) {
        return allPairMap[token0][token1].status > 0;
    }

    function getAllPairs() public view returns(Pair[] memory) {
        return allPairs;
    }

    // 设置算力倍数
    function setHashrateMultiple(uint8 scaleType, uint256 multiple) public onlyOwner {
        require(scaleType > 0 && scaleType <= 4, "Invalid scale type");
        scaleMultipleMap[scaleType] = multiple;
    }

    function getScaleMultiple(uint8 scaleType) public override view returns(uint256) {
        return scaleMultipleMap[scaleType];
    }

    function setPairStatus(address token0, address token1, uint8 status) public onlyOwner {
        require(status == 0 || status == 1, "Invalid status");
        allPairMap[token0][token1].status = status;
    }

    function setLevelCommission(uint8 levelNo, uint8 gen, uint256 rate) public onlyOwner {
        require(levelNo >= 0 && levelNo <= 7, "Gen levelNo");
        require(gen > 0 && gen <= 20, "Gen invalid");
        require(rate > 0, "Rate invalid");
        
        levelCommissionMap[levelNo][gen] = rate;
    }

    function addLevel(string calldata name, uint8 levelNo, uint8 commissionGen, uint256 price) public onlyOwner {
        require(levelNo > 0, "level no must great than 0");
        require(levelMap[levelNo].commissionGen == 0, "level exists");

        levelMap[levelNo] = Model.Level({
            name: name,
            levelNo: levelNo,
            commissionGen: commissionGen,
            price: price
        });
        allLevels.push(levelMap[levelNo]);
    }

    function getLevelCommissionRate(uint8 levelNo, uint8 gen) public override view returns(uint256) {
        return levelCommissionMap[levelNo][gen];
    }

    function getAllLevels() public view returns(Model.Level[] memory) {
        return allLevels;
    }

    function getLevel(uint8 levelNo) public override view returns(Model.Level memory) {
        return levelMap[levelNo];
    }

    function setLevelMultiple(uint256 _levelMultiple) public onlyOwner {
        levelMultiple = _levelMultiple;
    }

    function getLevelMultiple() public override view returns(uint256) {
        return levelMultiple;
    }

    function setCoolAddr(address _coolAddr) public onlyOwner {
        coolAddr = _coolAddr;
    }

    function getCoolAddr() public view override returns(address) {
        return coolAddr;
    }

    function setRootInviter(address _rootInviter) public onlyOwner {
        rootInviter = _rootInviter;
    }

    function getRootInviter() public view override returns(address) {
        return rootInviter;
    }

    function setLPMultiple(uint256 _multiple) public onlyOwner {
        require(_multiple > 0, "Invlaid multiple");
        lpMultiple = _multiple;
    }

    function getLPMultiple() public view override returns(uint256) {
        return lpMultiple;
    }

    function setPairImg(address token0, address token1, string calldata imgUrl) public onlyOwner {
        allPairMap[token0][token1].imgUrl = imgUrl;
    }

    function setLevelCommissionGen(uint8 levelNo, uint8 commissionGen) public onlyOwner {
        levelMap[levelNo].commissionGen = commissionGen;
    }

    function setLevelPrice(uint8 levelNo, uint256 price) public onlyOwner {
        levelMap[levelNo].price = price;
        for (uint256 i = 0; i < allLevels.length; i++) {
            if (allLevels[i].levelNo == levelNo) {
                allLevels[i].price = price;
                break;
            }
        }
    }

    function getHashrateConf(uint8 category) public override view returns(Model.HashrateConf memory) {
        return hashrateConfMap[category];
    }

    function setHashrateConf(uint8 category, uint256 baseAmount, uint256 minTotalHashrate, uint256 maxTotalHashrate, uint256 maxReward, uint8 rebate) 
        public onlyOwner {
        hashrateConfMap[category].baseAmount = baseAmount;
        hashrateConfMap[category].minTotalHashrate = minTotalHashrate;
        hashrateConfMap[category].maxTotalHashrate = maxTotalHashrate;
        hashrateConfMap[category].maxReward = maxReward;
        hashrateConfMap[category].rebate = rebate;
    }

    function setRewardAddr(address _rewardAddr) public onlyOwner {
        rewardAddr = _rewardAddr;
    }

    function getRewardAddr() public view override returns(address) {
        return rewardAddr;
    }

    function setQuoteDiscount(uint256 _quoteDiscount) public onlyOwner {
        quoteDiscount = _quoteDiscount;
    }

    function getQuoteDiscount() public override view returns(uint256) {
        return quoteDiscount;
    }

    function setRewardBlockCount(uint256 _rewardBlockCount) public onlyOwner {
        rewardBlockCount = _rewardBlockCount;
    }

    function getRewardBlockCount() public view override returns(uint256) {
        return rewardBlockCount;
    }

    function setBurnAddr(address _burnAddr) public onlyOwner {
        burnAddr = _burnAddr;
    }

    function getBurnAddr() public view override returns(address) {
        return burnAddr;
    }

    function getBurnRate() public view override returns(uint256) {
        return burnRate;
    }

    function setBurnRate(uint256 _burnRate) public onlyOwner {
        burnRate = _burnRate;
    }

    function getUsdtRebateRate() public view override returns(uint256) {
        return usdtRebateRate;
    }

    function setUsdtRebateRate(uint256 _usdtRebateRate) public onlyOwner {
        usdtRebateRate = _usdtRebateRate;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Model.sol";

interface IAppData {
    function validPair(address token0, address token1) external view returns(bool);    
    function getScaleMultiple(uint8 scaleType) external view returns(uint256);
    function getLevelCommissionRate(uint8 levelNo, uint8 gen) external view returns(uint256);
    function getLevel(uint8 levelNo) external view returns(Model.Level memory);
    function getLevelMultiple() external view returns(uint256);
    function getCoolAddr() external view returns(address);
    function getRootInviter() external view returns(address);
    function getLPMultiple() external view returns(uint256);
    function getRewardAddr() external view returns(address);
    function getHashrateConf(uint8 category) external view returns(Model.HashrateConf memory);
    function getQuoteDiscount() external view returns(uint256);
    function getRewardBlockCount() external view returns(uint256);
    function getBurnAddr() external view returns(address);
    function getBurnRate() external view returns(uint256);
    function getUsdtRebateRate() external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Model {

    uint8 constant CATEGORY_LEVEL = 1;
    uint8 constant CATEGORY_LP = 2;
    uint8 constant CATEGORY_PAIR = 3;

    uint8 constant SCALE_TYPE_UNKNOWN = 0;
    uint8 constant SCALE_TYPE_82 = 1;
    uint8 constant SCALE_TYPE_73 = 2;
    uint8 constant SCALE_TYPE_55 = 3;
    uint8 constant SCALE_TYPE_100 = 4;

    struct User {
        address addr;
        address inviterAddr;
        uint8 levelNo;
    }

    // 级别
    struct Level  {
        string name; // 名称
        uint8 levelNo; // 级别号
        uint8 commissionGen; // 佣金代数
        uint256 price; // 需要的usdt数量
    }

    struct HashrateConf {
        uint256 baseAmount; // 基数
        uint256 minTotalHashrate; // 全网最小算力
        uint256 maxTotalHashrate; // 全网最大算力, 超过最高算力后代币产值减半
        uint256 maxReward; // 全网最大奖励
        uint8 rebate; // 算力返佣, 0=不返佣, 1=返佣
        uint8 usdtRebate; // usdt返佣, 0=不返佣, 1=返佣
        uint8 invited; // 是否需要绑定邀请关系, 0=不需要, 1=需要
    }

    // 算力记录
    struct HashrateRecord {
        uint8 category; // 0=all, 1=level, 2=lp, 3=pair
        uint256 blockNumber;
        uint256 timestamp;
        uint256 totalHashrate;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}