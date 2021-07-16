//SourceUnit: AddressSetLib.sol

pragma solidity 0.5.8;


////////////////////////////////////////////
//    ┏┓   ┏┓
//   ┏┛┻━━━┛┻┓
//   ┃       ┃
//   ┃   ━   ┃
//   ┃ ＞   ＜  ┃
//   ┃       ┃
//   ┃    . ⌒ .. ┃
//   ┃       ┃
//   ┗━┓   ┏━┛
//     ┃   ┃ Codes are far away from bugs
//     ┃   ┃ with the animal protecting
//     ┃   ┃
//     ┃   ┃
//     ┃   ┃
//     ┃   ┃
//     ┃   ┗━━━┓
//     ┃       ┣┓
//     ┃       ┏┛
//     ┗┓┓┏━┳┓┏┛
//      ┃┫┫ ┃┫┫
//      ┗┻┛ ┗┻┛
////////////////////////////////////////////

library AddressSetLib {
    struct AddressSet {
        address[] elements;
        mapping(address => uint) indices;
    }

    function contains(AddressSet storage set, address candidate) internal view returns (bool) {
        if (set.elements.length == 0) {
            return false;
        }
        uint index = set.indices[candidate];
        return index != 0 || set.elements[0] == candidate;
    }

    function getPage(
        AddressSet storage set,
        uint index,
        uint pageSize
    ) internal view returns (address[] memory) {
        // NOTE: This implementation should be converted to slice operators if the compiler is updated to v0.6.0+
        uint endIndex = index + pageSize; // The check below that endIndex <= index handles overflow.

        // If the page extends past the end of the list, truncate it.
        if (endIndex > set.elements.length) {
            endIndex = set.elements.length;
        }
        if (endIndex <= index) {
            return new address[](0);
        }

        uint n = endIndex - index; // We already checked for negative overflow.
        address[] memory page = new address[](n);
        for (uint i; i < n; i++) {
            page[i] = set.elements[i + index];
        }
        return page;
    }

    function add(AddressSet storage set, address element) internal {
        // Adding to a set is an idempotent operation.
        if (!contains(set, element)) {
            set.indices[element] = set.elements.length;
            set.elements.push(element);
        }
    }

    function remove(AddressSet storage set, address element) internal {
        require(contains(set, element), "Element not in set.");
        // Replace the removed element with the last element of the list.
        uint index = set.indices[element];
        uint lastIndex = set.elements.length - 1; // We required that element is in the list, so it is not empty.
        if (index != lastIndex) {
            // No need to shift the last element if it is the one we want to delete.
            address shiftedElement = set.elements[lastIndex];
            set.elements[index] = shiftedElement;
            set.indices[shiftedElement] = index;
        }
        set.elements.pop();
        delete set.indices[element];
    }
}


//SourceUnit: BAOZISupply.sol

pragma solidity 0.5.8;

import "./ITRC20.sol";
import "./Ownable.sol";
import "./TRC20.sol";
import "./BAOZIToken.sol";
import './TransferHelper.sol';
import './Rank.sol';
import './IRefer.sol';
import './Refer.sol';

////////////////////////////////////////////
//    ┏┓   ┏┓
//   ┏┛┻━━━┛┻┓
//   ┃       ┃
//   ┃   ━   ┃
//   ┃ ＞   ＜  ┃
//   ┃       ┃
//   ┃    . ⌒ .. ┃
//   ┃       ┃
//   ┗━┓   ┏━┛
//     ┃   ┃ Codes are far away from bugs
//     ┃   ┃ with the animal protecting
//     ┃   ┃
//     ┃   ┃
//     ┃   ┃
//     ┃   ┃
//     ┃   ┗━━━┓
//     ┃       ┣┓
//     ┃       ┏┛
//     ┗┓┓┏━┳┓┏┛
//      ┃┫┫ ┃┫┫
//      ┗┻┛ ┗┻┛
////////////////////////////////////////////

