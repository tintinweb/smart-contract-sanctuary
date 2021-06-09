// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;
pragma abicoder v2;

import '../interfaces/IAccounting.sol';
import '../utils/Governed.sol';
import '../utils/Math.sol';
import '../utils/SafeMath.sol';
import '../utils/TCPSafeMath.sol';
import '../utils/TCPSafeCast.sol';

import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';

import '@uniswap/v3-core/contracts/libraries/TickMath.sol';


contract Accounting is IAccounting, Governed, IERC721Receiver {
    using Math for uint;
    using SafeMath for uint128;
    using SafeMath for uint256;
    using TCPSafeMath for uint128;
    using TCPSafeMath for uint256;
    using TCPSafeCast for uint64;
    using TCPSafeCast for uint256;
    using TCPSafeCast for int256;

    int24 public constant TICK_SPACING = 200; 
    uint internal constant Q96 = 0x1000000000000000000000000; 

    INonfungiblePositionManager internal immutable nftPositionManager;

    constructor(INonfungiblePositionManager _nftPositionManager) {
        nftPositionManager = _nftPositionManager;
    }

    function _initHook() internal override {
        
        sdi.debtExchangeRate = TCPSafeMath.ONE.toUint128();

        _setNFTApproval(address(governor.rewards()));

        validUpdate[this.stopIndexingDebtPositions.selector] = true;
        validUpdate[this.stopIndexingPoolPositions.selector] = true;
    }

    function onRewardsUpgrade(address newRewards) external override onlyGovernor {
        _setNFTApproval(newRewards);
    }

    
    
    function _setNFTApproval(address approvee) internal {
        
        nftPositionManager.setApprovalForAll(approvee, true);
    }

    
    receive() external payable {
        assert(msg.sender == address(governor.market()));
    }

    
    
    mapping(uint64 => DebtPositionStorage) internal position;

    
    
    
    
    bool public debtPositionIndexingEnabled = true;
    
    
    
    
    
    bool public poolPositionIndexingEnabled = true;
    
    mapping(int24 => uint64[]) internal tickPositions;

    
    
    mapping(address => bool) internal participatedInMarketGenesis;

    
    function getBasicPositionInfo(
        uint64 positionID
    ) external view override returns(uint debtCount, uint collateralCount) {
        debtCount = position[positionID].debt;
        collateralCount = position[positionID].collateral;

        uint positionExchangeRate = position[positionID].startDebtExchangeRate;
        uint systemExchangeRate = sdi.debtExchangeRate;
        if (positionExchangeRate != systemExchangeRate) {
            debtCount = debtCount.mulDiv(systemExchangeRate, positionExchangeRate);
        }
    }

    
    function getParticipatedInMarketGenesis(address account) external view override returns (bool participated) {
        return participatedInMarketGenesis[account];
    }

    
    function setParticipatedInMarketGenesis(address account, bool participated) external override lockContract {
        _requireAuthorized(msg.sender == address(governor.market()));

        participatedInMarketGenesis[account] = participated;
    }

    
    function getPosition(uint64 positionID) external view override returns (DebtPosition memory) {
        return dpStorageToMemory(positionID);
    }

    
    function setPosition(uint64 positionID, DebtPosition memory dp) external override lockContract {
        governor.requirePositionWriteAccess(msg.sender);

        if (debtPositionIndexingEnabled && positionID != 0) dp = _indexPosition(positionID, dp);

        
        if (dp.collateral == 0 && dp.debt == 0) delete position[positionID];
        else dpMemoryToStorage(positionID, dp);
    }

    
    function sendCollateral(address payable dest, uint count) external override lockContract {
        governor.requireStoredCollateralAccess(msg.sender);

        dest.transfer(count);
    }

    
    
    function sendOneToOneBackedTokens(IERC20 token, address dest, uint count) external override lockContract {
        _requireAuthorized(msg.sender == address(governor.lend()));

        TransferHelper.safeTransfer(address(token), dest, count);
    }


    
    uint public override lentZhu;

    
    function increaseLentZhu(uint count) external override lockContract {
        governor.requireLentZhuCountAccess(msg.sender);

        lentZhu = lentZhu.add(count);
    }

    
    function sendLentZhu(address dest, uint count) external override lockContract {
        _requireAuthorized(msg.sender == address(governor.lend()));
        lentZhu = lentZhu.sub(count);

        TransferHelper.safeTransfer(address(zhu), dest, count);
    }

    
    function sweepZhu() external lockContract {
        TransferHelper.safeTransfer(address(zhu), address(zhu), zhu.balanceOf(address(this)).sub(lentZhu));
    }

    
    
    function positionsForTick(int24 tick) external view returns (uint64[] memory) {
        return tickPositions[snapRawTickToSpacing(tick, TICK_SPACING)];
    }

    
    function getTick(uint collateralCount, uint debtCount) public pure returns (int24) {
        if (collateralCount == 0 || debtCount == 0) return type(int24).max;

        
        
        
        
        
        
        
        uint sqrtPriceE18 = Math.sqrt(collateralCount.mul(TCPSafeMath.ONE)._div(debtCount));

        
        
        return snapRawTickToSpacing(
            TickMath.getTickAtSqrtRatio(sqrtPriceE18._mul(Q96).toUint160()),
            TICK_SPACING);
    }

    
    
    function snapRawTickToSpacing(int24 rawTick, int24 tickSpacing) public pure returns (int24) {
        int intRawTick = int(rawTick);
        int remainder = intRawTick % tickSpacing;
        if (remainder == 0) return rawTick;

        int tick = intRawTick > 0
            ? intRawTick - remainder
            : (intRawTick - remainder) - tickSpacing;

        return tick.toInt24();
    }

    
    function positionsCollateralization(
        uint64[] memory positionIDs
    ) external view returns (uint[] memory collateralizations) {
        collateralizations = new uint[](positionIDs.length);
        DebtPositionStorage storage acct;

        uint currentDebtExchangeRate = sdi.debtExchangeRate;
        for (uint i = 0; i < positionIDs.length; i++) {
            acct = position[positionIDs[i]];
            collateralizations[i] =
                acct.collateral._div(
                    acct.debt.mulDiv(
                        currentDebtExchangeRate,
                        acct.startDebtExchangeRate
                    )
                );
        }
    }

    
    
    SystemDebtInfoStorage internal sdi;

    
    function debt() external view override returns (uint) {
        return sdi.debt;
    }

    
    function getSystemDebtInfo() external view override returns (SystemDebtInfo memory) {
        return sdiStorageToMemory();
    }

    
    function setSystemDebtInfo(SystemDebtInfo memory _sdi) external override lockContract {
        _requireAuthorized(msg.sender == address(governor.market()));

        sdiMemoryToStorage(_sdi);
    }

    
    function increaseDebt(uint count) external override lockContract {
        _requireAuthorized(msg.sender == address(governor.market()));

        sdi.debt = sdi.debt.add(count).toUint128();
    }

    
    function decreaseDebt(uint count) external override lockContract {
        governor.requireDecreaseDebtAccess(msg.sender);

        sdi.debt = sdi.debt.sub(count).toUint128();
    }

    
    
    mapping(uint16 => RewardStatus) internal rewardStatus;
    
    mapping(uint => PoolPositionStorage) public poolPosition;
    
    mapping(address => uint) internal participatedInLiquidityGenesis;
    
    mapping(IUniswapV3Pool => uint) public override poolLiquidity;

    
    function increasePoolLiquidity(IUniswapV3Pool pool, uint liquidity) external override lockContract {
        _requireAuthorized(msg.sender == address(governor.rewards()));

        poolLiquidity[pool] = poolLiquidity[pool].add(liquidity);
    }

    
    function decreasePoolLiquidity(IUniswapV3Pool pool, uint liquidity) external override lockContract {
        _requireAuthorized(msg.sender == address(governor.rewards()));

        poolLiquidity[pool] = poolLiquidity[pool].sub(liquidity);
    }

    
    function getRewardStatus(uint16 poolID) external view override returns (RewardStatus memory) {
        return rewardStatus[poolID];
    }

    
    function setRewardStatus(uint16 poolID, RewardStatus memory rs) external override lockContract {
        _requireAuthorized(msg.sender == address(governor.rewards()));

        rewardStatus[poolID] = rs;
    }

    
    function getParticipatedInLiquidityGenesis(address owner, uint16 poolID) external view override returns (bool) {
        require(poolID < 255);
        return _getParticipatedInLiquidityGenesis(owner, poolID);
    }

    
    function _getParticipatedInLiquidityGenesis(address owner, uint16 poolID) internal view returns (bool) {
        return (participatedInLiquidityGenesis[owner] & (1 << poolID)) > 0;
    }

    
    function setParticipatedInLiquidityGenesis(address owner, uint16 poolID, bool participated) external override lockContract {
        _requireAuthorized(msg.sender == address(governor.rewards()));
        require(poolID < 255);

        _setParticipatedInLiquidityGenesis(owner, poolID, participated);
    }

    
    function _setParticipatedInLiquidityGenesis(address owner, uint16 poolID, bool participated) internal {
        participatedInLiquidityGenesis[owner] = participated
            ? participatedInLiquidityGenesis[owner] | (1 << poolID)
            : participatedInLiquidityGenesis[owner] & ~(1 << poolID);
    }

    
    function getPoolPosition(
        uint nftID
    ) external view override returns (PoolPosition memory pp) {
        pp = ppStorageToMemory(nftID);
        require(pp.poolID > 0, 'Position DNE');

        (,,,,, pp.tickLower, pp.tickUpper, pp.liquidity,,,, ) = nftPositionManager.positions(nftID);
    }

    
    function setPoolPosition(
        uint nftID,
        PoolPosition memory pp
    ) external override lockContract {
        _requireAuthorized(msg.sender == address(governor.rewards()));

        ppMemoryToStorage(nftID, pp);
    }

    
    function isPositionOwner(uint nftID, address addressToCheck) external view override returns (bool) {
        return poolPosition[nftID].owner == addressToCheck;
    }

    
    function deletePoolPosition(uint nftID) external override lockContract {
        _requireAuthorized(msg.sender == address(governor.rewards()));

        delete poolPosition[nftID];
    }

    
    function onERC721Received(address, address, uint256, bytes calldata) external view override returns (bytes4) {
        require(msg.sender == address(nftPositionManager), 'Unknown NFT');
        return this.onERC721Received.selector;
    }

    
    
    function _requireAuthorized(bool authorized) internal pure {
        require(authorized, 'Not Authorized');
    }

    
    function _indexPosition(uint64 positionID, DebtPosition memory dp) internal returns (DebtPosition memory) {

        
        
        bool previousTickSet = position[positionID].tickSet;
        
        int24 prevTick = previousTickSet ? position[positionID].tick : type(int24).max;
        
        
        uint64 prevTickIndex = position[positionID].tickIndex;

        
        
        int24 newTick = getTick(dp.collateral, dp.debt);

        
        if (prevTick != newTick) {
            
            dp.tick = newTick;
            
            uint64[] storage positionsIndex;

            
            
            if (prevTick < type(int24).max) {
                

                
                positionsIndex = tickPositions[prevTick];
                
                uint64 lastIndex = (positionsIndex.length - 1).toUint64();
                
                
                
                if (prevTickIndex != lastIndex) {
                    uint64 movedPositionID = positionsIndex[lastIndex];
                    positionsIndex[prevTickIndex] = movedPositionID;
                    position[movedPositionID].tickIndex = prevTickIndex;
                }
                positionsIndex.pop();
            }

            
            if (newTick < type(int24).max) {
                
                positionsIndex = tickPositions[newTick];
                dp.tickIndex = positionsIndex.length.toUint64();
                dp.tickSet = true;
                positionsIndex.push(positionID);
            }
        }

        return dp;
    }

    
    

    
    
    
    
    
    mapping(address => uint64[]) internal poolPositionsByOwner;

    
    function getPoolPositionNftIdsByOwner(address owner) external view returns (uint128[] memory) {
        uint64[] memory localIDs = poolPositionsByOwner[owner];
        uint128[] memory allNftIDs = new uint128[](localIDs.length);

        uint i;
        uint j;
        uint128 nftID;
        for(i = 0; i < allNftIDs.length; i++) {
            nftID = localNftID[localIDs[i]];
            if (owner == poolPosition[nftID].owner) allNftIDs[j++] = nftID;
        }

        uint128[] memory nftIDs = new uint128[](j);
        for(i = 0; i < j; i++) nftIDs[i] = allNftIDs[i];

        return nftIDs;
    }

    
    mapping(uint16 => mapping(int24 => uint64[])) public positionsByTickLower;
    
    mapping(uint16 => mapping(int24 => uint64[])) public positionsByTickUpper;
    
    
    uint128[] public localNftID;


    
    function addPositionToIndex(
        uint nftID,
        uint16 poolID,
        int24 tickLower,
        int24 tickUpper,
        address owner
    ) external override {
        _addPositionToIndexImpl(nftID, poolID, tickLower, tickUpper, owner);
    }

    
    function _addPositionToIndexImpl(
        uint nftID,
        uint16 poolID,
        int24 tickLower,
        int24 tickUpper,
        address owner
    ) internal {
        if (!poolPositionIndexingEnabled) return;

        _requireAuthorized(msg.sender == address(governor.rewards()));

        require(localNftID.length < type(uint64).max);
        uint64 nftLocalID64 = uint64(localNftID.length);

        localNftID.push(nftID.toUint128());
        
        poolPositionsByOwner[owner].push(nftLocalID64);
        
        
        positionsByTickLower[poolID][tickLower].push(nftLocalID64);
        positionsByTickUpper[poolID][tickUpper].push(nftLocalID64);
    }

    
    
    
    function indexPoolPositionsByTickLower(
        uint16 poolID,
        int24 tick,
        uint start,
        uint end
    ) external view returns (uint64[] memory subArray) {
        return _getUint64SubArray(positionsByTickLower[poolID][tick], start, end);
    }

    function indexPoolPositionsByTickUpper(
        uint16 poolID,
        int24 tick,
        uint start,
        uint end
    ) external view returns (uint64[] memory subArray) {
        return _getUint64SubArray(positionsByTickUpper[poolID][tick], start, end);
    }

    function indexPoolPositionsByOwner(
        address owner,
        uint start,
        uint end
    ) external view returns (uint64[] memory subArray) {
        return _getUint64SubArray(poolPositionsByOwner[owner], start, end);
    }

    function indexLocalNftID(
        uint start,
        uint end
    ) external view returns (uint128[] memory subArray) {
        return _getUint128SubArray(localNftID, start, end);
    }

    function _getUint64SubArray(
        uint64[] storage array,
        uint start,
        uint end
    ) internal view returns (uint64[] memory subArray) {
        uint arrayLength = array.length;
        if (arrayLength == 0) return subArray;
        require(start < arrayLength, 'SAL');
        require(start < end, 'SE');

        end = _min(end, arrayLength);
        subArray = new uint64[](end - start);

        uint subArrayIndex;
        while(start < end) subArray[subArrayIndex++] = array[start++];

        return subArray;
    }

    function _getUint128SubArray(
        uint128[] storage array,
        uint start,
        uint end
    ) internal view returns (uint128[] memory subArray) {
        uint arrayLength = array.length;
        if (arrayLength == 0) return subArray;
        require(start < arrayLength, 'SAL');
        require(start < end, 'SE');

        end = _min(end, arrayLength);
        subArray = new uint128[](end - start);

        uint subArrayIndex;
        while(start < end) subArray[subArrayIndex++] = array[start++];

        return subArray;
    }

    
    function _min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }

    
    
    function stopIndexingDebtPositions() external onlyGovernor {
        debtPositionIndexingEnabled = false;
        emit DebtPositionIndexingDisabled();
    }

    
    function stopIndexingPoolPositions() external onlyGovernor {
        poolPositionIndexingEnabled = false;
        emit PoolPositionIndexingDisabled();
    }

    
    
    function dpStorageToMemory(uint64 positionID) internal view returns (DebtPosition memory) {
        DebtPositionStorage memory dpStorage = position[positionID];
        return DebtPosition({
            startCumulativeDebt: dpStorage.startCumulativeDebt,
            collateral: dpStorage.collateral,
            debt: dpStorage.debt,
            startDebtExchangeRate: dpStorage.startDebtExchangeRate,
            startTCPRewards: dpStorage.startTCPRewards,
            lastTimeUpdated: dpStorage.lastTimeUpdated,
            lastBorrowTime: dpStorage.lastBorrowTime,
            tick: dpStorage.tick,
            tickSet: dpStorage.tickSet,
            tickIndex: dpStorage.tickIndex
        });
    }

    function dpMemoryToStorage(uint64 positionID, DebtPosition memory dp) internal {
        position[positionID] = DebtPositionStorage({
            startCumulativeDebt: dp.startCumulativeDebt,
            collateral: dp.collateral.toUint128(),
            debt: dp.debt.toUint128(),
            startDebtExchangeRate: dp.startDebtExchangeRate.toUint128(),
            startTCPRewards: dp.startTCPRewards.toUint128(),
            lastTimeUpdated: dp.lastTimeUpdated,
            lastBorrowTime: dp.lastBorrowTime,
            tick: dp.tick,
            tickSet: dp.tickSet,
            tickIndex: dp.tickIndex
        });
    }

    function sdiStorageToMemory() internal view returns (SystemDebtInfo memory) {
        SystemDebtInfoStorage memory sdiStorage = sdi;
        return SystemDebtInfo({
            debt: sdiStorage.debt,
            debtExchangeRate: sdiStorage.debtExchangeRate,
            totalTCPRewards: sdiStorage.totalTCPRewards,
            cumulativeDebt: sdiStorage.cumulativeDebt
        });
    }

    function sdiMemoryToStorage(SystemDebtInfo memory _sdi) internal  {
        sdi = SystemDebtInfoStorage({
            debt: _sdi.debt.toUint128(),
            debtExchangeRate: _sdi.debtExchangeRate.toUint128(),
            totalTCPRewards: _sdi.totalTCPRewards.toUint128(),
            cumulativeDebt: _sdi.cumulativeDebt
        });
    }

      function ppStorageToMemory(
        uint nftID
    ) internal view returns (PoolPosition memory) {
        PoolPositionStorage memory ppStorage = poolPosition[nftID];
        return PoolPosition({
            owner: ppStorage.owner,
            poolID: ppStorage.poolID,
            tickLower: 0,
            tickUpper: 0,
            liquidity: 0,
            cumulativeLiquidity: ppStorage.cumulativeLiquidity,
            totalRewards: ppStorage.totalRewards,
            lastTimeRewarded: ppStorage.lastTimeRewarded,
            lastBlockPositionIncreased: ppStorage.lastBlockPositionIncreased
        });
    }

    function ppMemoryToStorage(
        uint nftID,
        PoolPosition memory pp
    ) internal {
        poolPosition[nftID] = PoolPositionStorage({
            owner: pp.owner,
            poolID: pp.poolID,
            cumulativeLiquidity: pp.cumulativeLiquidity,
            totalRewards: pp.totalRewards.toUint176(),
            lastTimeRewarded: pp.lastTimeRewarded.toUint40(),
            lastBlockPositionIncreased: pp.lastBlockPositionIncreased.toUint40()
        });
    }
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;
pragma abicoder v2;

