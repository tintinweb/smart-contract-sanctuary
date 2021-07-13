/**
 *Submitted for verification at Etherscan.io on 2021-07-13
*/

// File: contracts/FarmStorage.sol

pragma solidity ^0.6.0;

contract FarmAdminStorage {
    address public admin;

    address public implementation;
}

contract FarmStorageV1 is FarmAdminStorage {
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardGanDebt; //user Debt for 2 month（continuous Mining）
        uint256 rewardLockGanDebt; //user Debt for 10 mon th(concentrated Mining)
        uint256 rewardUsdtDebt; //user Debt for 10 mon th(concentrated Mining)
        uint256 lockPending;
        uint256 lastRewardBlock;
    }

    // Info of each pool.
    struct PoolInfo {
        address lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. MDXs to distribute per block.
        uint256 lastRewardBlock; // Last block number that Gans distribution occurs.
        uint256 accGanPerShare; //PerShare for continuous Mining
        uint256 accLockGanPerShare; //PerShare for concentrated Mining
        uint256 accUsdtPerShare;
        uint256 totalAmount; // Total amount of current pool deposit.
        uint256 lastAccLockGanPerShare; //last year PerShare for concentrated Mining (corculate pengding gan)
    }

    uint256 public startBlockOfGan;

    address public gandalf;

    uint256 public ganPerBlockConcentratedMining; // concentrated Mining per block gan
    uint256 public ganPerBlockContinuousMining; // continuous Mining per block gan

    address public usdt;
    uint256 public usdtPerBlock;
    uint256 public usdtStartBlock;
    uint256 public usdtEndBlock;
    uint256 public cycle;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Control mining
    bool public paused = false;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when gandalf mining starts.

    // How many blocks are halved
    uint256 public halvingPeriod0;
    uint256 public halvingPeriod1;

    mapping(address => uint256) public pidOfLP;
}

// File: contracts/libraries/EnumerableSet.sol

pragma solidity >=0.6.0;

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

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1;
            // All indexes are 1-based

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
    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
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
    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        require(
            set._values.length > index,
            "EnumerableSet: index out of bounds"
        );
        return set._values[index];
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
    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
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
    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
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
    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
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
    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }
}

// File: contracts/libraries/TransferHelper.sol

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

// File: contracts/interfaces/IGan.sol

pragma solidity >=0.6.0;



interface IGan {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function burn(uint256 value) external;

    function mint(address to, uint256 value) external;

    function initialize(
        string memory _name,
        string memory _symbol,
        address market
    ) external;

    function getPriorVotes(address account, uint256 blockNumber)
        external
        view
        returns (uint256);
}

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
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

// File: contracts/FarmDelegate.sol

pragma solidity ^0.6.0;







