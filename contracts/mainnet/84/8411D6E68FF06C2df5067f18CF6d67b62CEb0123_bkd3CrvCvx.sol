/**
 *Submitted for verification at Etherscan.io on 2021-09-27
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;



// Part: Error

library Error {
    string constant ADDRESS_WHITELISTED = "address already whitelisted";
    string constant ADMIN_ALREADY_SET = "admin has already been set once";
    string constant ADDRESS_NOT_WHITELISTED = "address not whitelisted";
    string constant ADDRESS_NOT_FOUND = "address not found";
    string constant CONTRACT_INITIALIZED = "contract can only be initialized once";
    string constant CONTRACT_PAUSED = "contract is paused";
    string constant INVALID_AMOUNT = "invalid amount";
    string constant INVALID_INDEX = "invalid index";
    string constant INVALID_VALUE = "invalid msg.value";
    string constant INVALID_SENDER = "invalid msg.sender";
    string constant INVALID_TOKEN = "token address does not match pool's LP token address";
    string constant INVALID_DECIMALS = "incorrect number of decimals";
    string constant INVALID_ARGUMENT = "invalid argument";
    string constant INVALID_IMPLEMENTATION = "invalid pool implementation for given coin";
    string constant INSUFFICIENT_BALANCE = "insufficient balance";
    string constant INSUFFICIENT_STRATEGY_BALANCE = "insufficient strategy balance";
    string constant ROLE_EXISTS = "role already exists";
    string constant UNAUTHORIZED_ACCESS = "unauthorized access";
    string constant SAME_ADDRESS_NOT_ALLOWED = "same address not allowed";
    string constant SELF_TRANSFER_NOT_ALLOWED = "self-transfer not allowed";
    string constant ZERO_ADDRESS_NOT_ALLOWED = "zero address not allowed";
    string constant ZERO_TRANSFER_NOT_ALLOWED = "zero transfer not allowed";
    string constant INSUFFICIENT_THRESHOLD = "insufficient threshold";
    string constant NO_POSITION_EXISTS = "no position exists";
    string constant POSITION_ALREADY_EXISTS = "position already exists";
    string constant PROTOCOL_NOT_FOUND = "protocol not found";
    string constant TOP_UP_FAILED = "top up failed";
    string constant SWAP_PATH_NOT_FOUND = "swap path not found";
    string constant UNDERLYING_NOT_SUPPORTED = "underlying token not supported";
    string constant NOT_ENOUGH_FUNDS_WITHDRAWN = "not enough funds were withdrawn from the pool";
    string constant FAILED_TRANSFER = "transfer failed";
    string constant FAILED_MINT = "mint failed";
    string constant FAILED_REPAY_BORROW = "repay borrow failed";
    string constant FAILED_METHOD_CALL = "method call failed";
    string constant NOTHING_TO_CLAIM = "there is no claimable balance";
    string constant ERC20_BALANCE_EXCEEDED = "ERC20: transfer amount exceeds balance";
    string constant INVALID_MINTER =
        "the minter address of the LP token and the pool address do not match";
    string constant STAKER_VAULT_EXISTS = "a staker vault already exists for the token";
    string constant DEADLINE_NOT_ZERO = "deadline must be 0";
    string constant INSUFFICIENT_UPDATE_BALANCE = "insufficient funds for updating the position";
    string constant SAME_AS_CURRENT = "value must be different to existing value";
    string constant NOT_CAPPED = "the pool is not currently capped";
    string constant ALREADY_CAPPED = "the pool is already capped";
    string constant EXCEEDS_DEPOSIT_CAP = "deposit exceeds deposit cap";
    string constant INVALID_TOKEN_TO_REMOVE = "token can not be removed";
}

// Part: IAdmin

interface IAdmin {
    event NewAdminAdded(address newAdmin);
    event AdminRenounced(address oldAdmin);

    function addAdmin(address newAdmin) external returns (bool);

    function renounceAdmin() external returns (bool);

    function isAdmin(address account) external view returns (bool);
}

// Part: IBooster

interface IBooster {
    function poolInfo(uint256 pid)
        external
        returns (
            address lpToken,
            address token,
            address gauge,
            address crvRewards,
            address stash,
            bool shutdown
        );

    /**
     * @dev `_pid` is the ID of the Convex for a specific Curve LP token.
     */
    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) external returns (bool);

    function withdraw(uint256 _pid, uint256 _amount) external returns (bool);

    function withdrawAll(uint256 _pid) external returns (bool);
}

// Part: ICrvDepositor

interface ICrvDepositor {
    function deposit(
        uint256 _amount,
        bool _lock,
        address _stakeAddress
    ) external;

    function depositAll(bool _lock, address _stakeAddress) external;
}

// Part: ICurveSwap

