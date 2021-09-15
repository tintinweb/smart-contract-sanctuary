// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;

import './interfaces/IFuzzyswapFactory.sol';
import './interfaces/IFuzzyswapPoolDeployer.sol';
import './interfaces/IExternalOracle.sol';

import './ExternalOracle.sol';

/// @title Canonical Fuzzyswap factory
/// @notice Deploys Fuzzyswap pools and manages ownership and control over pool protocol fees
contract FuzzyswapFactory is IFuzzyswapFactory {
    /// @inheritdoc IFuzzyswapFactory
    address public override owner;

    /// @inheritdoc IFuzzyswapFactory
    address public override poolDeployer;

    /// @inheritdoc IFuzzyswapFactory
    address public override stackerAddress;

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    /// @inheritdoc IFuzzyswapFactory
    mapping(address => mapping(address => address)) public override getPool;

    constructor(address _poolDeployer) {
        owner = msg.sender;
        emit OwnerChanged(address(0), msg.sender);

        poolDeployer = _poolDeployer;
    }

    /// @inheritdoc IFuzzyswapFactory
    function createPool(
        address tokenA,
        address tokenB
    ) external override returns (address pool) {
        require(tokenA != tokenB);
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0));
        require(getPool[token0][token1] == address(0));

        IExternalOracle oracle = IExternalOracle(address(new ExternalOracle()));

        pool = IFuzzyswapPoolDeployer(poolDeployer).deploy(address(oracle), address(this), token0, token1);

        oracle.setPool(address(pool));
        getPool[token0][token1] = pool;
        // populate mapping in the reverse direction, deliberate choice to avoid the cost of comparing addresses
        getPool[token1][token0] = pool;
        emit PoolCreated(token0, token1, pool);
    }

    /// @inheritdoc IFuzzyswapFactory
    function setOwner(address _owner) external onlyOwner override {
        emit OwnerChanged(owner, _owner);
        owner = _owner;
    }

    /// @inheritdoc IFuzzyswapFactory
    function setStackerAddress(address _stackerAddress) external onlyOwner override {
        stackerAddress = _stackerAddress;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Fuzzyswap Factory
/// @notice The Fuzzyswap Factory facilitates creation of Fuzzyswap pools and control over the protocol fees
interface IFuzzyswapFactory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        address pool
    );

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);


    /// @notice Returns the current poolDeployerAddress
    /// @return The address of the poolDeployer
    function poolDeployer() external view returns (address);

    /** @dev Is retrieved from the pools to restrict calling
     *  certain functions not by a stacker contract
     *  @return The stacker contract address
     */
    function stackerAddress() external view returns (address);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB
    ) external view returns (address pool);


    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /**
     * @dev updates stacker address on the factory
     * @param _stackerAddress The new stacker contract address
     */
    function setStackerAddress(address _stackerAddress) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title An interface for a contract that is capable of deploying Uniswap V3 Pools
/// @notice A contract that constructs a pool must implement this to pass arguments to the pool
/// @dev This is used to avoid having constructor arguments in the pool contract, which results in the init code hash
/// of the pool being constant allowing the CREATE2 address of the pool to be cheaply computed on-chain
interface IFuzzyswapPoolDeployer {
    /// @notice Get the parameters to be used in constructing the pool, set transiently during pool creation.
    /// @dev Called by the pool constructor to fetch the parameters of the pool
    /// Returns factory The factory address
    /// Returns token0 The first token of the pool by address sort order
    /// Returns token1 The second token of the pool by address sort order
    /// Returns fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    function parameters()
        external
        view
        returns (
            address oracle,
            address factory,
            address token0,
            address token1
        );

    function deploy(
        address oracle,
        address factory,
        address token0,
        address token1
    ) external returns (address pool);

    function setFactory(
        address factory
    ) external;
}

pragma solidity >=0.7.0;

interface IExternalOracle{
    function observations(uint256 index)
    external
    view
    returns (
        uint32 blockTimestamp,
        int56 tickCumulative,
        uint160 secondsPerLiquidityCumulative,
        uint112 volatilityCumulative,
        bool initialized
    );

    function setPool(address _pool) external;

    function setFactory(address _factory) external;

    function initialize(uint32 time)
        external;