contract BAOZISupply is Ownable, Rank {
    using SafeMath for uint256;

    struct SystemSetting {
        uint256 round;  // 当前轮次
        uint256 layers; // 当前层数
        uint256 limitPerLayer; // 当前轮每一层开放的BAOZI购买额度
        uint256 price; // 初始价格，放大100倍，方便整数计算
        uint256 curLeftOver; // 当前层剩余的BAOZI额度
    }

    // The BAOZI token
    address public gamma;   // BAOZI token合约地址
    address public oldGamma;
    uint256 public reflectPercent = 5;

    address public usdt;  // USDT token合约地址
    // Dev address.
    address public devaddr;  // 提现USDT地址

    uint256 public startBlock; // 当前轮开始的区块高度

    Refer public refer;
    uint256 public totalReferBonus; // 全网推荐总收益

    mapping(address => uint256) referBonus;

    // 系统参数
    SystemSetting public setting;

    // 不同层的差价
    uint256[] public priceDeltas = [5, 1, 2, 3, 4, 5, 6, 7, 8, 9];

    // 最少需要投入1 BAOZI
    uint256 public constant MIN_GAMMA_REQUIRE = 1e6;

    // 每层增加10000 BAOZI额度
    uint256 public constant LAYER_DELTA = 10000e6;
//    uint256 public constant LAYER_DELTA = 1000e6; //测试用，每层增加1000

    // 最大轮数限制
    uint256 public constant TOTAL_ROUND = 10;
    // 最大层数限制
    uint256 public constant TOTAL_LAYERS = 10;
    // 9 人一组开奖
    uint256 public constant GROUP_NUM_LIMIT = 9;
    // 一组开奖3人
    uint256 public constant GROUP_WIN_NUM = 3;

    uint256 public constant USDTAmountLow = 100e6;
    uint256 public constant USDTAmountMedium = 500e6;
    uint256 public constant USDTAmountHigh = 1000e6;

    address[] public winnersLow;
    address[] public winnersMedium;
    address[] public winnersHigh;

    struct winAmount {
        uint256 gammaAmount;
        uint256 usdtAmount;
    }

    // 保存熔炼成功获得的BAOZI数量
    mapping (address => winAmount) public forgeWinAmount;

    // 用于计算链上随机数
    uint256 nonce = 0;

    // 当季新增资金量
    uint256 public increasedTotalAmount = 0;

    // 奖励赛奖金池，前三轮资金的20%
    uint256 public racePoolTotalAmount = 0;

    // 奖励赛前20名奖励的百分比，放大1000倍
    uint256[] bonusRate = [300, 200, 100, 80, 70, 60, 50, 40, 30, 20, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5];
    uint256 public constant RANK_TOP_NUM = 20;

    // 奖励赛前20名
    address[] public topRank;

    // constructor
    constructor (
        address _gamma,
        address _oldGamma,
        address _usdt,
        address _devaddr,
        Refer _refer
    ) public {
        gamma = _gamma;
        oldGamma = _oldGamma;
        usdt = _usdt;
        devaddr = _devaddr;
        refer = _refer;
    }

    // set init params
    function setParams(uint256 _startBlock) public onlyOwner {
        startBlock = _startBlock;
        // 设置系统参数 (round, layers, limitPerLayer, price, curLeftOver)
        setting = SystemSetting(1, 1, 50000e6, 10, 50000e6);

//        setting = SystemSetting(1, 1, 10000e6, 10, 10000e6);
    }

    // set system setting
    function setSystemSetting(uint256 _round, uint256 _layers, uint256 _limitPerLayer, uint256 _price, uint256 _curLeftOver) public onlyOwner {
        setting = SystemSetting(_round, _layers, _limitPerLayer, _price, _curLeftOver);
    }

    function setReflectPercent(uint256 _percent) public onlyOwner {
        require(_percent < 100, "percent too large");
        reflectPercent = _percent;
    }

    function reflect() public returns (bool) {
        address sender = msg.sender;
        uint256 balance = ITRC20(oldGamma).balanceOf(sender);
        uint256 amount = balance.add(balance.mul(reflectPercent).div(100));
        TransferHelper.safeTransferFrom(oldGamma, sender, devaddr, balance);
        TransferHelper.safeTransferFrom(gamma, devaddr, sender, amount);
        return true;
    }

    // 产生一个[0 - 8]的随机数
    function winnerNumber(uint256 N) internal returns (uint256, uint256, uint256) {
        uint256 base = now;
        uint256 a = base.add(nonce++).mod(N);
        uint256 b = base.add(nonce++).mod(N);
        uint256 c = base.add(nonce++).mod(N);
        return (a, b, c);
    }

    // 系统只运行在每天的[20 - 21]点
    function requireSystemActive() internal view {
//        require(block.number >= startBlock, "next round not yet started");
        uint256 startHour = 12;
        uint256 endHour = 13;
        uint256 hour = now % (1 days) / (1 hours);
        require(hour >= startHour && hour <= endHour, "system only works in [20 - 21] hour!");
    }

    function enterNextLayer() internal {
        setting.layers = setting.layers.add(1);
        if (setting.layers > TOTAL_LAYERS) {
            // 当前轮已超过10层，进入下一轮，轮数加1
            setting.round = setting.round.add(1);
            setting.layers = 1;

            increasedTotalAmount = 0;
        }

        // 下一层增加1万额度，同时把上一层剩余的累加上去
        setting.limitPerLayer = setting.limitPerLayer.add(LAYER_DELTA).add(setting.curLeftOver);
        setting.curLeftOver = setting.limitPerLayer;
        setting.price = setting.price.add(priceDeltas[setting.round.sub(1)]);
    }

    // 获取熔炼成功的BAOZI数量
    function getForgeWinAmount (address usr) public view returns (uint256 gammaAmount, uint256 usdtAmount) {
        gammaAmount =  forgeWinAmount[usr].gammaAmount;
        usdtAmount = forgeWinAmount[usr].usdtAmount;
    }

    function forgeLow(address referrer) public {
        address sender = msg.sender;

//        requireSystemActive();
        uint256 usdtAmount = USDTAmountLow;
        SystemSetting memory ss = setting;

        // 如果额度不足，则进入下一层
        uint256 gammaAmount = usdtAmount.mul(100).div(ss.price);
        if (ss.curLeftOver < gammaAmount.mul(GROUP_WIN_NUM)) {
            // 如果剩余额度不足一组，则额度累加到下一层
            enterNextLayer();// 返回值为是否进入了奖励赛
            ss = setting;
            gammaAmount = usdtAmount.mul(100).div(ss.price);
        }
        // 最多10轮
        require(ss.round <= TOTAL_ROUND, "total 10 round finisehd");

        TransferHelper.safeTransferFrom(address(gamma), sender, address(this), MIN_GAMMA_REQUIRE);
        TransferHelper.safeTransferFrom(usdt, sender, devaddr, usdtAmount);

        // 记录推荐关系
        refer.submitRefer(sender, referrer);

        // 存储并计算熔炼成功者
        if (winnersLow.length < GROUP_NUM_LIMIT) {
            winnersLow.push(sender);
        }

        if (winnersLow.length == GROUP_NUM_LIMIT) {
            // 计算出3个随机index, 范围[0 - 8]
            (uint256 idx1, uint256 idx2, uint256 idx3) = winnerNumber(GROUP_NUM_LIMIT);

            // 开奖
            for (uint256 i = 0; i < winnersLow.length; i++) {
                address win = winnersLow[i];
                if (i == idx1 || i == idx2 || i == idx3) {
                    // 熔炼成功
                    // 发送BAOZI
                    TransferHelper.safeTransferFrom(gamma, devaddr, win, gammaAmount);
                    forgeWinAmount[win].gammaAmount = forgeWinAmount[win].gammaAmount.add(gammaAmount);
                    forgeWinAmount[win].usdtAmount = forgeWinAmount[win].usdtAmount.add(usdtAmount);

                    // 一级推荐人获得4%
                    address refAddr = refer.getReferrer(win);
                    referBonus[refAddr] = referBonus[refAddr].add(usdtAmount.mul(4).div(100));

                    // 二级推荐人获得1%
                    address refAddr2 = refer.getReferrer(refAddr);
                    referBonus[refAddr2] = referBonus[refAddr2].add(usdtAmount.mul(1).div(100));
                } else {
                    // 熔炼失败
                    // 退还110%
                    uint256 amount = usdtAmount.add(usdtAmount.div(10));
                    TransferHelper.safeTransferFrom(usdt, devaddr, win, amount);

                    // 一级推荐人获得0.8%
                    address refAddr = refer.getReferrer(win);
                    referBonus[refAddr] = referBonus[refAddr].add(usdtAmount.mul(8).div(1000));

                    // 二级推荐人获得0.2%
                    address refAddr2 = refer.getReferrer(refAddr);
                    referBonus[refAddr2] = referBonus[refAddr2].add(usdtAmount.mul(2).div(1000));
                }
            }

            updateLeftOver(gammaAmount);
            updateTotalReferBonus(usdtAmount);

            if (ss.round <= 3) {
                // 取前三轮的20%累积到资金池
                updateRacePoolTotalAmount(usdtAmount.mul(3).div(5));
            } else {
                // 当前轮新增资金量
                updateIncreasedTotalAmount(usdtAmount.mul(3));
            }

            delete winnersLow;
        }
    }

    // 为TOP K分发奖励
    // only dev
    function distributeBonus() public returns (bool) {
        require(msg.sender == devaddr, "dev: only devaddr");

        uint256 totalBonus = getBonus();
        address[] memory topList = getTopRank();
        require(topList.length <= bonusRate.length, "topList above RANK_TOP_NUM");

        for (uint256 i = 0; i < topList.length; i++) {
            uint256 bonus = totalBonus.div(1000).mul(bonusRate[i]);
            TransferHelper.safeTransferFrom(usdt, devaddr, topList[i], bonus);
        }
        return true;
    }

    function claimRewards() public returns (uint256) {
        address sender = msg.sender;
        uint256 rewards = referBonus[sender];
        referBonus[sender] = 0;
        TransferHelper.safeTransferFrom(usdt, devaddr, sender, rewards);
        return rewards;
    }

    function updateLeftOver(uint256 gammaAmount) internal {
        uint256 amount = gammaAmount.mul(3);
        setting.curLeftOver = setting.curLeftOver.sub(amount);
    }

    function updateTotalReferBonus(uint256 usdtAmount) internal {
        uint256 total = totalReferBonus;
        total = total.add(usdtAmount.mul(3).div(20));
        total = total.add(usdtAmount.mul(6).div(100));
        totalReferBonus = total;
    }

    function updateRacePoolTotalAmount(uint256 amount) internal {
        racePoolTotalAmount = racePoolTotalAmount.add(amount);
    }

    function updateIncreasedTotalAmount(uint256 amount) internal {
        increasedTotalAmount = increasedTotalAmount.add(amount);
    }

    function setRacePoolTotalAmount(uint256 amount) public onlyOwner {
        racePoolTotalAmount = amount;
    }

    function setIncreasedTotalAmount(uint256 amount) public onlyOwner {
        increasedTotalAmount = amount;
    }

    // 查询推荐的总收益
    function getReferBonus(address usr) public view returns (uint256) {
        return referBonus[usr];
    }

    // 查询初级熔炼池未成团人数
    function getWinnersLowLength() public view returns (uint256) {
        return winnersLow.length;
    }

    // 查询中级熔炼池未成团人数
    function getWinnersMediumLength() public view returns (uint256) {
        return winnersMedium.length;
    }

    // 查询高级熔炼池未成团人数
    function getWinnersHighLength() public view returns (uint256) {
        return winnersHigh.length;
    }

    // 奖励池
    function getBonus() public view returns (uint256) {
        return racePoolTotalAmount.div(7).add(increasedTotalAmount.div(5));
    }

    // 查询在三个熔炼池中成团情况
    function getPendingForge(address usr) public view returns (bool low, bool medium,bool high) {
        low = false;
        medium = false;
        high = false;

        // low
        for (uint256 i = 0; i < winnersLow.length; i++) {
            if (usr == winnersLow[i]) {
                low = true;
                break;
            }
        }
        // medium
        for (uint256 i = 0; i < winnersMedium.length; i++) {
            if (usr == winnersMedium[i]) {
                medium = true;
                break;
            }
        }
        // high
        for (uint256 i = 0; i < winnersHigh.length; i++) {
            if (usr == winnersHigh[i]) {
                high = true;
                break;
            }
        }
    }

    function getTopRank() public view returns (address[] memory) {
        return getTop(RANK_TOP_NUM);
    }

    function getUserRank(address usr) public view returns (uint256) {
        return getRank(usr);
    }

    function updateUserRank(address usr) public returns (bool) {
        uint256 balance = forgeWinAmount[usr].gammaAmount;
        uint256 rankBalance = getRankBalance(usr);
        if (balance > rankBalance) {
            updateRank(usr, balance);
        }
        return true;
    }

    function forgeMedium(address referrer) public {
        address sender = msg.sender;

        //        requireSystemActive();
        uint256 usdtAmount = USDTAmountMedium;
        SystemSetting memory ss = setting;

        // 如果额度不足，则进入下一层
        uint256 gammaAmount = usdtAmount.mul(100).div(ss.price);
        if (ss.curLeftOver < gammaAmount.mul(GROUP_WIN_NUM)) {
            // 如果剩余额度不足一组，则额度累加到下一层
            enterNextLayer();// 返回值为是否进入了奖励赛
            ss = setting;
            gammaAmount = usdtAmount.mul(100).div(ss.price);
        }
        // 最多10轮
        require(ss.round <= TOTAL_ROUND, "total 10 round finisehd");

        TransferHelper.safeTransferFrom(gamma, sender, address(this), MIN_GAMMA_REQUIRE);
        TransferHelper.safeTransferFrom(usdt, sender, devaddr, usdtAmount);

        // 记录推荐关系
        refer.submitRefer(sender, referrer);

        // 存储并计算熔炼成功者
        if (winnersMedium.length < GROUP_NUM_LIMIT) {
            winnersMedium.push(sender);
        }

        if (winnersMedium.length == GROUP_NUM_LIMIT) {
            // 计算出3个随机index, 范围[0 - 8]
            (uint256 idx1, uint256 idx2, uint256 idx3) = winnerNumber(GROUP_NUM_LIMIT);

            // 开奖
            for (uint256 i = 0; i < winnersMedium.length; i++) {
                address win = winnersMedium[i];
                if (i == idx1 || i == idx2 || i == idx3) {
                    // 熔炼成功
                    // 发送GAMMA
                    TransferHelper.safeTransferFrom(gamma, devaddr, win, gammaAmount);
                    forgeWinAmount[win].gammaAmount = forgeWinAmount[win].gammaAmount.add(gammaAmount);
                    forgeWinAmount[win].usdtAmount = forgeWinAmount[win].usdtAmount.add(usdtAmount);

                    // 推荐人获得5%
                    address refAddr = refer.getReferrer(win);
                    referBonus[refAddr] = referBonus[refAddr].add(usdtAmount.div(20));
                } else {
                    // 熔炼失败
                    // 退还110%
                    uint256 amount = usdtAmount.add(usdtAmount.div(10));
                    TransferHelper.safeTransferFrom(usdt, devaddr, win, amount);

                    // 推荐人获得1%
                    address refAddr = refer.getReferrer(win);
                    referBonus[refAddr] = referBonus[refAddr].add(usdtAmount.div(100));
                }
            }

            updateLeftOver(gammaAmount);
            updateTotalReferBonus(usdtAmount);

            if (ss.round <= 3) {
                // 取前三轮的20%累积到资金池
                updateRacePoolTotalAmount(usdtAmount.mul(3).div(5));
            } else {
                // 当前轮新增资金量
                updateIncreasedTotalAmount(usdtAmount.mul(3));
            }

            delete winnersMedium;
        }
    }

    function forgeHigh(address referrer) public {
        address sender = msg.sender;

        //        requireSystemActive();
        uint256 usdtAmount = USDTAmountHigh;
        SystemSetting memory ss = setting;

        // 如果额度不足，则进入下一层
        uint256 gammaAmount = usdtAmount.mul(100).div(ss.price);
        if (ss.curLeftOver < gammaAmount.mul(GROUP_WIN_NUM)) {
            // 如果剩余额度不足一组，则额度累加到下一层
            enterNextLayer();// 返回值为是否进入了奖励赛
            ss = setting;
            gammaAmount = usdtAmount.mul(100).div(ss.price);
        }
        // 最多10轮
        require(ss.round <= TOTAL_ROUND, "total 10 round finisehd");

        TransferHelper.safeTransferFrom(address(gamma), sender, address(this), MIN_GAMMA_REQUIRE);
        TransferHelper.safeTransferFrom(usdt, sender, devaddr, usdtAmount);

        // 记录推荐关系
        refer.submitRefer(sender, referrer);

        // 存储并计算熔炼成功者
        if (winnersHigh.length < GROUP_NUM_LIMIT) {
            winnersHigh.push(sender);
        }

        if (winnersHigh.length == GROUP_NUM_LIMIT) {
            // 计算出3个随机index, 范围[0 - 8]
            (uint256 idx1, uint256 idx2, uint256 idx3) = winnerNumber(GROUP_NUM_LIMIT);

            // 开奖
            for (uint256 i = 0; i < winnersHigh.length; i++) {
                address win = winnersHigh[i];
                if (i == idx1 || i == idx2 || i == idx3) {
                    // 熔炼成功
                    // 发送GAMMA
                    TransferHelper.safeTransferFrom(gamma, devaddr, win, gammaAmount);
                    forgeWinAmount[win].gammaAmount = forgeWinAmount[win].gammaAmount.add(gammaAmount);
                    forgeWinAmount[win].usdtAmount = forgeWinAmount[win].usdtAmount.add(usdtAmount);

                    // 推荐人获得5%
                    address refAddr = refer.getReferrer(win);
                    referBonus[refAddr] = referBonus[refAddr].add(usdtAmount.div(20));
                } else {
                    // 熔炼失败
                    // 退还110%
                    uint256 amount = usdtAmount.add(usdtAmount.div(10));
                    TransferHelper.safeTransferFrom(usdt, devaddr, win, amount);

                    // 推荐人获得1%
                    address refAddr = refer.getReferrer(win);
                    referBonus[refAddr] = referBonus[refAddr].add(usdtAmount.div(100));
                }
            }

            updateLeftOver(gammaAmount);
            updateTotalReferBonus(usdtAmount);

            if (ss.round <= 3) {
                // 取前三轮的20%累积到资金池
                updateRacePoolTotalAmount(usdtAmount.mul(3).div(5));
            } else {
                // 当前轮新增资金量
                updateIncreasedTotalAmount(usdtAmount.mul(3));
            }

            delete winnersHigh;
        }
    }

    // 查询推荐人地址
    function getReferrer(address usr) public view returns (address) {
        return refer.getReferrer(usr);
    }

    // 查询推荐的总人数
    function getReferrerLength(address referrer) public view returns (uint256) {
        return refer.getReferLength(referrer);
    }

    // only dev
    function distributeRewards(address to, uint256 amount) public returns (bool) {
        require(msg.sender == devaddr, "dev: only devaddr");
        TransferHelper.safeTransferFrom(usdt, devaddr, to, amount);
        return true;
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: only devaddr");
        devaddr = _devaddr;
    }

    function withdrawUSDT(uint256 amount) public returns (bool) {
        require(msg.sender == devaddr, "dev: only devaddr");
        TransferHelper.safeTransfer(usdt, devaddr, amount);
        return true;
    }

    function withdrawBAOZI(uint256 amount) public returns (bool) {
        require(msg.sender == devaddr, "dev: only devaddr");
        TransferHelper.safeTransfer(gamma, devaddr, amount);
        return true;
    }

}