interface ICurveSwap {
    function get_virtual_price() external view returns (uint256);

    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount) external;

    function remove_liquidity_imbalance(uint256[3] calldata amounts, uint256 max_burn_amount)
        external;

    function remove_liquidity(uint256 _amount, uint256[3] calldata min_amounts) external;

    function exchange(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external;

    function coins(uint256 i) external view returns (address);

    function calc_token_amount(uint256[4] calldata amounts, bool deposit)
        external
        view
        returns (uint256);

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i)
        external
        view
        returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;
}

// Part: IRewardStaking

interface IRewardStaking {
    function stakeFor(address, uint256) external;

    function stake(uint256) external;

    function stakeAll() external returns (bool);

    function withdraw(uint256 amount, bool claim) external returns (bool);

    function withdrawAndUnwrap(uint256 amount, bool claim) external;

    function earned(address account) external view returns (uint256);

    function getReward() external;

    function getReward(address _account, bool _claimExtras) external;

    function extraRewardsLength() external returns (uint256);

    function extraRewards(uint256 _pid) external returns (address);

    function rewardToken() external returns (address);

    function balanceOf(address account) external view returns (uint256);
}

// Part: IStrategy

interface IStrategy {
    function deposit() external payable returns (bool);

    function balance() external view returns (uint256);

    function withdraw(uint256 amount) external returns (bool);

    function withdrawAll() external returns (bool);

    function harvest() external returns (uint256);

    function strategist() external view returns (address);

    function shutdown() external returns (bool);

    function hasPendingFunds() external view returns (bool);
}

// Part: MathFuncs

library MathFuncs {
    /*
     * Natural logarithm of 2, i.e. ln(2) scaled to 1e18
     */
    int256 internal constant LN2 = 693147180559945309;
    uint256 internal constant DECIMAL_SCALE = 1e18;
    uint256 internal constant ONE = DECIMAL_SCALE;

    /*
     * @notice Computes e^x where x is a fixed-point number.
     * It uses a Taylor series approximation with 30 or 50 iterations, which
     * should be precise enough for -5 <= x <= 10.
     * The number of iteration should be increased accordingly for x > 10.
     * using the overloaded `exp(int256 x, uint256 n) returns (uint256)`
     * @param x the number of which to compute the exponent.
     * @return e^x.
     */
    function exp(int256 x) internal pure returns (uint256) {
        unchecked {
            if (x >= int256(ONE) * -5 && x <= int256(ONE) * 10) {
                return exp(x, 30);
            }
            return exp(x, 80);
        }
    }

    /*
     * @notice See `exp(int256 x)` documentation.
     * @param n the number of iteration for the series.
     */
    function exp(int256 x, uint256 n) internal pure returns (uint256) {
        unchecked {
            // TODO: better check for convergence given x and n
            require(x <= int256(ONE) * 20, "exponent too large");
            require(x >= int256(ONE) * -10, "exponent too small");

            uint256 factorial = 1;
            int256 numerator = int256(ONE);
            int256 result = 0;
            for (uint256 k = 1; k <= n; k++) {
                int256 term = numerator / int256(factorial);
                result += term;
                factorial *= k;
                numerator = (numerator * x) / int256(DECIMAL_SCALE);
            }
            return uint256(result);
        }
    }

    /*
     * Computes ln(x) where x is fixed-point number.
     * It uses a Taylor series approximation with `n` iterations, which
     * only works for values of x with range of roughly 0.1 < x < 2.
     * This is useful to compute the "reminder" of log2 where
     * log2(x) = n + log2(reminder), 1 < reminder <= 2.
     * @param x the number of which to compute ln(x), 0.1 <= x < 3.
     * @return ln(x).
     */
    function lnSmall(uint256 x) internal pure returns (int256) {
        unchecked {
            if (x <= ONE / 2 || x >= ONE + ONE / 2) {
                return lnSmall(x, 50);
            }
            return lnSmall(x, 30);
        }
    }

    /*
     * @notice See `lnSmall(uint256 x)` documentation.
     * @param n the number of iteration for the series.
     * TODO: do something about slow convergence for values < 0.1
     */
    function lnSmall(uint256 x, uint256 n) internal pure returns (int256) {
        unchecked {
            require(x < 3 * ONE, "x too large for lnSmall, use ln instead");
            // too slow to converge for values < 0.1, better abort here
            require(x >= ONE / 10, "x too small for lnSmall");

            int256 result = 0;
            int256 x_min_1 = int256(x) - int256(ONE);
            int256 numerator = x_min_1;
            for (int256 k = 1; k <= int256(n); k++) {
                int256 term = numerator / k;
                if (k % 2 == 0) {
                    result -= term;
                } else {
                    result += term;
                }
                numerator = (numerator * x_min_1) / int256(DECIMAL_SCALE);
            }
            return result;
        }
    }

    /*
     * @notice Computes log2(x) where x is fixed-point number.
     * First computes the integer part of the log by iteratively dividing by 2
     * until the number is <= 1.
     * Then uses the taylor series approximation of ln(x) for 1 < x <= 2
     * to compute the decimal part of the log.
     * This has the same constraint as `lnSmall` for small values, i.e.
     * only works for values ~ >= 0.1 but works for any value > 1.
     * @param x the numer of which to compute log2.
     * @return log2(x).
     */
    function logBase2(uint256 x) internal pure returns (int256) {
        // Takes longer to converge for small values (< 0.5)
        unchecked {
            if (x <= ONE / 2) {
                return logBase2(x, 50);
            }
            return logBase2(x, 30);
        }
    }

    /*
     * @notice See `logBase2(uint256 x)` documentation.
     * @param n the number of iteration for the series.
     */
    function logBase2(uint256 x, uint256 n) internal pure returns (int256) {
        unchecked {
            uint256 number = x;
            uint256 y = ONE;
            uint256 integerPart = 0;
            while (number > ONE) {
                number /= 2;
                y /= 2;
                integerPart += ONE;
            }
            int256 decimalPart = (lnSmall((y * x) / DECIMAL_SCALE, n) * int256(DECIMAL_SCALE)) /
                LN2;
            return int256(integerPart) + decimalPart;
        }
    }

    /*
     * @notice Computes the natural logarithm of x, ln(x) by using `logBase2`
     * and a precomputed value for ln(2).
     */
    function ln(uint256 x) internal pure returns (int256) {
        unchecked {
            if (x <= ONE / 2) {
                return ln(x, 50);
            }
            return ln(x, 30);
        }
    }

    /*
     * @notice See `ln(uint256 x)` documentation.
     * @param n the number of iteration for the series.
     */
    function ln(uint256 x, uint256 n) internal pure returns (int256) {
        unchecked {
            return (logBase2(x, n) * LN2) / int256(DECIMAL_SCALE);
        }
    }

    /*
     * Computes base^exponent by using the identity
     * base^exponent = e^(exponent * ln(base))
     * where base > 0.
     * @param base the base of the exponetiation.
     * @param exponent the exponent of the exponetiation.
     * @return base^exponent.
     */

    function pow(uint256 base, int256 exponent) internal pure returns (uint256) {
        unchecked {
            if (base >= ONE / 2 && base < 2 * ONE) {
                return pow(base, exponent, 30);
            }
            return pow(base, exponent, 80);
        }
    }

    /*
     * @notice See `pow(uint256 base, int256 exponent)` documentation.
     * @param n the number of iteration for the series.
     */
    function pow(
        uint256 base,
        int256 exponent,
        uint256 n
    ) internal pure returns (uint256) {
        unchecked {
            if (base == 0) {
                return 0;
            }
            return exp((exponent * ln(base, n)) / int256(DECIMAL_SCALE), n);
        }
    }
}