import './IGovernor.sol';
import './IRewards.sol';

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';


interface IAccounting {
    
    function getBasicPositionInfo(uint64 positionID) external view returns (uint debtCount, uint collateralCount);
    function getPosition(uint64 positionID) external view returns (DebtPosition memory acct);
    function setPosition(uint64 positionID, DebtPosition memory dp) external;
    function sendCollateral(address payable account, uint count) external;
    function getParticipatedInMarketGenesis(address account) external view returns (bool participated);
    function setParticipatedInMarketGenesis(address account, bool participated) external;

    
    function lentZhu() external view returns (uint);
    function increaseLentZhu(uint count) external;
    function sendLentZhu(address dest, uint count) external;

    
    function sendOneToOneBackedTokens(IERC20 token, address dest, uint count) external;

    
    function debt() external view returns (uint);
    function getSystemDebtInfo() external view returns (SystemDebtInfo memory);
    function setSystemDebtInfo(SystemDebtInfo memory _systemDebtInfo) external;
    function increaseDebt(uint count) external;
    function decreaseDebt(uint count) external;

    
    function getPoolPosition(uint nftID) external view returns (PoolPosition memory pt);
    function setPoolPosition(uint nftID, PoolPosition memory pt) external;
    function isPositionOwner(uint nftID, address addressToCheck) external view returns (bool);
    function deletePoolPosition(uint nftID) external;

