/**
 *Submitted for verification at Etherscan.io on 2021-05-10
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma experimental ABIEncoderV2;

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


pragma solidity >=0.6.0 <0.8.0;

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

// File: contracts/Balancer.sol

pragma solidity ^0.6.0;


interface BFactory
{
	function newBPool() external returns (address _pool);
}

interface BPool is IERC20
{
	function getBalance(address _token) external view returns (uint256 _balance);

	function bind(address _token, uint256 _balance, uint256 _denorm) external;
	function finalize() external;
	function setSwapFee(uint256 _swapFee) external;
}

interface CrpPool is IERC20
{
	function bPool() external view returns (address _bpool);
	function isPublicSwap() external view returns (bool _isPublicSwap);

	function createPool(uint256 _initialSupply, uint256 _minimumWeightChangeBlockPeriodParam, uint256 _addTokenTimeLockInBlocksParam) external;
	function exitPool(uint256 _poolAmountIn, uint256[] calldata _minAmountsOut) external;
	function setController(address _controller) external;
	function setPublicSwap(bool _public) external;
	function updateWeightsGradually(uint256[] calldata _weights, uint256 _startBlock, uint256 _endBlock) external;
}

interface CrpFactory
{
	struct PoolParams {
		string poolTokenSymbol;
		string poolTokenName;
		address[] constituentTokens;
		uint[] tokenBalances;
		uint[] tokenWeights;
		uint swapFee;
	}

	struct Rights {
		bool canPauseSwapping;
		bool canChangeSwapFee;
		bool canChangeWeights;
		bool canAddRemoveTokens;
		bool canWhitelistLPs;
		bool canChangeCap;
	}

	function newCrp(address _factory, PoolParams calldata _params, Rights calldata _rights) external returns (address _pool);
}

// File: @openzeppelin/contracts/GSN/Context.sol


pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/utils/EnumerableSet.sol


pragma solidity >=0.6.0 <0.8.0;

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
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
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
        return address(uint256(_at(set._inner, index)));
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

// File: contracts/WhitelistGuard.sol

pragma solidity ^0.6.0;



abstract contract WhitelistGuard is Ownable
{
	using EnumerableSet for EnumerableSet.AddressSet;

	EnumerableSet.AddressSet private whitelist;

	modifier onlyEOAorWhitelist()
	{
		address _from = _msgSender();
		require(tx.origin == _from || whitelist.contains(_from), "access denied");
		_;
	}

	modifier onlyWhitelist()
	{
		address _from = _msgSender();
		require(whitelist.contains(_from), "access denied");
		_;
	}

	function addToWhitelist(address _address) external onlyOwner
	{
		require(whitelist.add(_address), "already listed");
	}

	function removeFromWhitelist(address _address) external onlyOwner
	{
		require(whitelist.remove(_address), "not listed");
	}
}

// File: @openzeppelin/contracts/math/SafeMath.sol


pragma solidity >=0.6.0 <0.8.0;

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

// File: @openzeppelin/contracts/utils/Address.sol


pragma solidity >=0.6.2 <0.8.0;

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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol


pragma solidity >=0.6.0 <0.8.0;




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

// File: contracts/TimeLockedAccounts.sol

pragma solidity ^0.6.0;



abstract contract TimeLockedAccounts
{
	using SafeERC20 for IERC20;

	struct PeriodInfo {
		uint256 periodDuration;
		uint256 periodCount;
		uint256 ratePerPeriod;
	}

	struct PlanInfo {
		string description;
		PeriodInfo[] periods;
		bool enabled;
	}

	struct AccountInfo {
		uint256 planId;
		uint256 initialBalance;
		uint256 currentBalance;
		uint256 baseTime;
		uint256 basePeriodIndex;
		uint256 basePeriodCount;
	}

	address public immutable token;

	uint256 private planCount_;
	mapping (uint256 => PlanInfo) private planInfo_;

	mapping (address => AccountInfo) public accountInfo;

	constructor (address _token) public
	{
		token = _token;
	}

	function planInfo(uint256 _planId) external view returns (string memory _description, bool _enabled)
	{
		PlanInfo memory _plan = planInfo_[_planId];
		return (_plan.description, _plan.enabled);
	}

	function periodInfo(uint256 _planId, uint256 _i) external view returns (uint256 periodDuration, uint256 periodCount, uint256 ratePerPeriod)
	{
		PlanInfo memory _plan = planInfo_[_planId];
		PeriodInfo memory _period = _plan.periods[_i];
		return (_period.periodDuration, _period.periodCount, _period.ratePerPeriod);
	}

	function available(address _receiver) external view returns (uint256 _amount)
	{
		uint256 _when = now;
		(,,,,_amount) = _available(_receiver, _when);
		return _amount;
	}

	function available(address _receiver, uint256 _when) external view returns (uint256 _amount)
	{
		(,,,,_amount) = _available(_receiver, _when);
		return _amount;
	}

	function deposit(address _receiver, uint256 _amount, uint256 _planId) public virtual
	{
		address _sender = msg.sender;
		uint256 _baseTime = now;
		_deposit(_receiver, _amount, _planId, _baseTime);
		IERC20(token).safeTransferFrom(_sender, address(this), _amount);
	}

	function depositBatch(address _sender, address[] memory _receivers, uint256[] memory _amounts, uint256 _planId, uint256 _baseTime) public virtual
	{
		require(_receivers.length == _amounts.length, "length mismatch");
		uint256 _totalAmount = 0;
		for (uint256 _i = 0; _i < _receivers.length; _i++) {
			address _receiver = _receivers[_i];
			uint256 _amount = _amounts[_i];
			_deposit(_receiver, _amount, _planId, _baseTime);
			uint256 _prevTotalAmount = _totalAmount;
			_totalAmount += _amount;
			require(_totalAmount >= _prevTotalAmount, "excessive amount");
		}
		IERC20(token).safeTransferFrom(_sender, address(this), _totalAmount);
	}

	function withdraw() public virtual
	{
		address _receiver = msg.sender;
		_withdraw(_receiver);
	}

	function withdrawBatch(address[] memory _receivers) public virtual
	{
		for (uint256 _i = 0; _i < _receivers.length; _i++) {
			_withdraw(_receivers[_i]);
		}
	}

	function _available(address _receiver, uint256 _when) private view returns (uint256 _newCurrentBalance, uint256 _newBaseTime, uint256 _newBasePeriodIndex, uint256 _newBasePeriodCount, uint256 _amount)
	{
		AccountInfo memory _account = accountInfo[_receiver];
		uint256 _planId = _account.planId;
		uint256 _initialBalance = _account.initialBalance;
		_newCurrentBalance = _account.currentBalance;
		_newBaseTime = _account.baseTime;
		_newBasePeriodIndex = _account.basePeriodIndex;
		_newBasePeriodCount = _account.basePeriodCount;
		require(_planId > 0, "nonexistent");
		require(_when >= _newBaseTime, "unavailable");
		PlanInfo memory _plan = planInfo_[_planId];
		PeriodInfo[] memory _periods = _plan.periods;
		for (; _newBasePeriodIndex < _periods.length; _newBasePeriodIndex++) {
			PeriodInfo memory _period = _periods[_newBasePeriodIndex];
			uint256 _periodDuration = _period.periodDuration;
			uint256 _periodCount = (_when - _newBaseTime) / _periodDuration;
			if (_periodCount == 0) break;
			if (_newBasePeriodCount == 0) _newBasePeriodCount = _period.periodCount;
			if (_periodCount > _newBasePeriodCount) _periodCount = _newBasePeriodCount;
			uint256 _ratePerPeriod = _period.ratePerPeriod;
			uint256 _amountPerPeriod = (_initialBalance * _ratePerPeriod) / 1e12;
			_newCurrentBalance -= _periodCount * _amountPerPeriod;
			_newBaseTime += _periodCount * _periodDuration;
			_newBasePeriodCount -= _periodCount;
			if (_newBasePeriodCount > 0) break;
		}
		_amount = _account.currentBalance - _newCurrentBalance;
		return (_newCurrentBalance, _newBaseTime, _newBasePeriodIndex, _newBasePeriodCount, _amount);
	}

	function _deposit(address _receiver, uint256 _amount, uint256 _planId, uint256 _baseTime) private
	{
		require(1 <= _amount && _amount <= uint256(-1) / 1e12, "invalid amount");
		require(1 <= _planId && _planId <= planCount_, "invalid plan");
		PlanInfo memory _plan = planInfo_[_planId];
		require(_plan.enabled, "unavailable");
		PeriodInfo[] memory _periods = _plan.periods;
		uint256 _sumAmount = 0;
		for (uint256 _i = 0; _i < _periods.length; _i++) {
			PeriodInfo memory _period = _periods[_i];
			uint256 _periodCount = _period.periodCount;
			uint256 _ratePerPeriod = _period.ratePerPeriod;
			uint256 _amountPerPeriod = (_amount * _ratePerPeriod) / 1e12;
			_sumAmount += _periodCount * _amountPerPeriod;
		}
		require(_sumAmount == _amount, "invalid amount");
		AccountInfo storage _account = accountInfo[_receiver];
		require(_account.planId == 0, "already exists");
		_account.planId = _planId;
		_account.initialBalance = _amount;
		_account.currentBalance = _amount;
		_account.baseTime = _baseTime;
		_account.basePeriodIndex = 0;
		_account.basePeriodCount = 0;
	}

	function _withdraw(address _receiver) private
	{
		uint256 _when = now;
		(uint256 _newCurrentBalance, uint256 _newBaseTime, uint256 _newBasePeriodIndex, uint256 _newBasePeriodCount, uint256 _amount) = _available(_receiver, _when);
		require(_amount > 0, "unavailable");
		AccountInfo storage _account = accountInfo[_receiver];
		_account.currentBalance = _newCurrentBalance;
		_account.baseTime = _newBaseTime;
		_account.basePeriodIndex = _newBasePeriodIndex;
		_account.basePeriodCount = _newBasePeriodCount;
		IERC20(token).safeTransfer(_receiver, _amount);
	}

	function _createPlan(string memory _description) internal returns (uint256 _planId)
	{
		_planId = ++planCount_;
		PlanInfo storage _plan = planInfo_[_planId];
		_plan.description = _description;
		_plan.enabled = false;
		return _planId;
	}

	function _addPlanPeriod(uint256 _planId, uint256 _periodDuration, uint256 _periodCount, uint256 _ratePerPeriod) internal
	{
		require(1 <= _planId && _planId <= planCount_, "invalid plan");
		require(_periodDuration > 0, "invalid duration");
		require(_ratePerPeriod <= 1e12, "invalid rate");
		uint256 _maxPeriodCount = _ratePerPeriod == 0 ? 1 : 1e12 / _ratePerPeriod;
		require(1 <= _periodCount && _periodCount <= _maxPeriodCount, "invalid count");
		PlanInfo storage _plan = planInfo_[_planId];
		require(!_plan.enabled, "unavailable");
		_plan.periods.push(PeriodInfo({
			periodDuration: _periodDuration,
			periodCount: _periodCount,
			ratePerPeriod: _ratePerPeriod
		}));
	}

	function _enablePlan(uint256 _planId) internal
	{
		require(1 <= _planId && _planId <= planCount_, "invalid plan");
		PlanInfo storage _plan = planInfo_[_planId];
		require(!_plan.enabled, "unavailable");
		PeriodInfo[] memory _periods = _plan.periods;
		uint256 _sumRate = 0;
		for (uint256 _i = 0; _i < _periods.length; _i++) {
			uint256 _periodCount = _periods[_i].periodCount;
			uint256 _ratePerPeriod = _periods[_i].ratePerPeriod;
			_sumRate += _periodCount * _ratePerPeriod;
		}
		require(_sumRate == 1e12, "invalid rate sum");
		_plan.enabled = true;
	}
}

// File: contracts/ManagedTimeLockedAccounts.sol

pragma solidity ^0.6.0;




contract ManagedTimeLockedAccounts is WhitelistGuard, TimeLockedAccounts
{
	address public treasury;

	uint256 public totalBalance;

	constructor (address _token, address _treasury) TimeLockedAccounts(_token) public
	{
		treasury = _treasury;
	}

	function deposit(address _receiver, uint256 _amount, uint256 _planId) public override onlyOwner
	{
		uint256 _balanceBefore = IERC20(token).balanceOf(address(this));
		TimeLockedAccounts.deposit(_receiver, _amount, _planId);
		uint256 _balanceAfter = IERC20(token).balanceOf(address(this));
		totalBalance += _balanceAfter - _balanceBefore;
	}

	function depositBatch(address _sender, address[] memory _receivers, uint256[] memory _amounts, uint256 _planId, uint256 _baseTime) public override onlyOwner
	{
		uint256 _balanceBefore = IERC20(token).balanceOf(address(this));
		TimeLockedAccounts.depositBatch(_sender, _receivers, _amounts, _planId, _baseTime);
		uint256 _balanceAfter = IERC20(token).balanceOf(address(this));
		totalBalance += _balanceAfter - _balanceBefore;
	}

	function withdraw() public override onlyEOAorWhitelist
	{
		uint256 _balanceBefore = IERC20(token).balanceOf(address(this));
		TimeLockedAccounts.withdraw();
		uint256 _balanceAfter = IERC20(token).balanceOf(address(this));
		totalBalance -= _balanceBefore - _balanceAfter;
	}

	function withdrawBatch(address[] memory _receivers) public override onlyOwner
	{
		uint256 _balanceBefore = IERC20(token).balanceOf(address(this));
		TimeLockedAccounts.withdrawBatch(_receivers);
		uint256 _balanceAfter = IERC20(token).balanceOf(address(this));
		totalBalance -= _balanceBefore - _balanceAfter;
	}

	function createPlan(string memory _description) external onlyOwner returns (uint256 _planId)
	{
		return _createPlan(_description);
	}

	function addPlanPeriod(uint256 _planId, uint256 _periodDuration, uint256 _periodCount, uint256 _ratePerPeriod) external onlyOwner
	{
		_addPlanPeriod(_planId, _periodDuration, _periodCount, _ratePerPeriod);
	}

	function enablePlan(uint256 _planId) external onlyOwner
	{
		_enablePlan(_planId);
	}

	function recoverLostFunds(address _token) external onlyOwner
	{
		uint256 _balance = IERC20(_token).balanceOf(address(this));
		if (_token == token) {
			_balance -= totalBalance;
		}
		IERC20(_token).safeTransfer(treasury, _balance);
	}

	function setTreasury(address _newTreasury) external onlyOwner
	{
		require(_newTreasury != address(0), "invalid address");
		address _oldTreasury = treasury;
		treasury = _newTreasury;
		emit ChangeTreasury(_oldTreasury, _newTreasury);
	}

	event ChangeTreasury(address _oldTreasury, address _newTreasury);
}

// File: contracts/MasterChef.sol

pragma solidity ^0.6.0;





contract RewardPool
{
	using SafeERC20 for IERC20;

	constructor (address _rewardToken) public
	{
		IERC20(_rewardToken).safeApprove(msg.sender, uint256(-1));
	}
}

contract MasterChef is WhitelistGuard
{
	using SafeMath for uint256;
	using SafeERC20 for IERC20;

	struct PoolInfo {
		address token;
		uint256 allocPoint;
		uint256 lastRewardBlock;
		uint256 accRewardPerShare;
		uint256 withdrawalUnlockTime;
	}

	struct UserInfo {
		uint256 amount;
		uint256 rewardDebt;
		uint256 rewardCredit;
	}

	address public immutable rewardToken;
	address public immutable availablePool;
	address public immutable allocatedPool;

	address public treasury;

	uint256 public bonusMultiplier = 1;
	uint256 public rewardPerBlock = 0;
	uint256 public totalAllocPoint = 0;

	PoolInfo[] public poolInfo;
	mapping (uint256 => mapping (address => UserInfo)) public userInfo;

	constructor (address _rewardToken, address _treasury) public
	{
		rewardToken = _rewardToken;
		availablePool = address(new RewardPool(_rewardToken));
		allocatedPool = address(new RewardPool(_rewardToken));
		treasury = _treasury;
	}

	function poolLength() external view returns (uint256 _poolLength)
	{
		return poolInfo.length;
	}

	function pendingReward(uint256 _pid, address _account) external view returns (uint256 _pendingReward)
	{
		PoolInfo storage _pool = poolInfo[_pid];
		UserInfo storage _user = userInfo[_pid][_account];
		uint256 _accRewardPerShare = _pool.accRewardPerShare;
		uint256 _balance = IERC20(_pool.token).balanceOf(address(this));
		if (block.number > _pool.lastRewardBlock && _balance > 0) {
			uint256 _blockCount = _getBlockCount(_pool.lastRewardBlock, block.number);
			uint256 _reward = _blockCount.mul(rewardPerBlock).mul(_pool.allocPoint).div(totalAllocPoint);
			_accRewardPerShare = _accRewardPerShare.add(_reward.mul(1e12).div(_balance));
		}
		return _user.amount.mul(_accRewardPerShare).div(1e12).sub(_user.rewardDebt).add(_user.rewardCredit);
	}

	function massUpdatePools() public
	{
		uint256 _length = poolInfo.length;
		for (uint256 _pid = 0; _pid < _length; _pid++) {
			updatePool(_pid);
		}
	}

	function updatePool(uint256 _pid) public
	{
		require(_pid < poolInfo.length, "invalid pid");
		PoolInfo storage _pool = poolInfo[_pid];
		if (block.number <= _pool.lastRewardBlock) {
			return;
		}
		uint256 _balance = IERC20(_pool.token).balanceOf(address(this));
		if (_balance == 0) {
			_pool.lastRewardBlock = block.number;
			return;
		}
		uint256 _blockCount = _getBlockCount(_pool.lastRewardBlock, block.number);
		uint256 _reward = _blockCount.mul(rewardPerBlock).mul(_pool.allocPoint).div(totalAllocPoint);
		_pool.accRewardPerShare = _pool.accRewardPerShare.add(_reward.mul(1e12).div(_balance));
		_pool.lastRewardBlock = block.number;
		_safeRewardTransferFrom(availablePool, allocatedPool, _reward);
	}

	function deposit(uint256 _pid, uint256 _amount) external onlyEOAorWhitelist
	{
		PoolInfo storage _pool = poolInfo[_pid];
		UserInfo storage _user = userInfo[_pid][msg.sender];
		updatePool(_pid);
		uint256 _reward = _user.amount.mul(_pool.accRewardPerShare).div(1e12).sub(_user.rewardDebt);
		_user.rewardCredit = _user.rewardCredit.add(_reward);
		if (now >= _pool.withdrawalUnlockTime) {
			if (_user.rewardCredit > 0) {
				_safeRewardTransferFrom(allocatedPool, msg.sender, _user.rewardCredit);
				_user.rewardCredit = 0;
			}
		}
		if (_amount > 0) {
			IERC20(_pool.token).safeTransferFrom(msg.sender, address(this), _amount);
			_user.amount = _user.amount.add(_amount);
		}
		_user.rewardDebt = _user.amount.mul(_pool.accRewardPerShare).div(1e12);
		emit Deposit(msg.sender, _pid, _amount);
	}

	function withdraw(uint256 _pid, uint256 _amount) external onlyEOAorWhitelist
	{
		PoolInfo storage _pool = poolInfo[_pid];
		UserInfo storage _user = userInfo[_pid][msg.sender];
		require(now >= _pool.withdrawalUnlockTime, "withdrawal unavailable");
		require(_user.amount >= _amount, "insufficient balance");
		updatePool(_pid);
		uint256 _reward = _user.amount.mul(_pool.accRewardPerShare).div(1e12).sub(_user.rewardDebt);
		_user.rewardCredit = _user.rewardCredit.add(_reward);
		if (_user.rewardCredit > 0) {
			_safeRewardTransferFrom(allocatedPool, msg.sender, _user.rewardCredit);
			_user.rewardCredit = 0;
		}
		if (_amount > 0) {
			_user.amount = _user.amount.sub(_amount);
			IERC20(_pool.token).safeTransfer(msg.sender, _amount);
		}
		_user.rewardDebt = _user.amount.mul(_pool.accRewardPerShare).div(1e12);
		emit Withdraw(msg.sender, _pid, _amount);
	}

	function recoverRewardFunds() external onlyOwner
	{
		_safeRewardTransferFrom(availablePool, treasury, uint256(-1));
	}

	function updateBonusMultiplier(uint256 _bonusMultiplier, bool _withUpdate) external onlyOwner
	{
		if (_withUpdate) {
			massUpdatePools();
		}
		bonusMultiplier = _bonusMultiplier;
	}

	function updateRewardPerBlock(uint256 _rewardPerBlock, bool _withUpdate) external onlyOwner
	{
		if (_withUpdate) {
			massUpdatePools();
		}
		rewardPerBlock = _rewardPerBlock;
	}

	function addPool(address _token, uint256 _allocPoint, uint256 _startBlock, uint256 _withdrawalUnlockTime, bool _withUpdate) external onlyOwner
	{
		if (_withUpdate) {
			massUpdatePools();
		}
		uint256 _lastRewardBlock = block.number > _startBlock ? block.number : _startBlock;
		totalAllocPoint = totalAllocPoint.add(_allocPoint);
		poolInfo.push(PoolInfo({
			token: _token,
			allocPoint: _allocPoint,
			lastRewardBlock: _lastRewardBlock,
			accRewardPerShare: 0,
			withdrawalUnlockTime: _withdrawalUnlockTime
		}));
	}

	function setPoolAllocPoint(uint256 _pid, uint256 _allocPoint, bool _withUpdate) external onlyOwner
	{
		require(_pid < poolInfo.length, "invalid pid");
		if (_withUpdate) {
			massUpdatePools();
		}
		uint256 _prevAllocPoint = poolInfo[_pid].allocPoint;
		poolInfo[_pid].allocPoint = _allocPoint;
		totalAllocPoint = totalAllocPoint.sub(_prevAllocPoint).add(_allocPoint);
	}

	function setTreasury(address _newTreasury) external onlyOwner
	{
		require(_newTreasury != address(0), "invalid address");
		address _oldTreasury = treasury;
		treasury = _newTreasury;
		emit ChangeTreasury(_oldTreasury, _newTreasury);
	}

	function _getBlockCount(uint256 _from, uint256 _to) internal view returns (uint256 _blockCount)
	{
		return _to.sub(_from).mul(bonusMultiplier);
	}

	function _safeRewardTransferFrom(address _from, address _to, uint256 _amount) internal
	{
		uint256 _balance = IERC20(rewardToken).balanceOf(_from);
		if (_amount > _balance) _amount = _balance;
		uint256 _allowance = IERC20(rewardToken).allowance(_from, address(this));
		if (_amount > _allowance) _amount = _allowance;
		IERC20(rewardToken).safeTransferFrom(_from, _to, _amount);
	}

	event Deposit(address indexed _account, uint256 indexed _pid, uint256 _amount);
	event Withdraw(address indexed _account, uint256 indexed _pid, uint256 _amount);
	event ChangeTreasury(address _oldTreasury, address _newTreasury);
}

// File: contracts/TimeLockedVault.sol

pragma solidity ^0.6.0;




contract TimeLockedVault is Ownable
{
	using SafeERC20 for IERC20;

	uint256 constant WITHDRAWAL_WAIT_INTERVAL = 1 days;
	uint256 constant WITHDRAWAL_OPEN_INTERVAL = 1 days;

	mapping (address => Withdrawal) public withdrawals;

	struct Withdrawal {
		uint256 timestamp;
		address to;
		uint256 amount;
	}

	function announceWithdrawal(address _token, address _to, uint256 _amount) external onlyOwner
	{
		Withdrawal storage _withdrawal = withdrawals[_token];
		require(_withdrawal.timestamp == 0, "existing withdrawal");
		uint256 _balance = IERC20(_token).balanceOf(address(this));
		require(_balance >= _amount, "insufficient balance");
		uint256 _timestamp = now;
		_withdrawal.timestamp = _timestamp;
		_withdrawal.to = _to;
		_withdrawal.amount = _amount;
		emit AnnounceWithdrawal(_token, _to, _amount, _timestamp);
	}

	function cancelWithdrawal(address _token) external onlyOwner
	{
		Withdrawal storage _withdrawal = withdrawals[_token];
		uint256 _timestamp = _withdrawal.timestamp;
		require(_timestamp != 0, "unknown withdrawal");
		address _to = withdrawals[_token].to;
		uint256 _amount = withdrawals[_token].amount;
		_withdrawal.timestamp = 0;
		_withdrawal.to = address(0);
		_withdrawal.amount = 0;
		emit CancelWithdrawal(_token, _to, _amount, _timestamp);
	}

	function withdraw(address _token, address _to, uint256 _amount) external onlyOwner
	{
		Withdrawal storage _withdrawal = withdrawals[_token];
		uint256 _timestamp = _withdrawal.timestamp;
		require(_timestamp != 0, "unknown withdrawal");
		require(_to == _withdrawal.to, "to mismatch");
		require(_amount == _withdrawal.amount, "amount mismatch");
		uint256 _start = _timestamp + WITHDRAWAL_WAIT_INTERVAL;
		uint256 _end = _start + WITHDRAWAL_OPEN_INTERVAL;
		require(_start <= now && now < _end, "not available");
		_withdrawal.timestamp = 0;
		_withdrawal.to = address(0);
		_withdrawal.amount = 0;
		IERC20(_token).safeTransfer(_to, _amount);
		emit Withdraw(_token, _to, _amount, _timestamp);
	}

	event AnnounceWithdrawal(address indexed _token, address indexed _to, uint256 _amount, uint256 indexed _timestamp);
	event CancelWithdrawal(address indexed _token, address indexed _to, uint256 _amount, uint256 indexed _timestamp);
	event Withdraw(address indexed _token, address indexed _to, uint256 _amount, uint256 indexed _timestamp);
}

// File: contracts/NftfyLauncher.sol

pragma solidity ^0.6.0;









contract NftfyLauncher is Ownable
{
	using SafeMath for uint256;
	using SafeERC20 for IERC20;

	bool constant MAINNET = false;

	uint256 constant CHAINID = MAINNET ? 1 : 42;

	address constant BALANCER_FACTORY = MAINNET
		? 0x9424B1412450D0f8Fc2255FAf6046b98213B76Bd
		: 0x8f7F78080219d4066A8036ccD30D588B416a40DB;

	address constant BALANCER_CRP_FACTORY = MAINNET
		? 0xed52D8E202401645eDAD1c0AA21e872498ce47D0
		: 0x53265f0e014995363AE54DAd7059c018BaDbcD74;

	address public constant DAI = MAINNET
		? 0x6B175474E89094C44Da98b954EedeAC495271d0F
		: 0xE04b61898e2fa66bBF9628d1C6f756cab89DdBb4;
	address public constant WETH = MAINNET
		? 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
		: 0xd0A1E359811322d97991E03f863a0C30C2cF029C;

	uint256 public constant PREPARE_BLOCK = 12407157;  // Mon May 10 2021 13:30 GMT
	uint256 public constant RELEASE_BLOCK = 12417126;

	uint256 public constant RELEASE_TIME = 1620783000; // Wed May 12 2021 01:30 GMT

	uint256 public constant BOOTSTRAP_PRICE = MAINNET
		? 5e17 // 0.5
		: 5e12; // 0.000005

	uint256 public constant BOOTSTRAP_AMOUNT = 2_000_000e18; // 2mi
	uint256 public constant VESTING_AMOUNT = 80_000_000e18; // 80mi
	uint256 public constant STAKING_REWARD = 10_000e18;     //  10k
	uint256 public constant FARMING_REWARD = 200_000e18;    // 200k

	uint256 constant WEEK = MAINNET ? 7 days : 7 minutes;
	uint256 constant MONTH = MAINNET ? 30 days : 30 minutes;

	uint256 constant SWAP_FEE = 3e15; // 0.3%

	address public immutable token;
	address public immutable treasury;
	address public immutable operator;
	address public immutable masterChef;
	address public immutable schedule;

	address public daoVault;
	address public lmVault;
	address public ecoVault;
	address public opsVault;
	address public teamVault;

	address public lbp;

	address public poolDAI;
	address public poolETH;

	enum Stage { Prepare, Populate, Release, Done }

	Stage public stage = Stage.Prepare;

	constructor (address _token, address _treasury, address _operator, address _masterChef, address _schedule) public
	{
		require(_chainId() == CHAINID, "wrong network");
		token = _token;
		treasury = _treasury;
		operator = _operator;
		masterChef = _masterChef;
		schedule = _schedule;
		transferOwnership(_treasury);
	}

	function recoverOwnership(address _ownable) external onlyOwner
	{
		Ownable(_ownable).transferOwnership(msg.sender);
	}

	function recoverControl(address _pool) external onlyOwner
	{
		CrpPool(_pool).setController(msg.sender);
	}

	function recoverLostFunds(address _token) external onlyOwner
	{
		IERC20(_token).safeTransfer(treasury, IERC20(_token).balanceOf(address(this)));
	}

	// must transfer masterChef ownership
	// must approve (2mi + 10k) NFTFY from treasury
	// must approve (1mi) DAI from treasury
	function prepare() external onlyOwner
	{
		require(stage == Stage.Prepare, "unavailable");

		uint256 _rewardPerBlock = 1003e15; // 10k / 36h

		uint256 _tokenAmount = BOOTSTRAP_AMOUNT;
		uint256 _daiAmount = _tokenAmount.mul(BOOTSTRAP_PRICE).div(1e18);
		IERC20(token).safeTransferFrom(treasury, address(this), _tokenAmount);
		IERC20(DAI).safeTransferFrom(treasury, address(this), _daiAmount);
		lbp = LibNftfyLauncher.createBalancerSmartPool(BALANCER_CRP_FACTORY, BALANCER_FACTORY, token, DAI, _tokenAmount, _daiAmount, SWAP_FEE);
//		uint256[] memory _tokenWeights = new uint256[](2);
//		_tokenWeights[0] = 12e18;
//		_tokenWeights[1] = 28e18;
//		uint256 _prepareBlock = PREPARE_BLOCK > block.number ? PREPARE_BLOCK : block.number;
//		uint256 _releaseBlock = RELEASE_BLOCK > block.number ? RELEASE_BLOCK : block.number;
//		CrpPool(lbp).updateWeightsGradually(_tokenWeights, _prepareBlock, _releaseBlock);
		CrpPool(lbp).setPublicSwap(false);
		CrpPool(lbp).setController(operator);
		IERC20(lbp).safeTransfer(treasury, IERC20(lbp).balanceOf(address(this)));

		require(IERC20(token).balanceOf(address(this)) == 0, "balance left over");
		require(IERC20(DAI).balanceOf(address(this)) == 0, "balance left over");
		require(IERC20(lbp).balanceOf(address(this)) == 0, "balance left over");

		MasterChef(masterChef).updateRewardPerBlock(_rewardPerBlock, false);
		MasterChef(masterChef).addPool(token, 1000, PREPARE_BLOCK, RELEASE_TIME, false);
		IERC20(token).safeTransferFrom(treasury, MasterChef(masterChef).availablePool(), STAKING_REWARD);

		stage = Stage.Populate;
		emit PreparePerformed();
	}

	// must transfer schedule ownership
	// must approve (80mi) NFTFY from treasury
	function populate() external onlyOwner
	{
		require(stage == Stage.Populate, "unavailable");

		daoVault = LibNftfyLauncher.createVault();
		lmVault = LibNftfyLauncher.createVault();
		ecoVault = LibNftfyLauncher.createVault();
		opsVault = LibNftfyLauncher.createVault();
		teamVault = LibNftfyLauncher.createVault();
		Ownable(daoVault).transferOwnership(treasury);
		Ownable(lmVault).transferOwnership(treasury);
		Ownable(ecoVault).transferOwnership(treasury);
		Ownable(opsVault).transferOwnership(treasury);
		Ownable(teamVault).transferOwnership(treasury);

		uint256[] memory _rates = new uint256[](6);
		_rates[0] = 24e10;
		_rates[1] = 22e10;
		_rates[2] = 18e10;
		_rates[3] = 16e10;
		_rates[4] = 12e10;
		_rates[5] = 8e10;
		uint256 _planId = LibNftfyLauncher.addVestingPlan(schedule, "Vesting", WEEK, 52, _rates); // 52 x (1w => 24%/52) + 52 x (1w => 22%/52) + 52 x (1w => 18%/52) + 52 x (1w => 16%/52) + 52 x (1w => 12%/52) + 52 x (1w => 8%/52)
		require(_planId == 1, "invalid schedule config");
		LibNftfyLauncher.addSalesPlan(schedule, "Sales A", MONTH, 8e10, MONTH, 16, 575e8); // 30d => 8% + 16 x (30d => 5.75%)
		LibNftfyLauncher.addSalesPlan(schedule, "Sales S", MONTH, 10e10, MONTH, 12, 75e9); // 30d => 10% + 12 x (30d => 7.5%)
		LibNftfyLauncher.addSalesPlan(schedule, "Sales P", 1 seconds, 12e10, MONTH, 8, 11e10); // 1s => 12% + 8 x (30d => 11%)
		LibNftfyLauncher.addAirdropPlan(schedule, "Airdrop", 1 seconds); // 1s => 100%
		IERC20(token).safeTransferFrom(treasury, address(this), VESTING_AMOUNT);
		IERC20(token).safeApprove(schedule, VESTING_AMOUNT);
		address[] memory _receivers = new address[](5);
		_receivers[0] = daoVault;
		_receivers[1] = lmVault;
		_receivers[2] = ecoVault;
		_receivers[3] = opsVault;
		_receivers[4] = teamVault;
		uint256[] memory _amounts = new uint256[](5);
		_amounts[0] = 30_000_000e18; // 30mi DAO
		_amounts[1] = 20_000_000e18; // 20mi Liquidity Mining
		_amounts[2] =  5_000_000e18; //  5mi Ecosystem
		_amounts[3] =  5_000_000e18; //  5mi Marketing/Operations
		_amounts[4] = 20_000_000e18; // 20mi Team
		ManagedTimeLockedAccounts(schedule).depositBatch(address(this), _receivers, _amounts, _planId, RELEASE_TIME);
		Ownable(schedule).transferOwnership(operator);

		require(IERC20(token).balanceOf(address(this)) == 0, "balance left over");

		stage = Stage.Release;
		emit PopulatePerformed();
	}

	// must approve (100) LBP shares from treasury
	// must approve (<DAI pool liquidity> * token price) DAI from treasury
	// must approve (<ETH pool liquidity> * token price / eth price) WETH from treasury
	// must approve (<DAI pool liquidity> + <ETH pool liquidity1> + 200k) NFTFY from treasury
	function release(uint256 _tokenAmountForDAI, uint256 _tokenAmountForETH, uint256 _tokenPrice, uint256 _ethPrice, bool _exitPool) external onlyOwner
	{
		require(stage == Stage.Release, "unavailable");

		uint256 _rewardPerBlock = 836e15; // 1mi / 6mo

		if (_exitPool) {
			require(!CrpPool(lbp).isPublicSwap(), "pool active");
			IERC20(lbp).safeTransferFrom(treasury, address(this), IERC20(lbp).balanceOf(treasury));
			LibNftfyLauncher.exitPool(lbp, token, DAI);
			IERC20(token).safeTransfer(treasury, IERC20(token).balanceOf(address(this)));
			IERC20(DAI).safeTransfer(treasury, IERC20(DAI).balanceOf(address(this)));
			IERC20(lbp).safeTransfer(treasury, IERC20(lbp).balanceOf(address(this)));
		}

//		require(IERC20(token).balanceOf(address(this)) == 0, "balance left over");
//		require(IERC20(DAI).balanceOf(address(this)) == 0, "balance left over");
//		require(IERC20(lbp).balanceOf(address(this)) == 0, "balance left over");

		uint256 _daiAmount = _tokenAmountForDAI.mul(_tokenPrice).div(1e18);
		uint256 _ethAmount = _tokenAmountForETH.mul(_tokenPrice).div(_ethPrice);
		uint256 _tokenAmount = _tokenAmountForDAI.add(_tokenAmountForETH);
		IERC20(token).safeTransferFrom(treasury, address(this), _tokenAmount);
		IERC20(DAI).safeTransferFrom(treasury, address(this), _daiAmount);
		IERC20(WETH).safeTransferFrom(treasury, address(this), _ethAmount);
		poolDAI = LibNftfyLauncher.createBalancerPool(BALANCER_FACTORY, token, DAI, _tokenAmountForDAI, _daiAmount, SWAP_FEE);
		poolETH = LibNftfyLauncher.createBalancerPool(BALANCER_FACTORY, token, WETH, _tokenAmountForETH, _ethAmount, SWAP_FEE);
		IERC20(poolDAI).safeTransfer(treasury, IERC20(poolDAI).balanceOf(address(this)));
		IERC20(poolETH).safeTransfer(treasury, IERC20(poolETH).balanceOf(address(this)));

//		require(IERC20(token).balanceOf(address(this)) == 0, "balance left over");
//		require(IERC20(DAI).balanceOf(address(this)) == 0, "balance left over");
//		require(IERC20(WETH).balanceOf(address(this)) == 0, "balance left over");
//		require(IERC20(poolDAI).balanceOf(address(this)) == 0, "balance left over");
//		require(IERC20(poolETH).balanceOf(address(this)) == 0, "balance left over");

		require(MasterChef(masterChef).poolLength() == 1, "invalid pool config");
		MasterChef(masterChef).setPoolAllocPoint(0, 0, true);
		MasterChef(masterChef).updateRewardPerBlock(_rewardPerBlock, false);
		MasterChef(masterChef).addPool(poolDAI, 1000, 0, now, false);
		MasterChef(masterChef).addPool(poolETH, 1000, 0, now, false);
		IERC20(token).safeTransferFrom(treasury, MasterChef(masterChef).availablePool(), FARMING_REWARD);
		Ownable(masterChef).transferOwnership(treasury);

		stage = Stage.Done;
		emit ReleasePerformed();
	}

	function _chainId() internal pure returns (uint256 _chainid)
	{
		assembly { _chainid := chainid() }
		return _chainid;
	}

	event PreparePerformed();
	event PopulatePerformed();
	event ReleasePerformed();
}

library LibNftfyLauncher
{
	using SafeMath for uint256;
	using SafeERC20 for IERC20;

	function createVault() public returns (address _vault)
	{
		return address(new TimeLockedVault());
	}

	function createBalancerPool(address _factory, address _token0, address _token1, uint256 _balance0, uint256 _balance1, uint256 _swapFee) public returns (address _pool)
	{
		_pool = BFactory(_factory).newBPool();
		IERC20(_token0).safeApprove(_pool, _balance0);
		IERC20(_token1).safeApprove(_pool, _balance1);
		BPool(_pool).bind(_token0, _balance0, 25e18);
		BPool(_pool).bind(_token1, _balance1, 25e18);
		BPool(_pool).setSwapFee(_swapFee);
		BPool(_pool).finalize();
		return _pool;
	}
	
	function createBalancerSmartPool(address _crpFactory, address _factory, address _token0, address _token1, uint256 _balance0, uint256 _balance1, uint256 _swapFee) public returns (address _pool)
	{
		address[] memory _constituentTokens = new address[](2);
		_constituentTokens[0] = _token0;
		_constituentTokens[1] = _token1;
		uint256[] memory _tokenBalances = new uint256[](2);
		_tokenBalances[0] = _balance0;
		_tokenBalances[1] = _balance1;
		uint256[] memory _tokenWeights = new uint256[](2);
		_tokenWeights[0] = 36e18;
		_tokenWeights[1] = 4e18;
		CrpFactory.PoolParams memory _params = CrpFactory.PoolParams({
			poolTokenSymbol: "LBP",
			poolTokenName: "NFTFY LBP",
			constituentTokens: _constituentTokens,
			tokenBalances: _tokenBalances,
			tokenWeights: _tokenWeights,
			swapFee: _swapFee
		});
		CrpFactory.Rights memory _rights = CrpFactory.Rights({
			canPauseSwapping: true,
			canChangeSwapFee: true,
			canChangeWeights: true,
			canAddRemoveTokens: false,
			canWhitelistLPs: true,
			canChangeCap: true
		});
		_pool = CrpFactory(_crpFactory).newCrp(_factory, _params, _rights);
		IERC20(_token0).safeApprove(_pool, _balance0);
		IERC20(_token1).safeApprove(_pool, _balance1);
		CrpPool(_pool).createPool(100e18, 10, 10);
		return _pool;
	}

	function exitPool(address _pool, address _token0, address _token1) public
	{
		uint256 MIN_BALANCE = 1e12;
		address _bpool = CrpPool(_pool).bPool();
		uint256 _balance0 = BPool(_bpool).getBalance(_token0);
		uint256 _balance1 = BPool(_bpool).getBalance(_token1);
		if (_balance0 <= MIN_BALANCE || _balance1 <= MIN_BALANCE) return;
		uint256 _percent0 = MIN_BALANCE.mul(1e18).div(_balance0);
		uint256 _percent1 = MIN_BALANCE.mul(1e18).div(_balance1);
		uint256 _percent = _percent0 > _percent1 ? _percent0 : _percent1;
		uint256 _shares = IERC20(_pool).balanceOf(address(this));
		uint256 _minShares = _shares.mul(_percent).div(1e18);
		uint256[] memory _minAmountsOut = new uint256[](2);
		_minAmountsOut[0] = 1;
		_minAmountsOut[1] = 1;
		CrpPool(_pool).exitPool(_shares.sub(_minShares), _minAmountsOut);
	}

	function addAirdropPlan(address _schedule, string memory _description, uint256 _periodDuration) public returns (uint256 _planId)
	{
		_planId = ManagedTimeLockedAccounts(_schedule).createPlan(_description);
		ManagedTimeLockedAccounts(_schedule).addPlanPeriod(_planId, _periodDuration, 1, 1e12);
		ManagedTimeLockedAccounts(_schedule).enablePlan(_planId);
		return _planId;
	}

	function addSalesPlan(address _schedule, string memory _description, uint256 _cliffDuration, uint256 _ratePerCliff, uint256 _periodDuration, uint256 _periodCount, uint256 _ratePerPeriod) public returns (uint256 _planId)
	{
		_planId = ManagedTimeLockedAccounts(_schedule).createPlan(_description);
		ManagedTimeLockedAccounts(_schedule).addPlanPeriod(_planId, _cliffDuration, 1, _ratePerCliff);
		ManagedTimeLockedAccounts(_schedule).addPlanPeriod(_planId, _periodDuration, _periodCount, _ratePerPeriod);
		ManagedTimeLockedAccounts(_schedule).enablePlan(_planId);
		return _planId;
	}

	function addVestingPlan(address _schedule, string memory _description, uint256 _periodDuration, uint256 _periodCount, uint256[] memory _rates) public returns (uint256 _planId)
	{
		_planId = ManagedTimeLockedAccounts(_schedule).createPlan(_description);
		uint256 _remRate = 0;
		for (uint256 _i = 0; _i < _rates.length; _i++) {
			uint256 _rate = _rates[_i];
			uint256 _ratePerPeriod = _rate / _periodCount;
			ManagedTimeLockedAccounts(_schedule).addPlanPeriod(_planId, _periodDuration, _periodCount, _ratePerPeriod);
			_remRate += _rate - _periodCount * _ratePerPeriod;
		}
		if (_remRate > 0) {
			ManagedTimeLockedAccounts(_schedule).addPlanPeriod(_planId, 1, 1, _remRate);
		}
		ManagedTimeLockedAccounts(_schedule).enablePlan(_planId);
		return _planId;
	}
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


pragma solidity >=0.6.0 <0.8.0;




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
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
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

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
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
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
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

// File: @openzeppelin/contracts/token/ERC20/ERC20Burnable.sol


pragma solidity >=0.6.0 <0.8.0;



/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    using SafeMath for uint256;

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}

// File: @openzeppelin/contracts/math/Math.sol


pragma solidity >=0.6.0 <0.8.0;

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

// File: @openzeppelin/contracts/utils/Arrays.sol


pragma solidity >=0.6.0 <0.8.0;


/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
   /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}

// File: @openzeppelin/contracts/utils/Counters.sol


pragma solidity >=0.6.0 <0.8.0;


/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol


pragma solidity >=0.6.0 <0.8.0;





/**
 * @dev This contract extends an ERC20 token with a snapshot mechanism. When a snapshot is created, the balances and
 * total supply at the time are recorded for later access.
 *
 * This can be used to safely create mechanisms based on token balances such as trustless dividends or weighted voting.
 * In naive implementations it's possible to perform a "double spend" attack by reusing the same balance from different
 * accounts. By using snapshots to calculate dividends or voting power, those attacks no longer apply. It can also be
 * used to create an efficient ERC20 forking mechanism.
 *
 * Snapshots are created by the internal {_snapshot} function, which will emit the {Snapshot} event and return a
 * snapshot id. To get the total supply at the time of a snapshot, call the function {totalSupplyAt} with the snapshot
 * id. To get the balance of an account at the time of a snapshot, call the {balanceOfAt} function with the snapshot id
 * and the account address.
 *
 * ==== Gas Costs
 *
 * Snapshots are efficient. Snapshot creation is _O(1)_. Retrieval of balances or total supply from a snapshot is _O(log
 * n)_ in the number of snapshots that have been created, although _n_ for a specific account will generally be much
 * smaller since identical balances in subsequent snapshots are stored as a single entry.
 *
 * There is a constant overhead for normal ERC20 transfers due to the additional snapshot bookkeeping. This overhead is
 * only significant for the first transfer that immediately follows a snapshot for a particular account. Subsequent
 * transfers will have normal cost until the next snapshot, and so on.
 */