contract FarmDelegate is FarmStorageV1 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _blackList;
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    function initialize(
        address _Gan,
        address _usdt,
        uint256 _ganPerBlock0,
        uint256 _ganPerBlock1,
        uint256 _startBlock,
        uint256 _cycle
    ) public {
        require(msg.sender == admin, "unautherized");
        gandalf = _Gan;
        usdt = _usdt;
        ganPerBlockConcentratedMining = _ganPerBlock0;
        ganPerBlockContinuousMining = _ganPerBlock1;
        startBlockOfGan = _startBlock;
        cycle = _cycle;
    }

    function setHalvingPeriod(uint256 _block0, uint256 _block1) public {
        require(msg.sender == admin, "unauthorized");
        halvingPeriod0 = _block0;
        halvingPeriod1 = _block1;
    }

    // Set the number of gandalf produced by each block
    function setGanPerBlock(uint256 newPerBlock0, uint256 newPerBlock1) public {
        require(msg.sender == admin, "unauthorized");
        massUpdatePools();
        ganPerBlockConcentratedMining = newPerBlock0;
        ganPerBlockContinuousMining = newPerBlock1;
    }

    function poolLength() public view returns (uint256) {
        return poolInfo.length;
    }

    function setPause() public {
        require(msg.sender == admin, "unauthorized");
        paused = !paused;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        address _lpToken,
        bool _withUpdate
    ) public {
        require(msg.sender == admin, "unauthorized");
        require(_lpToken != address(0), "_lpToken is the zero address");

        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlockOfGan
            ? block.number
            : startBlockOfGan;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accGanPerShare: 0,
                accLockGanPerShare: 0,
                accUsdtPerShare: 0,
                totalAmount: 0,
                lastAccLockGanPerShare: 0
            })
        );

        uint256 pid = poolInfo.length - 1;
        pidOfLP[_lpToken] = pid;
    }

    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = IERC20(pool.lpToken).balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        (uint256 blockLockReward, uint256 blockReward) = getGanBlockReward(
            pool.lastRewardBlock
        );
        if (blockLockReward <= 0 && blockReward <= 0) {
            return;
        }

        uint256 ganLockReward = blockLockReward.mul(pool.allocPoint).div(
            totalAllocPoint
        );
        uint256 ganReward = blockReward.mul(pool.allocPoint).div(
            totalAllocPoint
        );
        uint256 totalReward = ganLockReward.add(ganReward);
        IGan(gandalf).mint(address(this), totalReward);

        pool.accLockGanPerShare = pool.accLockGanPerShare.add(
            ganLockReward.mul(1e12).div(lpSupply)
        );
        pool.accGanPerShare = pool.accGanPerShare.add(
            ganReward.mul(1e12).div(lpSupply)
        );

        uint256 number = block.number > usdtEndBlock
            ? usdtEndBlock
            : block.number;
        if (number > usdtStartBlock) {
            uint256 multiplier = number.sub(pool.lastRewardBlock);
            uint256 usdtReward = multiplier
            .mul(usdtPerBlock)
            .mul(pool.allocPoint)
            .div(totalAllocPoint);
            pool.accUsdtPerShare = pool.accUsdtPerShare.add(
                usdtReward.mul(1e12).div(lpSupply)
            );
        }

        //update lastAccLockGanPerShare

        uint256 lastAccLockGanPerShare = getLastAccLockGanPerShare(_pid);
        if (lastAccLockGanPerShare != pool.lastAccLockGanPerShare) {
            pool.lastAccLockGanPerShare = lastAccLockGanPerShare;
        }
        pool.lastRewardBlock = block.number;
    }

    function phase(uint256 blockNumber) public view returns (uint256) {
        uint256 halvingPeriod = halvingPeriod0.add(halvingPeriod1);
        if (halvingPeriod == 0) {
            return 0;
        }
        if (blockNumber > startBlockOfGan) {
            return (blockNumber.sub(startBlockOfGan).sub(1)).div(halvingPeriod);
        }
        return 0;
    }

    function reward(uint256 blockNumber) public view returns (uint256) {
        uint256 _phase = phase(blockNumber);
        if (isHalvingPeriod0(blockNumber))
            return ganPerBlockConcentratedMining.div(2**_phase);
        else ganPerBlockContinuousMining.div(2**_phase);
    }

    function isHalvingPeriod0(uint256 blockNumber) public view returns (bool) {
        uint256 halvingPeriod = halvingPeriod0.add(halvingPeriod1);
        if (blockNumber > startBlockOfGan) {
            return
                blockNumber.sub(startBlockOfGan).sub(1).mod(halvingPeriod) <
                    halvingPeriod0
                    ? true
                    : false;
        }

        return true;
    }

    function getGanBlockReward(uint256 _lastRewardBlock)
        public
        view
        returns (uint256, uint256)
    {
        uint256 blockReward = 0;
        uint256 blockLockReward = 0;
        uint256 halvingPeriod = halvingPeriod0.add(halvingPeriod1);
        uint256 n = phase(_lastRewardBlock);
        uint256 m = phase(block.number);
        while (n < m) {
            n++;
            uint256 r = n.mul(halvingPeriod).add(startBlockOfGan);
            uint256 switchBlock = (n - 1)
            .mul(halvingPeriod)
            .add(startBlockOfGan)
            .add(halvingPeriod0);
            //先把本周期的集中挖矿的收益计算出来
            if (switchBlock > _lastRewardBlock) {
                blockLockReward = blockLockReward.add(
                    (switchBlock.sub(_lastRewardBlock)).mul(
                        reward(_lastRewardBlock)
                    )
                );
            }

            // 再把本周期持续挖矿的数量计算出来
            blockReward = blockReward.add(
                (r.sub(switchBlock)).mul(reward(switchBlock.add(1)))
            );

            _lastRewardBlock = r;
        }
        uint256 switchBlock = m.mul(halvingPeriod).add(startBlockOfGan).add(
            halvingPeriod0
        );

        if (switchBlock >= block.number) {
            //把最近周期的集中挖矿的收益计算出来
            blockLockReward = blockLockReward.add(
                (block.number.sub(_lastRewardBlock)).mul(
                    reward(_lastRewardBlock)
                )
            );
        } else {
            //先把最近周期的集中挖矿的收益计算出来
            blockLockReward = blockLockReward.add(
                (switchBlock.sub(_lastRewardBlock)).mul(
                    reward(_lastRewardBlock)
                )
            );
            // 再把最近周期持续挖矿的数量计算出来
            blockReward = blockReward.add(
                (block.number.sub(switchBlock)).mul(reward(switchBlock.add(1)))
            );
        }

        return (blockLockReward, blockReward);
    }

    function pending(uint256 _pid, address _user)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        //PoolInfo storage pool = poolInfo[_pid];

        uint256 ganAmount = pendingGan(_pid, _user);
        uint256 usdtAmount = pendingUsdt(_pid, _user);
        return (ganAmount, usdtAmount, block.number);
    }

    function pendingUsdt(uint256 _pid, address _user)
        private
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accUsdtPerShare = pool.accUsdtPerShare;
        uint256 number = block.number > usdtEndBlock
            ? usdtEndBlock
            : block.number;
        uint256 lpSupply = IERC20(pool.lpToken).balanceOf(address(this));
        if (number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = number.sub(pool.lastRewardBlock);
            uint256 usdtReward = multiplier
            .mul(usdtPerBlock)
            .mul(pool.allocPoint)
            .div(totalAllocPoint);
            accUsdtPerShare = accUsdtPerShare.add(
                usdtReward.mul(1e12).div(lpSupply)
            );
        }
        return
            user.amount.mul(accUsdtPerShare).div(1e12).sub(user.rewardUsdtDebt);
    }

    function pendingGan(uint256 _pid, address _user)
        private
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accGanPerShare = pool.accGanPerShare;
        uint256 accLockGanPerShare = pool.accLockGanPerShare;
        uint256 lpSupply = IERC20(pool.lpToken).balanceOf(address(this));
        if (user.amount > 0) {
            if (block.number > pool.lastRewardBlock) {
                (
                    uint256 blockReward,
                    uint256 blockLockReward
                ) = getGanBlockReward(pool.lastRewardBlock);
                blockReward = blockReward.mul(pool.allocPoint).div(
                    totalAllocPoint
                );
                blockLockReward = blockLockReward.mul(pool.allocPoint).div(
                    totalAllocPoint
                );
                accGanPerShare = accGanPerShare.add(
                    blockReward.mul(1e12).div(lpSupply)
                );
                accLockGanPerShare = accLockGanPerShare.add(
                    blockLockReward.mul(1e12).div(lpSupply)
                );
                uint256 userReward = user
                .amount
                .mul(accGanPerShare)
                .div(1e12)
                .sub(user.rewardGanDebt);

                uint256 userLockReward = user
                .amount
                .mul(accLockGanPerShare)
                .div(1e12)
                .sub(user.rewardLockGanDebt)
                .add(user.lockPending);
                uint256 stillLockReward = getUserLockReward(_pid, _user);
                return userReward.add(userLockReward).sub(stillLockReward);
            }
            if (block.number == pool.lastRewardBlock) {
                return 0;
            }
        }
        return 0;
    }

    function getUserLockReward(uint256 _pid, address _user)
        private
        view
        returns (uint256)
    {
        UserInfo storage user = userInfo[_pid][_user];
        PoolInfo storage pool = poolInfo[_pid];
        uint256 halvingPeriod = halvingPeriod0.add(halvingPeriod1);
        //判断池子更新点和用户更新点是不是同一阶段 同一阶段的话 加在lockAmount上 ，不同阶段的话重新计算lockAmount
        uint256 m = phase(block.number);
        uint256 n = phase(user.lastRewardBlock);
        //
        uint256 accLockGanPerShare = pool.accLockGanPerShare;
        uint256 lastAccLockGanPerShare = getLastAccLockGanPerShare(_pid);
        uint256 totalLockPendingAmount;
        if (m > n) {
            uint256 rewardDebt = user.amount.mul(lastAccLockGanPerShare).div(
                1e12
            );
            totalLockPendingAmount = user
            .amount
            .mul(accLockGanPerShare)
            .div(1e12)
            .sub(rewardDebt);
        } else {
            totalLockPendingAmount = user
            .amount
            .mul(pool.accLockGanPerShare)
            .div(1e12)
            .sub(user.rewardLockGanDebt)
            .add(user.lockPending);
        }

        //get unlock gan Amount

        uint256 switchBlock = m.mul(halvingPeriod).add(startBlockOfGan).add(
            halvingPeriod0
        );
        uint256 realLockGanReward;
        if (block.number > switchBlock) {
            uint256 unLockGanReward = block
            .number
            .sub(switchBlock)
            .mul(totalLockPendingAmount)
            .div(halvingPeriod1);
            realLockGanReward = totalLockPendingAmount.sub(unLockGanReward);
        } else realLockGanReward = totalLockPendingAmount;

        return realLockGanReward;
    }

    function getLastAccLockGanPerShare(uint256 _pid)
        private
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 lastRewardBlock = pool.lastRewardBlock;
        uint256 m = phase(block.number);
        uint256 n = phase(lastRewardBlock);
        uint256 halvingPeriod = halvingPeriod0.add(halvingPeriod1);
        uint256 blockLockReward = 0;
        uint256 lastAccLockGanPerShare = pool.lastAccLockGanPerShare;
        uint256 accLockGanPerShare = pool.accLockGanPerShare;
        while (m > n) {
            n++;
            uint256 r = n.mul(halvingPeriod).add(startBlockOfGan);
            //获取上个阶段之前的所有集中挖矿奖励
            uint256 switchBlock = (n - 1)
            .mul(halvingPeriod)
            .add(startBlockOfGan)
            .add(halvingPeriod0);
            if (switchBlock > lastRewardBlock) {
                blockLockReward = blockLockReward.add(
                    (switchBlock.sub(lastRewardBlock)).mul(
                        reward(lastRewardBlock)
                    )
                );
            }
            lastRewardBlock = r;
        }
        blockLockReward = blockLockReward.mul(pool.allocPoint).div(
            totalAllocPoint
        );
        uint256 lpSupply = IERC20(pool.lpToken).balanceOf(address(this));
        lastAccLockGanPerShare = accLockGanPerShare.add(
            blockLockReward.mul(1e12).div(lpSupply)
        );
        return lastAccLockGanPerShare;
    }

    function deposit(uint256 _pid, uint256 _amount) public {
        //require(!isBadAddress(msg.sender), "Illegal, rejected ");
        // if (Address.isContract(msg.sender)) {
        //     require(isWhiteListAddress(msg.sender), "Illegal, rejected ");
        // }
        //PoolInfo storage pool = poolInfo[_pid];

        depositLPToken(_pid, _amount, msg.sender);
    }

    function depositLPToken(
        uint256 _pid,
        uint256 _amount,
        address _user
    ) private {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        updatePool(_pid);
        uint256 stillLockReward;
        if (user.amount > 0) {
            uint256 userReward = user
            .amount
            .mul(pool.accGanPerShare)
            .div(1e12)
            .sub(user.rewardGanDebt);

            uint256 userLockReward = user
            .amount
            .mul(pool.accLockGanPerShare)
            .div(1e12)
            .sub(user.rewardLockGanDebt)
            .add(user.lockPending);
            stillLockReward = getUserLockReward(_pid, _user);
            uint256 pendingAmount = userReward.add(userLockReward).sub(
                stillLockReward
            );
            if (pendingAmount > 0) {
                safeGanTransfer(_user, pendingAmount);
            }

            uint256 usdtReward = user
            .amount
            .mul(pool.accUsdtPerShare)
            .div(1e12)
            .sub(user.rewardUsdtDebt);

            if (usdtReward > 0) {
                IERC20(usdt).safeTransfer(_user, usdtReward);
            }
        }
        if (_amount > 0) {
            IERC20(pool.lpToken).safeTransferFrom(
                _user,
                address(this),
                _amount
            );

            user.amount = user.amount.add(_amount);
            pool.totalAmount = pool.totalAmount.add(_amount);
        }
        user.rewardGanDebt = user.amount.mul(pool.accGanPerShare).div(1e12);
        user.lockPending = stillLockReward;
        user.rewardLockGanDebt = user.amount.mul(pool.accLockGanPerShare).div(
            1e12
        );
        user.rewardUsdtDebt = user.amount.mul(pool.accUsdtPerShare).div(1e12);
        emit Deposit(_user, _pid, _amount);
    }

    function withdraw(uint256 _pid, uint256 _amount) public {
        // PoolInfo storage pool = poolInfo[_pid];

        withdrawLPToken(_pid, _amount, msg.sender);
    }

    function withdrawLPToken(
        uint256 _pid,
        uint256 _amount,
        address _user
    ) private {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 stillLockReward;
        if (user.amount >= 0) {
            uint256 userReward = user
            .amount
            .mul(pool.accGanPerShare)
            .div(1e12)
            .sub(user.rewardGanDebt);

            uint256 userLockReward = user
            .amount
            .mul(pool.accLockGanPerShare)
            .div(1e12)
            .sub(user.rewardLockGanDebt)
            .add(user.lockPending);
            stillLockReward = getUserLockReward(_pid, _user);
            uint256 pendingAmount = userReward.add(userLockReward).sub(
                stillLockReward
            );
            if (pendingAmount > 0) {
                safeGanTransfer(_user, pendingAmount);
            }
            uint256 usdtReward = user
            .amount
            .mul(pool.accUsdtPerShare)
            .div(1e12)
            .sub(user.rewardUsdtDebt);

            if (usdtReward > 0) {
                IERC20(usdt).safeTransfer(_user, usdtReward);
            }
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.totalAmount = pool.totalAmount.sub(_amount);
            IERC20(pool.lpToken).safeTransfer(_user, _amount);
        }
        user.rewardGanDebt = user.amount.mul(pool.accGanPerShare).div(1e12);
        user.lockPending = stillLockReward;
        user.rewardLockGanDebt = user.amount.mul(pool.accLockGanPerShare).div(
            1e12
        );
        user.rewardUsdtDebt = user.amount.mul(pool.accUsdtPerShare).div(1e12);
        emit Withdraw(_user, _pid, _amount);
    }

    function safeGanTransfer(address _to, uint256 _amount) internal {
        uint256 ganBal = IGan(gandalf).balanceOf(address(this));
        if (_amount > ganBal) {
            IGan(gandalf).transfer(_to, ganBal);
        } else {
            IGan(gandalf).transfer(_to, _amount);
        }
    }

    function newReward(
        uint256 _usdtAmount,
        uint256 _newPerBlock,
        uint256 _startBlock
    ) public {
        require(msg.sender == admin, "unauthorized");
        require(
            block.number > usdtEndBlock && _startBlock >= usdtEndBlock,
            "Not finished"
        );
        massUpdatePools();
        uint256 beforeAmount = IERC20(usdt).balanceOf(address(this));
        TransferHelper.safeTransferFrom(
            usdt,
            msg.sender,
            address(this),
            _usdtAmount
        );
        uint256 afterAmount = IERC20(usdt).balanceOf(address(this));
        uint256 balance = afterAmount.sub(beforeAmount);
        require(balance == _usdtAmount, "Error balance");
        require(
            balance > 0 && (cycle * _newPerBlock) <= balance,
            "Balance not enough"
        );
        usdtPerBlock = _newPerBlock;
        usdtStartBlock = _startBlock;
        usdtEndBlock = _startBlock.add(cycle);
        // updatePoolLastRewardBlock(_startBlock);
    }
}