    function setRewardStatus(uint16 poolID, RewardStatus memory rs) external;
    function getRewardStatus(uint16 poolID) external view returns (RewardStatus memory rs);

    function getParticipatedInLiquidityGenesis(address owner, uint16 poolID) external view returns (bool);
    function setParticipatedInLiquidityGenesis(address owner, uint16 poolID, bool participated) external;

    function poolLiquidity(IUniswapV3Pool pool) external view returns (uint liquidity);
    function increasePoolLiquidity(IUniswapV3Pool pool, uint liquidity) external;
    function decreasePoolLiquidity(IUniswapV3Pool pool, uint liquidity) external;

    
    function addPositionToIndex(uint nftID, uint16 poolID, int24 tickLower, int24 tickUpper, address owner) external;

    
    function onRewardsUpgrade(address newRewards) external;


    

    
    struct SystemDebtInfo {
        uint debt;
        uint totalTCPRewards;
        uint cumulativeDebt;
        uint debtExchangeRate;
    }

    struct SystemDebtInfoStorage {
        uint cumulativeDebt;
        uint128 debt;
        uint128 debtExchangeRate;
        uint128 totalTCPRewards;
    }

    
    struct DebtPosition { 
        uint startCumulativeDebt;
        uint collateral;
        uint debt;
        uint startDebtExchangeRate;
        uint startTCPRewards;
        uint64 lastTimeUpdated;
        uint64 lastBorrowTime;
        int24 tick;
        bool tickSet;
        uint64 tickIndex;
    }