//SourceUnit: BAOZIToken.sol

pragma solidity 0.5.8;

import "./Ownable.sol";
import "./TRC20.sol";

////////////////////////////////////////////
//    ┏┓   ┏┓
//   ┏┛┻━━━┛┻┓
//   ┃       ┃
//   ┃   ━   ┃
//   ┃ ＞   ＜  ┃
//   ┃       ┃
//   ┃    . ⌒ .. ┃
//   ┃       ┃
//   ┗━┓   ┏━┛
//     ┃   ┃ Codes are far away from bugs
//     ┃   ┃ with the animal protecting
//     ┃   ┃
//     ┃   ┃
//     ┃   ┃
//     ┃   ┃
//     ┃   ┗━━━┓
//     ┃       ┣┓
//     ┃       ┏┛
//     ┗┓┓┏━┳┓┏┛
//      ┃┫┫ ┃┫┫
//      ┗┻┛ ┗┻┛
////////////////////////////////////////////

contract BAOZIToken is TRC20("BAOZI Token", "BAOZI"), Ownable {
    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner.
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) public onlyOwner {
        _burn(_from, _amount);
    }
}


//SourceUnit: IRefer.sol

pragma solidity 0.5.8;

////////////////////////////////////////////
//    ┏┓   ┏┓
//   ┏┛┻━━━┛┻┓
//   ┃       ┃
//   ┃   ━   ┃
//   ┃ ＞   ＜  ┃
//   ┃       ┃
//   ┃    . ⌒ .. ┃
//   ┃       ┃
//   ┗━┓   ┏━┛
//     ┃   ┃ Codes are far away from bugs
//     ┃   ┃ with the animal protecting
//     ┃   ┃
//     ┃   ┃
//     ┃   ┃
//     ┃   ┃
//     ┃   ┗━━━┓
//     ┃       ┣┓
//     ┃       ┏┛
//     ┗┓┓┏━┳┓┏┛
//      ┃┫┫ ┃┫┫
//      ┗┻┛ ┗┻┛
////////////////////////////////////////////

