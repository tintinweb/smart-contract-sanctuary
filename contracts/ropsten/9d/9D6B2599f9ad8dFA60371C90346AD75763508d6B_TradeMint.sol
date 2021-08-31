pragma solidity >=0.7.6;
pragma abicoder v2;

import "../libraries/SafeMath.sol";
import "../libraries/Address.sol";
import "../libraries/trademint/PoolAddress.sol";
import "../interface/IERC20.sol";
import "../interface/ITokenIssue.sol";
import "../libraries/SafeERC20.sol";
import "../interface/trademint/ISummaSwapV3Manager.sol";
import "../interface/trademint/ITradeMint.sol";
import "../libraries/Context.sol";
import "../libraries/Owned.sol";
import "../libraries/FixedPoint128.sol";
import "../libraries/FullMath.sol";
import "../interface/ISummaPri.sol";

contract TradeMint is ITradeMint, Context, Owned {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    ITokenIssue public tokenIssue; // 发行合约 。根据发行合约的发行量分奖励，百分80给中心化挖矿，百分20给LP质押。这里从百分20中分

    ISummaSwapV3Manager public iSummaSwapV3Manager; // 管理合约地址。通过管理地址合约拿到用户LP情况

    uint256 public totalIssueRate = 0.1 * 10000; // TradeMint 占发行合约发行量的比例。

    uint256 public settlementBlock; //结算区块。每多少个区块结算一次

    mapping(address => bool) public isReward; //设置资金池是否可以获得奖励

    uint256 public totalRewardShare; // 每一个交易对的累加起来的总份额

    address public factory; //工厂地址合约

    uint256 public tradeShare; //交易占LP挖矿的比例

    bytes32 public constant PUBLIC_ROLE = keccak256("PUBLIC_ROLE"); //查询是否激活的Key

    uint24 public reduceFee; // 激活地址减少的手续费，设置 5 则减少1/5。激活的地址去交易比正常的地址少1/5的手续费

    uint24 private superFee; //激活地址如果存在上级。给上级的手续费。如设置 5.则给上级1/5. 激活的地址比正常的少1/5的手续费。而且剩下的4/5还要分出1/5给上级

    uint256 public easterEggPoint; //每次结算扣出来用作彩蛋资金的百分比

    uint256 public easterEggReward; //结算彩蛋的奖励百分。如果没有设置，默认百分百。如果某一次彩蛋资金过高。可以设置一个百分比。将资金留一部分下一次彩蛋

    bool public easterEggEnable;

    uint256 public luckNum;

    struct TickInfo {
        uint256 liquidityVolumeGrowthOutside; // Tick储存的 单位流动性交易量的增长。
        uint256 liquidityIncentiveGrowthOutside; // Tick储存 单位流动性 资金量的增长
        uint256 settlementBlock; // 该Tick 未结算的单位流动性交易量的增长，应该结算的区块
    }

    struct PoolInfo {
        uint256 lastSettlementBlock; // 上一次结算的区块
        mapping(int24 => TickInfo) ticks; //存储的Tick信息。Tick信息用来计算两个Tick之间组成的区间的奖励
        uint256 liquidityVolumeGrowth; // 全局单位流动性交易量增长
        uint256 liquidityIncentiveGrowth; //全局单位流动性 奖励增长
        uint256 rewardShare; // 资金池占的份额。与总份额对比计算每一个资金池能结算的奖励
        int24 currentTick; //资金池当前的Tick。根据当前Tick判断Tick存在的outside增长属于那一边
        uint256 unSettlementAmount; //资金池未结算的金额
        mapping(uint256 => uint256) blockSettlementVolume; // 结算时每一单位交易量 LP获取的奖励
        address poolAddress; //资金池地址
        mapping(uint256 => uint256) tradeSettlementAmountGrowth; // 结算时每一单位交易量 交易获取获取的奖励
        uint256 easterEgg; // 彩蛋 数值
        address[] rewardAddress; //中奖地址列表
    }

    struct UserInfo {
        uint256 tradeSettlementedAmount; // 用户交易结算的奖励
        uint256 tradeUnSettlementedAmount; // 用户交易未结算的交易量
        uint256 lastTradeBlock; //上一次交易的区块。根据上一次交易的区块计算用户应该结算在哪一个区块  根据用户应该结算的区块。找出已结算在资金池的每一个单位交易量应该获取的奖励。乘以用户的交易量。得到用户的应该分到的奖励
        uint256 lastRewardGrowthInside; // 用上一次提取奖励获取 或者追加流动性 记录当前的增长量。即之前的增长与该用户无关。在用户移除流动性或者追加流动性应提示用户先提取奖励。
    }

    address[] public poolAddress; //可以获取奖励的资金池地址列表

    uint256 public pledgeRate; //质押率

    uint256 public minPledge; //最小质押率

    address public summaAddress; //奖励SUMMMA的地址

    address public priAddress; //绑定关系的Pri合约地址

    mapping(address => mapping(address => UserInfo)) public userInfo; //根据用户地址跟资金池地址记录用户在每一个资金池的奖励信息

    mapping(address => PoolInfo) public poolInfoByPoolAddress; // 根据资金池地址找到资金池奖励信息

    uint256 public lastWithdrawBlock; // 上一次从发行合约提取SUM的区块。 用户提取SUM的时候会把当前区块到上一次提取的区块直接产生的发行量。提取对应的SUM到TradeMint

    event Cross(int24 _tick, int24 _nextTick);

    event Snapshot(
        address tradeAddress,
        int24 tick,
        uint256 liquidityVolumeGrowth,
        uint256 tradeVolume
    );

    event SnapshotLiquidity(
        address tradeAddress,
        address poolAddress,
        int24 _tickLower,
        int24 _tickUpper
    );

    //设置发行合约
    function setTokenIssue(ITokenIssue _tokenIssue) public onlyOwner {
        tokenIssue = _tokenIssue;
    }

    //设置NFT管理合约
    function setISummaSwapV3Manager(ISummaSwapV3Manager _ISummaSwapV3Manager)
        public
        onlyOwner
    {
        iSummaSwapV3Manager = _ISummaSwapV3Manager;
    }

    //设置 TradeMint 应该分到每一段结算区块产生的发行量的百分比。 以10000为单位。2000则表示，百分二十。从发行量中取出百分二十用来奖励交易跟LP挖矿
    function setTotalIssueRate(uint256 _totalIssueRate) public onlyOwner {
        totalIssueRate = _totalIssueRate;
    }

    //设置结算区块
    function setSettlementBlock(uint256 _settlementBlock) public onlyOwner {
        settlementBlock = _settlementBlock;
    }

    //设置工厂地址合约
    function setFactory(address _factory) public onlyOwner {
        factory = _factory;
    }

    //设置交易奖励占比
    function setTradeShare(uint256 _tradeShare) public onlyOwner {
        tradeShare = _tradeShare;
    }

    //设置最小质押率
    function setPledgeRate(uint256 _pledgeRate) public onlyOwner {
        pledgeRate = _pledgeRate;
    }

    // 设置最小质押值
    function setMinPledge(uint256 _minPledge) public onlyOwner {
        minPledge = _minPledge;
    }

    //设置SUMMA 奖励SUMMA的地址
    function setSummaAddress(address _summaAddress) public onlyOwner {
        summaAddress = _summaAddress;
    }

    //设置pri推荐关系绑定合约
    function setPriAddress(address _priAddress) public onlyOwner {
        priAddress = _priAddress;
    }

    //设置上级减少的手续费比例。5表示减少1/5
    function setReduceFee(uint24 _reduceFee) public onlyOwner {
        reduceFee = _reduceFee;
    }

    //设置给上级的手续费比例。5表示给上级1/5
    function setSuperFee(uint24 _superFee) public onlyOwner {
        superFee = _superFee;
    }

    //设置某一个资金池是否可以获取奖励。true 表示该资金池可以获取奖励。如果是true _rewardShare 必须大于0.如果是false。则必须上一次设置了奖励的。因为添加了新的交易对。奖励分配比例发生了变化。所有要把之前的交易对都结算。
    function enableReward(
        address _poolAddress,
        bool _isReward,
        uint256 _rewardShare
    ) public onlyOwner {
        require(settlementBlock > 0, "error settlementBlock");
        massUpdatePools();
        if (_isReward) {
            require(_rewardShare > 0, "error rewardShare");
            PoolInfo storage _poolInfo = poolInfoByPoolAddress[_poolAddress];
            _poolInfo.lastSettlementBlock = block
                .number
                .div(settlementBlock)
                .mul(settlementBlock);
            if (poolAddress.length == 0) {
                lastWithdrawBlock = _poolInfo.lastSettlementBlock;
            }
            _poolInfo.poolAddress = _poolAddress;
            _poolInfo.rewardShare = _rewardShare;
            totalRewardShare += _rewardShare;
            poolAddress.push(_poolAddress);
        } else {
            require(isReward[_poolAddress], "pool is not reward");
            PoolInfo storage _poolInfo = poolInfoByPoolAddress[_poolAddress];
            totalRewardShare -= _poolInfo.rewardShare;
            _poolInfo.rewardShare = 0;
        }
        isReward[_poolAddress] = _isReward;
    }

    function rand(uint256 _length) public view returns (uint256) {
        uint256 random = uint256(
            keccak256(abi.encodePacked(block.difficulty, block.timestamp))
        );
        return random % _length;
    }

    //设置某一个资金池是否可以获取奖励。true 表示该资金池可以获取奖励。如果是true _rewardShare 必须大于0.如果是false。则必须上一次设置了奖励的。因为添加了新的交易对。奖励分配比例发生了变化。所有要把之前的交易对都结算。
    function enableReward(
        address token0,
        address token1,
        uint24 fee,
        bool _isReward,
        uint256 _rewardShare
    ) public onlyOwner {
        require(settlementBlock > 0, "error settlementBlock");
        address _poolAddress = PoolAddress.computeAddress(
            factory,
            token0,
            token1,
            fee
        );
        massUpdatePools();
        if (_isReward) {
            require(_rewardShare > 0, "error rewardShare");
            PoolInfo storage _poolInfo = poolInfoByPoolAddress[_poolAddress];
            _poolInfo.lastSettlementBlock = block
                .number
                .div(settlementBlock)
                .mul(settlementBlock);
            if (poolAddress.length == 0) {
                lastWithdrawBlock = _poolInfo.lastSettlementBlock;
            }
            _poolInfo.poolAddress = _poolAddress;
            _poolInfo.rewardShare = _rewardShare;
            totalRewardShare += _rewardShare;
            poolAddress.push(_poolAddress);
        } else {
            require(isReward[_poolAddress], "pool is not reward");
            PoolInfo storage _poolInfo = poolInfoByPoolAddress[_poolAddress];
            totalRewardShare -= _poolInfo.rewardShare;
            _poolInfo.rewardShare = 0;
        }
        isReward[_poolAddress] = _isReward;
    }

    function setEasterEggPoint(uint256 _easterEggPoint) public onlyOwner {
        easterEggPoint = _easterEggPoint;
    }

    function setEasterEggReward(uint256 _easterEggReward) public onlyOwner {
        easterEggReward = _easterEggReward;
    }

    function setEasterEggEnable(bool _easterEggEnable) public onlyOwner {
        require(luckNum > 0, "please set luckNum");
        easterEggEnable = _easterEggEnable;
    }

    function setLuckNum(uint256 _luckNum) public onlyOwner {
        luckNum = _luckNum;
    }

    function withdrawSumma(uint256 amount) public onlyOwner {
        IERC20(summaAddress).safeTransfer(msg.sender, amount);
    }

    function massUpdatePools() public {
        uint256 length = poolAddress.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function updatePool(uint256 _pid) public {
        address _poolAddress = poolAddress[_pid];
        PoolInfo storage poolInfo = poolInfoByPoolAddress[_poolAddress];
        if (
            poolInfo.lastSettlementBlock.add(settlementBlock) <= block.number &&
            poolInfo.unSettlementAmount > 0
        ) {
            uint256 form = poolInfo.lastSettlementBlock;
            uint256 to = (form.add(settlementBlock));
            uint256 summaReward = getMultiplier(form, to)
                .mul(poolInfo.rewardShare)
                .div(totalRewardShare);
            poolInfo.easterEgg += summaReward.mul(easterEggPoint).div(100); //彩蛋抽成
            settlementTrade(
                poolInfo.poolAddress,
                (summaReward.sub(summaReward.mul(easterEggPoint).div(100))).div(
                    tradeShare
                )
            ); //结算交易
            settlementPoolNewLiquidityIncentiveGrowth(poolInfo.poolAddress);
        }
        if (
            block.number.div(settlementBlock).mul(settlementBlock) >
            poolInfo.lastSettlementBlock
        ) {
            poolInfo.easterEgg += getMultiplier(
                poolInfo.lastSettlementBlock,
                block.number.div(settlementBlock).mul(settlementBlock)
            ).mul(poolInfo.rewardShare).div(totalRewardShare);
            poolInfo.lastSettlementBlock = poolInfo.lastSettlementBlock;
        }
    }

    function pendingSumma(address userAddress) public view returns (uint256) {
        uint256 amount = 0;
        uint256 length = poolAddress.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            address _poolAddress = poolAddress[pid];
            PoolInfo storage poolInfo = poolInfoByPoolAddress[_poolAddress];
            UserInfo storage userInfo = userInfo[userAddress][poolAddress[pid]];
            if (userInfo.lastTradeBlock != 0) {
                if (userInfo.lastTradeBlock < poolInfo.lastSettlementBlock) {
                    amount += FullMath.mulDiv(
                        userInfo.tradeUnSettlementedAmount,
                        poolInfo.tradeSettlementAmountGrowth[
                            (
                                userInfo
                                    .lastTradeBlock
                                    .div(settlementBlock)
                                    .add(1)
                            ).mul(settlementBlock)
                        ],
                        FixedPoint128.Q128
                    );
                } else if (
                    (userInfo.lastTradeBlock.div(settlementBlock).add(1)).mul(
                        settlementBlock
                    ) <=
                    block.number &&
                    poolInfo.unSettlementAmount > 0
                ) {
                    uint256 form = (
                        userInfo.lastTradeBlock.div(settlementBlock)
                    ).mul(settlementBlock);
                    uint256 to = (
                        userInfo.lastTradeBlock.div(settlementBlock).add(1)
                    ).mul(settlementBlock);
                    uint256 summaReward = getMultiplier(form, to)
                        .mul(poolInfo.rewardShare)
                        .div(totalRewardShare);
                    uint256 tradeReward = (
                        summaReward.sub(
                            summaReward.mul(easterEggPoint).div(100)
                        )
                    ).div(tradeShare);
                    uint256 quotient = FullMath.mulDiv(
                        tradeReward,
                        FixedPoint128.Q128,
                        poolInfo.unSettlementAmount
                    );
                    amount += FullMath.mulDiv(
                        quotient,
                        userInfo.tradeUnSettlementedAmount,
                        FixedPoint128.Q128
                    );
                }
                amount += userInfo.tradeSettlementedAmount;
            }
        }
        uint256 balance = iSummaSwapV3Manager.balanceOf(userAddress);
        for (uint256 pid = 0; pid < balance; ++pid) {
            (
                ,
                ,
                address token0,
                address token1,
                uint24 fee,
                int24 tickLower,
                int24 tickUpper,
                uint128 liquidity,
                ,
                ,
                ,

            ) = iSummaSwapV3Manager.positions(
                    iSummaSwapV3Manager.tokenOfOwnerByIndex(userAddress, pid)
                );
            address poolAddress = PoolAddress.computeAddress(
                factory,
                token0,
                token1,
                fee
            );
            if (isReward[poolAddress]) {
                uint256 userLastReward = userInfo[userAddress][poolAddress]
                    .lastRewardGrowthInside;
                uint256 liquidityIncentiveGrowthInPosition = getLiquidityIncentiveGrowthInPosition(
                        tickLower,
                        tickUpper,
                        poolAddress
                    ).sub(userLastReward);
                amount += FullMath.mulDiv(
                    liquidityIncentiveGrowthInPosition,
                    liquidity,
                    FixedPoint128.Q128
                );
            }
        }
        return amount;
    }

    function getEasterEgg(address poolAddress) public view returns (uint256) {
        PoolInfo storage poolInfo = poolInfoByPoolAddress[poolAddress];
        uint256 easterEgg = poolInfo.easterEgg;
        if (
            block.number.div(settlementBlock).mul(settlementBlock) >
            poolInfo.lastSettlementBlock
        ) {
            easterEgg += getMultiplier(
                poolInfo.lastSettlementBlock,
                block.number.div(settlementBlock).mul(settlementBlock)
            ).mul(poolInfo.rewardShare).div(totalRewardShare);
        }
        return easterEgg;
    }

    function getPoolReward(address poolAddress)
        internal
        view
        returns (uint256)
    {
        PoolInfo storage poolInfo = poolInfoByPoolAddress[poolAddress];

        uint256 form = poolInfo.lastSettlementBlock;
        uint256 to = poolInfo.lastSettlementBlock.add(settlementBlock);
        uint256 multiplier = getMultiplier(form, to);
        uint256 reward = multiplier
            .mul(poolInfo.rewardShare)
            .mul(uint256(100).sub(easterEggPoint))
            .div(100)
            .div(totalRewardShare)
            .div(tradeShare)
            .mul(tradeShare.sub(1));
        return reward;
    }

    function getLiquidityIncentiveGrowthInPosition(
        int24 _tickLower,
        int24 _tickUpper,
        address poolAddress
    ) internal view returns (uint256) {
        PoolInfo storage poolInfo = poolInfoByPoolAddress[poolAddress];
        uint256 newLiquidityIncentiveGrowth = poolInfo.liquidityIncentiveGrowth;
        uint256 newSettlement = 0;
        if (
            poolInfo.lastSettlementBlock.add(settlementBlock) <= block.number &&
            poolInfo.unSettlementAmount > 0
        ) {
            newSettlement = getPoolNewLiquidityIncentiveGrowth(poolAddress);
            newLiquidityIncentiveGrowth += newSettlement;
        }
        TickInfo storage tickLower = poolInfo.ticks[_tickLower];
        uint256 newLowerLiquidityIncentiveGrowthOutside = tickLower
            .liquidityIncentiveGrowthOutside;
        if (tickLower.liquidityVolumeGrowthOutside != 0) {
            if (
                poolInfo.blockSettlementVolume[tickLower.settlementBlock] != 0
            ) {
                newLowerLiquidityIncentiveGrowthOutside += FullMath.mulDiv(
                    tickLower.liquidityVolumeGrowthOutside,
                    poolInfo.blockSettlementVolume[tickLower.settlementBlock],
                    FixedPoint128.Q128
                );
            } else {
                newLowerLiquidityIncentiveGrowthOutside += FullMath.mulDiv(
                    tickLower.liquidityVolumeGrowthOutside,
                    newSettlement,
                    FixedPoint128.Q128
                );
            }
        }
        TickInfo storage tickUpper = poolInfo.ticks[_tickUpper];
        uint256 newUpLiquidityIncentiveGrowthOutside = tickUpper
            .liquidityIncentiveGrowthOutside;
        if (tickUpper.liquidityVolumeGrowthOutside != 0) {
            if (
                poolInfo.blockSettlementVolume[tickUpper.settlementBlock] != 0
            ) {
                newUpLiquidityIncentiveGrowthOutside += FullMath.mulDiv(
                    tickUpper.liquidityVolumeGrowthOutside,
                    poolInfo.blockSettlementVolume[tickUpper.settlementBlock],
                    FixedPoint128.Q128
                );
            } else {
                newLowerLiquidityIncentiveGrowthOutside += FullMath.mulDiv(
                    tickLower.liquidityVolumeGrowthOutside,
                    newSettlement,
                    FixedPoint128.Q128
                );
            }
        }
        // calculate fee growth below
        uint256 feeGrowthBelow;
        if (poolInfo.currentTick >= _tickLower) {
            feeGrowthBelow = newLowerLiquidityIncentiveGrowthOutside;
        } else {
            feeGrowthBelow =
                newLiquidityIncentiveGrowth -
                newLowerLiquidityIncentiveGrowthOutside;
        }
        uint256 feeGrowthAbove;
        if (poolInfo.currentTick < _tickUpper) {
            feeGrowthAbove = newUpLiquidityIncentiveGrowthOutside;
        } else {
            feeGrowthAbove =
                newLiquidityIncentiveGrowth -
                newUpLiquidityIncentiveGrowthOutside;
        }
        uint256 feeGrowthInside = newLiquidityIncentiveGrowth -
            feeGrowthBelow -
            feeGrowthAbove;
        return feeGrowthInside;
    }

    function settlementLiquidityIncentiveGrowthInPosition(
        int24 _tickLower,
        int24 _tickUpper,
        address poolAddress
    ) internal returns (uint256) {
        PoolInfo storage poolInfo = poolInfoByPoolAddress[poolAddress];

        if (
            poolInfo.lastSettlementBlock.add(settlementBlock) <= block.number &&
            poolInfo.unSettlementAmount > 0
        ) {
            settlementPoolNewLiquidityIncentiveGrowth(poolAddress);
        }
        uint256 newLiquidityIncentiveGrowth = poolInfo.liquidityIncentiveGrowth;
        if (newLiquidityIncentiveGrowth == 0) {
            return 0;
        }
        TickInfo storage tickLower = poolInfo.ticks[_tickLower];
        if (
            poolInfo.blockSettlementVolume[tickLower.settlementBlock] > 0 &&
            tickLower.liquidityVolumeGrowthOutside > 0
        ) {
            tickLower.liquidityIncentiveGrowthOutside += FullMath.mulDiv(
                tickLower.liquidityVolumeGrowthOutside,
                poolInfo.blockSettlementVolume[tickLower.settlementBlock],
                FixedPoint128.Q128
            );
        }
        uint256 newLowerLiquidityIncentiveGrowthOutside = tickLower
            .liquidityIncentiveGrowthOutside;
        TickInfo storage tickUpper = poolInfo.ticks[_tickUpper];
        if (
            poolInfo.blockSettlementVolume[tickUpper.settlementBlock] > 0 &&
            tickUpper.liquidityVolumeGrowthOutside > 0
        ) {
            tickUpper.liquidityIncentiveGrowthOutside =
                tickUpper.liquidityIncentiveGrowthOutside +
                FullMath.mulDiv(
                    tickUpper.liquidityVolumeGrowthOutside,
                    poolInfo.blockSettlementVolume[tickLower.settlementBlock],
                    FixedPoint128.Q128
                );
        }
        uint256 newUpLiquidityIncentiveGrowthOutside = tickUpper
            .liquidityIncentiveGrowthOutside;
        // calculate fee growth below
        uint256 feeGrowthBelow;
        if (poolInfo.currentTick >= _tickLower) {
            feeGrowthBelow = newLowerLiquidityIncentiveGrowthOutside;
        } else {
            feeGrowthBelow =
                newLiquidityIncentiveGrowth -
                newLowerLiquidityIncentiveGrowthOutside;
        }
        uint256 feeGrowthAbove;
        if (poolInfo.currentTick < _tickUpper) {
            feeGrowthAbove = newUpLiquidityIncentiveGrowthOutside;
        } else {
            feeGrowthAbove =
                newLiquidityIncentiveGrowth -
                newUpLiquidityIncentiveGrowthOutside;
        }
        uint256 feeGrowthInside = newLiquidityIncentiveGrowth -
            feeGrowthBelow -
            feeGrowthAbove;
        return feeGrowthInside;
    }

    function settlementPoolNewLiquidityIncentiveGrowth(address poolAddress)
        internal
        returns (uint256)
    {
        PoolInfo storage poolInfo = poolInfoByPoolAddress[poolAddress];
        uint256 reward = getPoolReward(poolAddress);
        poolInfo.liquidityIncentiveGrowth +=
            poolInfo.liquidityIncentiveGrowth +
            reward.mul(poolInfo.liquidityVolumeGrowth).div(
                poolInfo.unSettlementAmount
            );
        poolInfo.liquidityVolumeGrowth = 0;
        poolInfo.blockSettlementVolume[
            poolInfo.lastSettlementBlock.add(settlementBlock)
        ] = FullMath.mulDiv(
            reward,
            FixedPoint128.Q128,
            poolInfo.unSettlementAmount
        );
        poolInfo.unSettlementAmount = 0;
        poolInfo.lastSettlementBlock = poolInfo.lastSettlementBlock.add(
            settlementBlock
        );
        if (
            block.number.div(settlementBlock).mul(settlementBlock) >
            poolInfo.lastSettlementBlock
        ) {
            poolInfo.easterEgg += getMultiplier(
                poolInfo.lastSettlementBlock,
                block.number.div(settlementBlock).mul(settlementBlock)
            ).mul(poolInfo.rewardShare).div(totalRewardShare);
            poolInfo.lastSettlementBlock = block
                .number
                .div(settlementBlock)
                .mul(settlementBlock);
        }
        return poolInfo.liquidityIncentiveGrowth;
    }

    function getPoolNewLiquidityIncentiveGrowth(address poolAddress)
        internal
        view
        returns (uint256)
    {
        PoolInfo storage poolInfo = poolInfoByPoolAddress[poolAddress];
        uint256 reward = getPoolReward(poolAddress);
        uint256 newLiquidityIncentiveGrowth = reward
            .mul(poolInfo.liquidityVolumeGrowth)
            .div(poolInfo.unSettlementAmount);
        return newLiquidityIncentiveGrowth;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        internal
        view
        returns (uint256)
    {
        uint256 issueTime = tokenIssue.startIssueTime();
        if (_to < issueTime) {
            return 0;
        }
        if (_from < issueTime) {
            return getIssue(issueTime, _to).mul(totalIssueRate).div(10000);
        }
        return
            getIssue(issueTime, _to)
                .sub(getIssue(issueTime, _from))
                .mul(totalIssueRate)
                .div(10000);
    }

    function withdraw() public {
        require(lastWithdrawBlock != 0);
        uint256 summaReward = getMultiplier(lastWithdrawBlock, block.number);
        tokenIssue.transByContract(address(this), summaReward);
        lastWithdrawBlock = block.number;
        uint256 amount = withdrawSettlement();
        uint256 pledge = amount.mul(pledgeRate).div(100);
        if (pledge < minPledge) {
            pledge = minPledge;
        }
        if (pledge != 0) {
            require(
                IERC20(summaAddress).balanceOf(msg.sender) > pledge,
                "Insufficient pledge"
            );
        }
        IERC20(summaAddress).safeTransfer(address(msg.sender), amount);
    }

    function settlementTrade(
        address tradeAddress,
        address poolAddress,
        uint256 summaReward
    ) internal {
        UserInfo storage userInfo = userInfo[tradeAddress][poolAddress];
        PoolInfo storage poolInfo = poolInfoByPoolAddress[poolAddress];
        poolInfo.tradeSettlementAmountGrowth[
            poolInfo.lastSettlementBlock.add(settlementBlock)
        ] += FullMath.mulDiv(
            summaReward,
            FixedPoint128.Q128,
            poolInfo.unSettlementAmount
        );
        userInfo.tradeSettlementedAmount += FullMath.mulDiv(
            userInfo.tradeUnSettlementedAmount,
            poolInfo.tradeSettlementAmountGrowth[
                (userInfo.lastTradeBlock.div(settlementBlock).add(1)).mul(
                    settlementBlock
                )
            ],
            FixedPoint128.Q128
        );
        userInfo.tradeUnSettlementedAmount = 0;
    }

    //结算资金池的奖励
    function settlementTrade(address poolAddress, uint256 summaReward)
        internal
    {
        PoolInfo storage poolInfo = poolInfoByPoolAddress[poolAddress];
        poolInfo.tradeSettlementAmountGrowth[
            poolInfo.lastSettlementBlock.add(settlementBlock)
        ] += FullMath.mulDiv(
            summaReward,
            FixedPoint128.Q128,
            poolInfo.unSettlementAmount
        );
    }

    function withdrawSettlement() internal returns (uint256) {
        uint256 amount = 0;
        uint256 length = poolAddress.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            address _poolAddress = poolAddress[pid];
            PoolInfo storage poolInfo = poolInfoByPoolAddress[_poolAddress];
            UserInfo storage userInfo = userInfo[msg.sender][poolAddress[pid]];
            if (
                poolInfo.lastSettlementBlock.add(settlementBlock) < block.number
            ) {
                uint256 form = (userInfo.lastTradeBlock.div(settlementBlock))
                    .mul(settlementBlock);
                uint256 to = (form.add(settlementBlock));
                uint256 summaReward = getMultiplier(form, to)
                    .mul(poolInfo.rewardShare)
                    .div(totalRewardShare);
                poolInfo.easterEgg += summaReward.mul(easterEggPoint).div(100); //彩蛋抽成
                poolInfo.tradeSettlementAmountGrowth[to] += FullMath.mulDiv(
                    (summaReward.sub(summaReward.mul(easterEggPoint).div(100)))
                        .div(tradeShare),
                    FixedPoint128.Q128,
                    poolInfo.unSettlementAmount
                );
                if (userInfo.tradeUnSettlementedAmount != 0) {
                userInfo.tradeSettlementedAmount += FullMath.mulDiv(
                    userInfo.tradeUnSettlementedAmount,
                    poolInfo.tradeSettlementAmountGrowth[
                        userInfo
                            .lastTradeBlock
                            .div(settlementBlock)
                            .mul(settlementBlock)
                            .add(settlementBlock)
                    ],
                    FixedPoint128.Q128
                );
                userInfo.tradeUnSettlementedAmount = 0;
            }
            }
            amount += userInfo.tradeSettlementedAmount;
            userInfo.tradeSettlementedAmount = 0;
        }
        uint256 balance = iSummaSwapV3Manager.balanceOf(msg.sender);
        for (uint256 pid = 0; pid < balance; ++pid) {
            (
                ,
                ,
                address token0,
                address token1,
                uint24 fee,
                int24 tickLower,
                int24 tickUpper,
                uint128 liquidity,
                ,
                ,
                ,

            ) = iSummaSwapV3Manager.positions(
                    iSummaSwapV3Manager.tokenOfOwnerByIndex(msg.sender, pid)
                );
            address poolAddress = PoolAddress.computeAddress(
                factory,
                token0,
                token1,
                fee
            );
            if (isReward[poolAddress]) {
                uint256 newLiquidityIncentiveGrowthInPosition = settlementLiquidityIncentiveGrowthInPosition(
                        tickLower,
                        tickUpper,
                        poolAddress
                    );
                uint256 liquidityIncentiveGrowthInPosition = newLiquidityIncentiveGrowthInPosition
                        .sub(
                            userInfo[msg.sender][poolAddress]
                                .lastRewardGrowthInside
                        );
                userInfo[msg.sender][poolAddress]
                    .lastRewardGrowthInside = newLiquidityIncentiveGrowthInPosition;
                amount += FullMath.mulDiv(
                    liquidityIncentiveGrowthInPosition,
                    liquidity,
                    FixedPoint128.Q128
                );
            }
        }
        return amount;
    }

    function getIssue(uint256 _from, uint256 _to)
        private
        view
        returns (uint256)
    {
        if (_to <= _from || _from <= 0) {
            return 0;
        }
        uint256 timeInterval = _to - _from;
        uint256 monthIndex = timeInterval.div(tokenIssue.MONTH_SECONDS());
        if (monthIndex < 1) {
            return
                timeInterval.mul(
                    tokenIssue.issueInfo(monthIndex).div(
                        tokenIssue.MONTH_SECONDS()
                    )
                );
        } else if (monthIndex < tokenIssue.issueInfoLength()) {
            uint256 tempTotal = 0;
            for (uint256 j = 0; j < monthIndex; j++) {
                tempTotal = tempTotal.add(tokenIssue.issueInfo(j));
            }
            uint256 calcAmount = timeInterval
                .sub(monthIndex.mul(tokenIssue.MONTH_SECONDS()))
                .mul(
                    tokenIssue.issueInfo(monthIndex).div(
                        tokenIssue.MONTH_SECONDS()
                    )
                )
                .add(tempTotal);
            if (
                calcAmount >
                tokenIssue.TOTAL_AMOUNT().sub(tokenIssue.INIT_MINE_SUPPLY())
            ) {
                return
                    tokenIssue.TOTAL_AMOUNT().sub(
                        tokenIssue.INIT_MINE_SUPPLY()
                    );
            }
            return calcAmount;
        } else {
            return 0;
        }
    }

    function cross(int24 _tick, int24 _nextTick) external override {
        require(Address.isContract(_msgSender()));
        PoolInfo storage poolInfo = poolInfoByPoolAddress[_msgSender()];
        if (isReward[_msgSender()]) {
            poolInfo.currentTick = _nextTick;
            TickInfo storage tick = poolInfo.ticks[_tick];
            if (tick.liquidityVolumeGrowthOutside > 0) {
                tick.liquidityIncentiveGrowthOutside =
                    tick.liquidityIncentiveGrowthOutside +
                    FullMath.mulDiv(
                        poolInfo.blockSettlementVolume[tick.settlementBlock],
                        tick.liquidityVolumeGrowthOutside,
                        FixedPoint128.Q128
                    );
            }
            tick.liquidityIncentiveGrowthOutside =
                poolInfo.liquidityIncentiveGrowth -
                tick.liquidityIncentiveGrowthOutside;
            tick.liquidityVolumeGrowthOutside =
                poolInfo.liquidityVolumeGrowth -
                tick.liquidityVolumeGrowthOutside;
            tick.settlementBlock = (block.number.div(settlementBlock).add(1))
                .mul(settlementBlock);
            emit Cross(_tick, _nextTick);
        }
    }

    function snapshot(
        address tradeAddress,
        int24 tick,
        uint256 liquidityVolumeGrowth,
        uint256 tradeVolume
    ) external override {
        require(Address.isContract(_msgSender()));
        PoolInfo storage poolInfo = poolInfoByPoolAddress[_msgSender()];
        if (isReward[_msgSender()]) {
            if (
                poolInfo.lastSettlementBlock.add(settlementBlock) <=
                block.number &&
                poolInfo.unSettlementAmount > 0
            ) {
                uint256 form = poolInfo.lastSettlementBlock;
                uint256 to = (form.add(settlementBlock));
                uint256 summaReward = getMultiplier(form, to)
                    .mul(poolInfo.rewardShare)
                    .div(totalRewardShare);
                poolInfo.easterEgg += summaReward.mul(easterEggPoint).div(100); //彩蛋抽成
                settlementTrade(
                    tradeAddress,
                    _msgSender(),
                    (summaReward.sub(summaReward.mul(easterEggPoint).div(100)))
                        .div(tradeShare)
                );
                settlementPoolNewLiquidityIncentiveGrowth(_msgSender());
                if (easterEggEnable && poolInfo.easterEgg > 0) {
                    if (rand(luckNum) == 0) {
                        uint256 eggAmount = poolInfo
                            .easterEgg
                            .mul(easterEggReward)
                            .div(100);
                        poolInfo.rewardAddress.push(tradeAddress);
                        IERC20(summaAddress).safeTransfer(
                            tradeAddress,
                            eggAmount
                        );
                    }
                }
            }
            UserInfo storage userInfo = userInfo[tradeAddress][_msgSender()];
            userInfo.tradeUnSettlementedAmount += tradeVolume;
            userInfo.lastTradeBlock = block.number;
            poolInfo.currentTick = tick;
            poolInfo.liquidityVolumeGrowth += liquidityVolumeGrowth;
            poolInfo.unSettlementAmount += tradeVolume;
            poolInfo.lastSettlementBlock = block
                .number
                .div(settlementBlock)
                .mul(settlementBlock);
            emit Snapshot(
                tradeAddress,
                tick,
                liquidityVolumeGrowth,
                tradeVolume
            );
        }
    }

    function snapshotLiquidity(
        address tradeAddress,
        int24 _tickLower,
        int24 _tickUpper
    ) external override {
        require(Address.isContract(_msgSender()));
        PoolInfo storage poolInfo = poolInfoByPoolAddress[_msgSender()];
        if (isReward[_msgSender()]) {
            UserInfo storage userInfo = userInfo[tradeAddress][_msgSender()];
            if (
                poolInfo.lastSettlementBlock.add(settlementBlock) <=
                block.number &&
                poolInfo.unSettlementAmount > 0
            ) {
                uint256 form = poolInfo.lastSettlementBlock;
                uint256 to = (form.add(settlementBlock));
                uint256 summaReward = getMultiplier(form, to)
                    .mul(poolInfo.rewardShare)
                    .div(totalRewardShare);
                poolInfo.easterEgg += summaReward.mul(easterEggPoint).div(100); //彩蛋抽成
                settlementTrade(
                    tradeAddress,
                    _msgSender(),
                    (summaReward.sub(summaReward.mul(easterEggPoint).div(100)))
                        .div(tradeShare)
                );
            }
            userInfo
                .lastRewardGrowthInside = settlementLiquidityIncentiveGrowthInPosition(
                _tickLower,
                _tickUpper,
                _msgSender()
            );
            emit SnapshotLiquidity(
                tradeAddress,
                _msgSender(),
                _tickLower,
                _tickUpper
            );
        }
    }

    function getFee(address current, uint24 fee)
        external
        view
        override
        returns (uint24)
    {
        uint24 newfee = fee;
        if (ISummaPri(priAddress).hasRole(PUBLIC_ROLE, current)) {
            newfee = fee - (fee / reduceFee);
        }
        return newfee;
    }

    function getRelation(address current)
        external
        view
        override
        returns (address)
    {
        return ISummaPri(priAddress).getRelation(current);
    }

    function getSuperFee() external view override returns (uint24) {
        return superFee;
    }

    function getPoolLength() external view returns (uint256) {
        return poolAddress.length;
    }

    // 测试用方法

    function getPoolReward(address poolAddress, uint256 blockNum)
        external
        view
        returns (uint256 lpReward, uint256 tradeReward)
    {
        PoolInfo storage poolInfo = poolInfoByPoolAddress[poolAddress];
        uint256 form = blockNum.sub(settlementBlock);
        uint256 to = blockNum;
        uint256 summaReward = getMultiplier(form, to)
            .mul(poolInfo.rewardShare)
            .div(totalRewardShare);
        tradeReward = (
            summaReward.sub(summaReward.mul(easterEggPoint).div(100))
        ).div(tradeShare);
        lpReward = summaReward.sub(tradeReward);
    }
}