    struct DebtPositionStorage {
        uint startCumulativeDebt; 
        uint128 collateral; 
        uint128 debt; 
        uint128 startDebtExchangeRate; 
        uint128 startTCPRewards; 
        uint64 lastTimeUpdated; 
        uint64 lastBorrowTime; 
        int24 tick;
        bool tickSet;
        uint64 tickIndex; 
    }

    
    struct RewardStatus {
        uint totalRewards;
        uint cumulativeLiquidity;
    }

    struct PoolPosition {
        address owner;
        uint16 poolID;
        uint cumulativeLiquidity;
        uint totalRewards;
        uint64 lastTimeRewarded;
        uint lastBlockPositionIncreased;
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
    }

    struct PoolPositionStorage {
        address owner;
        uint16 poolID;
        uint cumulativeLiquidity;
        uint176 totalRewards;
        uint40 lastTimeRewarded;
        uint40 lastBlockPositionIncreased;
    }

    
    event PoolPositionIndexingDisabled();
    event DebtPositionIndexingDisabled();
}

// Copyright (c) 2020. All Rights Reserved
// adapted from OpenZeppelin v3.1.0 Ownable.sol


pragma solidity =0.7.6;
pragma abicoder v2;

import '../interfaces/IGovernor.sol';



abstract contract Governed {

    
    
    IGovernor public governor;
    
    bool public stopped;
    
    address public deployer;

    
    IAccounting internal accounting;
    
    IZhu internal zhu;
    
    IProtocolLock internal protocolLock;

    event Initialized(address indexed governor);
    event Stopped();

    constructor () {
        deployer = msg.sender;
    }

    
    function init(IGovernor _governor) external {
        require(msg.sender == deployer);
        delete deployer;

        governor = _governor;

        accounting = governor.accounting();
        zhu = governor.zhu();
        protocolLock = governor.protocolLock();

        _initHook();

        emit Initialized(address(_governor));
    }

    
    function _initHook() internal virtual { }

    
    function _stopImpl() internal {
        stopped = true;
        emit Stopped();
    }

    
    
    mapping(bytes4 => bool) public validUpdate;

    
    
    modifier onlyGovernor() {
        _onlyGovernor();
        _;
    }

    function _onlyGovernor() internal view {
        require(msg.sender == address(governor), 'Not Authorized');
    }


    
    modifier runnable() {
        _runnable();
        _;
    }

    function _runnable() internal view {
        _notStopped();
        require(!governor.isShutdown(), 'Protocol shutdown');
    }

    modifier beforePhase(uint8 phase) {
        require(governor.currentPhase() < phase, 'Action window passed');
        _;
    }

    modifier atLeastPhase(uint8 phase) {
        require(phase <= governor.currentPhase(), 'Action available soon');
        _;
    }

    modifier notStopped() {
        _notStopped();
        _;
    }

    function _notStopped() internal view {
        require(!stopped, 'Contract is stopped');
    }

    uint private constant _NOT_ENTERED = 1;
    uint private constant _ENTERED = 2;
    uint private _status = _NOT_ENTERED;

    
    modifier lockContract() {
        _lockContract();
        _;
        _unlockContract();
    }

    function _lockContract() internal {
        require(_status != _ENTERED, 'LC Reentrancy');
        _status = _ENTERED;
    }

    function _unlockContract() internal {
        _status = _NOT_ENTERED;
    }

    
    
    modifier lockProtocol() {
        _lockProtocol();
        _;
        _unlockProtocol();
    }

    function _lockProtocol() internal {
        protocolLock.enter();

        require(_status != _ENTERED, 'LP Reentrancy');
        _status = _ENTERED;
    }

    function _unlockProtocol() internal {
        _status = _NOT_ENTERED;

        protocolLock.exit();
    }
}