// Part: OpenZeppelin/[email protected]/Address

/**
 * @dev Collection of functions related to the address type
 */
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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// Part: OpenZeppelin/[email protected]/Context

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// Part: OpenZeppelin/[email protected]/EnumerableSet

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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
}

// Part: OpenZeppelin/[email protected]/IERC20

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

// Part: SaferMath

/*
 * @dev To use functions of this contract, at least one of the numbers must
 * be scaled to `decimalScale`. The result will scaled to `decimalScale`
 * if both numbers are scaled to `decimalScale`, otherwise to the scale
 * of the number not scaled by `decimalScale`
 */
library SaferMath {
    uint256 internal constant decimalScale = 1e18;

    /**
     * @notice Performs a multiplication between two scaled numbers
     */
    function scaledMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * b) / decimalScale;
    }

    /**
     * @notice Performs a division between two scaled numbers
     */
    function scaledDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * decimalScale) / b;
    }

    /**
     * @notice Performs a division between two numbers, rounding up the result
     */
    function scaledDivRoundUp(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * decimalScale + b - 1) / b;
    }
}

// Part: UniswapRouter02

interface UniswapRouter02 {
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function WETH() external pure returns (address);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);
}

// Part: UniswapV2Pair

interface UniswapV2Pair {
    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );
}

// Part: AdminBase

abstract contract AdminBase is IAdmin {
    mapping(address => bool) admins;

    /**
     * @notice Make a function only callable by admins.
     * @dev Fails if msg.sender is not an admin.
     */
    modifier onlyAdmin() {
        require(isAdmin(msg.sender), Error.UNAUTHORIZED_ACCESS);
        _;
    }

    /**
     * @notice Add a new admin.
     * @dev This fails if the newAdmin was added previously.
     * @param newAdmin Address to add as admin.
     * @return `true` if successful.
     */
    function addAdmin(address newAdmin) public override onlyAdmin returns (bool) {
        require(!admins[newAdmin], Error.ROLE_EXISTS);
        admins[newAdmin] = true;
        emit NewAdminAdded(newAdmin);
        return true;
    }

    /**
     * @notice Remove msg.sender from admin list.
     * @return `true` if sucessful.
     */
    function renounceAdmin() external override onlyAdmin returns (bool) {
        admins[msg.sender] = false;
        emit AdminRenounced(msg.sender);
        return true;
    }

    /**
     * @notice Check if an account is admin.
     * @param account Address to check.
     * @return `true` if account is an admin.
     */
    function isAdmin(address account) public view override returns (bool) {
        return admins[account];
    }
}