pragma solidity =0.7.6;

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

pragma solidity =0.7.6;
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

pragma solidity =0.7.6;
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe61a34668db5979dd57d3c1587816c5ddedd55f27559757941bc4a7fb04a681e;

   
    function computeAddress(address factory, address token0,address token1,uint24 fee) internal pure returns (address pool) {
        require(token0 < token1);
        pool = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        factory,
                        keccak256(abi.encode(token0, token1, fee)),
                        POOL_INIT_CODE_HASH
                    )
                )
            )
        );
    }
}

pragma solidity >=0.7.6;
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

pragma solidity >=0.7.6;
interface ITokenIssue {
    function transByContract(address to, uint256 amount) external;

    function issueInfo(uint256 monthIndex) external view returns (uint256);

    function startIssueTime() external view returns (uint256);

    function issueInfoLength() external view returns (uint256);

    function TOTAL_AMOUNT() external view returns (uint256);

    function DAY_SECONDS() external view returns (uint256);

    function MONTH_SECONDS() external view returns (uint256);

    function INIT_MINE_SUPPLY() external view returns (uint256);
}

pragma solidity =0.7.6;

import './SafeMath.sol';
import './Address.sol';
import '../interface/IERC20.sol';

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity >=0.7.6;
interface ISummaSwapV3Manager{
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );
        
    function balanceOf(address owner) external view  returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view   returns (uint256);
}