    function observeSingle(
        uint32 time,
        uint32 secondsAgo,
        int24 tick,
        uint16 index,
        uint128 liquidity
    ) external view returns (int56 tickCumulative,
                            uint160 secondsPerLiquidityCumulative,
                            uint112 volatilityCumulative);

    function observe(
        uint32 time,
        uint32[] memory secondsAgos,
        int24 tick,
        uint16 index,
        uint128 liquidity
    ) external view returns (int56[] memory tickCumulatives,
                            uint160[] memory secondsPerLiquidityCumulatives,
                            uint112[] memory volatilityCumulatives);

    function getVolatilityAverage(
        uint32 time,
        int24 tick,
        uint16 index,
        uint128 liquidity
) external view returns (uint112 TWVolatilityAverage);

    function write(
        uint16 index,
        uint32 blockTimestamp,
        int24 tick,
        uint128 liquidity
    ) external returns (uint16 indexUpdated);

    function timeAgo() external view returns(uint16);
}

pragma solidity >=0.7.0;

import './libraries/Oracle.sol';

contract ExternalOracle {
    using Oracle for Oracle.Observation[65535];

    Oracle.Observation[65535] public observations;

    address private pool;
    address private factory;

    modifier onlyPool(){
        require(msg.sender == pool, "only the pool can call this contract");
        _;
    }

    modifier onlyFactory(){
        require(msg.sender == factory, "only the factory can call this function");
        _;
    }

    function setPool(address _pool) external onlyFactory{
        require(pool == address(0), "pool address is already set");
        pool = _pool;
    }

    constructor() {
        factory = msg.sender;
    }

    function initialize(uint32 time)
        external
        onlyPool
    {
        return observations.initialize(time);
    }

    function observeSingle(
        uint32 time,
        uint32 secondsAgo,
        int24 tick,
        uint16 index,
        uint128 liquidity
    )
        external
        view
        onlyPool
        returns (int56 tickCumulative,
                            uint160 secondsPerLiquidityCumulative,
                            uint112 volatilityCumulative){
        return observations.observeSingle(
            time,
            secondsAgo,
            tick,
            index,
            liquidity
        );
    }

    function observe(
        uint32 time,
        uint32[] memory secondsAgos,
        int24 tick,
        uint16 index,
        uint128 liquidity
    )
        external
        view
        onlyPool
        returns (int56[] memory tickCumulatives,
                            uint160[] memory secondsPerLiquidityCumulatives,
                            uint112[] memory volatilityCumulatives) {
        return observations.observe(
            time,
            secondsAgos,
            tick,
            index,
            liquidity
        );
    }

    function getVolatilityAverage(
        uint32 time,
        int24 tick,
        uint16 index,
        uint128 liquidity
    )
        external
        view
        onlyPool
        returns (uint112 TWVolatilityAverage)
    {
        return observations.getVolatilityAverage(
            time,
            tick,
            index,
            liquidity
        );
    }

    function write(
        uint16 index,
        uint32 blockTimestamp,
        int24 tick,
        uint128 liquidity
    )
        external
        onlyPool
        returns (uint16 indexUpdated)
    {
        return observations.write(
            index,
            blockTimestamp,
            tick,
            liquidity
        );
    }

    function timeAgo()
        external
        pure
        returns(uint16)
    {
        return Oracle.timeAgo();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.5.0;


/// @title Oracle
/// @notice Provides price and liquidity data useful for a wide variety of system designs
/// @dev Instances of stored oracle data, "observations", are collected in the oracle array
/// Every pool is initialized with an oracle array length of 1. Anyone can pay the SSTOREs to increase the
/// maximum length of the oracle array. New slots will be added when the array is fully populated.
/// Observations are overwritten when the full length of the oracle array is populated.
/// The most recent observation is available, independent of the length of the oracle array, by passing 0 to observe()
library Oracle {
    uint16 constant public TIME_AGO = 600;
    struct Observation {
        // the block timestamp of the observation
        uint32 blockTimestamp;
        // the tick accumulator, i.e. tick * time elapsed since the pool was first initialized
        int56 tickCumulative;
        // the seconds per liquidity, i.e. seconds elapsed / max(1, liquidity) since the pool was first initialized
        uint160 secondsPerLiquidityCumulative;
        uint112 volatilityCumulative;
        // whether or not the observation is initialized
        bool initialized;
    }

    function timeAgo() internal pure returns(uint16){
        return TIME_AGO;
    }

    /// @notice Transforms a previous observation into a new observation, given the passage of time and the current tick and liquidity values
    /// @dev blockTimestamp _must_ be chronologically equal to or greater than last.blockTimestamp, safe for 0 or 1 overflows
    /// @param last The specified observation to be transformed
    /// @param blockTimestamp The timestamp of the new observation
    /// @param tick The active tick at the time of the new observation
    /// @param liquidity The total in-range liquidity at the time of the new observation
    /// @return Observation The newly populated observation
    function transform(
        Observation memory last,
        uint32 blockTimestamp,
        int24 tick,
        uint128 liquidity,
        int24 averageTick
    ) private pure returns (Observation memory) {
        uint32 delta = blockTimestamp - last.blockTimestamp;
        return
            Observation({
                blockTimestamp: blockTimestamp,
                tickCumulative: last.tickCumulative + int56(tick) * delta,
                secondsPerLiquidityCumulative: last.secondsPerLiquidityCumulative +
                    ((uint160(delta) << 128) / (liquidity > 0 ? liquidity : 1)),
                volatilityCumulative: last.volatilityCumulative + uint112(int112(averageTick - tick) ** 2),
                initialized: true
            });
    }


    /// @notice comparator for 32-bit timestamps
    /// @dev safe for 0 or 1 overflows, a and b _must_ be chronologically before or equal to time
    /// @param time A timestamp truncated to 32 bits
    /// @param a A comparison timestamp from which to determine the relative position of `time`
    /// @param b From which to determine the relative position of `time`
    /// @return bool Whether `a` is chronologically <= `b`
    function lte(
        uint32 time,
        uint32 a,
        uint32 b
    ) private pure returns (bool) {
        // if there hasn't been overflow, no need to adjust
        if (a <= time && b <= time) return a <= b;

        uint256 aAdjusted = a;
        uint256 bAdjusted = b;
        if (aAdjusted > time) {
            aAdjusted += 2**32;
            bAdjusted += bAdjusted > time ? 2**32 : 0;
        } else {
            bAdjusted += 2**32;
        }

        return aAdjusted <= bAdjusted;
    }

    /// @notice Fetches the observations beforeOrAt and atOrAfter a target, i.e. where [beforeOrAt, atOrAfter] is satisfied.
    /// The result may be the same observation, or adjacent observations.
    /// @dev The answer must be contained in the array, used when the target is located within the stored observation
    /// boundaries: older than the most recent observation and younger, or the same age as, the oldest observation
    /// @param self The stored oracle array
    /// @param time The current block.timestamp
    /// @param target The timestamp at which the reserved observation should be for
    /// @param index The index of the observation that was most recently written to the observations array
    /// @return beforeOrAt The observation recorded before, or at, the target
    /// @return atOrAfter The observation recorded at, or after, the target
    function binarySearch(
        Observation[65535] storage self,
        uint32 time,
        uint32 target,
        uint16 index
    ) private view returns (Observation memory beforeOrAt, Observation memory atOrAfter) {
        uint256 l = addmod(index, 1, 65535); // oldest observation
        uint256 r = l + 65535 - 1; // newest observation
        uint256 i;
        while (true) {
            i = (l + r) / 2;

            beforeOrAt = self[i % 65535];

            // we've landed on an uninitialized tick, keep searching higher (more recently)
            if (!beforeOrAt.initialized) {
                l = i + 1;
                continue;
            }

            // check if we've found the answer!
            if (lte(time, beforeOrAt.blockTimestamp, target)) {
                atOrAfter = self[addmod(i, 1, 65535)];

                if (lte(time, target, atOrAfter.blockTimestamp)) 
                    break;
                l = i + 1;
            } else {
                r = i - 1;
            }
        }
    }

    /// @notice Fetches the observations beforeOrAt and atOrAfter a given target, i.e. where [beforeOrAt, atOrAfter] is satisfied
    /// @dev Assumes there is at least 1 initialized observation.
    /// Used by observeSingle() to compute the counterfactual accumulator values as of a given block timestamp.
    /// @param self The stored oracle array
    /// @param time The current block.timestamp
    /// @param target The timestamp at which the reserved observation should be for
    /// @param tick The active tick at the time of the returned or simulated observation
    /// @param index The index of the observation that was most recently written to the observations array
    /// @param liquidity The total pool liquidity at the time of the call
    /// @return beforeOrAt The observation which occurred at, or before, the given timestamp
    /// @return atOrAfter The observation which occurred at, or after, the given timestamp
    function getSurroundingObservations(
        Observation[65535] storage self,
        uint32 time,
        uint32 target,
        int24 tick,
        uint16 index,
        uint128 liquidity
    ) private view returns (Observation memory beforeOrAt, Observation memory atOrAfter) {
        // optimistically set before to the newest observation
        beforeOrAt = self[index];

        // if the target is chronologically at or after the newest observation, we can early return
        if (lte(time, beforeOrAt.blockTimestamp, target)) {
            if (beforeOrAt.blockTimestamp == target) {
                // if newest observation equals target, we're in the same block, so we can ignore atOrAfter
                return (beforeOrAt, atOrAfter);
            } else {
                Observation storage last = self[index];
                Observation storage oldest = self[addmod(index, 1, 65535)];
                if (!oldest.initialized) oldest = self[0];

                int24 averageTick;

                // if (oldest.blockTimestamp <= time - TIME_AGO && time > TIME_AGO){
                if (lte(time, oldest.blockTimestamp, time - TIME_AGO)){
                    if (last.blockTimestamp + TIME_AGO > time){
                        (int56 b,, ) = observeSingle(
                            self, time, TIME_AGO, tick, index, liquidity
                        );
                        averageTick = int24((last.tickCumulative - b) / (TIME_AGO + last.blockTimestamp - time));
                    } else {
                        index = index == 0 ? 65535 - 1 : index - 1;
                        averageTick = self[index].initialized ?
                            int24(
                                  (last.tickCumulative - self[index].tickCumulative) /
                                  (last.blockTimestamp - self[index].blockTimestamp)
                                ) :
                            tick;
                    }
                } else {
                    averageTick = (last.blockTimestamp == oldest.blockTimestamp) ?
                        tick :
                        int24(
                            (last.tickCumulative - oldest.tickCumulative) /
                            (last.blockTimestamp - oldest.blockTimestamp)
                        );
                }
                // otherwise, we need to transform
                return (beforeOrAt, transform(beforeOrAt, target, tick, liquidity, averageTick));
            }
        }

        // now, set before to the oldest observation
        beforeOrAt = self[addmod(index, 1, 65535)];
        if (!beforeOrAt.initialized) beforeOrAt = self[0];

        // ensure that the target is chronologically at or after the oldest observation
        require(lte(time, beforeOrAt.blockTimestamp, target), 'OLD');

        // if we've reached this point, we have to binary search
        return binarySearch(self, time, target, index);
    }

    /// @dev Reverts if an observation at or before the desired observation timestamp does not exist.
    /// 0 may be passed as `secondsAgo' to return the current cumulative values.
    /// If called with a timestamp falling between two observations, returns the counterfactual accumulator values
    /// at exactly the timestamp between the two observations.
    /// @param self The stored oracle array
    /// @param time The current block timestamp
    /// @param secondsAgo The amount of time to look back, in seconds, at which point to return an observation
    /// @param tick The current tick
    /// @param index The index of the observation that was most recently written to the observations array
    /// @param liquidity The current in-range pool liquidity
    /// @return tickCumulative The tick * time elapsed since the pool was first initialized, as of `secondsAgo`
    /// @return secondsPerLiquidityCumulative The time elapsed / max(1, liquidity) since the pool was first initialized, as of `secondsAgo`
    function observeSingle(
        Observation[65535] storage self,
        uint32 time,
        uint32 secondsAgo,
        int24 tick,
        uint16 index,
        uint128 liquidity
    ) internal view returns (int56 tickCumulative,
                            uint160 secondsPerLiquidityCumulative,
                            uint112 volatilityCumulative ) {
        if (secondsAgo == 0) {
            Observation memory last = self[index];

            Observation storage oldest = self[addmod(index, 1, 65535)];
            if (!oldest.initialized) oldest = self[0];

            int24 averageTick;

            // if (oldest.blockTimestamp <= time - TIME_AGO && time > TIME_AGO){
            if (lte(time, oldest.blockTimestamp, time - TIME_AGO)){
                if (last.blockTimestamp + TIME_AGO > time){
                    (int56 b,,) = observeSingle(
                        self, time, TIME_AGO, tick, index, liquidity
                    );
                    averageTick = int24((last.tickCumulative - b) / (TIME_AGO + last.blockTimestamp - time));
                }
                else {
                    index = index == 0 ? 65535 - 1 : index - 1;
                    averageTick = self[index].initialized ?
                        int24(
                            (last.tickCumulative - self[index].tickCumulative) /
                            (last.blockTimestamp - self[index].blockTimestamp)
                        ) :
                        tick;
                }
            }
            else {
                averageTick = (last.blockTimestamp == oldest.blockTimestamp) ?
                    tick :
                    int24(
                        (last.tickCumulative - oldest.tickCumulative) /
                        (last.blockTimestamp - oldest.blockTimestamp)
                    );
            }
            

            if (last.blockTimestamp != time) last = transform(last, time, tick, liquidity, averageTick);
            return (last.tickCumulative, last.secondsPerLiquidityCumulative, last.volatilityCumulative);
        }

        uint32 target = time - secondsAgo;

        (Observation memory beforeOrAt, Observation memory atOrAfter) =
            getSurroundingObservations(self, time, target, tick, index, liquidity);

        if (target == beforeOrAt.blockTimestamp) {
            // we're at the left boundary
            return (beforeOrAt.tickCumulative, beforeOrAt.secondsPerLiquidityCumulative, beforeOrAt.volatilityCumulative);
        } else if (target == atOrAfter.blockTimestamp) {
            // we're at the right boundary
            return (atOrAfter.tickCumulative, atOrAfter.secondsPerLiquidityCumulative, atOrAfter.volatilityCumulative);
        } else {
            // we're in the middle
            uint32 observationTimeDelta = atOrAfter.blockTimestamp - beforeOrAt.blockTimestamp;
            uint32 targetDelta = target - beforeOrAt.blockTimestamp;
            return (
                beforeOrAt.tickCumulative +
                    ((atOrAfter.tickCumulative - beforeOrAt.tickCumulative) / observationTimeDelta) *
                    targetDelta,
                beforeOrAt.secondsPerLiquidityCumulative +
                    uint160(
                        (uint256(
                            atOrAfter.secondsPerLiquidityCumulative - beforeOrAt.secondsPerLiquidityCumulative
                        ) * targetDelta) / observationTimeDelta
                    ),
                beforeOrAt.volatilityCumulative +
                    ((atOrAfter.volatilityCumulative - beforeOrAt.volatilityCumulative) / observationTimeDelta) *
                    targetDelta
            );
        }
    }

    /// @notice Returns the accumulator values as of each time seconds ago from the given time in the array of `secondsAgos`
    /// @dev Reverts if `secondsAgos` > oldest observation
    /// @param self The stored oracle array
    /// @param time The current block.timestamp
    /// @param secondsAgos Each amount of time to look back, in seconds, at which point to return an observation
    /// @param tick The current tick
    /// @param index The index of the observation that was most recently written to the observations array
    /// @param liquidity The current in-range pool liquidity
    /// @return tickCumulatives The tick * time elapsed since the pool was first initialized, as of each `secondsAgo`
    /// @return secondsPerLiquidityCumulatives The cumulative seconds / max(1, liquidity) since the pool was first initialized, as of each `secondsAgo`
    function observe(
        Observation[65535] storage self,
        uint32 time,
        uint32[] memory secondsAgos,
        int24 tick,
        uint16 index,
        uint128 liquidity
    ) internal view returns(int56[] memory tickCumulatives,
                            uint160[] memory secondsPerLiquidityCumulatives,
                            uint112[] memory volatilityCumulatives) {
        tickCumulatives = new int56[](secondsAgos.length);
        secondsPerLiquidityCumulatives = new uint160[](secondsAgos.length);
        volatilityCumulatives = new uint112[](secondsAgos.length);
        for (uint256 i = 0; i < secondsAgos.length; i++) {
            (tickCumulatives[i], secondsPerLiquidityCumulatives[i], volatilityCumulatives[i]) = observeSingle(
                self,
                time,
                secondsAgos[i],
                tick,
                index,
                liquidity
            );
        }
    }

    /// @notice Returns average volatility in the range from time-TIME_AGO to time
    /// @dev if the oldest observation was written later than time-TIME_AGO returns 0 as average volatility
    /// @param self The stored oracle array
    /// @param time The current block.timestamp
    /// @param tick The current tick
    /// @param index The index of the observation that was most recently written to the observations array
    /// @param liquidity The current in-range pool liquidity
    /// @return TWVolatilityAverage The average volatility in the recent range
    function getVolatilityAverage(
        Observation[65535] storage self,
        uint32 time,
        int24 tick,
        uint16 index,
        uint128 liquidity)
        internal view returns (uint112 TWVolatilityAverage)
    {
        Observation storage oldest = self[addmod(index, 1, 65535)];
        if (!oldest.initialized) oldest = self[0];

        if (lte(time, oldest.blockTimestamp, time - TIME_AGO)){

            (,,uint112 volatilityBefore) = observeSingle(
                self,
                time,
                TIME_AGO,
                tick,
                index,
                liquidity
            );
            (,,uint112 volatilityAfter) = observeSingle(
                self,
                time,
                0,
                tick,
                index,
                liquidity
            );
            return (volatilityAfter - volatilityBefore) / TIME_AGO;
        }
    }

    /// @notice Initialize the oracle array by writing the first slot. Called once for the lifecycle of the observations array
    /// @param self The stored oracle array
    /// @param time The time of the oracle initialization, via block.timestamp truncated to uint32
    function initialize(Observation[65535] storage self, uint32 time)
        internal
    {
        self[0] = Observation({
            blockTimestamp: time,
            tickCumulative: 0,
            secondsPerLiquidityCumulative: 0,
            volatilityCumulative: 0,
            initialized: true
        });
        //grow(self, 1, 2);
    }

    /// @notice Writes an oracle observation to the array
    /// @dev Writable at most once per block. Index represents the most recently written element. index must be tracked externally.
    /// If the index is at the end of the allowable array length (according to cardinality), and the next cardinality
    /// is greater than the current one, cardinality may be increased. This restriction is created to preserve ordering.
    /// @param self The stored oracle array
    /// @param index The index of the observation that was most recently written to the observations array
    /// @param blockTimestamp The timestamp of the new observation
    /// @param tick The active tick at the time of the new observation
    /// @param liquidity The total in-range liquidity at the time of the new observation
    /// @return indexUpdated The new index of the most recently written element in the oracle array
     function write(
        Observation[65535] storage self,
        uint16 index,
        uint32 blockTimestamp,
        int24 tick,
        uint128 liquidity
    ) internal returns (uint16 indexUpdated) {
        Observation storage last = self[index];

        // early return if we've already written an observation this block
        if (last.blockTimestamp == blockTimestamp) return index;

        last = self[addmod(index, 1, 65535)];
        if (!last.initialized) last = self[0];

        int24 averageTick;

        // if (last.blockTimestamp <= blockTimestamp - TIME_AGO && blockTimestamp > TIME_AGO){
        if (lte(blockTimestamp, last.blockTimestamp, blockTimestamp - TIME_AGO)) {
            last = self[index];
            if (last.blockTimestamp + TIME_AGO > blockTimestamp) {
                (int56 b,, ) = observeSingle(
                    self, blockTimestamp, TIME_AGO, tick, index, liquidity
                );
                averageTick = int24((last.tickCumulative - b) / (TIME_AGO + last.blockTimestamp - blockTimestamp));
            }
            else {
                uint16 _index = index == 0 ? 65535 - 1 : index - 1;
                averageTick = self[_index].initialized ?
                int24(
                    (last.tickCumulative -  self[_index].tickCumulative) /
                    (last.blockTimestamp - self[_index].blockTimestamp)
                    ) :
                tick;
            }
        }
        else {
            averageTick = last.blockTimestamp == self[index].blockTimestamp ?
            tick :
            int24((self[index].tickCumulative - last.tickCumulative) / (self[index].blockTimestamp - last.blockTimestamp));

            last = self[index];
        }

        indexUpdated = uint16(addmod(index, 1, 65535));
        self[indexUpdated] = transform(last, blockTimestamp, tick, liquidity, averageTick);
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 0
  },
  "metadata": {
    "bytecodeHash": "none"
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