// SPDX-License-Identifier: GPL-3.0-only
// copied from uniswap v2 core 

pragma solidity =0.7.6;


library Math {
    
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;



library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'mul-overflow');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;



library TCPSafeMath {
    
    
    
    
    
    
    
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        
        
        
        
        
        uint256 prod0; 
        uint256 prod1; 
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        
        
        require(denominator > prod1);

        
        
        

        
        
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        
        
        
        uint256 twos = -denominator & denominator;
        
        assembly {
            denominator := div(denominator, twos)
        }

        
        assembly {
            prod0 := div(prod0, twos)
        }
        
        
        
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        
        
        
        
        
        uint256 inv = (3 * denominator) ^ 2;
        
        
        
        inv *= 2 - denominator * inv; 
        inv *= 2 - denominator * inv; 
        inv *= 2 - denominator * inv; 
        inv *= 2 - denominator * inv; 
        inv *= 2 - denominator * inv; 
        inv *= 2 - denominator * inv; 

        
        
        
        
        
        
        result = prod0 * inv;
        return result;
    }


    
    
    uint256 public constant ONE = 1e18;

    
    function _div(uint256 a, uint256 b) internal pure returns (uint256 r) {
        r = mulDiv(a, ONE, b);
    }

    
    function _mul(uint256 a, uint256 b) internal pure returns (uint256 r) {
        r = mulDiv(a, b, ONE);
    }
}

// SPDX-License-Identifier: MIT
// NOTE: modified compiler version to 0.7.4 and added toUint192, toUint160, and toUint96

pragma solidity =0.7.6;



library TCPSafeCast {
    
    
    

    
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value < 2**192, "more than 192 bits");
        return uint192(value);
    }

    
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value < 2**184, "more than 184 bits");
        return uint184(value);
    }

    
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value < 2**176, "more than 176 bits");
        return uint176(value);
    }

    
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value < 2**160, "more than 160 bits");
        return uint160(value);
    }

    
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "more than 128 bits");
        return uint128(value);
    }

    
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value < 2**96, "more than 96 bits");
        return uint96(value);
    }

    
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "more than 64 bits");
        return uint64(value);
    }

    
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value < 2**48, "more than 48 bits");
        return uint48(value);
    }

    
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value < 2**40, "more than 40 bits");
        return uint40(value);
    }

    
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "more than 32 bits");
        return uint32(value);
    }

    
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "more than 16 bits");
        return uint16(value);
    }

    
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "more than 8 bits");
        return uint8(value);
    }

    
    
    
    
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "more than 128 bits");
        return int128(value);
    }

    
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "more than 64 bits");
        return int64(value);
    }

    
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "more than 32 bits");
        return int32(value);
    }

    
    function toInt24(int256 value) internal pure returns (int24) {
        require(value >= -2**23 && value < 2**23, "more than 24 bits");
        return int24(value);
    }

    
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "more than 16 bits");
        return int16(value);
    }

    
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "more than 8 bits");
        return int8(value);
    }

    
    
    
    
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "value not positive");
        return uint256(value);
    }


    
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "too big for int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol';

import './IPoolInitializer.sol';
import './IERC721Permit.sol';
import './IPeripheryPayments.sol';
import './IPeripheryImmutableState.sol';
import '../libraries/PoolAddress.sol';