interface IRefer {
    function submitRefer(address referrer) external returns (bool);
    function getReferLength(address usr) external view returns (uint256);
    function isReferContains(address usr, address referrer) external view returns (bool);
    function getReferrer(address usr) external view returns (address);
}

//SourceUnit: ITRC20.sol

pragma solidity 0.5.8;

////////////////////////////////////////////
//    ┏┓   ┏┓
//   ┏┛┻━━━┛┻┓
//   ┃       ┃
//   ┃   ━   ┃
//   ┃ ＞   ＜  ┃
//   ┃       ┃
//   ┃    . ⌒ .. ┃
//   ┃       ┃
//   ┗━┓   ┏━┛
//     ┃   ┃ Codes are far away from bugs
//     ┃   ┃ with the animal protecting
//     ┃   ┃
//     ┃   ┃
//     ┃   ┃
//     ┃   ┃
//     ┃   ┗━━━┓
//     ┃       ┣┓
//     ┃       ┏┛
//     ┗┓┓┏━┳┓┏┛
//      ┃┫┫ ┃┫┫
//      ┗┻┛ ┗┻┛
////////////////////////////////////////////

/**
 * @title TRC20 interface
 */
interface ITRC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


//SourceUnit: Ownable.sol

pragma solidity 0.5.8;

