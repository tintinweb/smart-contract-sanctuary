// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import './interfaces/IAlgebraFactory.sol';
import './interfaces/IAlgebraPoolDeployer.sol';
import './interfaces/IDataStorageOperator.sol';

import './DataStorageOperator.sol';

/**
 * @title Algebra factory
 * @notice Is used to deploy pools and its dataStorages
 */
contract AlgebraFactory is IAlgebraFactory {
    /// @inheritdoc IAlgebraFactory
    address public override owner;

    // @inheritdoc IAlgebraFactory
    address public override poolDeployer;

    // @inheritdoc IAlgebraFactory
    address public override stakerAddress;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // @inheritdoc IAlgebraFactory
    mapping(address => mapping(address => address)) public override poolByPair;

    constructor(address _poolDeployer) {
        owner = msg.sender;
        emit OwnerChanged(address(0), msg.sender);

        poolDeployer = _poolDeployer;
    }

    // @inheritdoc IAlgebraFactory
    function createPool(address tokenA, address tokenB) external override returns (address pool) {
        require(tokenA != tokenB);
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0));
        require(poolByPair[token0][token1] == address(0));

        IDataStorageOperator dataStorage = IDataStorageOperator(
            address(new DataStorageOperator(computeAddress(token0, token1)))
        );

        pool = IAlgebraPoolDeployer(poolDeployer).deploy(address(dataStorage), address(this), token0, token1);

        poolByPair[token0][token1] = pool;
        // to avoid future addresses comparing we are populating the mapping twice
        poolByPair[token1][token0] = pool;
        emit PoolCreated(token0, token1, pool);
    }

    // @inheritdoc IAlgebraFactory
    function setOwner(address _owner) external override onlyOwner {
        emit OwnerChanged(owner, _owner);
        owner = _owner;
    }

    // @inheritdoc IAlgebraFactory
    function setStakerAddress(address _stakerAddress) external override onlyOwner {
        stakerAddress = _stakerAddress;
    }

    bytes32 internal constant POOL_INIT_CODE_HASH = 0x7f46fa63e80af4b4245cb4819c3af72a0417f14239c1af2596c4515297e80e40;

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param token0 first token
    /// @param token1 second token
    /// @return pool The contract address of the V3 pool
    function computeAddress(address token0, address token1) internal view returns (address pool) {
        pool = address(
            uint256(
                keccak256(
                    abi.encodePacked(hex'ff', poolDeployer, keccak256(abi.encode(token0, token1)), POOL_INIT_CODE_HASH)
                )
            )
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/**
 * @title The interface for the Algebra Factory
 */
interface IAlgebraFactory {
    /**
     *  @notice Emitted when the owner of the factory is changed
     *  @param oldOwner The owner before the owner was changed
     *  @param newOwner The owner after the owner was changed
     */
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /**
     *  @notice Emitted when a pool is created
     *  @param token0 The first token of the pool by address sort order
     *  @param token1 The second token of the pool by address sort order
     *  @param pool The address of the created pool
     */
    event PoolCreated(address indexed token0, address indexed token1, address pool);

    /**
     *  @notice Returns the current owner of the factory
     *  @dev Can be changed by the current owner via setOwner
     *  @return The address of the factory owner
     */
    function owner() external view returns (address);

    /**
     *  @notice Returns the current poolDeployerAddress
     *  @return The address of the poolDeployer
     */
    function poolDeployer() external view returns (address);

    /**
     * @dev Is retrieved from the pools to restrict calling
     * certain functions not by a staker contract
     * @return The staker contract address
     */
    function stakerAddress() external view returns (address);

    /**
     *  @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
     *  @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
     *  @param tokenA The contract address of either token0 or token1
     *  @param tokenB The contract address of the other token
     *  @return pool The pool address
     */
    function poolByPair(address tokenA, address tokenB) external view returns (address pool);

    /**
     *  @notice Creates a pool for the given two tokens and fee
     *  @param tokenA One of the two tokens in the desired pool
     *  @param tokenB The other of the two tokens in the desired pool
     *  @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
     *  from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
     *  are invalid.
     *  @return pool The address of the newly created pool
     */
    function createPool(address tokenA, address tokenB) external returns (address pool);

    /**
     *  @notice Updates the owner of the factory
     *  @dev Must be called by the current owner
     *  @param _owner The new owner of the factory
     */
    function setOwner(address _owner) external;

    /**
     * @dev updates staker address on the factory
     * @param _stakerAddress The new staker contract address
     */
    function setStakerAddress(address _stakerAddress) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/**
 * @title An interface for a contract that is capable of deploying Algebra Pools
 * @notice A contract that constructs a pool must implement this to pass arguments to the pool
 * @dev This is used to avoid having constructor arguments in the pool contract, which results in the init code hash
 * of the pool being constant allowing the CREATE2 address of the pool to be cheaply computed on-chain
 */
interface IAlgebraPoolDeployer {
    /**
     * @notice Get the parameters to be used in constructing the pool, set transiently during pool creation.
     * @dev Called by the pool constructor to fetch the parameters of the pool
     * Returns dataStorage The pools associated dataStorage
     * Returns factory The factory address
     * Returns token0 The first token of the pool by address sort order
     * Returns token1 The second token of the pool by address sort order
     */
    function parameters()
        external
        view
        returns (
            address dataStorage,
            address factory,
            address token0,
            address token1
        );

    /**
     * @dev Deploys a pool with the given parameters by transiently setting the parameters storage slot and then
     * clearing it after deploying the pool.
     * @param dataStorage The pools associated dataStorage
     * @param factory The contract address of the Algebra factory
     * @param token0 The first token of the pool by address sort order
     * @param token1 The second token of the pool by address sort order
     * @return pool The deployed pool's address
     */
    function deploy(
        address dataStorage,
        address factory,
        address token0,
        address token1
    ) external returns (address pool);

    /**
     * @dev Sets the factory address to the poolDeployer for permissioned actions
     * @param factory The address of the Algebra factory
     */
    function setFactory(address factory) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.7.0;

interface IDataStorageOperator {
    /**
     * @notice Returns data belonging to a certain timepoint
     * @param index The index of timepoint in the array
     * @dev There is more convenient function to fetch a timepoint: observe(). Which requires not an index but seconds
     * @return initialized whether the timepoint has been initialized and the values are safe to use
     * blockTimestamp The timestamp of the observation,
     * tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the timepoint timestamp,
     * secondsPerLiquidityCumulative the seconds per in range liquidity for the life of the pool as of the timepoint timestamp,
     * volatilityCumulative Cumulative standard deviation for the life of the pool as of the timepoint timestamp
     * volumePerAvgLiquidity Cumulative swap volume per liquidity for the life of the pool as of the timepoint timestamp
     */
    function timepoints(uint256 index)
        external
        view
        returns (
            bool initialized,
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulative,
            uint112 volatilityCumulative,
            uint144 volumePerLiquidityCumulative
        );

    function initialize(uint32 time) external;

    function getSingleTimepoint(
        uint32 time,
        uint32 secondsAgo,
        int24 tick,
        uint16 index,
        uint128 liquidity
    )
        external
        view
        returns (
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulative,
            uint112 volatilityCumulative,
            uint256 volumePerAvgLiquidity
        );

    function getTimepoints(
        uint32 time,
        uint32[] memory secondsAgos,
        int24 tick,
        uint16 index,
        uint128 liquidity
    )
        external
        view
        returns (
            int56[] memory tickCumulatives,
            uint160[] memory secondsPerLiquidityCumulatives,
            uint112[] memory volatilityCumulatives,
            uint256[] memory volumePerAvgLiquiditys
        );

    function getAverages(
        uint32 time,
        int24 tick,
        uint16 index,
        uint128 liquidity
    ) external view returns (uint112 TWVolatilityAverage, uint256 TWVolumePerLiqAverage);

    function write(
        uint16 index,
        uint32 blockTimestamp,
        int24 tick,
        uint128 liquidity,
        uint128 volumePerLiquidity
    ) external returns (uint16 indexUpdated);

    function calculateVolumePerLiquidity(
        uint128 liquidity,
        int256 amount0,
        int256 amount1
    ) external pure returns (uint128 volumePerLiquidity);

    function timeAgo() external view returns (uint32);

    function getFee(
        uint32 _time,
        int24 _tick,
        uint16 _index,
        uint128 _liquidity
    ) external view returns (uint16 fee);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.7.0;

import './interfaces/IAlgebraFactory.sol';
import './interfaces/IDataStorageOperator.sol';

import './libraries/DataStorage.sol';
import './libraries/Sqrt.sol';
import './libraries/AdaptiveFee.sol';

contract DataStorageOperator is IDataStorageOperator {
    using DataStorage for DataStorage.Timepoint[65535];

    DataStorage.Timepoint[65535] public override timepoints;
    AdaptiveFee.Configuration public feeConfig;

    address private immutable pool;
    address private immutable factory;

    modifier onlyPool() {
        require(msg.sender == pool, 'only pool can call this');
        _;
    }

    modifier onlyFactory() {
        require(msg.sender == factory, 'only factory can call this');
        _;
    }

    constructor(address _pool) {
        factory = msg.sender;
        pool = _pool;
        feeConfig = AdaptiveFee.Configuration(
            3000 - 500, // alpha1
            10000 - 3000, // alpha2
            180, // beta1
            1500, // beta2
            30, // gamma1
            100, // gamma2
            0, // volumeBeta
            4 // volumeGamma
        );
    }

    function initialize(uint32 time) external override onlyPool {
        return timepoints.initialize(time);
    }

    function changeFeeConfiguration(
        uint32 alpha1,
        uint32 alpha2,
        uint32 beta1,
        uint32 beta2,
        uint32 gamma1,
        uint32 gamma2,
        uint32 volumeBeta,
        uint32 volumeGamma
    ) external {
        require(msg.sender == IAlgebraFactory(factory).owner());
        feeConfig = AdaptiveFee.Configuration(alpha1, alpha2, beta1, beta2, gamma1, gamma2, volumeBeta, volumeGamma);
    }

    function getSingleTimepoint(
        uint32 time,
        uint32 secondsAgo,
        int24 tick,
        uint16 index,
        uint128 liquidity
    )
        external
        view
        override
        onlyPool
        returns (
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulative,
            uint112 volatilityCumulative,
            uint256 volumePerAvgLiquidity
        )
    {
        return timepoints.getSingleTimepoint(time, secondsAgo, tick, index, liquidity);
    }

    function getTimepoints(
        uint32 time,
        uint32[] memory secondsAgos,
        int24 tick,
        uint16 index,
        uint128 liquidity
    )
        external
        view
        override
        onlyPool
        returns (
            int56[] memory tickCumulatives,
            uint160[] memory secondsPerLiquidityCumulatives,
            uint112[] memory volatilityCumulatives,
            uint256[] memory volumePerAvgLiquiditys
        )
    {
        return timepoints.getTimepoints(time, secondsAgos, tick, index, liquidity);
    }

    function getAverages(
        uint32 time,
        int24 tick,
        uint16 index,
        uint128 liquidity
    ) external view override onlyPool returns (uint112 TWVolatilityAverage, uint256 TWVolumePerLiqAverage) {
        return timepoints.getAverages(time, tick, index, liquidity);
    }

    function write(
        uint16 index,
        uint32 blockTimestamp,
        int24 tick,
        uint128 liquidity,
        uint128 volumePerLiquidity
    ) external override onlyPool returns (uint16 indexUpdated) {
        return timepoints.write(index, blockTimestamp, tick, liquidity, volumePerLiquidity);
    }

    function calculateVolumePerLiquidity(
        uint128 liquidity,
        int256 amount0,
        int256 amount1
    ) external pure override returns (uint128 volumePerLiquidity) {
        uint256 volume = Sqrt.sqrt(amount0) * Sqrt.sqrt(amount1);
        uint256 volumeShifted;
        if (volume >= 2**192) volumeShifted = (type(uint256).max) / (liquidity > 0 ? liquidity : 1);
        else volumeShifted = (volume << 64) / (liquidity > 0 ? liquidity : 1);
        if (volumeShifted >= 100000 << 64) return 100000 << 64;
        volumePerLiquidity = uint128(volumeShifted);
    }

    function timeAgo() external pure override returns (uint32) {
        return DataStorage.window;
    }

    function getFee(
        uint32 _time,
        int24 _tick,
        uint16 _index,
        uint128 _liquidity
    ) external view override onlyPool returns (uint16 fee) {
        (uint112 TWVolatilityAverage, uint256 TWVolumePerLiqAverage) = timepoints.getAverages(
            _time,
            _tick,
            _index,
            _liquidity
        );

        return uint16(AdaptiveFee.getFee(TWVolatilityAverage, TWVolumePerLiqAverage, feeConfig));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './FullMath.sol';

/// @title DataStorage
/// @notice Provides price and liquidity data useful for a wide variety of system designs
/// @dev Instances of stored dataStorage data, "timepoints", are collected in the dataStorage array
/// Every pool is initialized with an dataStorage array length of 1. Anyone can pay the SSTOREs to increase the
/// maximum length of the dataStorage array. New slots will be added when the array is fully populated.
/// Timepoints are overwritten when the full length of the dataStorage array is populated.
/// The most recent timepoint is available, independent of the length of the dataStorage array, by passing 0 to getTimepoints()
library DataStorage {
    uint32 public constant window = 24 * 60 * 60;
    struct Timepoint {
        // whether or not the timepoint is initialized
        bool initialized;
        // the block timestamp of the timepoint
        uint32 blockTimestamp;
        // the tick accumulator, i.e. tick * time elapsed since the pool was first initialized
        int56 tickCumulative;
        // the seconds per liquidity, i.e. seconds elapsed / max(1, liquidity) since the pool was first initialized
        uint160 secondsPerLiquidityCumulative;
        uint112 volatilityCumulative;
        uint144 volumePerLiquidityCumulative;
    }

    /// @notice Transforms a previous timepoint into a new timepoint, given the passage of time and the current tick and liquidity values
    /// @dev blockTimestamp _must_ be chronologically equal to or greater than last.blockTimestamp, safe for 0 or 1 overflows
    /// @param last The specified timepoint to be used in creation of new timepoint
    /// @param blockTimestamp The timestamp of the new timepoint
    /// @param tick The active tick at the time of the new timepoint
    /// @param liquidity The total in-range liquidity at the time of the new timepoint
    /// @return Timepoint The newly populated timepoint
    //TODO: doc
    function createNewTimepoint(
        Timepoint memory last,
        uint32 blockTimestamp,
        int24 tick,
        uint128 liquidity,
        int24 averageTick,
        uint128 volumePerLiquidity
    ) private pure returns (Timepoint memory) {
        uint32 delta = blockTimestamp - last.blockTimestamp;

        return
            Timepoint({
                initialized: true,
                blockTimestamp: blockTimestamp,
                tickCumulative: last.tickCumulative + int56(tick) * delta, // TODO TIMEDELTAS
                secondsPerLiquidityCumulative: last.secondsPerLiquidityCumulative +
                    ((uint160(delta) << 128) / (liquidity > 0 ? liquidity : 1)),
                volatilityCumulative: last.volatilityCumulative + uint112(int112(averageTick - tick)**2),
                volumePerLiquidityCumulative: last.volumePerLiquidityCumulative + volumePerLiquidity
            });
    }

    /// @notice comparator for 32-bit timestamps
    /// @dev safe for 0 or 1 overflows, a and b _must_ be chronologically before or equal to currentTime
    /// @param a A comparison timestamp from which to determine the relative position of `currentTime`
    /// @param b From which to determine the relative position of `currentTime`
    /// @param currentTime A timestamp truncated to 32 bits
    /// @return res Whether `a` is chronologically <= `b`
    function lteConsideringOverflow(
        uint32 a,
        uint32 b,
        uint32 currentTime
    ) private pure returns (bool res) {
        res = (a > currentTime);

        if (res == b > currentTime) return a <= b; // if both are on the same side
        // otherwise need to return (a > currentTime)
    }

    function _averages(
        Timepoint[65535] storage self,
        uint32 time,
        int24 tick,
        uint16 index,
        uint128 liquidity
    ) private view returns (int24 avgTick) {
        Timepoint memory last = self[index];

        Timepoint storage oldest = self[addmod(index, 1, 65535)];
        if (!oldest.initialized) oldest = self[0];

        if (lteConsideringOverflow(oldest.blockTimestamp, time - window, time)) {
            if (!lteConsideringOverflow(last.blockTimestamp, time - window, time)) {
                (int56 bTick, , , ) = getSingleTimepoint(
                    self,
                    time,
                    window,
                    tick,
                    index,
                    liquidity //TODO:MB last - window?
                );
                //    current-window  last   current
                // _________*____________*_______*_
                //           ||||||||||||

                // May be we should do:
                //    last-window         last   current
                // _________*_________________*_______*_
                //           |||||||||||||||||
                avgTick = int24((last.tickCumulative - bTick) / (window + last.blockTimestamp - time));
            } else {
                index = index == 0 ? 65535 - 1 : index - 1;
                avgTick = self[index].initialized
                    ? int24(
                        (last.tickCumulative - self[index].tickCumulative) /
                            (last.blockTimestamp - self[index].blockTimestamp)
                    )
                    : tick;
            }
        } else {
            avgTick = (last.blockTimestamp == oldest.blockTimestamp)
                ? tick
                : int24((last.tickCumulative - oldest.tickCumulative) / (last.blockTimestamp - oldest.blockTimestamp));
        }
    }

    /// @notice Fetches the timepoints beforeOrAt and atOrAfter a target, i.e. where [beforeOrAt, atOrAfter] is satisfied.
    /// The result may be the same timepoint, or adjacent timepoints.
    /// @dev The answer must be contained in the array, used when the target is located within the stored timepoint
    /// boundaries: older than the most recent timepoint and younger, or the same age as, the oldest timepoint
    /// @param self The stored dataStorage array
    /// @param time The current block.timestamp
    /// @param target The timestamp at which the reserved timepoint should be for
    /// @param index The index of the timepoint that was most recently written to the timepoints array
    /// @return beforeOrAt The timepoint recorded before, or at, the target
    /// @return atOrAfter The timepoint recorded at, or after, the target
    function binarySearch(
        Timepoint[65535] storage self,
        uint32 time,
        uint32 target,
        uint16 index
    ) private view returns (Timepoint memory beforeOrAt, Timepoint memory atOrAfter) {
        uint256 l = addmod(index, 1, 65535); // oldest timepoint
        uint256 r = l + 65534; // newest timepoint
        uint256 i;
        uint256 currentTimepointNum;
        while (true) {
            i = (l + r) / 2;
            currentTimepointNum = i % 65535;
            (
                beforeOrAt.initialized,
                beforeOrAt.blockTimestamp,
                beforeOrAt.tickCumulative,
                beforeOrAt.secondsPerLiquidityCumulative
            ) = (
                self[currentTimepointNum].initialized,
                self[currentTimepointNum].blockTimestamp,
                self[currentTimepointNum].tickCumulative,
                self[currentTimepointNum].secondsPerLiquidityCumulative
            );

            // we've landed on an uninitialized tick, keep searching higher (more recently)
            if (!beforeOrAt.initialized) {
                l = i + 1;
                continue;
            }

            // check if we've found the answer!
            if (lteConsideringOverflow(beforeOrAt.blockTimestamp, target, time)) {
                atOrAfter.blockTimestamp = self[addmod(i, 1, 65535)].blockTimestamp;
                if (lteConsideringOverflow(target, atOrAfter.blockTimestamp, time)) {
                    beforeOrAt.volatilityCumulative = self[currentTimepointNum].volatilityCumulative;
                    beforeOrAt.volumePerLiquidityCumulative = self[currentTimepointNum].volumePerLiquidityCumulative;
                    atOrAfter = self[addmod(i, 1, 65535)];
                    break;
                }
                l = i + 1;
            } else {
                r = i - 1;
            }
        }
    }

    /// @notice Fetches the timepoints beforeOrAt and atOrAfter a given target, i.e. where [beforeOrAt, atOrAfter] is satisfied
    /// @dev Assumes there is at least 1 initialized timepoint.
    /// Used by getSingleTimepoint() to compute the counterfactual accumulator values as of a given block timestamp.
    /// @param self The stored dataStorage array
    /// @param time The current block.timestamp
    /// @param target The timestamp at which the reserved timepoint should be for
    /// @param tick The active tick at the time of the returned or simulated timepoint
    /// @param index The index of the timepoint that was most recently written to the timepoints array
    /// @param liquidity The total pool liquidity at the time of the call
    /// @return beforeOrAt The timepoint which occurred at, or before, the given timestamp
    /// @return atOrAfter The timepoint which occurred at, or after, the given timestamp
    function getSurroundingTimepoints(
        Timepoint[65535] storage self,
        uint32 time,
        uint32 target,
        int24 tick,
        uint16 index,
        uint128 liquidity
    ) private view returns (Timepoint memory beforeOrAt, Timepoint memory atOrAfter) {
        // if the target is chronologically at or after the newest timepoint, we can early return
        if (lteConsideringOverflow(self[index].blockTimestamp, target, time)) {
            beforeOrAt = self[index];
            if (beforeOrAt.blockTimestamp == target) {
                // if newest timepoint equals target, we're in the same block, so we can ignore atOrAfter
                return (beforeOrAt, atOrAfter);
            } else {
                int24 avgTick = _averages(self, time, tick, index, liquidity);
                // otherwise, we need to add new timepoint
                return (beforeOrAt, createNewTimepoint(beforeOrAt, target, tick, liquidity, avgTick, 0));
            }
        }

        // now, set before to the oldest timepoint

        if (!self[addmod(index, 1, 65535)].initialized) {
            beforeOrAt = self[0];
        } else {
            beforeOrAt = self[addmod(index, 1, 65535)];
        }

        // ensure that the target is chronologically at or after the oldest timepoint
        require(lteConsideringOverflow(beforeOrAt.blockTimestamp, target, time), 'OLD');

        // if we've reached this point, we have to binary search
        return binarySearch(self, time, target, index);
    }

    /// @dev Reverts if an timepoint at or before the desired timepoint timestamp does not exist.
    /// 0 may be passed as `secondsAgo' to return the current cumulative values.
    /// If called with a timestamp falling between two timepoints, returns the counterfactual accumulator values
    /// at exactly the timestamp between the two timepoints.
    /// @param self The stored dataStorage array
    /// @param time The current block timestamp
    /// @param secondsAgo The amount of time to look back, in seconds, at which point to return an timepoint
    /// @param tick The current tick
    /// @param index The index of the timepoint that was most recently written to the timepoints array
    /// @param liquidity The current in-range pool liquidity
    /// @return tickCumulative The tick * time elapsed since the pool was first initialized, as of `secondsAgo`
    /// @return secondsPerLiquidityCumulative The time elapsed / max(1, liquidity) since the pool was first initialized, as of `secondsAgo`
    function getSingleTimepoint(
        Timepoint[65535] storage self,
        uint32 time,
        uint32 secondsAgo,
        int24 tick,
        uint16 index,
        uint128 liquidity
    )
        internal
        view
        returns (
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulative,
            uint112 volatilityCumulative,
            uint256 volumePerLiquidityCumulative
        )
    {
        if (secondsAgo == 0) {
            Timepoint memory last = self[index];

            int24 avgTick = _averages(self, time, tick, index, liquidity);
            if (last.blockTimestamp != time) last = createNewTimepoint(last, time, tick, liquidity, avgTick, 0);
            return (
                last.tickCumulative,
                last.secondsPerLiquidityCumulative,
                last.volatilityCumulative,
                last.volumePerLiquidityCumulative
            );
        }

        uint32 target = time - secondsAgo;

        (Timepoint memory beforeOrAt, Timepoint memory atOrAfter) = getSurroundingTimepoints(
            self,
            time,
            target,
            tick,
            index,
            liquidity
        );

        if (target == beforeOrAt.blockTimestamp) {
            // we're at the left boundary
            return (
                beforeOrAt.tickCumulative,
                beforeOrAt.secondsPerLiquidityCumulative,
                beforeOrAt.volatilityCumulative,
                beforeOrAt.volumePerLiquidityCumulative
            );
        } else if (target == atOrAfter.blockTimestamp) {
            // we're at the right boundary
            return (
                atOrAfter.tickCumulative,
                atOrAfter.secondsPerLiquidityCumulative,
                atOrAfter.volatilityCumulative,
                atOrAfter.volumePerLiquidityCumulative
            );
        } else {
            // we're in the middle
            uint32 timepointTimeDelta = atOrAfter.blockTimestamp - beforeOrAt.blockTimestamp;
            uint32 targetDelta = target - beforeOrAt.blockTimestamp;
            return (
                beforeOrAt.tickCumulative +
                    ((atOrAfter.tickCumulative - beforeOrAt.tickCumulative) / timepointTimeDelta) *
                    targetDelta,
                beforeOrAt.secondsPerLiquidityCumulative +
                    uint160(
                        (uint256(atOrAfter.secondsPerLiquidityCumulative - beforeOrAt.secondsPerLiquidityCumulative) *
                            targetDelta) / timepointTimeDelta
                    ),
                beforeOrAt.volatilityCumulative +
                    ((atOrAfter.volatilityCumulative - beforeOrAt.volatilityCumulative) / timepointTimeDelta) *
                    targetDelta,
                beforeOrAt.volumePerLiquidityCumulative +
                    ((atOrAfter.volumePerLiquidityCumulative - beforeOrAt.volumePerLiquidityCumulative) /
                        timepointTimeDelta) *
                    targetDelta
            );
        }
    }

    /// @notice Returns the accumulator values as of each time seconds ago from the given time in the array of `secondsAgos`
    /// @dev Reverts if `secondsAgos` > oldest timepoint
    /// @param self The stored dataStorage array
    /// @param time The current block.timestamp
    /// @param secondsAgos Each amount of time to look back, in seconds, at which point to return an timepoint
    /// @param tick The current tick
    /// @param index The index of the timepoint that was most recently written to the timepoints array
    /// @param liquidity The current in-range pool liquidity
    /// @return tickCumulatives The tick * time elapsed since the pool was first initialized, as of each `secondsAgo`
    /// @return secondsPerLiquidityCumulatives The cumulative seconds / max(1, liquidity) since the pool was first initialized, as of each `secondsAgo`
    function getTimepoints(
        Timepoint[65535] storage self,
        uint32 time,
        uint32[] memory secondsAgos,
        int24 tick,
        uint16 index,
        uint128 liquidity
    )
        internal
        view
        returns (
            int56[] memory tickCumulatives,
            uint160[] memory secondsPerLiquidityCumulatives,
            uint112[] memory volatilityCumulatives,
            uint256[] memory volumePerAvgLiquiditys
        )
    {
        tickCumulatives = new int56[](secondsAgos.length);
        secondsPerLiquidityCumulatives = new uint160[](secondsAgos.length);
        volatilityCumulatives = new uint112[](secondsAgos.length);
        volumePerAvgLiquiditys = new uint256[](secondsAgos.length);
        for (uint256 i = 0; i < secondsAgos.length; i++) {
            (
                tickCumulatives[i],
                secondsPerLiquidityCumulatives[i],
                volatilityCumulatives[i],
                volumePerAvgLiquiditys[i]
            ) = getSingleTimepoint(self, time, secondsAgos[i], tick, index, liquidity);
        }
    }

    /// @notice Returns average volatility in the range from time-window to time
    /// @dev if the oldest timepoint was written later than time-window returns 0 as average volatility
    /// @param self The stored dataStorage array
    /// @param time The current block.timestamp
    /// @param tick The current tick
    /// @param index The index of the timepoint that was most recently written to the timepoints array
    /// @param liquidity The current in-range pool liquidity
    /// @return TWVolatilityAverage The average volatility in the recent range
    function getAverages(
        Timepoint[65535] storage self,
        uint32 time,
        int24 tick,
        uint16 index,
        uint128 liquidity
    ) internal view returns (uint112 TWVolatilityAverage, uint256 TWVolumePerLiqAverage) {
        Timepoint storage oldest = self[addmod(index, 1, 65535)];
        if (!oldest.initialized) oldest = self[0];
        (, , uint112 volatilityAfter, uint256 volumePerLiquidityCumulativeAfter) = getSingleTimepoint(
            self,
            time,
            0,
            tick,
            index,
            liquidity
        );
        if (lteConsideringOverflow(oldest.blockTimestamp, time - window, time)) {
            (, , uint112 volatilityBefore, uint256 volumePerLiquidityCumulativeBefore) = getSingleTimepoint(
                self,
                time,
                window,
                tick,
                index,
                liquidity
            );
            return (
                (volatilityAfter - volatilityBefore) / window,
                uint256((volumePerLiquidityCumulativeAfter - volumePerLiquidityCumulativeBefore)) >> 64
            );
        } else {
            return ((volatilityAfter) / window, uint256((volumePerLiquidityCumulativeAfter)) >> 64);
        }
    }

    /// @notice Initialize the dataStorage array by writing the first slot. Called once for the lifecycle of the timepoints array
    /// @param self The stored dataStorage array
    /// @param time The time of the dataStorage initialization, via block.timestamp truncated to uint32
    function initialize(Timepoint[65535] storage self, uint32 time) internal {
        self[0] = Timepoint({
            initialized: true,
            blockTimestamp: time,
            tickCumulative: 0,
            secondsPerLiquidityCumulative: 0,
            volatilityCumulative: 0,
            volumePerLiquidityCumulative: 0
        });
    }

    /// @notice Writes an dataStorage timepoint to the array
    /// @dev Writable at most once per block. Index represents the most recently written element. index must be tracked externally.
    /// If the index is at the end of the allowable array length (according to cardinality), and the next cardinality
    /// is greater than the current one, cardinality may be increased. This restriction is created to preserve ordering.
    /// @param self The stored dataStorage array
    /// @param index The index of the timepoint that was most recently written to the timepoints array
    /// @param blockTimestamp The timestamp of the new timepoint
    /// @param tick The active tick at the time of the new timepoint
    /// @param liquidity The total in-range liquidity at the time of the new timepoint
    /// @return indexUpdated The new index of the most recently written element in the dataStorage array
    function write(
        Timepoint[65535] storage self,
        uint16 index,
        uint32 blockTimestamp,
        int24 tick,
        uint128 liquidity,
        uint128 volumePerLiquidity
    ) internal returns (uint16 indexUpdated) {
        Timepoint storage last = self[index];

        // early return if we've already written an timepoint this block
        if (last.blockTimestamp == blockTimestamp) {
            return index;
        }

        indexUpdated = uint16(addmod(index, 1, 65535));
        int24 avgTick = _averages(self, blockTimestamp, tick, index, liquidity);
        self[indexUpdated] = createNewTimepoint(last, blockTimestamp, tick, liquidity, avgTick, volumePerLiquidity);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.7.6;

library Sqrt {
    function sqrt(int256 _x) internal pure returns (uint256 result) {
        // get abs value
        int256 mask = _x >> (256 - 1);
        uint256 x = uint256((_x ^ mask) - mask);
        if (x == 0) result = 0;
        else {
            uint256 xx = x;
            uint256 r = 1;
            if (xx >= 0x100000000000000000000000000000000) {
                xx >>= 128;
                r <<= 64;
            }
            if (xx >= 0x10000000000000000) {
                xx >>= 64;
                r <<= 32;
            }
            if (xx >= 0x100000000) {
                xx >>= 32;
                r <<= 16;
            }
            if (xx >= 0x10000) {
                xx >>= 16;
                r <<= 8;
            }
            if (xx >= 0x100) {
                xx >>= 8;
                r <<= 4;
            }
            if (xx >= 0x10) {
                xx >>= 4;
                r <<= 2;
            }
            if (xx >= 0x8) {
                r <<= 1;
            }
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1; // @dev Seven iterations should be enough.
            uint256 r1 = x / r;
            result = r < r1 ? r : r1;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

import './Constants.sol';

library AdaptiveFee {
    struct Configuration {
        uint32 alpha1;
        uint32 alpha2;
        uint32 beta1;
        uint32 beta2;
        uint32 gamma1;
        uint32 gamma2;
        uint32 volumeBeta;
        uint32 volumeGamma;
    }

    // Maybe uint112
    function getFee(
        uint112 volatility,
        uint256 volumePerLiquidity,
        Configuration memory config
    ) internal pure returns (uint256 fee) {
        uint256 sigm1 = sigmoid(volatility, config.gamma1, config.alpha1, config.beta1);
        uint256 sigm2 = sigmoid(volatility, config.gamma2, config.alpha2, config.beta2);

        fee = Constants.BASE_FEE + sigmoid(volumePerLiquidity, config.volumeGamma, sigm1 + sigm2, config.volumeBeta);
    }

    function sigmoid(
        uint256 x,
        uint256 g,
        uint256 alpha,
        uint256 beta
    ) internal pure returns (uint256 res) {
        if (x > beta) {
            x = x - beta;
            if (x >= 6 * g) return alpha;
            uint256 ex = exp(x, g);
            res = ((10 * alpha * (ex)) / (g**7 + ex)) / 10;
        } else {
            x = beta - x;
            if (x >= 6 * g) return 0;
            uint256 ex = g**7 + exp(x, g);
            res = ((10 * alpha * g**7) / (ex)) / 10;
        }
    }

    function exp(uint256 x, uint256 g) internal pure returns (uint256 res) {
        return
            g**7 +
            x *
            g**6 +
            (x**2 * g**5) /
            2 +
            (x**3 * g**4) /
            6 +
            (x**4 * g**3) /
            24 +
            (x**5 * g**2) /
            120 +
            (x**6 * g) /
            720 +
            x**7 /
            (720 * 7);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
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
        uint256 prod0 = a * b; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        // Subtract 256 bit remainder from 512 bit number
        assembly {
            let remainder := mulmod(a, b, denominator)
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
        if (a == 0 || ((result = a * b) / a == b)) {
            require(denominator > 0);
            assembly {
                result := add(div(result, denominator), gt(mod(result, denominator), 0))
            }
            return result;
        }

        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }

    /// @notice Returns ceil(x / y)
    /// @dev division by 0 has unspecified behavior, and must be checked externally
    /// @param x The dividend
    /// @param y The divisor
    /// @return z The quotient, ceil(x / y)
    function divRoundingUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := add(div(x, y), gt(mod(x, y), 0))
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

library Constants {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;
    uint16 internal constant BASE_FEE = 500;
}