/// @title Non-fungible token for positions
/// @notice Wraps Uniswap V3 positions in a non-fungible token interface which allows for them to be transferred
/// and authorized.
interface INonfungiblePositionManager is
    IPoolInitializer,
    IPeripheryPayments,
    IPeripheryImmutableState,
    IERC721Metadata,
    IERC721Enumerable,
    IERC721Permit
{
    /// @notice Emitted when liquidity is increased for a position NFT
    /// @dev Also emitted when a token is minted
    /// @param tokenId The ID of the token for which liquidity was increased
    /// @param liquidity The amount by which liquidity for the NFT position was increased
    /// @param amount0 The amount of token0 that was paid for the increase in liquidity
    /// @param amount1 The amount of token1 that was paid for the increase in liquidity
    event IncreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when liquidity is decreased for a position NFT
    /// @param tokenId The ID of the token for which liquidity was decreased
    /// @param liquidity The amount by which liquidity for the NFT position was decreased
    /// @param amount0 The amount of token0 that was accounted for the decrease in liquidity
    /// @param amount1 The amount of token1 that was accounted for the decrease in liquidity
    event DecreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when tokens are collected for a position NFT
    /// @dev The amounts reported may not be exactly equivalent to the amounts transferred, due to rounding behavior
    /// @param tokenId The ID of the token for which underlying tokens were collected
    /// @param recipient The address of the account that received the collected tokens
    /// @param amount0 The amount of token0 owed to the position that was collected
    /// @param amount1 The amount of token1 owed to the position that was collected
    event Collect(uint256 indexed tokenId, address recipient, uint256 amount0, uint256 amount1);

    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
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

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(MAX_TICK), 'T');

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, 'R');
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
    }
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;
pragma abicoder v2;


import './IAccounting.sol';
import './IAuctions.sol';
import './ITCP.sol';
import './IZhu.sol';
import './IPositionNFT.sol';
import './IEnforcedDecentralization.sol';
import './ILend.sol';
import './ILendZhu.sol';
import './ILiquidations.sol';
import './IMarket.sol';
import './IPrices.sol';
import './IProtocolLock.sol';
import './IRates.sol';
import './IRewards.sol';
import './ISettlement.sol';

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';


interface IGovernor {
    
    function isShutdown() external view returns (bool);
    function shutdownTime() external view returns (uint64);
    function currentDailyRewardCount() external view returns (uint count);
    function distributedTCP() external view returns (uint circulating);
    function protocolDeployer() external view returns (address);
    function currentPhase() external view returns (uint8);
    function requireValidAction(address target, string calldata signature) external view;
    function GENESIS_PERIODS() external view returns (uint64 periods);

    
    function protocolPool() external view returns(IUniswapV3Pool);
    function collateralPool() external view returns(IUniswapV3Pool);
    function getReferencePools() external view returns(IUniswapV3Pool[] memory);

    
    function accounting() external view returns (IAccounting);
    function auctions() external view returns (IAuctions);
    function tcp() external view returns (ITCP);
    function zhu() external view returns (IZhu);
    function zhuPositionNFT() external view returns (IPositionNFT);
    function enforcedDecentralization() external view returns (IEnforcedDecentralization);
    function lend() external view returns (ILend);
    function lendZhu() external view returns (ILendZhu);
    function liquidations() external view returns (ILiquidations);
    function market() external view returns (IMarket);
    function prices() external view returns (IPrices);
    function protocolLock() external view returns (IProtocolLock);
    function rates() external view returns (IRates);
    function rewards() external view returns (IRewards);
    function settlement() external view returns (ISettlement);
    function timelock() external view returns (address);

    
    function requireDecreaseDebtAccess(address caller) external view;
    function requireLentZhuCountAccess(address caller) external view;
    function requirePositionWriteAccess(address caller) external view;
    function requireZhuMintingAccess(address caller) external view;
    function requireZhuReservesBurnAccess(address caller) external view;
    function requireStoredCollateralAccess(address caller) external view;
    function requireUpdatePositionAccess(address caller) external view;

    function getIsGenesisPhaseAndRequireAuthIfSo(address caller, GenesisAuth calldata ga) external view returns (bool isGenesis);

    
    struct GenesisAuth { uint8 v; bytes32 r; bytes32 s; }

    
    function execute(
        address target,
        string memory signature,
        bytes memory data
    ) external returns (bool success, bytes memory returnData);
    function executeShutdown() external;
    function upgradeProtocol(address newGovernor) external;

    function addReferencePoolToProtocol(IUniswapV3Pool pool) external;
    function removeReferencePoolFromProtocol(IUniswapV3Pool pool) external;

    
    function mintTCP(address to, uint count) external;
    function distributeLiquidityRewards(address to, uint count) external;
    function increaseLiquidationAccountRewards(uint count) external;
    function poolRemovalTime(IUniswapV3Pool pool) external returns (uint64);

    
    function upgradeAuctions(IAuctions _auctions) external;
    function upgradeLend(ILend _lend) external;
    function upgradeLiquidations(ILiquidations _liquidations) external;
    function upgradeMarket(IMarket _market) external;
    function upgradePrices(IPrices _prices) external;
    function upgradeRates(IRates _rates) external;
    function upgradeRewards(IRewards _rewards) external;
    function upgradeSettlement(ISettlement _settlement) external;

    
    
    event AdminUpdated(address indexed from, address indexed to);
    
    event ContractUpgraded(string indexed contractName, address indexed contractAddress);
    event ShutdownTokensLocked(address indexed locker, uint count);
    event ShutdownTokensUnlocked(address indexed locker, uint count);
    event EmergencyShutdownExecuted(uint64 shutdownTime);
    event ShutdownExecuted();
    event ProtocolUpgraded(address indexed newGovernor);
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;


import './IGovernor.sol';

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';

interface IRewards {
    
    function borrowRewardsPortion() external view returns (uint);

    
    function accrueRewards() external;

    
    function addReferencePool(IUniswapV3Pool pool) external;
    function removeReferencePool(IUniswapV3Pool pool) external;
    function completeSetup() external;
    function stop() external;

    
    struct UpdateStatus {
        bool isGenesis;
        bool isShutdown;
        bool isTickSet;
        int24 tick;
    }

    
    
