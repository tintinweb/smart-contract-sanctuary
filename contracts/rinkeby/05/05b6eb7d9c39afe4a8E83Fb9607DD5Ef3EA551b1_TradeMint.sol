// SPDX-License-Identifier: GPL-2.0-or-later

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
import "../libraries/FixedPoint64.sol";
import "../libraries/FullMath.sol";
import "../interface/ISummaPri.sol";

contract TradeMint is ITradeMint, Context, Owned {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    ITokenIssue public tokenIssue;

    ISummaSwapV3Manager public iSummaSwapV3Manager;

    uint256 public totalIssueRate = 0.1 * 10000;

    uint256 public settlementBlock;

    mapping(address => bool) public isReward;

    uint256 public totalRewardShare;

    address public factory;
    uint256 public tradeShare;

    bytes32 public constant PUBLIC_ROLE = keccak256("PUBLIC_ROLE");

    uint24 public reduceFee;

    uint24 public superFee;

    uint256 public easterEggPoint;

    uint256 public easterEggReward;

    bool public easterEggEnable;

    uint256 public luckNum;

    struct TickInfo {
        uint256 liquidityVolumeGrowthOutside;
        uint256 liquidityIncentiveGrowthOutside;
        uint256 settlementBlock;
    }

    struct PoolInfo {
        uint256 lastSettlementBlock;
        mapping(int24 => TickInfo) ticks;
        uint256 liquidityVolumeGrowth;
        uint256 liquidityIncentiveGrowth;
        uint256 rewardShare;
        int24 currentTick;
        uint256 unSettlementAmount;
        mapping(uint256 => uint256) blockSettlementVolume;
        address poolAddress;
        mapping(uint256 => uint256) tradeSettlementAmountGrowth;
        uint256 easterEgg;
        address[] rewardAddress;
    }

    struct UserInfo {
        uint256 tradeSettlementedAmount;
        uint256 tradeUnSettlementedAmount;
        uint256 lastTradeBlock;
    }

    struct Position {
        uint256 lastRewardGrowthInside;
        uint256 lastRewardVolumeGrowth;
        uint256 lastRewardSettlementedBlock;
        uint256 tokensOwed;
    }

    struct TradeMintCallbackData {
        bytes path;
        address payer;
        address realplay;
    }

    address[] public poolAddress;

    uint256 public pledgeRate;

    uint256 public minPledge;

    address public summaAddress;

    address public priAddress;

    address public router;

    mapping(uint256 => Position) private _positions;

    mapping(address => mapping(address => UserInfo)) public userInfo;

    mapping(address => PoolInfo) public poolInfoByPoolAddress;

    uint256 public lastWithdrawBlock;

    event Cross(
        int24 _tick,
        int24 _nextTick,
        uint256 liquidityVolumeGrowth,
        uint256 liquidityIncentiveGrowth,
        uint256 tickliquidityVolumeGrowth,
        uint256 tickliquidityIncentiveGrowth
    );

    event Snapshot(
        address tradeAddress,
        int24 tick,
        uint256 liquidityVolumeGrowth,
        uint256 tradeVolume
    );

    event SnapshotLiquidity(
        uint256 tokenId,
        address poolAddress,
        int24 _tickLower,
        int24 _tickUpper
    );

    function setTokenIssue(ITokenIssue _tokenIssue) public onlyOwner {
        tokenIssue = _tokenIssue;
    }

    function setISummaSwapV3Manager(ISummaSwapV3Manager _ISummaSwapV3Manager)
        public
        onlyOwner
    {
        iSummaSwapV3Manager = _ISummaSwapV3Manager;
    }

    function setTotalIssueRate(uint256 _totalIssueRate) public onlyOwner {
        totalIssueRate = _totalIssueRate;
    }

    function setSettlementBlock(uint256 _settlementBlock) public onlyOwner {
        settlementBlock = _settlementBlock;
    }

    function setFactory(address _factory) public onlyOwner {
        factory = _factory;
    }

    function setRouterAddress(address _routerAddress) public onlyOwner {
        router = _routerAddress;
    }

    function setTradeShare(uint256 _tradeShare) public onlyOwner {
        tradeShare = _tradeShare;
    }

    function setPledgeRate(uint256 _pledgeRate) public onlyOwner {
        pledgeRate = _pledgeRate;
    }

    function setMinPledge(uint256 _minPledge) public onlyOwner {
        minPledge = _minPledge;
    }

    function setSummaAddress(address _summaAddress) public onlyOwner {
        summaAddress = _summaAddress;
    }

    function setPriAddress(address _priAddress) public onlyOwner {
        priAddress = _priAddress;
    }

    function setReduceFee(uint24 _reduceFee) public onlyOwner {
        reduceFee = _reduceFee;
    }

    function setSuperFee(uint24 _superFee) public onlyOwner {
        superFee = _superFee;
    }

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
            if (!isReward[_poolAddress]) {
                poolAddress.push(_poolAddress);
            }
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
            poolInfo.easterEgg += summaReward.mul(easterEggPoint).div(100);
            settlementTrade(
                poolInfo.poolAddress,
                (summaReward.sub(summaReward.mul(easterEggPoint).div(100))).div(
                    tradeShare
                )
            );
            settlementPoolNewLiquidityIncentiveGrowth(poolInfo.poolAddress);
            withdrawTokenFromPri();
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
            withdrawTokenFromPri();
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
                        FixedPoint64.Q64
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
                        FixedPoint64.Q64,
                        poolInfo.unSettlementAmount
                    );
                    amount += FullMath.mulDiv(
                        quotient,
                        userInfo.tradeUnSettlementedAmount,
                        FixedPoint64.Q64
                    );
                }
                amount += userInfo.tradeSettlementedAmount;
            }
        }
        uint256 balance = iSummaSwapV3Manager.balanceOf(userAddress);
        for (uint256 pid = 0; pid < balance; ++pid) {
            uint256 tokenId = iSummaSwapV3Manager.tokenOfOwnerByIndex(
                userAddress,
                pid
            );
            amount += getPendingSummaByTokenId(tokenId);
        }
        return amount;
    }

    function pendingTradeSumma(address userAddress)
        public
        view
        returns (uint256)
    {
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
                        FixedPoint64.Q64
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
                        FixedPoint64.Q64,
                        poolInfo.unSettlementAmount
                    );
                    amount += FullMath.mulDiv(
                        quotient,
                        userInfo.tradeUnSettlementedAmount,
                        FixedPoint64.Q64
                    );
                }
                amount += userInfo.tradeSettlementedAmount;
            }
        }
        return amount;
    }

    function getPendingSummaByTokenId(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        uint256 amount = 0;
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

        ) = iSummaSwapV3Manager.positions(tokenId);
        address poolAddress = PoolAddress.computeAddress(
            factory,
            token0,
            token1,
            fee
        );
        address userAddress = iSummaSwapV3Manager.ownerOf(tokenId);
        if (isReward[poolAddress]) {
            (
                uint256 liquidityIncentiveGrowthInPosition,
                uint256 blockSettlementVolume
            ) = getLiquidityIncentiveGrowthInPosition(
                    tickLower,
                    tickUpper,
                    tokenId,
                    poolAddress
                );
            Position memory position = _positions[tokenId];
            uint256 userLastReward = position.lastRewardGrowthInside;
            if (position.lastRewardVolumeGrowth > 0) {
                userLastReward += FullMath.mulDiv(
                    position.lastRewardVolumeGrowth,
                    blockSettlementVolume,
                    FixedPoint64.Q64
                );
            }
            uint256 newliquidityIncentiveGrowthInPosition = liquidityIncentiveGrowthInPosition
                    .sub(userLastReward);
            amount += FullMath.mulDiv(
                newliquidityIncentiveGrowthInPosition,
                liquidity,
                FixedPoint64.Q64
            );
            amount += position.tokensOwed;
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
        uint256 tokenId,
        address poolAddress
    )
        public
        view
        returns (uint256 feeGrowthInside, uint256 blockSettlementVolume)
    {
        PoolInfo storage poolInfo = poolInfoByPoolAddress[poolAddress];
        uint256 newLiquidityIncentiveGrowth = poolInfo.liquidityIncentiveGrowth;
        if (
            poolInfo.lastSettlementBlock.add(settlementBlock) <= block.number &&
            poolInfo.unSettlementAmount > 0
        ) {
            (
                uint256 newSettlement,
                uint256 _blockSettlementVolume
            ) = getPoolNewLiquidityIncentiveGrowth(poolAddress);
            newLiquidityIncentiveGrowth += newSettlement;
            blockSettlementVolume = _blockSettlementVolume;
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
                    FixedPoint64.Q64
                );
            } else if (
                tickLower.settlementBlock ==
                poolInfo.lastSettlementBlock.add(settlementBlock)
            ) {
                newLowerLiquidityIncentiveGrowthOutside += FullMath.mulDiv(
                    tickLower.liquidityVolumeGrowthOutside,
                    blockSettlementVolume,
                    FixedPoint64.Q64
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
                    FixedPoint64.Q64
                );
            } else if (
                tickUpper.settlementBlock ==
                poolInfo.lastSettlementBlock.add(settlementBlock)
            ) {
                newUpLiquidityIncentiveGrowthOutside += FullMath.mulDiv(
                    tickUpper.liquidityVolumeGrowthOutside,
                    blockSettlementVolume,
                    FixedPoint64.Q64
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
        feeGrowthInside =
            newLiquidityIncentiveGrowth -
            feeGrowthBelow -
            feeGrowthAbove;
        if (
            poolInfo.blockSettlementVolume[
                _positions[tokenId].lastRewardSettlementedBlock
            ] != 0
        ) {
            blockSettlementVolume = poolInfo.blockSettlementVolume[
                _positions[tokenId].lastRewardSettlementedBlock
            ];
        }
    }

    function settlementVolumeIncentiveGrowthInPosition(
        int24 _tickLower,
        int24 _tickUpper,
        address poolAddress
    ) internal returns (uint256) {
        PoolInfo storage poolInfo = poolInfoByPoolAddress[poolAddress];
        TickInfo storage tickLower = poolInfo.ticks[_tickLower];
        TickInfo storage tickUpper = poolInfo.ticks[_tickUpper];
        // calculate fee growth below
        uint256 feeGrowthBelow;
        if (poolInfo.currentTick >= _tickLower) {
            feeGrowthBelow = tickLower.liquidityVolumeGrowthOutside;
        } else {
            feeGrowthBelow =
                poolInfo.liquidityVolumeGrowth -
                tickLower.liquidityVolumeGrowthOutside;
        }
        uint256 feeGrowthAbove;
        if (poolInfo.currentTick < _tickUpper) {
            feeGrowthAbove = tickUpper.liquidityVolumeGrowthOutside;
        } else {
            feeGrowthAbove =
                poolInfo.liquidityVolumeGrowth -
                tickUpper.liquidityVolumeGrowthOutside;
        }
        uint256 feeGrowthInside = poolInfo.liquidityVolumeGrowth -
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
        uint256 newLiquidityIncentiveGrowth = poolInfo.liquidityIncentiveGrowth;
        if (
            poolInfo.lastSettlementBlock.add(settlementBlock) <= block.number &&
            poolInfo.unSettlementAmount > 0
        ) {
            newLiquidityIncentiveGrowth = settlementPoolNewLiquidityIncentiveGrowth(
                poolAddress
            );
        }
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
                FixedPoint64.Q64
            );
            tickLower.liquidityVolumeGrowthOutside = 0;
        }
        uint256 newLowerLiquidityIncentiveGrowthOutside = tickLower
            .liquidityIncentiveGrowthOutside;
        TickInfo storage tickUpper = poolInfo.ticks[_tickUpper];
        if (
            poolInfo.blockSettlementVolume[tickUpper.settlementBlock] > 0 &&
            tickUpper.liquidityVolumeGrowthOutside > 0
        ) {
            tickUpper.liquidityIncentiveGrowthOutside += FullMath.mulDiv(
                tickUpper.liquidityVolumeGrowthOutside,
                poolInfo.blockSettlementVolume[tickLower.settlementBlock],
                FixedPoint64.Q64
            );
            tickUpper.liquidityVolumeGrowthOutside = 0;
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
        poolInfo.liquidityIncentiveGrowth += reward
            .mul(poolInfo.liquidityVolumeGrowth)
            .div(poolInfo.unSettlementAmount);
        poolInfo.liquidityVolumeGrowth = 0;
        poolInfo.blockSettlementVolume[
            poolInfo.lastSettlementBlock.add(settlementBlock)
        ] = FullMath.mulDiv(
            reward,
            FixedPoint64.Q64,
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
        public
        view
        returns (
            uint256 newLiquidityIncentiveGrowth,
            uint256 blockSettlementVolume
        )
    {
        PoolInfo storage poolInfo = poolInfoByPoolAddress[poolAddress];
        uint256 reward = getPoolReward(poolAddress);
        newLiquidityIncentiveGrowth = reward
            .mul(poolInfo.liquidityVolumeGrowth)
            .div(poolInfo.unSettlementAmount);
        blockSettlementVolume = FullMath.mulDiv(
            reward,
            FixedPoint64.Q64,
            poolInfo.unSettlementAmount
        );
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

    function withdrawTokenFromPri() internal {
        require(lastWithdrawBlock != 0);
        uint256 nowWithdrawBlock = block.number.div(settlementBlock).mul(
            settlementBlock
        );
        if (nowWithdrawBlock > lastWithdrawBlock) {
            uint256 summaReward = getMultiplier(
                lastWithdrawBlock,
                nowWithdrawBlock
            );
            tokenIssue.transByContract(address(this), summaReward);
        }
        lastWithdrawBlock = nowWithdrawBlock;
    }

    function withdraw() public {
        withdrawTokenFromPri();
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
            FixedPoint64.Q64,
            poolInfo.unSettlementAmount
        );
        userInfo.tradeSettlementedAmount += FullMath.mulDiv(
            userInfo.tradeUnSettlementedAmount,
            poolInfo.tradeSettlementAmountGrowth[
                (userInfo.lastTradeBlock.div(settlementBlock).add(1)).mul(
                    settlementBlock
                )
            ],
            FixedPoint64.Q64
        );
        userInfo.tradeUnSettlementedAmount = 0;
    }

    function settlementTrade(address poolAddress, uint256 summaReward)
        internal
    {
        PoolInfo storage poolInfo = poolInfoByPoolAddress[poolAddress];
        poolInfo.tradeSettlementAmountGrowth[
            poolInfo.lastSettlementBlock.add(settlementBlock)
        ] += FullMath.mulDiv(
            summaReward,
            FixedPoint64.Q64,
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
                poolInfo.lastSettlementBlock.add(settlementBlock) <=
                block.number &&
                poolInfo.unSettlementAmount > 0
            ) {
                uint256 form = poolInfo.lastSettlementBlock;
                uint256 to = poolInfo.lastSettlementBlock.add(settlementBlock);
                uint256 summaReward = getMultiplier(form, to)
                    .mul(poolInfo.rewardShare)
                    .div(totalRewardShare);
                poolInfo.easterEgg += summaReward.mul(easterEggPoint).div(100);
                poolInfo.tradeSettlementAmountGrowth[to] += FullMath.mulDiv(
                    (summaReward.sub(summaReward.mul(easterEggPoint).div(100)))
                        .div(tradeShare),
                    FixedPoint64.Q64,
                    poolInfo.unSettlementAmount
                );
                settlementPoolNewLiquidityIncentiveGrowth(poolInfo.poolAddress);
            }
            uint256 tradeSettlementAmount = poolInfo
                .tradeSettlementAmountGrowth[
                    userInfo
                        .lastTradeBlock
                        .div(settlementBlock)
                        .mul(settlementBlock)
                        .add(settlementBlock)
                ];
            if (
                userInfo.tradeUnSettlementedAmount != 0 &&
                tradeSettlementAmount != 0
            ) {
                userInfo.tradeSettlementedAmount += FullMath.mulDiv(
                    userInfo.tradeUnSettlementedAmount,
                    tradeSettlementAmount,
                    FixedPoint64.Q64
                );
                userInfo.tradeUnSettlementedAmount = 0;
            }
            amount += userInfo.tradeSettlementedAmount;
            userInfo.tradeSettlementedAmount = 0;
        }
        uint256 balance = iSummaSwapV3Manager.balanceOf(msg.sender);

        for (uint256 pid = 0; pid < balance; ++pid) {
            uint256 tokenId = iSummaSwapV3Manager.tokenOfOwnerByIndex(
                msg.sender,
                pid
            );
            amount += settlementByTokenId(tokenId);
        }
        return amount;
    }

    function settlementByTokenId(uint256 tokenId) internal returns (uint256) {
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

        ) = iSummaSwapV3Manager.positions(tokenId);
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
            uint256 userLastReward = settlementLastReward(poolAddress, tokenId);
            if (newLiquidityIncentiveGrowthInPosition > userLastReward) {
                uint256 liquidityIncentiveGrowthInPosition = newLiquidityIncentiveGrowthInPosition
                        .sub(userLastReward);
                _positions[tokenId]
                    .lastRewardGrowthInside = newLiquidityIncentiveGrowthInPosition;
                uint256 amount = _positions[tokenId].tokensOwed +
                    FullMath.mulDiv(
                        liquidityIncentiveGrowthInPosition,
                        liquidity,
                        FixedPoint64.Q64
                    );
                _positions[tokenId].tokensOwed = 0;
                return amount;
            }
        }
        return 0;
    }

    function settlementLastReward(address poolAddress, uint256 tokenId)
        internal
        returns (uint256 userLastReward)
    {
        PoolInfo storage poolInfo = poolInfoByPoolAddress[poolAddress];
        userLastReward = _positions[tokenId].lastRewardGrowthInside;
        if (
            _positions[tokenId].lastRewardVolumeGrowth >= 0 &&
            poolInfo.blockSettlementVolume[
                _positions[tokenId].lastRewardSettlementedBlock
            ] !=
            0
        ) {
            userLastReward += (
                FullMath.mulDiv(
                    _positions[tokenId].lastRewardVolumeGrowth,
                    poolInfo.blockSettlementVolume[
                        _positions[tokenId].lastRewardSettlementedBlock
                    ],
                    FixedPoint64.Q64
                )
            );
            _positions[tokenId].lastRewardVolumeGrowth = 0;
        }
    }

    // function getLastReward(address poolAddress, uint256 tokenId)
    //     internal
    //     view
    //     returns (uint256 userLastReward)
    // {
    //     PoolInfo storage poolInfo = poolInfoByPoolAddress[poolAddress];
    //     userLastReward = _positions[tokenId].lastRewardGrowthInside;
    //     if (_positions[tokenId].lastRewardVolumeGrowth >= 0) {
    //         userLastReward += (
    //             FullMath.mulDiv(
    //                 _positions[tokenId].lastRewardVolumeGrowth,
    //                 poolInfo.blockSettlementVolume[
    //                     _positions[tokenId].lastRewardSettlementedBlock
    //                 ],
    //                 FixedPoint64.Q64
    //             )
    //         );
    //     }
    // }

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
            if (
                tick.liquidityVolumeGrowthOutside > 0 &&
                poolInfo.blockSettlementVolume[tick.settlementBlock] > 0
            ) {
                tick.liquidityIncentiveGrowthOutside += FullMath.mulDiv(
                    poolInfo.blockSettlementVolume[tick.settlementBlock],
                    tick.liquidityVolumeGrowthOutside,
                    FixedPoint64.Q64
                );
                tick.liquidityVolumeGrowthOutside = 0;
            }
            tick.liquidityIncentiveGrowthOutside = poolInfo
                .liquidityIncentiveGrowth
                .sub(tick.liquidityIncentiveGrowthOutside);
            tick.liquidityVolumeGrowthOutside = poolInfo
                .liquidityVolumeGrowth
                .sub(tick.liquidityVolumeGrowthOutside);
            tick.settlementBlock = (block.number.div(settlementBlock).add(1))
                .mul(settlementBlock);
            emit Cross(
                _tick,
                _nextTick,
                poolInfo.liquidityVolumeGrowth,
                poolInfo.liquidityIncentiveGrowth,
                tick.liquidityVolumeGrowthOutside,
                tick.liquidityIncentiveGrowthOutside
            );
        }
    }

    function snapshot(
        bytes calldata _data,
        int24 tick,
        uint256 liquidityVolumeGrowth,
        uint256 tradeVolume
    ) external override {
        require(Address.isContract(_msgSender()));
        TradeMintCallbackData memory data = abi.decode(
            _data,
            (TradeMintCallbackData)
        );
        PoolInfo storage poolInfo = poolInfoByPoolAddress[_msgSender()];
        UserInfo storage userInfo = userInfo[data.realplay][_msgSender()];
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
                poolInfo.easterEgg += summaReward.mul(easterEggPoint).div(100);
                settlementTrade(
                    data.realplay,
                    _msgSender(),
                    (summaReward.sub(summaReward.mul(easterEggPoint).div(100)))
                        .div(tradeShare)
                );
                settlementPoolNewLiquidityIncentiveGrowth(_msgSender());
            } else {
                uint256 tradeSettlementAmount = poolInfo
                    .tradeSettlementAmountGrowth[
                        userInfo
                            .lastTradeBlock
                            .div(settlementBlock)
                            .mul(settlementBlock)
                            .add(settlementBlock)
                    ];
                if (
                    userInfo.tradeUnSettlementedAmount != 0 &&
                    tradeSettlementAmount != 0
                ) {
                    userInfo.tradeSettlementedAmount += FullMath.mulDiv(
                        userInfo.tradeUnSettlementedAmount,
                        tradeSettlementAmount,
                        FixedPoint64.Q64
                    );
                    userInfo.tradeUnSettlementedAmount = 0;
                }
            }
            if (easterEggEnable && poolInfo.easterEgg > 0) {
                if (rand(luckNum) == 0) {
                    uint256 eggAmount = poolInfo
                        .easterEgg
                        .mul(easterEggReward)
                        .div(100);
                    poolInfo.rewardAddress.push(data.realplay);
                    withdrawTokenFromPri();
                    IERC20(summaAddress).safeTransfer(data.realplay, eggAmount);
                }
            }

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
                data.realplay,
                tick,
                liquidityVolumeGrowth,
                tradeVolume
            );
        }
    }

    function snapshotLiquidity(
        address poolAddress,
        uint128 liquidity,
        uint256 tokenId,
        int24 _tickLower,
        int24 _tickUpper
    ) external override {
        require(_msgSender() == address(iSummaSwapV3Manager));
        PoolInfo storage poolInfo = poolInfoByPoolAddress[poolAddress];
        if (isReward[poolAddress]) {
            Position storage postion = _positions[tokenId];
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
                poolInfo.easterEgg += summaReward.mul(easterEggPoint).div(100);
                settlementTrade(
                    poolAddress,
                    (summaReward.sub(summaReward.mul(easterEggPoint).div(100)))
                        .div(tradeShare)
                );
            }
            settlementByTokenId(
                tokenId,
                poolAddress,
                liquidity,
                _tickLower,
                _tickUpper
            );
            emit SnapshotLiquidity(
                tokenId,
                poolAddress,
                _tickLower,
                _tickUpper
            );
        }
    }

    function snapshotMintLiquidity(
        address poolAddress,
        uint256 tokenId,
        int24 _tickLower,
        int24 _tickUpper
    ) external override {
        require(_msgSender() == address(iSummaSwapV3Manager));
        PoolInfo storage poolInfo = poolInfoByPoolAddress[poolAddress];
        if (isReward[poolAddress]) {
            Position storage postion = _positions[tokenId];
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
                poolInfo.easterEgg += summaReward.mul(easterEggPoint).div(100);
                settlementTrade(
                    poolAddress,
                    (summaReward.sub(summaReward.mul(easterEggPoint).div(100)))
                        .div(tradeShare)
                );
            }
            settlementByTokenId(
                tokenId,
                poolAddress,
                0,
                _tickLower,
                _tickUpper
            );
            emit SnapshotLiquidity(
                tokenId,
                poolAddress,
                _tickLower,
                _tickUpper
            );
        }
    }

    function settlementByTokenId(
        uint256 tokenId,
        address poolAddress,
        uint128 liquidity,
        int24 _tickLower,
        int24 _tickUpper
    ) internal {
        Position memory position = _positions[tokenId];
        uint256 newLiquidityIncentiveGrowthInPosition = settlementLiquidityIncentiveGrowthInPosition(
                _tickLower,
                _tickUpper,
                poolAddress
            );
        uint256 userLastReward = settlementLastReward(poolAddress, tokenId);
        uint256 liquidityIncentiveGrowthInPosition = newLiquidityIncentiveGrowthInPosition
                .sub(userLastReward);
        position.lastRewardGrowthInside = newLiquidityIncentiveGrowthInPosition;
        if (liquidity != 0) {
            position.tokensOwed += FullMath.mulDiv(
                liquidityIncentiveGrowthInPosition,
                liquidity,
                FixedPoint64.Q64
            );
        }
    }

    function getFee(
        address tradeAddress,
        bytes calldata _data,
        uint24 fee
    ) external view override returns (uint24) {
        uint24 newfee = 0;
        if (Address.isContract(tradeAddress)) {
            TradeMintCallbackData memory data = abi.decode(
                _data,
                (TradeMintCallbackData)
            );
            newfee = fee;
            if (ISummaPri(priAddress).hasRole(PUBLIC_ROLE, data.realplay)) {
                newfee = fee - (fee / reduceFee);
            }
        } else {
            newfee = fee;
            if (ISummaPri(priAddress).hasRole(PUBLIC_ROLE, tradeAddress)) {
                newfee = fee - (fee / reduceFee);
            }
        }

        return newfee;
    }

    function getRelation(address tradeAddress, bytes calldata _data)
        external
        view
        override
        returns (address)
    {
        if (Address.isContract(tradeAddress)) {
            TradeMintCallbackData memory data = abi.decode(
                _data,
                (TradeMintCallbackData)
            );
            return ISummaPri(priAddress).getRelation(data.realplay);
        } else {
            return ISummaPri(priAddress).getRelation(tradeAddress);
        }
    }

    function getPledge(address userAddess) external view returns (uint256) {
        uint256 amount = pendingSumma(userAddess);
        uint256 pledge = amount.mul(pledgeRate).div(100);
        if (pledge < minPledge) {
            pledge = minPledge;
        }
        return pledge;
    }

    function getSuperFee() external view override returns (uint24) {
        return superFee;
    }

     function routerAddress() external view override returns (address) {
        return router;
    }
    function getPoolLength() external view returns (uint256) {
        return poolAddress.length;
    }

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

    function getTradeSettlementAmountGrowth(
        address poolAddress,
        uint256 blockNum
    ) external view returns (uint256 tradeSettlementAmountGrowth) {
        PoolInfo storage poolInfo = poolInfoByPoolAddress[poolAddress];
        tradeSettlementAmountGrowth = poolInfo.tradeSettlementAmountGrowth[
            blockNum
        ];
    }

    function getTickLiquidityIncentiveGrowthOutside(
        address poolAddress,
        int24 _tick
    )
        external
        view
        returns (
            uint256 liquidityIncentiveGrowthOutside,
            uint256 liquidityVolumeGrowthOutside,
            uint256 settlementBlock
        )
    {
        PoolInfo storage poolInfo = poolInfoByPoolAddress[poolAddress];
        TickInfo storage tick = poolInfo.ticks[_tick];
        liquidityIncentiveGrowthOutside = tick.liquidityIncentiveGrowthOutside;
        liquidityVolumeGrowthOutside = tick.liquidityVolumeGrowthOutside;
        settlementBlock = tick.settlementBlock;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

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

// SPDX-License-Identifier: GPL-2.0-or-later

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

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.7.6;
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xa04cf9fa83ab2d3a658defb2430d74f27b5e63d2a173c51710023787603880cd;

   
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

// SPDX-License-Identifier: GPL-2.0-or-later

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

// SPDX-License-Identifier: GPL-2.0-or-later

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

// SPDX-License-Identifier: GPL-2.0-or-later

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

// SPDX-License-Identifier: GPL-2.0-or-later

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
        
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function balanceOf(address owner) external view  returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view   returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.7.6;
interface ITradeMint{
    
    function getFee(address tradeAddress,bytes calldata data,uint24 fee) external view returns (uint24);
    
    function getRelation(address tradeAddress,bytes calldata data) external view returns (address);
    
    function cross(int24 tick,int24 nextTick) external;
    
    function snapshot(bytes calldata data,int24 tick,uint256 liquidityVolumeGrowth,uint256 tradeVolume) external;
    
    function snapshotLiquidity(address poolAddress,uint128 liquidity,uint256 tokenId,int24 _tickLower,int24 _tickUpper) external;

    function snapshotMintLiquidity(address poolAddress,uint256 tokenId,int24 _tickLower,int24 _tickUpper) external;
    
    function getSuperFee() external view returns (uint24);

    function routerAddress() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later

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

// SPDX-License-Identifier: GPL-2.0-or-later

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

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.7.6;
library FixedPoint64 {
    uint256 internal constant Q64 = 0x10000000000000000;
}

// SPDX-License-Identifier: GPL-2.0-or-later

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

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.7.6;
interface ISummaPri{
     function getRelation(address addr) external view returns (address);
     
     
     function hasRole(bytes32 role, address account) external view returns (bool);
     
    
}

