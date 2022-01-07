// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

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
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAggregatorV3 {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IUniswapV2Factory {
    function getPair(address token0, address token1) external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.9;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../external/chainlink/IAggregatorV3.sol";

interface IChainlinkOracle {
    /// @notice Checks if token can be queried for price
    /// @param token token address
    /// @return `true` if token is allowed, `false` o/w
    function isAllowedToken(address token) external view returns (bool);

    /// @notice All allowed tokens
    function tokenAllowlist() external view returns (address[] memory);

    /// @notice Chainlink oracle for a ERC20 token
    /// @param token The address of the ERC20 token
    /// @return Address of the chainlink oracle
    function chainlinkOracles(address token) external view returns (address);

    /// @notice Current spot price for the tokens.
    /// @dev Throws if token is not allowed, or chainlink oracle doesn't have enough data. Required to have token1 > token0.
    /// @param token0 Token with the lower address
    /// @param token1 Token with the higher address
    /// @return priceX96 The price is `token1 / token0`, i.e. how much token1 needed to buy one unit of token0. The price is in X96 format.
    function spotPrice(address token0, address token1) external view returns (uint256 priceX96);

    /// Add a Chainlink price feed for a token
    /// @param tokens ERC20 tokens for the feed
    /// @param oracles Chainlink oracle price feeds (token / USD)
    function addChainlinkOracles(address[] memory tokens, address[] memory oracles) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IMellowOracle {
    /// @notice Gets the spot price for tokens
    /// @dev Out of each suboracle (univ2, chainlink) it extracts spot price. Out of univ3 it extracts spotPrice and average price for
    /// the last n blocks (excluding current block). Then all this values are combined, minPrice is minimum value, maxPrice is maximum
    /// value price is average of these values. It is highly recommended to use this oracle with setting Chainlink + Univ3 or Chainlink + Univ3 + UniV2. All other combinations
    /// might be unsafe and should be used only for dev / test purposes.
    /// @param token0 First token for the price
    /// @param token1 Second token for the price
    /// @return priceX96 Price estimation. The price is `token1 / token0`, i.e. how much token1 needed to buy one unit of token0. The price is in X96 format.
    /// @return minPriceX96 Lower price estimation. The price is `token1 / token0`, i.e. how much token1 needed to buy one unit of token0. The price is in X96 format.
    /// @return maxPriceX96 Upper price estimation. The price is `token1 / token0`, i.e. how much token1 needed to buy one unit of token0. The price is in X96 format.
    function spotPrice(address token0, address token1)
        external
        view
        returns (
            uint256 priceX96,
            uint256 minPriceX96,
            uint256 maxPriceX96
        );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../external/univ2/IUniswapV2Factory.sol";

interface IUniV2Oracle {
    /// @notice Reference to UniV2 factory
    function factory() external returns (IUniswapV2Factory);

    /// @notice UniV3 prices for a token pair
    /// @dev Tokens must be sorted (token 1 > token0). Throws if univ2 pool doesn't exist.
    /// @param token0 Token 0 for price
    /// @param token1 Token 1 for price
    /// @return spotPriceX96 Current UniV3 price
    function spotPrice(address token0, address token1) external view returns (uint256 spotPriceX96);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../external/univ3/IUniswapV3Factory.sol";

interface IUniV3Oracle {
    /// @notice Reference to UniV3 factory
    function factory() external returns (IUniswapV3Factory);

    /// @notice Number of observations for average price
    function observationsForAverage() external returns (uint16);

    /// @notice UniV3 prices for a token pair
    /// @dev Tokens must be sorted (token 1 > token0). Throws if univ3 pool doesn't exist or there's no data to fulfill
    /// observationsForAverage requirement.
    /// @param token0 Token 0 for price
    /// @param token1 Token 1 for price
    /// @return spotPriceX96 Current UniV3 price
    /// @return avgPriceX96 Average UniV3 price in the observation range [-observationsForAverage, -1]. Calculated by averaging ticks and then calculating price.
    function prices(address token0, address token1) external view returns (uint256 spotPriceX96, uint256 avgPriceX96);

    /// @notice Update number of observations for average price
    /// @param newObservationsForAverage New value for observations
    function setObservationsForAverage(uint16 newObservationsForAverage) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./external/FullMath.sol";
import "./ExceptionsLibrary.sol";

/// @notice CommonLibrary shared utilities
library CommonLibrary {
    uint256 constant DENOMINATOR = 10**9;
    uint256 constant PRICE_DENOMINATOR = 10**18;
    uint256 constant YEAR = 365 * 24 * 3600;
    uint256 constant Q128 = 2**128;
    uint256 constant Q96 = 2**96;
    uint256 constant Q48 = 2**48;
    uint256 constant Q160 = 2**160;
    uint256 constant UNI_FEE_DENOMINATOR = 10**6;

    function deviationFactor(uint256 a, uint256 b) internal pure returns (uint256 deviationX96) {
        if (a > b) {
            (a, b) = (b, a);
        }
        if (a == 0) {
            return type(uint256).max;
        }
        if (b / a >= Q160) {
            // overflow for X96 format
            return type(uint256).max;
        }

        deviationX96 = FullMath.mulDiv(b, Q96, a);
    }

    /// @notice Sort addresses using bubble sort. The sorting is done in-place.
    /// @param arr Array of addresses
    function bubbleSort(address[] memory arr) internal pure {
        uint256 l = arr.length;
        for (uint256 i = 0; i < l; ++i) {
            for (uint256 j = i + 1; j < l; ++j) {
                if (arr[i] > arr[j]) {
                    address temp = arr[i];
                    arr[i] = arr[j];
                    arr[j] = temp;
                }
            }
        }
    }

    /// @notice Sort uint256 using bubble sort. The sorting is done in-place.
    /// @param arr Array of uint256
    function bubbleSortUint(uint256[] memory arr) internal pure {
        uint256 l = arr.length;
        for (uint256 i = 0; i < l; ++i) {
            for (uint256 j = i + 1; j < l; ++j) {
                if (arr[i] > arr[j]) {
                    uint256 temp = arr[i];
                    arr[i] = arr[j];
                    arr[j] = temp;
                }
            }
        }
    }

    /// @notice Checks if array of addresses is sorted and all adresses are unique
    /// @param tokens A set of addresses to check
    /// @return `true` if all addresses are sorted and unique, `false` otherwise
    function isSortedAndUnique(address[] memory tokens) internal pure returns (bool) {
        if (tokens.length < 2) {
            return true;
        }
        for (uint256 i = 0; i < tokens.length - 1; ++i) {
            if (tokens[i] >= tokens[i + 1]) {
                return false;
            }
        }
        return true;
    }

    /// @dev
    /// Requires both sets of tokens to be sorted. When tokens are not sorted, it's undefined behavior.
    /// If there is a token in tokensToProject that is not part of tokens and corresponding tokenAmountsToProject > 0, reverts.
    /// Zero token amount is eqiuvalent to missing token
    function projectTokenAmounts(
        address[] memory tokens,
        address[] memory tokensToProject,
        uint256[] memory tokenAmountsToProject
    ) internal pure returns (uint256[] memory) {
        uint256[] memory res = new uint256[](tokens.length);
        uint256 t = 0;
        uint256 tp = 0;
        while ((t < tokens.length) && (tp < tokensToProject.length)) {
            if (tokens[t] < tokensToProject[tp]) {
                res[t] = 0;
                t++;
            } else if (tokens[t] > tokensToProject[tp]) {
                if (tokenAmountsToProject[tp] == 0) {
                    tp++;
                } else {
                    revert("TPS");
                }
            } else {
                res[t] = tokenAmountsToProject[tp];
                t++;
                tp++;
            }
        }
        while (t < tokens.length) {
            res[t] = 0;
            t++;
        }
        return res;
    }

    /// @notice Splits each amount of n tokens from `amounts` into k vaults according to `weights`.
    /// @dev Requires tokens and tokenAmounts to be vector of size n and delegatedTokenAmounts to be k x n matrix
    /// so that delegatedTokenAmounts[i] is a vector of size n
    /// norm is a vector 1 x k
    /// the error is up to k tokens due to rounding
    /// @param amounts Amounts to split, vector n x 1
    /// @param weights Weights of the split, matrix n x k, weights[i] is vector n x 1.
    /// Weights do not need to sum to 1 in each column, but they will be normalized on split.
    function splitAmounts(uint256[] memory amounts, uint256[][] memory weights)
        internal
        pure
        returns (uint256[][] memory)
    {
        uint256 k = weights.length;
        require(k > 0, ExceptionsLibrary.EMPTY_LIST);
        uint256 n = amounts.length;
        require(n > 0, ExceptionsLibrary.EMPTY_LIST);
        uint256[] memory weightsNorm = new uint256[](n);
        for (uint256 i = 0; i < k; ++i) {
            require(weights[i].length == n, ExceptionsLibrary.INVALID_VALUE);
        }
        for (uint256 j = 0; j < n; ++j) {
            weightsNorm[j] = 0;
            for (uint256 i = 0; i < k; ++i) {
                weightsNorm[j] += weights[i][j];
            }
        }
        uint256[][] memory res = new uint256[][](k);
        for (uint256 i = 0; i < k; ++i) {
            res[i] = new uint256[](n);
            for (uint256 j = 0; j < n; ++j) {
                if (weightsNorm[j] == 0) {
                    res[i][j] = amounts[j] / k;
                } else {
                    res[i][j] = (amounts[j] * weights[i][j]) / weightsNorm[j];
                }
            }
        }
        return res;
    }

    function sqrtX96(uint256 xX96) internal pure returns (uint256) {
        uint256 sqX96 = sqrt(xX96);
        return sqX96 << 48;
    }

    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
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
        r = (r + x / r) >> 1;
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @notice Exceptions stores project`s smart-contracts exceptions
library ExceptionsLibrary {
    string constant ADDRESS_ZERO = "AZ";
    string constant VALUE_ZERO = "VZ";
    string constant EMPTY_LIST = "EMPL";
    string constant NOT_FOUND = "NF";
    string constant INIT = "INIT";
    string constant DUPLICATE = "DUP";
    string constant NULL = "NULL";
    string constant TIMESTAMP = "TS";
    string constant FORBIDDEN = "FRB";
    string constant ALLOWLIST = "ALL";
    string constant LIMIT_OVERFLOW = "LIMO";
    string constant LIMIT_UNDERFLOW = "LIMU";
    string constant INVALID_VALUE = "INV";
    string constant INVARIANT = "INVA";
    string constant INVALID_TARGET = "INVTR";
    string constant INVALID_TOKEN = "INVTO";
    string constant LOCK = "LCKD";
    string constant INVALID_INTERFACE = "INVI";
    string constant DISABLED = "DIS";
    string constant INVALID_STATE = "INVST";
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

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
        // diff: original lib works under 0.7.6 with overflows enabled
        unchecked {
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
            // diff: original uint256 twos = -denominator & denominator;
            uint256 twos = uint256(-int256(denominator)) & denominator;
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
        // diff: original lib works under 0.7.6 with overflows enabled
        unchecked {
            result = mulDiv(a, b, denominator);
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../interfaces/oracles/IChainlinkOracle.sol";
import "../interfaces/oracles/IUniV3Oracle.sol";
import "../interfaces/oracles/IUniV2Oracle.sol";
import "../interfaces/oracles/IMellowOracle.sol";
import "../libraries/CommonLibrary.sol";

contract MellowOracle is IMellowOracle {
    IUniV2Oracle public immutable univ2Oracle;
    IUniV3Oracle public immutable univ3Oracle;
    IChainlinkOracle public immutable chainlinkOracle;

    constructor(
        IUniV2Oracle univ2Oracle_,
        IUniV3Oracle univ3Oracle_,
        IChainlinkOracle chainlinkOracle_
    ) {
        univ2Oracle = univ2Oracle_;
        univ3Oracle = univ3Oracle_;
        chainlinkOracle = chainlinkOracle_;
    }

    /// @inheritdoc IMellowOracle
    function spotPrice(address token0, address token1)
        external
        view
        returns (
            uint256 priceX96,
            uint256 minPriceX96,
            uint256 maxPriceX96
        )
    {
        uint256 len;
        if (address(univ3Oracle) != address(0)) {
            len += 2;
        }
        if (address(univ2Oracle) != address(0)) {
            len += 1;
        }
        if (address(chainlinkOracle) != address(0)) {
            len += 1;
        }
        uint256[] memory values = new uint256[](len);
        len = 0;
        if (address(univ3Oracle) != address(0)) {
            (uint256 spotPriceX96, uint256 avgPriceX96) = univ3Oracle.prices(token0, token1);
            values[0] = spotPriceX96;
            values[1] = avgPriceX96;
            len += 2;
        }
        if (address(univ2Oracle) != address(0)) {
            values[len] = univ2Oracle.spotPrice(token0, token1);
            len += 1;
        }
        if (address(chainlinkOracle) != address(0)) {
            values[len] = chainlinkOracle.spotPrice(token0, token1);
        }
        CommonLibrary.bubbleSortUint(values);
        priceX96 = 0;
        for (uint256 i = 0; i < values.length; i++) {
            priceX96 += values[i];
        }
        priceX96 /= values.length;
        minPriceX96 = values[0];
        maxPriceX96 = values[values.length - 1];
    }
}