    event LiquidityPositionCreated(address indexed owner, uint16 indexed poolID, uint indexed nftID, int24 tickLower, int24 tickUpper, uint128 liquidity);
    event LiquidityPositionIncreased(uint indexed nftID, uint128 liquidity);
    event LiquidityPositionDecreased(uint indexed nftID, uint amount0, uint amount1);
    event LiquidityPositionRemoved(uint indexed nftID, uint amount0, uint amount1);
    event LiquidityPositionLiquidated(uint indexed nftID, uint amount0, uint amount1);

    
    event ClaimedInflationRewards(address indexed owner, uint indexed nftTokenID);
    event CollectedFees(address indexed owner, uint indexed nftTokenID, uint amount0, uint amount1);

    
    event RewardsAccrued(uint count, uint64 periods);
    event RewardsDistributed(address indexed account, uint64 indexed period, uint tcpRewards);

    
    event ParameterUpdatedAddress(string indexed paramName, address value);
    event ParameterUpdated(string indexed paramName, uint value);
    event ParameterUpdated128(string indexed paramName, uint value);
    event ParameterUpdated64(string indexed paramName, uint value);
    event ParameterUpdated32(string indexed paramName, uint value);

    event RewardsPortionsUpdated(uint protocolPortion, uint collateralPortion, uint referencePortion);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;


interface IAuctions {
    
    function latestAuctionCompletionTime() external view returns (uint64);

    
    struct Auction {
        uint128 count;
        uint128 bid;
        address bidder;
        uint48 endTime;
        uint48 maxEndTime;
    }

    
    function completeSetup() external;
    function stop() external;

    
    event SurplusAuctionStarted(uint64 indexed auctionID, uint indexed count, uint64 maxEndTime);
    event DeficitAuctionStarted(uint64 indexed auctionID, uint indexed count, uint64 maxEndTime);
    event SurplusAuctionBid(uint64 indexed auctionID, address indexed bidder, uint bid);
    event DeficitAuctionBid(uint64 indexed auctionID, address indexed bidder, uint bid);
    event SurplusAuctionSettled(uint64 indexed auctionID, address indexed winner);
    event DeficitAuctionSettled(uint64 indexed auctionID, address indexed winner);
    event ParameterUpdated(string indexed paramName, uint value);
    event ParameterUpdated64(string indexed paramName, uint64 value);
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';


interface ITCP is IERC20 {
    
    function mintTo(address to, uint count) external;
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function addGovernor(address newGovernor) external;
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';


interface IZhu is IERC20 {
    
    function reserves() external view returns (uint);

    
    function distributeReserves(address dest, uint count) external;
    function burnReserves(uint count) external;
    function mintTo(address account, uint countTokensToMint) external;
    function burnFrom(address account, uint256 amount) external;

    
    event ParameterUpdated(string indexed paramName, uint value);
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol';



interface IPositionNFT is IERC721, IERC721Metadata {
    
    function mintTo(address to) external returns (uint64 id);
    function burn(uint64 tokenID) external;

    
    function isApprovedOrOwner(address account, uint tokenId) external view returns (bool r);
    function positionIDs(address account) external view returns (uint64[] memory IDs);
    function nextPositionID() external view returns (uint64 ID);
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;


interface IEnforcedDecentralization {
    function requireValidAction(address target, string memory signature) external view;
    function transferEmergencyShutdownTokens(address dest, uint count) external;
    function currentPhase() external view returns (uint8);

    
    function setPhaseOneStartTime(uint64 phaseOneStartTime) external;

    
    event PhaseOneStartTimeSet(uint64 startTime);
    event PhaseStartDelayed(uint8 indexed phase, uint64 startTime, uint8 delaysRemaining);
    event UpdateLockDelayed(uint64 locktime, uint8 delaysRemaining);
    event ActionBlacklisted(string indexed signature);
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';


interface ILend {
    
    function addReferencePool(IUniswapV3Pool pool) external;
    function removeReferencePool(IUniswapV3Pool pool) external;
    function completeSetup() external;
    function stop() external;

    
    event Lend(address indexed account, uint zhuCount, uint lendTokenCount);
    event Unlend(address indexed account, uint zhuCount, uint lendTokenCount);
    event MintZhu(address indexed user, address indexed token, uint count);
    event ReturnZhu(address indexed user, address indexed token, uint count);

    
    event ParameterUpdated(string indexed paramName, uint value);
    event ParameterUpdatedAddress(string indexed paramName, address indexed value);
    event OneToOneMintingDisabled();

}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';


interface ILendZhu is IERC20 {
    
    function mintTo(address account, uint countTokensToMint) external;
    function burnFrom(address account, uint256 amount) external;
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;


import './IAccounting.sol';
import './IGovernor.sol';
import './IMarket.sol';

interface ILiquidations {
    
    function completeSetup() external;
    function stop() external;

    
    struct LqInfo {
        uint discoverReward;
        uint liquidateReward;
        uint price;
        address discoverer;
        address priceInitializer;
        address account;
        uint8 collateral;
    }

    
    struct DiscoverLiquidationInfo {
        IAccounting.DebtPosition lqAcct;
        uint discoverReward;
        uint rewardsRemaining;
        uint collateralizationRequirement;
        IMarket market;
    }

    
    event UndercollatPositionDiscovered(
        uint64 indexed positionID,
        uint debtCount,
        uint collateralCount,
        uint price);
    event Liquidated(uint baseTokensToRepay, uint collateralToReceive);
    event CoveredUnbackedDebt(uint price, uint amountCovered);
    
    event ParameterUpdated(string indexed paramName, uint value);
    event ParameterUpdated32(string indexed paramName, uint32 value);
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;
pragma abicoder v2;

import './IGovernor.sol';
import './IAccounting.sol';

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';


interface IMarket {
    
    function collateralizationRequirement() external view returns (uint ratio);
    function lastPeriodGlobalInterestAccrued() external view returns (uint64 period);

    
    function accrueInterest() external;

    
    function systemGetUpdatedPosition(uint64 positionID) external returns (IAccounting.DebtPosition memory position);

    
    function completeSetup() external;
    function stop() external;

    
    struct CalculatedInterestInfo {
        uint newDebt;
        uint newExchangeRate;
        uint additionalReserves;
        uint additionalLends;
        uint reducedReserves;
    }

    
    
