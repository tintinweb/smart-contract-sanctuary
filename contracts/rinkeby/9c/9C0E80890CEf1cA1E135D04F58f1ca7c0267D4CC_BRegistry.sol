//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "./EnumerableSet.sol";
import "../interfaces/IBPool.sol";
import "../interfaces/IBFactory.sol";

/**
 * @title BRegistry
 * @author Protofire
 * @dev Stores a registry of Balancer Pool addresses for a given token address pair. Pools can be
 * sorted in order of liquidity and queried via view functions. Used in combination with the Exchange
 * Proxy swaps can be sourced and exectured entirely on-chain.
 *
 * This code is based on Balancer On Chain Registry contract
 * https://docs.balancer.finance/smart-contracts/on-chain-registry
 * (https://etherscan.io/address/0x7226DaaF09B3972320Db05f5aB81FF38417Dd687#code)
 */
contract BRegistry {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct PoolPairInfo {
        uint80 weight1;
        uint80 weight2;
        uint80 swapFee;
        uint256 liq;
    }

    struct SortedPools {
        EnumerableSet.AddressSet pools;
        bytes32 indices;
    }

    event PoolTokenPairAdded(address indexed pool, address indexed token1, address indexed token2);

    event IndicesUpdated(address indexed token1, address indexed token2, bytes32 oldIndices, bytes32 newIndices);

    uint256 private constant BONE = 10**18;
    uint256 private constant MAX_SWAP_FEE = (3 * BONE) / 100;

    mapping(bytes32 => SortedPools) private _pools;
    mapping(address => mapping(bytes32 => PoolPairInfo)) private _infos;

    IBFactory public bfactory;

    constructor(address _bfactory) {
        bfactory = IBFactory(_bfactory);
    }

    function getPairInfo(
        address pool,
        address fromToken,
        address destToken
    )
        external
        view
        returns (
            uint256 weight1,
            uint256 weight2,
            uint256 swapFee
        )
    {
        bytes32 key = _createKey(fromToken, destToken);
        PoolPairInfo memory info = _infos[pool][key];
        return (info.weight1, info.weight2, info.swapFee);
    }

    function getPoolsWithLimit(
        address fromToken,
        address destToken,
        uint256 offset,
        uint256 limit
    ) public view returns (address[] memory result) {
        bytes32 key = _createKey(fromToken, destToken);
        result = new address[](Math.min(limit, _pools[key].pools.values.length - offset));
        for (uint256 i = 0; i < result.length; i++) {
            result[i] = _pools[key].pools.values[offset + i];
        }
    }

    function getBestPools(address fromToken, address destToken) external view returns (address[] memory pools) {
        return getBestPoolsWithLimit(fromToken, destToken, 32);
    }

    function getBestPoolsWithLimit(
        address fromToken,
        address destToken,
        uint256 limit
    ) public view returns (address[] memory pools) {
        bytes32 key = _createKey(fromToken, destToken);
        bytes32 indices = _pools[key].indices;
        uint256 len = 0;
        while (indices[len] > 0 && len < Math.min(limit, indices.length)) {
            len++;
        }

        pools = new address[](len);
        for (uint256 i = 0; i < len; i++) {
            uint256 index = uint256(uint8(indices[i])).sub(1);
            pools[i] = _pools[key].pools.values[index];
        }
    }

    // Add and update registry

    function addPoolPair(
        address pool,
        address token1,
        address token2
    ) public returns (uint256 listed) {
        require(bfactory.isBPool(pool), "ERR_NOT_BPOOL");

        uint256 swapFee = IBPool(pool).getSwapFee();
        require(swapFee <= MAX_SWAP_FEE, "ERR_FEE_TOO_HIGH");

        bytes32 key = _createKey(token1, token2);
        _pools[key].pools.add(pool);

        if (token1 < token2) {
            _infos[pool][key] = PoolPairInfo({
                weight1: uint80(IBPool(pool).getDenormalizedWeight(token1)),
                weight2: uint80(IBPool(pool).getDenormalizedWeight(token2)),
                swapFee: uint80(swapFee),
                liq: uint256(0)
            });
        } else {
            _infos[pool][key] = PoolPairInfo({
                weight1: uint80(IBPool(pool).getDenormalizedWeight(token2)),
                weight2: uint80(IBPool(pool).getDenormalizedWeight(token1)),
                swapFee: uint80(swapFee),
                liq: uint256(0)
            });
        }

        emit PoolTokenPairAdded(pool, token1, token2);

        listed++;
    }

    function addPools(
        address[] calldata pools,
        address token1,
        address token2
    ) external returns (uint256[] memory listed) {
        listed = new uint256[](pools.length);
        for (uint256 i = 0; i < pools.length; i++) {
            listed[i] = addPoolPair(pools[i], token1, token2);
        }
    }

    function sortPools(address[] calldata tokens, uint256 lengthLimit) external {
        for (uint256 i = 0; i < tokens.length; i++) {
            for (uint256 j = i + 1; j < tokens.length; j++) {
                bytes32 key = _createKey(tokens[i], tokens[j]);
                address[] memory pools = getPoolsWithLimit(tokens[i], tokens[j], 0, Math.min(256, lengthLimit));
                uint256[] memory effectiveLiquidity = _getEffectiveLiquidityForPools(tokens[i], tokens[j], pools);

                bytes32 indices = _buildSortIndices(effectiveLiquidity);

                // console.logBytes32(indices);

                if (indices != _pools[key].indices) {
                    emit IndicesUpdated(
                        tokens[i] < tokens[j] ? tokens[i] : tokens[j],
                        tokens[i] < tokens[j] ? tokens[j] : tokens[i],
                        _pools[key].indices,
                        indices
                    );
                    _pools[key].indices = indices;
                }
            }
        }
    }

    function sortPoolsWithPurge(address[] calldata tokens, uint256 lengthLimit) external {
        for (uint256 i = 0; i < tokens.length; i++) {
            for (uint256 j = i + 1; j < tokens.length; j++) {
                bytes32 key = _createKey(tokens[i], tokens[j]);
                address[] memory pools = getPoolsWithLimit(tokens[i], tokens[j], 0, Math.min(256, lengthLimit));
                uint256[] memory effectiveLiquidity = _getEffectiveLiquidityForPoolsPurge(tokens[i], tokens[j], pools);
                bytes32 indices = _buildSortIndices(effectiveLiquidity);

                if (indices != _pools[key].indices) {
                    emit IndicesUpdated(
                        tokens[i] < tokens[j] ? tokens[i] : tokens[j],
                        tokens[i] < tokens[j] ? tokens[j] : tokens[i],
                        _pools[key].indices,
                        indices
                    );
                    _pools[key].indices = indices;
                }
            }
        }
    }

    // Internal

    function _createKey(address token1, address token2) internal pure returns (bytes32) {
        return
            bytes32(
                (uint256(uint128((token1 < token2) ? token1 : token2)) << 128) |
                    (uint256(uint128((token1 < token2) ? token2 : token1)))
            );
    }

    function _getEffectiveLiquidityForPools(
        address token1,
        address token2,
        address[] memory pools
    ) internal view returns (uint256[] memory effectiveLiquidity) {
        effectiveLiquidity = new uint256[](pools.length);
        for (uint256 i = 0; i < pools.length; i++) {
            bytes32 key = _createKey(token1, token2);
            PoolPairInfo memory info = _infos[pools[i]][key];
            if (token1 < token2) {
                // we define effective liquidity as b2 * w1 / (w1 + w2)
                effectiveLiquidity[i] = bdiv(uint256(info.weight1), uint256(info.weight1).add(uint256(info.weight2)));
                effectiveLiquidity[i] = effectiveLiquidity[i].mul(IBPool(pools[i]).getBalance(token2));
                // console.log("1. %s: %s", pools[i], effectiveLiquidity[i]);
            } else {
                effectiveLiquidity[i] = bdiv(uint256(info.weight2), uint256(info.weight1).add(uint256(info.weight2)));
                effectiveLiquidity[i] = effectiveLiquidity[i].mul(IBPool(pools[i]).getBalance(token2));
                // console.log("2. %s: %s", pools[i], effectiveLiquidity[i]);
            }
        }
    }

    // Calculates total liquidity for all existing token pair pools
    // Removes any that are below threshold
    function _getEffectiveLiquidityForPoolsPurge(
        address token1,
        address token2,
        address[] memory pools
    ) public returns (uint256[] memory effectiveLiquidity) {
        uint256 totalLiq = 0;
        bytes32 key = _createKey(token1, token2);

        // Store each pools liquidity and sum total liquidity
        for (uint256 i = 0; i < pools.length; i++) {
            PoolPairInfo memory info = _infos[pools[i]][key];
            if (token1 < token2) {
                // we define effective liquidity as b2 * w1 / (w1 + w2)
                _infos[pools[i]][key].liq = bdiv(
                    uint256(info.weight1),
                    uint256(info.weight1).add(uint256(info.weight2))
                );
                _infos[pools[i]][key].liq = _infos[pools[i]][key].liq.mul(IBPool(pools[i]).getBalance(token2));
                totalLiq = totalLiq.add(_infos[pools[i]][key].liq);
                // console.log("1. %s: %s", pools[i], _infos[pools[i]][key].liq);
            } else {
                _infos[pools[i]][key].liq = bdiv(
                    uint256(info.weight2),
                    uint256(info.weight1).add(uint256(info.weight2))
                );
                _infos[pools[i]][key].liq = _infos[pools[i]][key].liq.mul(IBPool(pools[i]).getBalance(token2));
                totalLiq = totalLiq.add(_infos[pools[i]][key].liq);
                // console.log("2. %s: %s", pools[i], _infos[pools[i]][key].liq);
            }
        }

        uint256 threshold = bmul(totalLiq, ((10 * BONE) / 100));
        // console.log("totalLiq: %s, Thresh: %s", totalLiq, threshold);

        // Delete any pools that aren't greater than threshold (10% of total)
        for (uint256 i = 0; i < _pools[key].pools.length(); i++) {
            //console.log("Pool: %s, %s", _pools[key].pools.values[i], info.liq);
            if (_infos[_pools[key].pools.values[i]][key].liq < threshold) {
                _pools[key].pools.remove(_pools[key].pools.values[i]);
            }
        }

        effectiveLiquidity = new uint256[](_pools[key].pools.length());

        // pool.remove reorders pools so need to use correct liq for index
        for (uint256 i = 0; i < _pools[key].pools.length(); i++) {
            // console.log(_pools[key].pools.values[i]);
            effectiveLiquidity[i] = _infos[_pools[key].pools.values[i]][key].liq;
        }
    }

    function bdiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "ERR_DIV_ZERO");
        uint256 c0 = a * BONE;
        require(a == 0 || c0 / a == BONE, "ERR_DIV_INTERNAL"); // bdiv overflow
        uint256 c1 = c0 + (b / 2);
        require(c1 >= c0, "ERR_DIV_INTERNAL"); //  badd require
        uint256 c2 = c1 / b;
        return c2;
    }

    function bmul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c0 = a * b;
        require(a == 0 || c0 / a == b, "ERR_MUL_OVERFLOW");
        uint256 c1 = c0 + (BONE / 2);
        require(c1 >= c0, "ERR_MUL_OVERFLOW");
        uint256 c2 = c1 / BONE;
        return c2;
    }

    function _buildSortIndices(uint256[] memory effectiveLiquidity) internal pure returns (bytes32) {
        uint256 result = 0;
        uint256 prevEffectiveLiquidity = uint256(-1);
        for (uint256 i = 0; i < Math.min(effectiveLiquidity.length, 32); i++) {
            uint256 bestIndex = 0;
            for (uint256 j = 0; j < effectiveLiquidity.length; j++) {
                if (
                    (effectiveLiquidity[j] > effectiveLiquidity[bestIndex] &&
                        effectiveLiquidity[j] < prevEffectiveLiquidity) ||
                    effectiveLiquidity[bestIndex] >= prevEffectiveLiquidity
                ) {
                    bestIndex = j;
                }
            }
            prevEffectiveLiquidity = effectiveLiquidity[bestIndex];
            result |= (bestIndex + 1) << (248 - i * 8);
        }
        return bytes32(result);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * As of v2.5.0, only `address` sets are supported.
 *
 * Include with `using EnumerableSet for EnumerableSet.AddressSet;`.
 *
 * _Available since v2.5.0._
 *
 * @author Alberto Cuesta Cañada
 */
library EnumerableSet {
    struct AddressSet {
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(address => uint256) index;
        address[] values;
    }

    /**
     * @dev Add a value to a set. O(1).
     * Returns false if the value was already in the set.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        if (!contains(set, value)) {
            set.values.push(value);
            set.index[value] = set.values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     * Returns false if the value was not present in the set.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        if (contains(set, value)) {
            uint256 toDeleteIndex = set.index[value] - 1;
            uint256 lastIndex = set.values.length - 1;

            // If the element we're deleting is the last one, we can just remove it without doing a swap
            if (lastIndex != toDeleteIndex) {
                address lastValue = set.values[lastIndex];

                // Move the last value to the index where the deleted value is
                set.values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set.index[lastValue] = toDeleteIndex + 1; // All indexes are 1-based
            }

            // Delete the index entry for the deleted value
            delete set.index[value];

            // Delete the old entry for the moved value
            set.values.pop();

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return set.index[value] != 0;
    }

    /**
     * @dev Returns an array with all values in the set. O(N).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.

     * WARNING: This function may run out of gas on large sets: use {length} and
     * {get} instead in these cases.
     */
    function enumerate(AddressSet storage set) internal view returns (address[] memory) {
        address[] memory output = new address[](set.values.length);
        for (uint256 i; i < set.values.length; i++) {
            output[i] = set.values[i];
        }
        return output;
    }

    /**
     * @dev Returns the number of elements on the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return set.values.length;
    }

    /** @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function get(AddressSet storage set, uint256 index) internal view returns (address) {
        return set.values[index];
    }
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

/**
 * @title IBPool
 * @author Protofire
 * @dev Balancer BPool contract interface.
 *
 */
interface IBPool {
    function isPublicSwap() external view returns (bool);

    function isFinalized() external view returns (bool);

    function isBound(address t) external view returns (bool);

    function getNumTokens() external view returns (uint256);

    function getCurrentTokens() external view returns (address[] memory tokens);

    function getFinalTokens() external view returns (address[] memory tokens);

    function getDenormalizedWeight(address token) external view returns (uint256);

    function getTotalDenormalizedWeight() external view returns (uint256);

    function getNormalizedWeight(address token) external view returns (uint256);

    function getBalance(address token) external view returns (uint256);

    function getSwapFee() external view returns (uint256);

    function getController() external view returns (address);

    function setSwapFee(uint256 swapFee) external;

    function setController(address manager) external;

    function setPublicSwap(bool public_) external;

    function finalize() external;

    function bind(
        address token,
        uint256 balance,
        uint256 denorm
    ) external;

    function rebind(
        address token,
        uint256 balance,
        uint256 denorm
    ) external;

    function unbind(address token) external;

    function gulp(address token) external;

    function getSpotPrice(address tokenIn, address tokenOut) external view returns (uint256 spotPrice);

    function getSpotPriceSansFee(address tokenIn, address tokenOut) external view returns (uint256 spotPrice);

    function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn) external;

    function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut) external;

    function swapExactAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        address tokenOut,
        uint256 minAmountOut,
        uint256 maxPrice
    ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter);

    function swapExactAmountOut(
        address tokenIn,
        uint256 maxAmountIn,
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 maxPrice
    ) external returns (uint256 tokenAmountIn, uint256 spotPriceAfter);

    function joinswapExternAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        uint256 minPoolAmountOut
    ) external returns (uint256 poolAmountOut);

    function joinswapPoolAmountOut(
        address tokenIn,
        uint256 poolAmountOut,
        uint256 maxAmountIn
    ) external returns (uint256 tokenAmountIn);

    function exitswapPoolAmountIn(
        address tokenOut,
        uint256 poolAmountIn,
        uint256 minAmountOut
    ) external returns (uint256 tokenAmountOut);

    function exitswapExternAmountOut(
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 maxPoolAmountIn
    ) external returns (uint256 poolAmountIn);

    function totalSupply() external view returns (uint256);

    function balanceOf(address whom) external view returns (uint256);

    function allowance(address src, address dst) external view returns (uint256);

    function approve(address dst, uint256 amt) external returns (bool);

    function transfer(address dst, uint256 amt) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amt
    ) external returns (bool);

    function calcSpotPrice(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 swapFee
    ) external pure returns (uint256 spotPrice);

    function calcOutGivenIn(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 tokenAmountIn,
        uint256 swapFee
    ) external pure returns (uint256 tokenAmountOut);

    function calcInGivenOut(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 tokenAmountOut,
        uint256 swapFee
    ) external pure returns (uint256 tokenAmountIn);

    function calcPoolOutGivenSingleIn(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 tokenAmountIn,
        uint256 swapFee
    ) external pure returns (uint256 poolAmountOut);

    function calcSingleInGivenPoolOut(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 poolAmountOut,
        uint256 swapFee
    ) external pure returns (uint256 tokenAmountIn);

    function calcSingleOutGivenPoolIn(
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 poolAmountIn,
        uint256 swapFee
    ) external pure returns (uint256 tokenAmountOut);

    function calcPoolInGivenSingleOut(
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 tokenAmountOut,
        uint256 swapFee
    ) external pure returns (uint256 poolAmountIn);
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

import "./IBPool.sol";

interface IBFactory {
    event LOG_NEW_POOL(address indexed caller, address indexed pool);

    function isBPool(address b) external view returns (bool);

    function newBPool() external returns (IBPool);

    function setExchProxy(address exchProxy) external;

    function setOperationsRegistry(address operationsRegistry) external;

    function setPermissionManager(address permissionManager) external;

    function setAuthorization(address _authorization) external;
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