////////////////////////////////////////////
//    ┏┓   ┏┓
//   ┏┛┻━━━┛┻┓
//   ┃       ┃
//   ┃   ━   ┃
//   ┃ ＞   ＜  ┃
//   ┃       ┃
//   ┃    . ⌒ .. ┃
//   ┃       ┃
//   ┗━┓   ┏━┛
//     ┃   ┃ Codes are far away from bugs
//     ┃   ┃ with the animal protecting
//     ┃   ┃
//     ┃   ┃
//     ┃   ┃
//     ┃   ┃
//     ┃   ┗━━━┓
//     ┃       ┣┓
//     ┃       ┏┛
//     ┗┓┓┏━┳┓┏┛
//      ┃┫┫ ┃┫┫
//      ┗┻┛ ┗┻┛
////////////////////////////////////////////

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev Initializes the contract setting the deployer as the initial owner.
    */
    constructor() internal {
        address msgSender = msg.sender;
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
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

//SourceUnit: Rank.sol

pragma solidity 0.5.8;

import "./Ownable.sol";

////////////////////////////////////////////
//    ┏┓   ┏┓
//   ┏┛┻━━━┛┻┓
//   ┃       ┃
//   ┃   ━   ┃
//   ┃ ＞   ＜  ┃
//   ┃       ┃
//   ┃    . ⌒ .. ┃
//   ┃       ┃
//   ┗━┓   ┏━┛
//     ┃   ┃ Codes are far away from bugs
//     ┃   ┃ with the animal protecting
//     ┃   ┃
//     ┃   ┃
//     ┃   ┃
//     ┃   ┃
//     ┃   ┗━━━┓
//     ┃       ┣┓
//     ┃       ┏┛
//     ┗┓┓┏━┳┓┏┛
//      ┃┫┫ ┃┫┫
//      ┗┻┛ ┗┻┛
////////////////////////////////////////////

contract Rank is Ownable {
    mapping(address => uint256)  balances;
    mapping(address => address)  _nextAddress;
    uint256 public listSize;
    address constant GUARD = address(1);

    constructor() public {
        _nextAddress[GUARD] = GUARD;
    }

    function addRankAddress(address addr, uint256 balance) internal {
        if (_nextAddress[addr] != address(0)) {
            return;
        }

        address index = _findIndex(balance);
        balances[addr] = balance;
        _nextAddress[addr] = _nextAddress[index];
        _nextAddress[index] = addr;
        listSize++;
    }

    function removeRankAddress(address addr) internal {
        if (_nextAddress[addr] == address(0)) {
            return;
        }

        address prevAddress = _findPrevAddress(addr);
        _nextAddress[prevAddress] = _nextAddress[addr];

        _nextAddress[addr] = address(0);
        balances[addr] = 0;
        listSize--;
    }

    function isContains(address addr) internal view returns (bool) {
        return _nextAddress[addr] != address(0);
    }

    function getRank(address addr) public view returns (uint256) {
        if (!isContains(addr)) {
            return 0;
        }

        uint idx = 0;
        address currentAddress = GUARD;
        while(_nextAddress[currentAddress] != GUARD) {
            if (addr != currentAddress) {
                currentAddress = _nextAddress[currentAddress];
                idx++;
            } else {
                break;
            }
        }
        return idx;
    }

    function getRankBalance(address addr) internal view returns (uint256) {
        return balances[addr];
    }

    function getTop(uint256 k) public view returns (address[] memory) {
        if (k > listSize) {
            k = listSize;
        }

        address[] memory addressLists = new address[](k);
        address currentAddress = _nextAddress[GUARD];
        for (uint256 i = 0; i < k; ++i) {
            addressLists[i] = currentAddress;
            currentAddress = _nextAddress[currentAddress];
        }

        return addressLists;
    }

    function updateRank(address addr, uint256 newBalance) internal {
        if (!isContains(addr)) {
            // 如果不存在，则添加
            addRankAddress(addr, newBalance);
        } else {
            // 已存在，则更新
            address prevAddress = _findPrevAddress(addr);
            address nextAddress = _nextAddress[addr];
            if (_verifyIndex(prevAddress, newBalance, nextAddress)) {
                balances[addr] = newBalance;
            } else {
                removeRankAddress(addr);
                addRankAddress(addr, newBalance);
            }
        }
    }

    function _isPrevAddress(address addr, address prevAddress) internal view returns (bool) {
        return _nextAddress[prevAddress] == addr;
    }

    // 用于验证该值在左右地址之间
    // 如果 左边的值 ≥ 新值 > 右边的值将返回 true(如果我们保持降序，并且如果值等于，则新值应该在旧值的后面)
    function _verifyIndex(address prevAddress, uint256 newValue, address nextAddress)
    internal
    view
    returns (bool) {
        return (prevAddress == GUARD || balances[prevAddress] >= newValue) &&
        (nextAddress == GUARD || newValue > balances[nextAddress]);
    }

    // 用于查找新值应该插入在哪一个地址后面
    function _findIndex(uint256 newValue) internal view returns (address) {
        address candidateAddress = GUARD;
        while(true) {
            if (_verifyIndex(candidateAddress, newValue, _nextAddress[candidateAddress]))
                return candidateAddress;

            candidateAddress = _nextAddress[candidateAddress];
        }
    }

    function _findPrevAddress(address addr) internal view returns (address) {
        address currentAddress = GUARD;
        while(_nextAddress[currentAddress] != GUARD) {
            if (_isPrevAddress(addr, currentAddress))
                return currentAddress;

            currentAddress = _nextAddress[currentAddress];
        }
        return address(0);
    }
}

//SourceUnit: Refer.sol

pragma solidity 0.5.8;

import "./AddressSetLib.sol";

////////////////////////////////////////////
//    ┏┓   ┏┓
//   ┏┛┻━━━┛┻┓
//   ┃       ┃
//   ┃   ━   ┃
//   ┃ ＞   ＜  ┃
//   ┃       ┃
//   ┃    . ⌒ .. ┃
//   ┃       ┃
//   ┗━┓   ┏━┛
//     ┃   ┃ Codes are far away from bugs
//     ┃   ┃ with the animal protecting
//     ┃   ┃
//     ┃   ┃
//     ┃   ┃
//     ┃   ┃
//     ┃   ┗━━━┓
//     ┃       ┣┓
//     ┃       ┏┛
//     ┗┓┓┏━┳┓┏┛
//      ┃┫┫ ┃┫┫
//      ┗┻┛ ┗┻┛
////////////////////////////////////////////


contract Refer {
    using AddressSetLib for AddressSetLib.AddressSet;

    mapping (address => address) public referrers; // 推荐关系
    mapping (address => address[]) public referList; // 推荐列表

    AddressSetLib.AddressSet internal addressSet;

    event NewReferr(address indexed usr, address refer);

    // 提交推荐关系
    function submitRefer(address usr, address referrer) public returns (bool) {
        require(usr == tx.origin, "usr must be tx origin");

        // 记录推荐关系
        if (referrers[usr] == address(0)) {
            referrers[usr] = referrer;
            emit NewReferr(usr, referrer);

            addressSet.add(referrer);

            if (!isReferContains(usr, referrer)) {
                referList[referrer].push(usr);
            }
        }
        return true;
    }

    // 查询推荐的总人数
    function getReferLength(address referrer) public view returns (uint256) {
        return referList[referrer].length;
    }

    // 查询用户是否在指定地址的推荐列表中
    function isReferContains(address usr, address referrer) public view returns (bool) {
        address[] memory addrList = referList[referrer];
        bool found = false;
        for (uint256 i = 0; i < addrList.length; i++) {
            if (usr == addrList[i]) {
                found = true;
                break;
            }
        }
        return found;
    }

    // 查询推荐人地址
    function getReferrer(address usr) public view returns (address) {
        return referrers[usr];
    }

    // 查询所有的推荐人，可指定index位置和返回数量
    function getReferrers(uint256 index, uint256 pageSize) public view returns (address[] memory) {
        return addressSet.getPage(index, pageSize);
    }
}


//SourceUnit: SafeMath.sol

pragma solidity 0.5.8;


////////////////////////////////////////////
//    ┏┓   ┏┓
//   ┏┛┻━━━┛┻┓
//   ┃       ┃
//   ┃   ━   ┃
//   ┃ ＞   ＜  ┃
//   ┃       ┃
//   ┃    . ⌒ .. ┃
//   ┃       ┃
//   ┗━┓   ┏━┛
//     ┃   ┃ Codes are far away from bugs
//     ┃   ┃ with the animal protecting
//     ┃   ┃
//     ┃   ┃
//     ┃   ┃
//     ┃   ┃
//     ┃   ┗━━━┓
//     ┃       ┣┓
//     ┃       ┏┛
//     ┗┓┓┏━┳┓┏┛
//      ┃┫┫ ┃┫┫
//      ┗┻┛ ┗┻┛
////////////////////////////////////////////


/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {

    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath#mul: OVERFLOW");

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath#div: DIVISION_BY_ZERO");
        uint256 c = a / b;

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath#sub: UNDERFLOW");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath#add: OVERFLOW");

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath#mod: DIVISION_BY_ZERO");
        return a % b;
    }

}