// Part: OpenZeppelin/[email protected]/ERC20

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// Part: OpenZeppelin/[email protected]/SafeERC20

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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

// Part: Admin

contract Admin is AdminBase {
    constructor(address _admin) {
        admins[_admin] = true;
        emit NewAdminAdded(_admin);
    }
}

// File: bkd3CrvCvx.sol

/**
 * This is the bkd3CRVCVX strategy, which is designed to be used by a Backd ERC20 Vault.
 * The strategy holds 3CRV as the underlying and allocates liquidity to Convex.
 * Rewards received on Convex (CVX, CRV, 3CRV), are sold in part for the underlying.
 * A share of earned CVX is retained on behalf of the Backd community to participate in governance.
 */

contract bkd3CrvCvx is IStrategy, Admin {
    using SaferMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for ERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    event DexUpdated(address token, address newDex);
    event RewardTokenAdded(address token);
    event RewardTokenRemoved(address token);
    event StashedReward(uint256 startTime, uint256 endTime, uint256 stashedAmount);

    uint256 public constant DAI_TARGET = 0;
    uint256 public constant USDC_TARGET = 1;

    modifier onlyVault() {
        require(msg.sender == vault, Error.UNAUTHORIZED_ACCESS);
        _;
    }

    struct RewardStash {
        uint64 startTime;
        uint64 endTime;
        uint128 unvested;
    }

    // @dev `vault` also needs to be set as an admin
    address public immutable vault;

    // Dex contracts
    address public constant uniswap = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public constant sushiSwap = address(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

    // ERC20 tokens
    address public constant cvx = address(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    address public constant crv = address(0xD533a949740bb3306d119CC777fa900bA034cd52);
    address public constant cvxCrv = address(0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7);
    address public constant cvxCrvCrvSushiLpToken =
        address(0x33F6DDAEa2a8a54062E021873bCaEE006CdF4007);
    address public constant weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public constant dai = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    address public constant usdc = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address public constant usdt = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);

    // Curve contracts
    address public constant curvePool = address(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);

    // Convex contracts
    address public constant booster = address(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);
    address public constant crvDepositor = address(0x8014595F2AB54cD7c604B00E9fb932176fDc86Ae);
    IRewardStaking public constant cvxCrvStaking =
        IRewardStaking(address(0x3Fe65692bfCD0e6CF84cB1E7d24108E434A7587e));
    IRewardStaking public immutable crvRewards; // Staking contract for Convex-3CRV deposit token

    uint256 public constant CONVEX_3CRV_PID = 9; // 3Curve pool id on Convex
    address public constant underlying = address(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490); // 3CRV

    address public communityReserve;
    uint256 public crvDumpShare;
    uint256 public cvxGovFee;

    bool public isShutdown;

    uint256 constant REWARDS_VESTING = 7 * 86400; // 1 week

    EnumerableSet.AddressSet private rewardTokens;

    mapping(address => address) public tokenDex;

    RewardStash[] public stashedRewards;
    uint256 public totalStashed; // rewards stashed after being liquidated

    mapping(address => address) public pathTarget; // swap target paths

    address public override strategist;

    constructor(address _vault, address _strategist) Admin(msg.sender) {
        (address lp, , , address _crvRewards, , ) = IBooster(booster).poolInfo(CONVEX_3CRV_PID);
        require(lp == address(underlying), "Incorrect Curve LP token");
        crvRewards = IRewardStaking(_crvRewards);
        strategist = _strategist;
        vault = _vault;

        // approve for Convex deposits
        IERC20(underlying).safeApprove(booster, type(uint256).max);

        // approve for locking CRV for cvxCRV
        IERC20(crv).safeApprove(crvDepositor, type(uint256).max);

        // approve for Curve pool deposits
        IERC20(dai).safeApprove(curvePool, type(uint256).max);
        IERC20(usdc).safeApprove(curvePool, type(uint256).max);
        IERC20(usdt).safeApprove(curvePool, type(uint256).max);

        tokenDex[crv] = sushiSwap; // CRV
        tokenDex[cvx] = sushiSwap; // CXV

        // approve for SushiSwap swaps
        IERC20(crv).safeApprove(sushiSwap, type(uint256).max);
        IERC20(cvx).safeApprove(sushiSwap, type(uint256).max);

        // approve for cvxCRV swaps
        IERC20(cvxCrv).safeApprove(sushiSwap, type(uint256).max);

        // approve cvxCRV staking on Convex
        IERC20(cvxCrv).safeApprove(address(cvxCrvStaking), type(uint256).max);

        // set target paths for DEX swaps
        setPathTarget(crv, DAI_TARGET);
        setPathTarget(cvx, DAI_TARGET);
    }

    /**
     * @notice Deposit all available Curve LP into Convex pool.
     * @dev Curve LP tokens are deposited into Convex and Convex LP tokens are staked for rewards by default.
     */
    function deposit() external payable override onlyAdmin returns (bool) {
        require(msg.value == 0, Error.INVALID_VALUE);
        require(!isShutdown, "Strategy is shut down");

        uint256 currentBalance = _underlyingBalance();
        if (currentBalance == 0) return false;
        IBooster(booster).deposit(CONVEX_3CRV_PID, currentBalance, true); // deposit Curve LP into Convex pool and stake Convex LP
        return true;
    }

    /**
     * @notice Harvests reward tokens and sells these for the underlying.
     * @dev Any underlying harvested is not redeposited by this method.
     * @return Amount of underlying harvested.
     */
    function harvest() external override onlyVault returns (uint256) {
        uint256 oldBalance = _underlyingBalance();
        _claimStashedRewards();

        // claim cvxCRV staking rewards
        uint256 stakedCvxCrv = _stakedBalance();
        if (stakedCvxCrv > 0) cvxCrvStaking.getReward();

        // claim Curve LP token staking rewards
        crvRewards.getReward();

        // process CRV rewards
        _swapForToken(crv, crvDumpShare);

        uint256 crvBalance = IERC20(crv).balanceOf(address(this));
        if (crvBalance > 0) {
            // Checks if we can get a better rate on SushiSwap
            (uint256 reserves0, uint256 reserves1, ) = UniswapV2Pair(cvxCrvCrvSushiLpToken)
                .getReserves();
            // TODO: use curve instead of uniswap to swap crv to cvxCRV
            uint256 amountOut = UniswapRouter02(sushiSwap).getAmountOut(
                crvBalance,
                reserves1,
                reserves0
            );
            if (amountOut > crvBalance) {
                address[] memory path = new address[](2);
                path[0] = crv;
                path[1] = cvxCrv;
                UniswapRouter02(sushiSwap).swapExactTokensForTokens(
                    crvBalance,
                    uint256(0),
                    path,
                    address(this),
                    block.timestamp
                );
                cvxCrvStaking.stakeAll();
            } else {
                ICrvDepositor(crvDepositor).deposit(crvBalance, true, address(cvxCrvStaking)); // Swap CRV for cxvCRV and stake
            }
        }

        uint256 cvxBalance = IERC20(cvx).balanceOf(address(this));
        if (cvxBalance > 0 && cvxGovFee > 0 && communityReserve != address(0)) {
            // tax CVX rewards
            uint256 govShare = cvxBalance.scaledMul(cvxGovFee);
            IERC20(cvx).safeTransfer(communityReserve, govShare);
        }

        // process CVX rewards
        _swapForToken(cvx, MathFuncs.ONE);

        // deposit into Curve pool
        _depositForUnderlying();

        uint256 newBalance = _underlyingBalance();
        return newBalance - oldBalance;
    }

    /**
     * @notice Swaps either CRV or CVX for the underlying.
     * @dev This swaps the dump share of CRV or all of the liquid CVX for the specified token (DAI by default).
     *      The token received is then deposited into the 3Curve pool to receive 3CRV tokens. Any 3CRV is not
     *      redeposited into Convex by this method. The amount if CRV to sell (if CRV is `token`) is determined
     *      by the CRV dump share.
     * @param token Address of the token to swap for the underlying.
     * @param dump Portion to dump if token is CRV.
     */
    function _swapForToken(address token, uint256 dump) internal {
        uint256 currentBalance = IERC20(token).balanceOf(address(this));
        uint256 sellAmount = currentBalance;

        sellAmount = currentBalance.scaledMul(dump);

        if (sellAmount == 0) return;

        address[] memory path = new address[](3);
        path[0] = token;
        path[1] = weth;
        path[2] = pathTarget[token];

        UniswapRouter02(tokenDex[token]).swapExactTokensForTokens(
            sellAmount,
            uint256(0),
            path,
            address(this),
            block.timestamp
        );
    }

    function _depositForUnderlying() internal {
        // redeposit received tokens for underlying
        uint256 daiBalance = IERC20(dai).balanceOf(address(this));
        uint256 usdcBalance = IERC20(usdc).balanceOf(address(this));
        uint256 usdtBalance = IERC20(usdt).balanceOf(address(this));
        if (daiBalance > 0 || usdcBalance > 0 || usdtBalance > 0) {
            // mint 3CRV
            ICurveSwap(curvePool).add_liquidity([daiBalance, usdcBalance, usdtBalance], 0);
        }
    }

    /**
     * @notice Unstake an amount of staked cvxCRV from Convex rewards contract.
     * @dev The unstaked cvxCRV is not swapped for CRV.
     * @param amount Amount of cxvCRV to unstake.
     * @return True if unstaking was succesful.
     */
    function _unstakeCvxCrv(uint256 amount) internal returns (bool) {
        require(_stakedBalance() >= amount, Error.INSUFFICIENT_BALANCE);
        cvxCrvStaking.withdraw(amount, false);
        return true;
    }

    /**
     * @notice Liquidates an amount of a token for the underlying.
     * @dev Liquidated funds are paid out immediately if the caller is the vault.
     * @param token Token to liquidate.
     * @param amount Amount of token that should be liquidated.
     * @return Amount of underlying received.
     */
    function liquidate(address token, uint256 amount) external onlyAdmin returns (uint256) {
        return _liquidate(token, amount);
    }

    function _liquidate(address token, uint256 amount) internal returns (uint256) {
        if (amount == 0) return 0;
        uint256 oldBal = _underlyingBalance();

        if (token == cvxCrv) {
            _unstakeCvxCrv(amount);
            uint256 cvxCrvBalance = IERC20(cvxCrv).balanceOf(address(this));
            if (cvxCrvBalance > 0) {
                // swap cvxCRV --> CRV
                address[] memory path = new address[](2);
                path[0] = cvxCrv;
                path[1] = crv;
                // TODO: use Curve
                UniswapRouter02(sushiSwap).swapExactTokensForTokens(
                    cvxCrvBalance,
                    uint256(0),
                    path,
                    address(this),
                    block.timestamp
                );
                _swapForToken(crv, MathFuncs.ONE);
                _depositForUnderlying();
            }
        } else {
            // check reward tokens
            if (rewardTokens.contains(token)) {
                uint256 rewardTokenBalance = IERC20(token).balanceOf(address(this));
                if (rewardTokenBalance < amount) return 0;
                address[] memory path = new address[](3);
                address target = pathTarget[token];
                path[0] = token;
                path[1] = weth;
                path[2] = target;
                UniswapRouter02(tokenDex[token]).swapExactTokensForTokens(
                    rewardTokenBalance,
                    uint256(0),
                    path,
                    address(this),
                    block.timestamp
                );

                // redeposit received tokens for underlying
                uint256 daiBalance = target == dai ? IERC20(target).balanceOf(address(this)) : 0;
                uint256 usdcBalance = target == usdc ? IERC20(target).balanceOf(address(this)) : 0;
                uint256 usdtBalance = target == usdt ? IERC20(target).balanceOf(address(this)) : 0;
                if (daiBalance > 0 || usdcBalance > 0 || usdtBalance > 0) {
                    // mint 3CRV
                    ICurveSwap(curvePool).add_liquidity([daiBalance, usdcBalance, usdtBalance], 0);
                }
            }
        }

        uint256 newBal = _underlyingBalance();
        uint256 liquidated = newBal - oldBal;
        if (liquidated == 0) return 0;

        if (msg.sender == vault) {
            IERC20(underlying).safeTransfer(vault, liquidated);
        } else {
            // add liquidated amount to stashed rewards
            uint256 endTime = block.timestamp + REWARDS_VESTING;
            _stashReward(block.timestamp, endTime, liquidated);
        }
        return liquidated;
    }

    function _stashReward(
        uint256 startTime,
        uint256 endTime,
        uint256 amount
    ) internal {
        stashedRewards.push(RewardStash(uint64(startTime), uint64(endTime), uint128(amount)));
        totalStashed += amount;
        emit StashedReward(startTime, endTime, amount);
    }

    /**
     * @notice Liquidates all assets held by the strategy for the underlying.
     */
    function liquidateAll() external onlyAdmin returns (bool) {
        _liquidateAll();
        return true;
    }

    function _liquidateAll() internal {
        uint256 oldBal = _underlyingBalance();
        uint256 cvxCrvBalance = _stakedBalance();
        if (cvxCrvBalance > 0) {
            _liquidate(cvxCrv, cvxCrvBalance); // unstake and liquidate
        }

        for (uint256 i = 0; i < rewardTokens.length(); i++) {
            address rewardToken = rewardTokens.at(i);
            uint256 rewardTokenBalance = IERC20(rewardToken).balanceOf(address(this));
            if (rewardTokenBalance == 0) continue;
            _liquidate(rewardToken, rewardTokenBalance);
        }

        uint256 newBal = _underlyingBalance();
        uint256 liquidated = newBal - oldBal;
        if (liquidated == 0) return;

        if (msg.sender == vault) {
            IERC20(underlying).safeTransfer(vault, liquidated);
        } else {
            // add liquidated amount to stashed rewards
            uint256 endTime = block.timestamp + REWARDS_VESTING;
            _stashReward(block.timestamp, endTime, liquidated);
        }
    }

    function _claimStashedRewards() internal {
        uint256 length = stashedRewards.length;
        if (length == 0) return;
        uint256 totalVested;
        uint256 count;
        uint256[] memory indexesToRemove = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            RewardStash storage stash = stashedRewards[i];
            uint256 endTime = stash.endTime;
            uint256 startTime = stash.startTime;
            if (block.timestamp >= endTime) {
                totalVested += stash.unvested;
                indexesToRemove[count] = i;
                count += 1;
                continue;
            }

            uint256 timeElapsed = block.timestamp - startTime;
            uint256 totalTime = endTime - startTime;
            uint256 claimed = uint256(stash.unvested).scaledMul(timeElapsed.scaledDiv(totalTime));
            totalVested += claimed;
            stash.unvested -= uint128(claimed);
            stash.startTime = uint64(block.timestamp);
        }

        totalStashed -= totalVested;

        if (count > 0) {
            // delete stashes from list
            for (uint256 i = count; i > 0; i--) {
                uint256 j = indexesToRemove[i - 1];
                stashedRewards[j] = stashedRewards[stashedRewards.length - 1];
                stashedRewards.pop();
            }
        }
    }

    /**
     * @dev Get the balance of the underlying including any vested stashed rewards.
     *      `totalStashed` is the unvested underlying. This gets updated on `claimStashedRewards`.
     */
    function _underlyingBalance() internal view returns (uint256) {
        uint256 currentBalance = IERC20(underlying).balanceOf(address(this));
        return currentBalance - totalStashed;
    }

    /**
     * @dev Get the balance of the underlying staked in the Curve pool
     */
    function _stakedBalance() internal view returns (uint256) {
        return cvxCrvStaking.balanceOf(address(this));
    }

    /**
     * @notice Withdraw an amount of underlying to the vault.
     * @dev This can only be called by the vault.
     *      If the amount is not available, it will be made liquid.
     * @param amount Amount of underlying to withdraw.
     * @return True if successful withdrawal.
     */
    function withdraw(uint256 amount) external override onlyVault returns (bool) {
        _withdraw(amount);
        return true;
    }

    function _withdraw(uint256 amount) internal {
        uint256 idleBalance = _underlyingBalance();
        if (idleBalance >= amount) {
            IERC20(underlying).safeTransfer(vault, amount);
            return;
        }
        uint256 requiredUnderlyingAmount = amount - idleBalance;
        // unstake Curve LP from Convex (not claiming rewards)
        require(
            crvRewards.balanceOf(address(this)) >= requiredUnderlyingAmount,
            Error.INSUFFICIENT_STRATEGY_BALANCE
        );
        crvRewards.withdraw(requiredUnderlyingAmount, false); // withdraw Convex pool LP tokens
        IBooster(booster).withdraw(CONVEX_3CRV_PID, requiredUnderlyingAmount); // burn Convex LP tokens for underlying
        uint256 currentBalance = IERC20(underlying).balanceOf(address(this));
        require(currentBalance >= amount, Error.INSUFFICIENT_STRATEGY_BALANCE);
        IERC20(underlying).safeTransfer(vault, amount);
    }

    /**
     * @notice Withdraw all underlying to vault.
     * @dev This does not liquidate reward tokens and only considers
     *      idle underlying or staked underlying.
     */
    function withdrawAll() external override onlyAdmin returns (bool) {
        uint256 totalBalance = balance();
        _withdraw(totalBalance);
        return true;
    }

    /**
     * @notice Set the DEX that should be used for swapping for a specific coin.
     *         If Uniswap is active, it will switch to SushiSwap and vice versa.
     * @dev Only SushiSwap and Uniswap are supported.
     * @param token Address of token for which the DEX should be updated.
     */
    function swapDex(address token) external onlyAdmin returns (bool) {
        address currentDex = tokenDex[token];
        require(currentDex != address(0), "no dex has been set for token");
        address newDex = currentDex == sushiSwap ? uniswap : sushiSwap;
        setDex(token, newDex);
        IERC20(token).safeApprove(currentDex, 0);
        IERC20(token).safeApprove(newDex, type(uint256).max);
        return true;
    }

    function setDex(address token, address dex) internal {
        tokenDex[token] = dex;
        emit DexUpdated(token, dex);
    }

    /**
     * @notice Add a reward token to list of extra reward tokens.
     * @dev These are tokens that are not the main assets of the strategy. For instance, temporary incentives.
     * @param token Address of token to add to reward token list.
     * @param id ID for target path (the token that should be swapped to).
     */
    function addRewardToken(address token, uint256 id) external onlyAdmin returns (bool) {
        require(
            token != cvx && token != cvxCrv && token != underlying && token != crv,
            "Invalid token to add"
        );
        require(id <= 2, "Invalid target path id");
        if (rewardTokens.contains(token)) return false;
        rewardTokens.add(token);
        setPathTarget(token, id);
        setDex(token, sushiSwap);

        // approve for swaps (default AMM is SushiSwap)
        IERC20(token).safeApprove(sushiSwap, 0);
        IERC20(token).safeApprove(sushiSwap, type(uint256).max);

        emit RewardTokenAdded(token);
        return true;
    }

    function withdrawAllToVault() external onlyAdmin returns (bool) {
        // strategy must be shut down
        if (!isShutdown) return false;
        _claimStashedRewards();
        _liquidateAll();
        uint256 currentBalance = _underlyingBalance();
        if (currentBalance == 0) return false;
        IERC20(underlying).safeTransfer(vault, currentBalance);
        return true;
    }

    /**
     * @notice Remove a reward token.
     * @param token Address of token to remove from reward token list.
     */
    function removeRewardToken(address token) external onlyAdmin returns (bool) {
        if (rewardTokens.remove(token)) {
            emit RewardTokenRemoved(token);
            return true;
        }
        return false;
    }

    /**
     * @notice Get the total underlying balance of the strategy.
     * @dev This only includes idle underlying and underlying deposited on Convex.
     */
    function balance() public view override returns (uint256) {
        uint256 currentBalance = _underlyingBalance();
        return crvRewards.balanceOf(address(this)) + currentBalance;
    }

    /**
     * @notice Returns true if the strategy has funds that are still locked or vested
     */
    function hasPendingFunds() external view override returns (bool) {
        return totalStashed > 0;
    }

    /**
     * @notice Get strategy name.
     */
    function name() external pure returns (string memory) {
        return "Strategy3CRV-CVX";
    }

    // Setters

    /**
     * @notice Set the address of the communit reserve.
     * @dev This can only be set once. CVX will be taxed and allocated to the reserve,
     *      such that Backd can participate in Convex governance.
     * @param _communityReserve Address of the community reserve.
     * @return True if reserve was successfully set.
     */
    function setCommunityReserve(address _communityReserve) external onlyAdmin returns (bool) {
        require(communityReserve == address(0), Error.ROLE_EXISTS);
        communityReserve = _communityReserve;
        return true;
    }

    /**
     * @notice Set amount of CRV rewards that should be sold for the underlying.
     * @dev The remainder of CRV rewards (if any) will be deposited for cvxCRV and staked on Convex.
     * @param _crvDumpShare Percentage of CRV rewards that should be sold for the underlying.
     * @return True if share was successfully set.
     */
    function setCrvDumpShare(uint256 _crvDumpShare) external onlyAdmin returns (bool) {
        require(_crvDumpShare <= MathFuncs.ONE, Error.INVALID_AMOUNT);
        crvDumpShare = _crvDumpShare;
        return true;
    }

    /**
     * @notice Set governance fee charges on CVX rewards.
     * @dev The "taxed" CVX is paid out to the community reserve.
     * @param _cvxGovFee New fee charged on CVX rewards for governance.
     * @return True if fee was successfully set.
     */
    function setCvxGovFee(uint256 _cvxGovFee) external onlyAdmin returns (bool) {
        require(_cvxGovFee <= MathFuncs.ONE, Error.INVALID_AMOUNT);
        require(communityReserve != address(0), "Community reserve must be set");
        cvxGovFee = _cvxGovFee;
        return true;
    }

    /**
     * @notice Set strategist.
     * @dev Can only be set by current strategist.
     * @param _strategist Address of new strategist.
     * @return True if successfully set.
     */
    function setStrategist(address _strategist) external returns (bool) {
        require(msg.sender == strategist, Error.UNAUTHORIZED_ACCESS);
        strategist = _strategist;
        return true;
    }

    function shutdown() external override onlyVault returns (bool) {
        if (!isShutdown) {
            isShutdown = true;
            return true;
        }
        return false;
    }

    /**
     * @notice Set target path for a token.
     * @dev This is required for Uniswap and SushiSwap to know what a particular token should be swapped for.
     * @param token Address of token that would be swapped.
     * @param id Id for token to swap for: 0 (DAI), 1 (USDC), 2 (USDT)
     */
    function setPathTarget(address token, uint256 id) public onlyAdmin returns (bool) {
        require(id <= 2, "unknown id");
        if (id == DAI_TARGET) {
            pathTarget[token] = dai;
        } else if (id == USDC_TARGET) {
            pathTarget[token] = usdc;
        } else {
            pathTarget[token] = usdt;
        }
        return true;
    }
}