    event NewPositionCreated(address indexed creator, uint64 indexed positionID);
    event PositionAdjusted(uint64 indexed positionID, int debtChange, int collateralChange);

    
    event InterestAccrued(uint64 indexed period, uint64 periods, uint newDebt, uint rewardCount, uint cumulativeDebt, uint debtExchangeRate);
    event PositionUpdated(uint indexed positionID, uint64 indexed period, uint debtAfter, uint tcpRewards);

    
    event ParameterUpdated(string indexed paramName, uint value);
    event ParameterUpdated64(string indexed paramName, uint64 value);
    event ParameterUpdatedAddress(string indexed paramName, address value);
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';


interface IPrices {
    
    function calculateTwappedPrice(IUniswapV3Pool pool, bool normalizeDecimals) external view returns (uint price);
    function calculateInstantTwappedPrice(IUniswapV3Pool pool, uint32 twapDuration) external view returns (uint);
    function calculateInstantTwappedTick(IUniswapV3Pool pool, uint32 twapDuration) external view returns (int24 tick);
    function zhuTcpPrice(uint32 twapDuration) external view returns (uint);
    function getRealZhuCountForSinglePoolPosition(
        IUniswapV3Pool pool,
        int24 tickLower,
        int24 tick,
        int24 tickUpper,
        uint128 liquidity,
        uint32 twapDuration
    ) external view returns (uint zhuCount);

    
    function systemObtainReferencePrice(IUniswapV3Pool pool) external returns (uint);

    
    function addReferencePool(IUniswapV3Pool pool) external;
    function completeSetup() external;
    function stop() external;

    
    struct PriceInfo {
        uint64 startTime;
        int56 tickCumulative;
        int24 tick;
        uint8 otherTokenDecimals;
        bool isToken0;
        bool valid;
    }

    
    event PriceUpdated(address indexed pool, uint price, int24 tick);
    event ParameterUpdatedAddress(string indexed paramName, address indexed addr);
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;


interface IProtocolLock {
    
    function enter() external;
    function exit() external;

    
    function authorizeCaller(address caller) external;
    function unauthorizeCaller(address caller) external;

    
    event CallerAuthorized(address indexed caller);
    event CallerUnauthorized(address indexed caller);
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;


import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';

interface IRates {
    
    function positiveInterestRate() external view returns (bool);
    function interestRateAbsoluteValue() external view returns (uint);

    
    function setInterestRateStep(uint128 step) external;
    function addReferencePool(IUniswapV3Pool pool) external;
    function removeReferencePool(IUniswapV3Pool pool) external;

    function completeSetup() external;
    function stop() external;

    
    event RateUpdated(int interestRate, uint price, uint rewardCount, uint64 nextUpdateTime);
    event ParameterUpdated64(string indexed paramName, uint64 value);
    event ParameterUpdated128(string indexed paramName, uint128 value);
    event ParameterUpdatedInt128(string indexed paramName, int128 value);
    event ParameterUpdatedAddress(string indexed paramName, address indexed addr);
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;


interface ISettlement {
    
    function stakeTokensForNoPriceConfidence(uint countTCPToStake) external;
    function unstakeTokensForNoPriceConfidence() external;

    
    function setEthPriceProvider(IPriceProvider aggregator) external;
    function stop() external;

    
    
    event SettlementInitialized(uint settlementDiscoveryStartTime);
    event StakedNoConfidenceTokens(address indexed account, uint count);
    event UnstakedNoConfidenceTokens(address indexed account, uint count);
    event NoConfidenceConfirmed(address indexed account);

    
    event SettlementWithdrawCollateral(uint64 indexed positionID, address indexed owner, uint collateralToWithdraw);
    event SettlementCollateralForZhu(uint64 indexed positionID, address indexed caller, uint zhuCount, uint collateralCount);

    
    event ParameterUpdatedAddress(string indexed paramName, address indexed _address);

    
    enum SettlementStage {
        ContractStopped,
        NotShutdown,
        NotInitialized,
        WaitingForPriceTime,
        NoPriceConfidence,
        PriceConfidence,
        PriceConfirmed
    }
}

interface IPriceProvider {
  function decimals() external view returns (uint8);
  function latestRoundData() external view returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Creates and initializes V3 Pools
/// @notice Provides a method for creating and initializing a pool, if necessary, for bundling with other methods that
/// require the pool to exist.
interface IPoolInitializer {
    /// @notice Creates a new pool if it does not exist, then initializes if not initialized
    /// @dev This method can be bundled with others via IMulticall for the first action (e.g. mint) performed against a pool
    /// @param token0 The contract address of token0 of the pool
    /// @param token1 The contract address of token1 of the pool
    /// @param fee The fee amount of the v3 pool for the specified token pair
    /// @param sqrtPriceX96 The initial square root price of the pool as a Q64.96 value
    /// @return pool Returns the pool address based on the pair of tokens and fee, will return the newly created pool address if necessary
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

/// @title ERC721 with permit
/// @notice Extension to ERC721 that includes a permit function for signature based approvals
interface IERC721Permit is IERC721 {
    /// @notice The permit typehash used in the permit signature
    /// @return The typehash for the permit
    function PERMIT_TYPEHASH() external pure returns (bytes32);

    /// @notice The domain separator used in the permit signature
    /// @return The domain seperator used in encoding of permit signature
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice Approve of a specific token ID for spending by spender via signature
    /// @param spender The account that is being approved
    /// @param tokenId The ID of the token that is being approved for spending
    /// @param deadline The deadline timestamp by which the call must be mined for the approve to work
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

/// @title Periphery Payments
/// @notice Functions to ease deposits and withdrawals of ETH
interface IPeripheryPayments {
    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;

    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundETH() external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IPeripheryImmutableState {
    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        factory,
                        keccak256(abi.encode(key.token0, key.token1, key.fee)),
                        POOL_INIT_CODE_HASH
                    )
                )
            )
        );
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000000
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