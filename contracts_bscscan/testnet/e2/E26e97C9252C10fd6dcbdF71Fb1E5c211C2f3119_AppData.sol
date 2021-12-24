// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

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

    // 代币返佣比例
    uint256 public tokenRebateRate = 70;

    // 1=level, 2=lp, 3=pair
    mapping(uint8 => Model.HashrateConf) hashrateConfMap;

    address public rewardAddr;

    address public burnAddr;

    // 销毁比例千分之999, 根据奖励比例推算销毁比例
    uint256 public burnRate = 999;

    uint256 public quoteDiscount = 95;

    // bsc 3s per block, 86400 / 3
    uint256 public rewardBlockCount = 28800;

    // 升级支付代币, token => status, 0=禁用，1=启用, 默认u
    mapping(address => uint8) public payTokenMap;

    uint256 public maxGen = 50;

    uint256 public outMultiple = 350;

    uint256 public claimFeeRate = 10;

    mapping(address => uint8) public farmAddrMap;

    constructor() {
        coolAddr = _msgSender();
        rootInviter = _msgSender();
        //rewardAddr = address(0);
        //burnAddr = address(1);

        // farm addr
        farmAddrMap[_msgSender()] = 1;

        // scale 
        scaleMultipleMap[Model.SCALE_TYPE_82] = 100;
        scaleMultipleMap[Model.SCALE_TYPE_73] = 120;
        scaleMultipleMap[Model.SCALE_TYPE_55] = 150;
        scaleMultipleMap[Model.SCALE_TYPE_100] = 200;

        // hashrate, 1=level, 2=lp, 3=pair
        hashrateConfMap[Model.CATEGORY_LEVEL] = Model.HashrateConf({
            baseAmount: 1000,
            minTotalHashrate: 10000,
            maxTotalHashrate: 3500000,
            maxReward: 3500,
            rebate: 1,
            tokenRebate: 1,
            invited: 1
        });
        hashrateConfMap[Model.CATEGORY_LP] = Model.HashrateConf({
            baseAmount: 1000,
            minTotalHashrate: 10000,
            maxTotalHashrate: 3500000,
            maxReward: 10000,
            rebate: 0,
            tokenRebate: 0,
            invited: 1
        });
        hashrateConfMap[Model.CATEGORY_PAIR] = Model.HashrateConf({
            baseAmount: 1000,
            minTotalHashrate: 10000,
            maxTotalHashrate: 3500000,
            maxReward: 2000,
            rebate: 1,
            tokenRebate: 0,
            invited: 1
        });
        hashrateConfMap[Model.CATEGORY_TOKEN] = Model.HashrateConf({
            baseAmount: 1000,
            minTotalHashrate: 10000,
            maxTotalHashrate: 3500000,
            maxReward: 1000,
            rebate: 1,
            tokenRebate: 0,
            invited: 1
        });

        // level
        levelMap[0] = Model.Level({
            name: "V0",
            levelNo: 0,
            commissionGen: 1,
            maxCommissionGen: 1,
            price: 0,
            needOut: 0,
            genCountPerOut: 0
        });
        allLevels.push(levelMap[0]);

        levelMap[1] = Model.Level({
            name: "V1",
            levelNo: 1,
            commissionGen: 3,
            maxCommissionGen: 3,
            price: 300 * (10 ** 18),
            needOut: 0,
            genCountPerOut: 0
        });
        allLevels.push(levelMap[1]);

        levelMap[2] = Model.Level({
            name: "V2",
            levelNo: 2,
            commissionGen: 6,
            maxCommissionGen: 6,
            price: 1000 * (10 ** 18),
            needOut: 0,
            genCountPerOut: 0
        });
        allLevels.push(levelMap[2]);

        levelMap[3] = Model.Level({
            name: "V3",
            levelNo: 3,
            commissionGen: 9,
            maxCommissionGen: 9,
            price: 2000 * (10 ** 18),
            needOut: 0,
            genCountPerOut: 0
        });
        allLevels.push(levelMap[3]);

        levelMap[4] = Model.Level({
            name: "V4",
            levelNo: 4,
            commissionGen: 13,
            maxCommissionGen: 13,
            price: 3000 * (10 ** 18),
            needOut: 0,
            genCountPerOut: 0
        });
        allLevels.push(levelMap[4]);

        levelMap[5] = Model.Level({
            name: "V5",
            levelNo: 5,
            commissionGen: 17,
            maxCommissionGen: 17,
            price: 4000 * (10 ** 18),
            needOut: 0,
            genCountPerOut: 0
        });
        allLevels.push(levelMap[5]);

        levelMap[6] = Model.Level({
            name: "V6",
            levelNo: 6,
            commissionGen: 23,
            maxCommissionGen: 23,
            price: 5000 * (10 ** 18),
            needOut: 1,
            genCountPerOut: 0
        });
        allLevels.push(levelMap[6]);

        levelMap[7] = Model.Level({
            name: "V7",
            levelNo: 7,
            commissionGen: 30,
            maxCommissionGen: 50,
            price: 6000 * (10 ** 18),
            needOut: 1,
            genCountPerOut: 5
        });
        allLevels.push(levelMap[7]);

        // gen commission
        levelCommissionMap[0][1] = 0;

        levelCommissionMap[1][1] = 50;
        levelCommissionMap[1][2] = 30;
        levelCommissionMap[1][3] = 10;

        levelCommissionMap[2][1] = 90;
        levelCommissionMap[2][2] = 50;
        levelCommissionMap[2][3] = 30;
        levelCommissionMap[2][4] = 20;
        levelCommissionMap[2][5] = 20;
        levelCommissionMap[2][6] = 10;

        levelCommissionMap[3][1] = 110;
        levelCommissionMap[3][2] = 90;
        levelCommissionMap[3][3] = 60;
        levelCommissionMap[3][4] = 50;
        levelCommissionMap[3][5] = 40;
        levelCommissionMap[3][6] = 30;
        levelCommissionMap[3][7] = 20;
        levelCommissionMap[3][8] = 10;
        levelCommissionMap[3][9] = 10;

        levelCommissionMap[4][1] = 130;
        levelCommissionMap[4][2] = 100;
        levelCommissionMap[4][3] = 70;
        levelCommissionMap[4][4] = 60;
        levelCommissionMap[4][5] = 50;
        levelCommissionMap[4][6] = 40;
        levelCommissionMap[4][7] = 30;
        levelCommissionMap[4][8] = 20;
        levelCommissionMap[4][9] = 20;
        levelCommissionMap[4][10] = 20;
        levelCommissionMap[4][11] = 10;
        levelCommissionMap[4][12] = 10;
        levelCommissionMap[4][13] = 10;

        levelCommissionMap[5][1] = 150;
        levelCommissionMap[5][2] = 110;
        levelCommissionMap[5][3] = 80;
        levelCommissionMap[5][4] = 70;
        levelCommissionMap[5][5] = 60;
        levelCommissionMap[5][6] = 50;
        levelCommissionMap[5][7] = 40;
        levelCommissionMap[5][8] = 30;
        levelCommissionMap[5][9] = 20;
        levelCommissionMap[5][10] = 10;
        levelCommissionMap[5][11] = 10;
        levelCommissionMap[5][12] = 10;
        levelCommissionMap[5][13] = 10;
        levelCommissionMap[5][14] = 5;
        levelCommissionMap[5][15] = 5;
        levelCommissionMap[5][16] = 5;
        levelCommissionMap[5][17] = 5;

        levelCommissionMap[6][1] = 170;
        levelCommissionMap[6][2] = 130;
        levelCommissionMap[6][3] = 90;
        levelCommissionMap[6][4] = 80;
        levelCommissionMap[6][5] = 70;
        levelCommissionMap[6][6] = 60;
        levelCommissionMap[6][7] = 50;
        levelCommissionMap[6][8] = 40;
        levelCommissionMap[6][9] = 30;
        levelCommissionMap[6][10] = 20;
        levelCommissionMap[6][11] = 10;
        levelCommissionMap[6][12] = 10;
        levelCommissionMap[6][13] = 10;
        levelCommissionMap[6][14] = 10;
        levelCommissionMap[6][15] = 10;
        levelCommissionMap[6][16] = 5;
        levelCommissionMap[6][17] = 5;
        levelCommissionMap[6][18] = 5;
        levelCommissionMap[6][19] = 5;
        levelCommissionMap[6][20] = 5;
        levelCommissionMap[6][21] = 5;
        levelCommissionMap[6][22] = 5;
        levelCommissionMap[6][23] = 5;

        levelCommissionMap[7][1] = 200;
        levelCommissionMap[7][2] = 140;
        levelCommissionMap[7][3] = 90;
        levelCommissionMap[7][4] = 80;
        levelCommissionMap[7][5] = 80;
        levelCommissionMap[7][6] = 60;
        levelCommissionMap[7][7] = 60;
        levelCommissionMap[7][8] = 50;
        levelCommissionMap[7][9] = 40;
        levelCommissionMap[7][10] = 30;
        levelCommissionMap[7][11] = 20;
        levelCommissionMap[7][12] = 20;
        levelCommissionMap[7][13] = 20;
        levelCommissionMap[7][14] = 10;
        levelCommissionMap[7][15] = 10;
        levelCommissionMap[7][16] = 10;
        levelCommissionMap[7][17] = 5;
        levelCommissionMap[7][18] = 5;
        levelCommissionMap[7][19] = 5;
        levelCommissionMap[7][20] = 5;
        levelCommissionMap[7][21] = 2;
        levelCommissionMap[7][22] = 2;
        levelCommissionMap[7][23] = 2;
        levelCommissionMap[7][24] = 2;
        levelCommissionMap[7][25] = 2;
        levelCommissionMap[7][26] = 2;
        levelCommissionMap[7][27] = 2;
        levelCommissionMap[7][28] = 2;
        levelCommissionMap[7][29] = 2;
        levelCommissionMap[7][30] = 2;
        levelCommissionMap[7][31] = 2;
        levelCommissionMap[7][32] = 2;
        levelCommissionMap[7][33] = 2;
        levelCommissionMap[7][34] = 2;
        levelCommissionMap[7][35] = 2;
        levelCommissionMap[7][36] = 2;
        levelCommissionMap[7][37] = 2;
        levelCommissionMap[7][38] = 2;
        levelCommissionMap[7][39] = 2;
        levelCommissionMap[7][40] = 2;
        levelCommissionMap[7][41] = 2;
        levelCommissionMap[7][42] = 2;
        levelCommissionMap[7][43] = 2;
        levelCommissionMap[7][44] = 2;
        levelCommissionMap[7][45] = 2;
        levelCommissionMap[7][46] = 2;
        levelCommissionMap[7][47] = 2;
        levelCommissionMap[7][48] = 2;
        levelCommissionMap[7][49] = 2;
        levelCommissionMap[7][50] = 2;
        
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

    function addLevel(string calldata name, uint8 levelNo, uint8 commissionGen, uint8 maxCommissionGen, uint256 price, uint8 needOut, uint8 genCountPerOut) public onlyOwner {
        require(levelNo > 0, "level no must great than 0");
        require(levelMap[levelNo].commissionGen == 0, "level exists");

        levelMap[levelNo] = Model.Level({
            name: name,
            levelNo: levelNo,
            commissionGen: commissionGen,
            maxCommissionGen: maxCommissionGen,
            price: price,
            needOut: needOut,
            genCountPerOut: genCountPerOut 
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

    function getTokenRebateRate() public view override returns(uint256) {
        return tokenRebateRate;
    }

    function setTokenRebateRate(uint256 _tokenRebateRate) public onlyOwner {
        tokenRebateRate = _tokenRebateRate;
    }

    function isValidPayToken(address token) public override view returns(bool) {
        return payTokenMap[token] == 1;
    }

    function setPayToken(address token, uint8 status) public onlyOwner {
        payTokenMap[token] = status;
    }

    function getMaxGen() public override view returns(uint256) {
        return maxGen;
    }

    function getOutMultiple() public view override returns(uint256) {
        return outMultiple;
    }

    function setOutMultiple(uint256 _outMultiple) public onlyOwner {
        outMultiple = _outMultiple;
    }

    function getClaimFeeRate() public view override returns(uint256) {
        return claimFeeRate;
    }

    function setClaimFeeRate(uint256 _claimFeeRate) public onlyOwner {
        claimFeeRate = _claimFeeRate;
    }

    function setFarmAddr(address farmAddr, uint8 status) public onlyOwner {
        farmAddrMap[farmAddr] = status;
    }

    function validFarm(address farmAddr) public view override returns(bool) {
        return farmAddrMap[farmAddr] == 1;
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

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
    function getTokenRebateRate() external view returns(uint256);
    function isValidPayToken(address token) external view returns(bool);
    function getMaxGen() external view returns(uint256);
    function getOutMultiple() external view returns(uint256);
    function getClaimFeeRate() external view returns(uint256);
    function validFarm(address farmAddr) external returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Model {
    uint8 constant CATEGORY_LEVEL = 1;
    uint8 constant CATEGORY_LP = 2;
    uint8 constant CATEGORY_PAIR = 3;
    uint8 constant CATEGORY_TOKEN = 4;

    uint8 constant SCALE_TYPE_UNKNOWN = 0;
    uint8 constant SCALE_TYPE_82 = 1;
    uint8 constant SCALE_TYPE_73 = 2;
    uint8 constant SCALE_TYPE_55 = 3;
    uint8 constant SCALE_TYPE_100 = 4;

    struct User {
        address addr;
        address inviterAddr;
        uint8 levelNo;
        uint8 out; // 是否已出局
        uint8 outTimes; // 出局次数
        uint256 outBalance; // 出局余额
        uint256 totalInvest; // 总投入
        uint256 totalYield; // 总收益
    }

    // 级别
    struct Level  {
        string name; // 名称
        uint8 levelNo; // 级别号
        uint8 commissionGen; // 佣金代数
        uint8 maxCommissionGen; // 最大佣金代数
        uint256 price; // 需要的usdt数量
        uint8 needOut; // 需要出局才能升级到该等级
        uint8 genCountPerOut; // 出局一次增加的代数奖励
    }

    struct HashrateConf {
        uint256 baseAmount; // 基数
        uint256 minTotalHashrate; // 全网最小算力
        uint256 maxTotalHashrate; // 全网最大算力, 超过最高算力后代币产值减半
        uint256 maxReward; // 全网最大奖励
        uint8 rebate; // 算力返佣, 0=不返佣, 1=返佣
        uint8 tokenRebate; // 代币返佣, 0=不返佣, 1=返佣
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}