pragma solidity >=0.7.6;
interface ITradeMint{
    function getFee(address current,uint24 fee) external view returns (uint24);
    
    function getRelation(address current) external view returns (address);
    
    function cross(int24 tick,int24 nextTick) external;
    
    function snapshot(address tradeAddress,int24 tick,uint256 liquidityVolumeGrowth,uint256 tradeVolume) external;
    
    function snapshotLiquidity(address tradeAddress,int24 _tickLower,int24 _tickUpper) external;
    
    function getSuperFee() external view returns (uint24);
}

pragma solidity =0.7.6;
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity >=0.6.12;

/**
 * @title Owned
 * @notice Basic contract to define an owner.
 * @author Julien Niset - <[email protected]>
 */
contract Owned {

    // The owner
    address public owner;

    event OwnerChanged(address indexed _newOwner);

    /**
     * @notice Throws if the sender is not the owner.
     */
    modifier onlyOwner {
        require(msg.sender == owner, "Must be owner");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    /**
     * @notice Lets the owner transfer ownership of the contract to a new owner.
     * @param _newOwner The new owner.
     */
    function changeOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Address must not be null");
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }
}

pragma solidity >=0.7.6;
library FixedPoint128 {
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;
}

pragma solidity >=0.7.6;

library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = -denominator & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

pragma solidity >=0.7.6;
interface ISummaPri{
     function getRelation(address addr) external view returns (address);
     
     
     function hasRole(bytes32 role, address account) external view returns (bool);
     
    
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}