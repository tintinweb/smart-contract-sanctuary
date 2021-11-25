pragma solidity 0.5.8;

import "./ITRC20.sol";
import "./MOTToken.sol";
import "./Ownable.sol";
import './TransferHelper.sol';
import './Rank.sol';
import './IRefer.sol';
import './Refer.sol';

contract Swap is Ownable, Rank {
    using SafeMath for uint256;

    /////////////////////////////////////////////////////////
    // for testnet
    bool public flagTestNet = true;
    function setTestFlag(bool flag) public returns (bool) {
        flagTestNet = flag;
        return flagTestNet;
    }
    /////////////////////////////////////////////////////////


    struct SystemSetting {
        uint256 round;
        uint256 layers;
        uint256 limitPerLayer;
        uint256 price; // 初始价格，放大100倍
        uint256 curLeftOver;
    }

    address public nullAddress = 0x0000000000000000000000000000000000000001;

    // The MOT token
    address public mot;

    address public usdt;
    // Dev address.
    address public devaddr;

    uint256 public startBlock;

    Refer public refer;
    uint256 public totalReferBonus; // 全网推荐总收益

    mapping(address => uint256) referBonus;

    // 系统参数
    SystemSetting public setting;

    // 不同层的差价
    uint256[] public priceDeltas = [5, 1, 2, 3, 4, 5, 6, 7, 8, 9];

    // 最少需要投入1 MOT
    uint256 public constant MIN_GAMMA_REQUIRE = 1e18;

    // 每层增加10000 MOT额度
    uint256 public constant LAYER_DELTA = 10000e18;
//    uint256 public constant LAYER_DELTA = 1000e18; //测试用，每层增加1000

    // 最大轮数限制
    uint256 public constant TOTAL_ROUND = 10;
    // 最大层数限制
    uint256 public constant TOTAL_LAYERS = 10;
    // 9 人一组开奖
    uint256 public constant GROUP_NUM_LIMIT = 9;
    // 一组开奖3人
    uint256 public constant GROUP_WIN_NUM = 3;

    uint256 public constant USDTAmountLow = 100e18;
    uint256 public constant USDTAmountMedium = 500e18;
    uint256 public constant USDTAmountHigh = 1000e18;

    address[] public winnersLow;
    address[] public winnersMedium;
    address[] public winnersHigh;

    struct winAmount {
        uint256 gammaAmount;
        uint256 usdtAmount;
    }

    // 保存通兑成功获得的MOT数量
    mapping (address => winAmount) public forgeWinAmount;

    // 用于计算链上随机数
    uint256 nonce = 0;

    // 当季新增资金量
    uint256 public increasedTotalAmount = 0;

    // 奖励赛奖金池
    mapping(uint256 => uint256) public racePool;

    // 奖励赛前20名奖励的百分比，放大1000倍
    uint256[] bonusRate = [300, 200, 100, 80, 70, 60, 50, 40, 30, 20, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5];
    uint256 public RANK_TOP_NUM = 20;
    uint256 public RANK_TOP_MAX = 100;

    // constructor
    constructor (
        address _mot,
        address _usdt,
        address _devaddr,
        Refer _refer
    ) public {
        mot = _mot;
        usdt = _usdt;
        devaddr = _devaddr;
        refer = _refer;
    }

    // set init params
    function setParams(uint256 _startBlock) public onlyOwner {
        startBlock = _startBlock;
        // 设置系统参数 (round, layers, limitPerLayer, price, curLeftOver)
        setting = SystemSetting(1, 1, 50000e18, 10, 50000e18);

//        setting = SystemSetting(1, 1, 10000e18, 10, 10000e18);
    }

    // set system setting
    function setSystemSetting(uint256 _round, uint256 _layers, uint256 _limitPerLayer, uint256 _price, uint256 _curLeftOver) public onlyOwner {
        setting = SystemSetting(_round, _layers, _limitPerLayer, _price, _curLeftOver);
    }

    function winnerNumber(uint256 N) internal returns (uint256, uint256, uint256) {
        uint256 base = now;
        uint256 a = base.add(nonce++).mod(N);
        uint256 b = base.add(nonce++).mod(N);
        uint256 c = base.add(nonce++).mod(N);
        return (a, b, c);
    }

    // run at [20:00 - 20:30]
    function requireSystemActive() internal view {
        require(block.number >= startBlock, "next round not yet started");
        if (flagTestNet) {
            return;
        }
        uint256 hour = now % (1 days) / (1 hours);
        uint256 minute = now % (1 hours) / (1 minutes);
        require(hour >= 12 && hour < 13, "system only works in [20:00 - 20:30]!");
        require(minute >= 0 && minute <= 30, "system only works in [20:00 - 20:30]!");
    }

    function enterNextLayer() internal {
        setting.layers = setting.layers.add(1);
        if (setting.layers > TOTAL_LAYERS) {
            // 当前轮已超过10层，进入下一轮，轮数加1
            setting.round = setting.round.add(1);
            setting.layers = 1;
        }

        // 下一层增加1万额度，同时把上一层剩余的累加上去
        setting.limitPerLayer = setting.limitPerLayer.add(LAYER_DELTA).add(setting.curLeftOver);
        setting.curLeftOver = setting.limitPerLayer;
        setting.price = setting.price.add(priceDeltas[setting.round.sub(1)]);
    }

    // 获取通兑成功的MOT数量
    function getForgeWinAmount (address usr) public view returns (uint256 gammaAmount, uint256 usdtAmount) {
        gammaAmount =  forgeWinAmount[usr].gammaAmount;
        usdtAmount = forgeWinAmount[usr].usdtAmount;
    }

    function forgeLow(address referrer) public {
        address sender = msg.sender;
        require(sender != referrer, "can't invite yourself");

        requireSystemActive();
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

        TransferHelper.safeTransferFrom(mot, sender, nullAddress, MIN_GAMMA_REQUIRE);
        TransferHelper.safeTransferFrom(usdt, sender, address(this), usdtAmount);

        // 记录推荐关系
        refer.submitRefer(sender, referrer);

        // 存储并计算通兑成功者
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
                    // 通兑成功
                    // 发送MOT
                    TransferHelper.safeTransfer(mot, win, gammaAmount);
                    forgeWinAmount[win].gammaAmount = forgeWinAmount[win].gammaAmount.add(gammaAmount);
                    forgeWinAmount[win].usdtAmount = forgeWinAmount[win].usdtAmount.add(usdtAmount);

                    // 一级推荐人获得4%
                    address refAddr = getReferrer(win);
                    referBonus[refAddr] = referBonus[refAddr].add(usdtAmount.mul(4).div(100));

                    // 二级推荐人获得1%
                    address refAddr2 = getReferrer(refAddr);
                    referBonus[refAddr2] = referBonus[refAddr2].add(usdtAmount.mul(1).div(100));
                } else {
                    // 通兑失败
                    // 退还110%
                    uint256 amount = usdtAmount.add(usdtAmount.div(10));
                    TransferHelper.safeTransfer(usdt, win, amount);

                    // 一级推荐人获得0.8%
                    address refAddr = getReferrer(win);
                    referBonus[refAddr] = referBonus[refAddr].add(usdtAmount.mul(8).div(1000));

                    // 二级推荐人获得0.2%
                    address refAddr2 = getReferrer(refAddr);
                    referBonus[refAddr2] = referBonus[refAddr2].add(usdtAmount.mul(2).div(1000));
                }
            }

            updateLeftOver(gammaAmount);
            updateTotalReferBonus(usdtAmount);

            uint256 delta = usdtAmount.mul(3).mul(15).div(100);
            updateRacePool(ss.round, delta);

            delete winnersLow;
        }
    }

    // 为TOP K分发奖励
    // only dev
    function distributeBonus() public returns (bool) {
        require(msg.sender == devaddr, "dev: only devaddr");

        uint256 round = setting.round;
        require(round > 3 && round <= 10, "round not good");

        uint256 totalBonus = getRacePoolBonus(round);
        address[] memory topList = getTopRank();
        require(topList.length <= bonusRate.length, "topList above RANK_TOP_NUM");

        for (uint256 i = 0; i < topList.length; i++) {
            uint256 bonus = totalBonus.div(1000).mul(bonusRate[i]);
            TransferHelper.safeTransfer(usdt, topList[i], bonus);
        }
        return true;
    }

    function claimRewards() public returns (uint256) {
        address sender = msg.sender;
        uint256 rewards = referBonus[sender];
        referBonus[sender] = 0;
        TransferHelper.safeTransfer(usdt, sender, rewards);
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

    function updateRacePool(uint256 round, uint256 amount) internal {
        racePool[round] = racePool[round].add(amount);
    }

    function setRacePool(uint256 round, uint256 amount) public onlyOwner {
        racePool[round]  = amount;
    }

    // 查询推荐的总收益
    function getReferBonus(address usr) public view returns (uint256) {
        return referBonus[usr];
    }

    // 查询初级通兑池未成团人数
    function getWinnersLowLength() public view returns (uint256) {
        return winnersLow.length;
    }

    // 查询中级通兑池未成团人数
    function getWinnersMediumLength() public view returns (uint256) {
        return winnersMedium.length;
    }

    // 查询高级通兑池未成团人数
    function getWinnersHighLength() public view returns (uint256) {
        return winnersHigh.length;
    }

    function getBonus() public view returns (uint256) {
        uint256 round3Total = racePool[0].add(racePool[1]).add(racePool[2]);
        return round3Total.div(7).add(racePool[setting.round]);
    }

    // 获取指定轮季度赛的奖励池份额
    function getRacePoolBonus(uint256 round) public view returns (uint256) {
        if (round <= 3 || round > 10) {
            return 0;
        }
        uint256 round3Total = racePool[0].add(racePool[1]).add(racePool[2]);
        return round3Total.div(7).add(racePool[round]);
    }

    // 查询在三个通兑池中成团情况
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
        address [] memory top100;
        top100 = getTop(RANK_TOP_MAX);

        address[] memory topk = new address[](RANK_TOP_NUM);
        uint256 idx = 0;
        for (uint256 i = 0; i < top100.length && idx < RANK_TOP_NUM; i++) {
            address usr = top100[i];
            if (getRankBalance(usr) <= ITRC20(mot).balanceOf(usr)) {
                topk[idx] = usr;
                idx = idx.add(1);
            }
        }
        return topk;
    }

    function getUserRank(address usr) public view returns (uint256) {
        if (getRankBalance(usr) > ITRC20(mot).balanceOf(usr)) {
            return 0;
        }
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
        require(sender != referrer, "can't invite yourself");

        requireSystemActive();
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

        TransferHelper.safeTransferFrom(mot, sender, nullAddress, MIN_GAMMA_REQUIRE);
        TransferHelper.safeTransferFrom(usdt, sender, address(this), usdtAmount);

        // 记录推荐关系
        refer.submitRefer(sender, referrer);

        // 存储并计算通兑成功者
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
                    // 通兑成功
                    // 发送MOT
                    TransferHelper.safeTransfer(mot, win, gammaAmount);
                    forgeWinAmount[win].gammaAmount = forgeWinAmount[win].gammaAmount.add(gammaAmount);
                    forgeWinAmount[win].usdtAmount = forgeWinAmount[win].usdtAmount.add(usdtAmount);

                    // 一级推荐人获得4%
                    address refAddr = getReferrer(win);
                    referBonus[refAddr] = referBonus[refAddr].add(usdtAmount.mul(4).div(100));

                    // 二级推荐人获得1%
                    address refAddr2 = getReferrer(refAddr);
                    referBonus[refAddr2] = referBonus[refAddr2].add(usdtAmount.mul(1).div(100));
                } else {
                    // 通兑失败
                    // 退还110%
                    uint256 amount = usdtAmount.add(usdtAmount.div(10));
                    TransferHelper.safeTransfer(usdt, win, amount);

                    // 一级推荐人获得0.8%
                    address refAddr = getReferrer(win);
                    referBonus[refAddr] = referBonus[refAddr].add(usdtAmount.mul(8).div(1000));

                    // 二级推荐人获得0.2%
                    address refAddr2 = getReferrer(refAddr);
                    referBonus[refAddr2] = referBonus[refAddr2].add(usdtAmount.mul(2).div(1000));
                }
            }

            updateLeftOver(gammaAmount);
            updateTotalReferBonus(usdtAmount);

            uint256 delta = usdtAmount.mul(3).mul(15).div(100);
            updateRacePool(ss.round, delta);

            delete winnersMedium;
        }
    }

    function forgeHigh(address referrer) public {
        address sender = msg.sender;
        require(sender != referrer, "can't invite yourself");

        requireSystemActive();
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

        TransferHelper.safeTransferFrom(mot, sender, nullAddress, MIN_GAMMA_REQUIRE);
        TransferHelper.safeTransferFrom(usdt, sender, address(this), usdtAmount);

        // 记录推荐关系
        refer.submitRefer(sender, referrer);

        // 存储并计算通兑成功者
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
                    // 通兑成功
                    // 发送MOT
                    TransferHelper.safeTransfer(mot, win, gammaAmount);
                    forgeWinAmount[win].gammaAmount = forgeWinAmount[win].gammaAmount.add(gammaAmount);
                    forgeWinAmount[win].usdtAmount = forgeWinAmount[win].usdtAmount.add(usdtAmount);

                    // 一级推荐人获得4%
                    address refAddr = getReferrer(win);
                    referBonus[refAddr] = referBonus[refAddr].add(usdtAmount.mul(4).div(100));

                    // 二级推荐人获得1%
                    address refAddr2 = getReferrer(refAddr);
                    referBonus[refAddr2] = referBonus[refAddr2].add(usdtAmount.mul(1).div(100));
                } else {
                    // 通兑失败
                    // 退还110%
                    uint256 amount = usdtAmount.add(usdtAmount.div(10));
                    TransferHelper.safeTransfer(usdt, win, amount);

                    // 一级推荐人获得0.8%
                    address refAddr = getReferrer(win);
                    referBonus[refAddr] = referBonus[refAddr].add(usdtAmount.mul(8).div(1000));

                    // 二级推荐人获得0.2%
                    address refAddr2 = getReferrer(refAddr);
                    referBonus[refAddr2] = referBonus[refAddr2].add(usdtAmount.mul(2).div(1000));
                }
            }

            updateLeftOver(gammaAmount);
            updateTotalReferBonus(usdtAmount);

            uint256 delta = usdtAmount.mul(3).mul(15).div(100);
            updateRacePool(ss.round, delta);

            delete winnersHigh;
        }
    }

    // 查询推荐人地址
    function getReferrer(address usr) public view returns (address) {
        return refer.getReferrer(usr);
    }

    // 查询推荐的总人数
    function getReferLength(address referrer) public view returns (uint256) {
        return refer.getReferLength(referrer);
    }

    // get invite list
    function getInviteList(address usr) public view returns (address[] memory) {
        uint256 referLen = refer.getReferLength(usr);
        address[] memory addrList = new address[](referLen);
        for(uint256 i = 0; i < referLen; i++) {
            addrList[i] = refer.referList(usr, i);
        }
        return addrList;
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

    function setMOT(address _mot) public onlyOwner {
        mot = _mot;
    }

    function setUSDT(address _usdt) public onlyOwner {
        usdt = _usdt;
    }

    function setRankTopNum(uint256 value) public onlyOwner {
        RANK_TOP_NUM = value;
    }

    function setRankTopMax(uint256 value) public onlyOwner {
        RANK_TOP_MAX = value;
    }

    function withdrawUSDT(uint256 amount) public returns (bool) {
        require(msg.sender == devaddr, "dev: only devaddr");
        TransferHelper.safeTransfer(usdt, devaddr, amount);
        return true;
    }

    function withdrawMOT(uint256 amount) public returns (bool) {
        require(msg.sender == devaddr, "dev: only devaddr");
        TransferHelper.safeTransfer(mot, devaddr, amount);
        return true;
    }
}