abstract contract ERC20Snapshot is ERC20 {
    // Inspired by Jordi Baylina's MiniMeToken to record historical balances:
    // https://github.com/Giveth/minimd/blob/ea04d950eea153a04c51fa510b068b9dded390cb/contracts/MiniMeToken.sol

    using SafeMath for uint256;
    using Arrays for uint256[];
    using Counters for Counters.Counter;

    // Snapshotted values have arrays of ids and the value corresponding to that id. These could be an array of a
    // Snapshot struct, but that would impede usage of functions that work on an array.
    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    mapping (address => Snapshots) private _accountBalanceSnapshots;
    Snapshots private _totalSupplySnapshots;

    // Snapshot ids increase monotonically, with the first value being 1. An id of 0 is invalid.
    Counters.Counter private _currentSnapshotId;

    /**
     * @dev Emitted by {_snapshot} when a snapshot identified by `id` is created.
     */
    event Snapshot(uint256 id);

    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     *
     * Emits a {Snapshot} event that contains the same id.
     *
     * {_snapshot} is `internal` and you have to decide how to expose it externally. Its usage may be restricted to a
     * set of accounts, for example using {AccessControl}, or it may be open to the public.
     *
     * [WARNING]
     * ====
     * While an open way of calling {_snapshot} is required for certain trust minimization mechanisms such as forking,
     * you must consider that it can potentially be used by attackers in two ways.
     *
     * First, it can be used to increase the cost of retrieval of values from snapshots, although it will grow
     * logarithmically thus rendering this attack ineffective in the long term. Second, it can be used to target
     * specific accounts and increase the cost of ERC20 transfers for them, in the ways specified in the Gas Costs
     * section above.
     *
     * We haven't measured the actual numbers; if this is something you're interested in please reach out to us.
     * ====
     */
    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = _currentSnapshotId.current();
        emit Snapshot(currentId);
        return currentId;
    }

    /**
     * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
     */
    function balanceOfAt(address account, uint256 snapshotId) public view returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account]);

        return snapshotted ? value : balanceOf(account);
    }

    /**
     * @dev Retrieves the total supply at the time `snapshotId` was created.
     */
    function totalSupplyAt(uint256 snapshotId) public view returns(uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _totalSupplySnapshots);

        return snapshotted ? value : totalSupply();
    }


    // Update balance and/or total supply snapshots before the values are modified. This is implemented
    // in the _beforeTokenTransfer hook, which is executed for _mint, _burn, and _transfer operations.
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
      super._beforeTokenTransfer(from, to, amount);

      if (from == address(0)) {
        // mint
        _updateAccountSnapshot(to);
        _updateTotalSupplySnapshot();
      } else if (to == address(0)) {
        // burn
        _updateAccountSnapshot(from);
        _updateTotalSupplySnapshot();
      } else {
        // transfer
        _updateAccountSnapshot(from);
        _updateAccountSnapshot(to);
      }
    }

    function _valueAt(uint256 snapshotId, Snapshots storage snapshots)
        private view returns (bool, uint256)
    {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");
        // solhint-disable-next-line max-line-length
        require(snapshotId <= _currentSnapshotId.current(), "ERC20Snapshot: nonexistent id");

        // When a valid snapshot is queried, there are three possibilities:
        //  a) The queried value was not modified after the snapshot was taken. Therefore, a snapshot entry was never
        //  created for this id, and all stored snapshot ids are smaller than the requested one. The value that corresponds
        //  to this id is the current one.
        //  b) The queried value was modified after the snapshot was taken. Therefore, there will be an entry with the
        //  requested id, and its value is the one to return.
        //  c) More snapshots were created after the requested one, and the queried value was later modified. There will be
        //  no entry for the requested id: the value that corresponds to it is that of the smallest snapshot id that is
        //  larger than the requested one.
        //
        // In summary, we need to find an element in an array, returning the index of the smallest value that is larger if
        // it is not found, unless said value doesn't exist (e.g. when all values are smaller). Arrays.findUpperBound does
        // exactly this.

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    function _updateAccountSnapshot(address account) private {
        _updateSnapshot(_accountBalanceSnapshots[account], balanceOf(account));
    }

    function _updateTotalSupplySnapshot() private {
        _updateSnapshot(_totalSupplySnapshots, totalSupply());
    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {
        uint256 currentId = _currentSnapshotId.current();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }
}

// File: contracts/NftfyToken.sol

pragma solidity ^0.6.0;





contract NftfyToken is Ownable, ERC20Burnable, ERC20Snapshot
{
	uint256 constant TOTAL_SUPPLY = 100_000_000e18; // 100 million

	constructor () ERC20("Nftfy Token", "NFTFY") public
	{
		address _from = msg.sender;
		_setupDecimals(18);
		_mint(_from, TOTAL_SUPPLY);
	}

	function snapshot() external onlyOwner returns (uint256 _snapshotId)
	{
		return _snapshot();
	}

	function _beforeTokenTransfer(address _from, address _to, uint256 _amount) internal override(ERC20, ERC20Snapshot)
	{
		ERC20Snapshot._beforeTokenTransfer(_from, _to, _amount);
	}
}

contract DaiToken is ERC20
{
	uint256 constant TOTAL_SUPPLY = 100_000_000e18; // 100 million

	constructor () ERC20("Dai", "DAI") public
	{
		address _from = msg.sender;
		_setupDecimals(18);
		_mint(_from, TOTAL_SUPPLY);
	}
}

// File: contracts/WrappedToken.sol

pragma solidity ^0.6.0;


interface WrappedToken is IERC20
{
	function deposit() external payable;
	function withdraw(uint256 _amount) external;
}

// File: contracts/Migrations.sol

pragma solidity ^0.6.0;

contract Migrations
{
	address public owner;
	uint256 public last_completed_migration;

	modifier restricted()
	{
		if (msg.sender == owner) _;
	}

	constructor() public
	{
		owner = msg.sender;
	}

	function setCompleted(uint256 _completed) public restricted
	{
		last_completed_migration = _completed;
	}
}

// File: contracts/UniswapV2.sol

pragma solidity ^0.6.0;

interface Router01
{
	function getAmountsIn(uint256 _amountOut, address[] calldata _path) external view returns (uint[] memory _amounts);

	function swapETHForExactTokens(uint256 _amountOut, address[] calldata _path, address _to, uint256 _deadline) external payable returns (uint256[] memory _amounts);
}

interface Router02 is Router01
{
}