//SourceUnit: TRC20.sol

pragma solidity 0.5.8;

import "./ITRC20.sol";
import "./SafeMath.sol";

////////////////////////////////////////////
//    ┏┓   ┏┓
//   ┏┛┻━━━┛┻┓
//   ┃       ┃
//   ┃   ━   ┃
//   ┃ ＞   ＜  ┃
//   ┃       ┃
//   ┃    . ⌒ .. ┃
//   ┃       ┃
//   ┗━┓   ┏━┛
//     ┃   ┃ Codes are far away from bugs
//     ┃   ┃ with the animal protecting
//     ┃   ┃
//     ┃   ┃
//     ┃   ┃
//     ┃   ┃
//     ┃   ┗━━━┓
//     ┃       ┣┓
//     ┃       ┏┛
//     ┗┓┓┏━┳┓┏┛
//      ┃┫┫ ┃┫┫
//      ┗┻┛ ┗┻┛
////////////////////////////////////////////


/**
 * @title Standard TRC20 token
 *
 * @dev Implementation of the basic standard token.
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn't required by the specification, and other
 * compliant implementations may not do it.
 */
contract TRC20 is ITRC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);


    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 internal _totalSupply;

    // Max supply
    uint256 public MAX_SUPPLY = 54500000e6;

    /**
      * Constructor function
      *
      * Initializes contract with initial supply tokens to the creator of the contract
      */
    constructor (string memory _name, string memory _symbol) public {
        name = _name;
        symbol = _symbol;
        decimals = 6;
    }

    /**
      * @dev Total number of tokens in existence
      */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
      * @dev Gets the balance of the specified address.
      * @param owner The address to query the balance of.
      * @return A uint256 representing the amount owned by the passed address.
      */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
      * @dev Function to check the amount of tokens that an owner allowed to a spender.
      * @param owner address The address which owns the funds.
      * @param spender address The address which will spend the funds.
      * @return A uint256 specifying the amount of tokens still available for the spender.
      */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
      * @dev Transfer token to a specified address
      * @param to The address to transfer to.
      * @param value The amount to be transferred.
      */
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
      * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
      * Beware that changing an allowance with this method brings the risk that someone may use both the old
      * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
      * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
      * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
      * @param spender The address which will spend the funds.
      * @param value The amount of tokens to be spent.
      */
    function approve(address spender, uint256 value) public returns (bool) {
        require((value == 0) || (_allowed[msg.sender][spender] == 0), "TRC20: use increaseAllowance or decreaseAllowance function instead");
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
      * @dev Transfer tokens from one address to another.
      * Note that while this function emits an Approval event, this is not required as per the specification,
      * and other compliant implementations may not emit the event.
      * @param from address The address which you want to send tokens from
      * @param to address The address which you want to transfer to
      * @param value uint256 the amount of tokens to be transferred
      */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    /**
      * @dev Increase the amount of tokens that an owner allowed to a spender.
      * approve should be called when _allowed[msg.sender][spender] == 0. To increment
      * allowed value is better to use this function to avoid 2 calls (and wait until
      * the first transaction is mined)
      * From MonolithDAO Token.sol
      * Emits an Approval event.
      * @param spender The address which will spend the funds.
      * @param addedValue The amount of tokens to increase the allowance by.
      */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
      * @dev Decrease the amount of tokens that an owner allowed to a spender.
      * approve should be called when _allowed[msg.sender][spender] == 0. To decrement
      * allowed value is better to use this function to avoid 2 calls (and wait until
      * the first transaction is mined)
      * From MonolithDAO Token.sol
      * Emits an Approval event.
      * @param spender The address which will spend the funds.
      * @param subtractedValue The amount of tokens to decrease the allowance by.
      */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
      * @dev Transfer token for a specified addresses
      * @param from The address to transfer from.
      * @param to The address to transfer to.
      * @param value The amount to be transferred.
      */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
      * @dev Internal function that mints an amount of the token and assigns it to
      * an account. This encapsulates the modification of balances such that the
      * proper events are emitted.
      * @param account The account that will receive the created tokens.
      * @param value The amount that will be created.
      */
    function _mint(address account, uint256 value) internal {
        require(account != address(0));
        require(_totalSupply <= MAX_SUPPLY, "TRC20: max supply exceed!");

        // Ensure that totalSupply not exceed 8600w after mint
        uint256 newTotalSupply = _totalSupply.add(value);
        require(newTotalSupply <= MAX_SUPPLY, "TRC20: max supply exceed!");

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    /**
      * @dev Internal function that burns an amount of the token of a given
      * account.
      * @param account The account whose tokens will be burnt.
      * @param value The amount that will be burnt.
      */
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
      * @dev Approve an address to spend another addresses' tokens.
      * @param owner The address that owns the tokens.
      * @param spender The address that will spend the tokens.
      * @param value The number of tokens that can be spent.
      */
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
      * @dev Internal function that burns an amount of the token of a given
      * account, deducting from the sender's allowance for said account. Uses the
      * internal burn function.
      * Emits an Approval event (reflecting the reduced allowance).
      * @param account The account whose tokens will be burnt.
      * @param value The amount that will be burnt.
      */
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}


//SourceUnit: TransferHelper.sol

pragma solidity 0.5.8;


////////////////////////////////////////////
//    ┏┓   ┏┓
//   ┏┛┻━━━┛┻┓
//   ┃       ┃
//   ┃   ━   ┃
//   ┃ ＞   ＜  ┃
//   ┃       ┃
//   ┃    . ⌒ .. ┃
//   ┃       ┃
//   ┗━┓   ┏━┛
//     ┃   ┃ Codes are far away from bugs
//     ┃   ┃ with the animal protecting
//     ┃   ┃
//     ┃   ┃
//     ┃   ┃
//     ┃   ┃
//     ┃   ┗━━━┓
//     ┃       ┣┓
//     ┃       ┏┛
//     ┗┓┓┏━┳┓┏┛
//      ┃┫┫ ┃┫┫
//      ┗┻┛ ┗┻┛
////////////////////////////////////////////

// helper methods for interacting with TRC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success, 'TransferHelper: TRANSFER_FAILED');
        //        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success, 'TransferHelper: TRANSFER_FROM_FAILED');
        //        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferTRX(address to, uint value) internal {
        (bool success,) = to.call.value(value)(new bytes(0));
        require(success, 'TransferHelper: TRX_TRANSFER_FAILED');
    }
}