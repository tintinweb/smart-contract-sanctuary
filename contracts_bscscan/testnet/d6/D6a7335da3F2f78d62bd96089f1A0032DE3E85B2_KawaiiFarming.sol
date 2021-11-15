// SPDX-License-Identifier: MIТ

pragma solidity 0.6.12;

/**
* @dev Interface of the ERC20 standard as defined in the EIP.
*/
interface IBEP20 {
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
    * zero by default.a
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
        assembly {size := extcodesize(account)}
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
        (bool success,) = recipient.call{value : amount}("");
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
        (bool success, bytes memory returndata) = target.call{value : value}(data);
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
    * _Available since v3.3._
    */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
    * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
    * but performing a delegate call.
    *
    * _Available since v3.3._
    */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns (bytes memory) {
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

/**
* @title SafeERC20
* @dev Wrappers around ERC20 operations that throw on failure (when the token
* contract returns false). Tokens that return no value (and instead revert or
* throw on failure) are also supported, non-reverting calls are assumed to be
* successful.
* To use this library you can add a `using SafeERC20 for IBEP20;` statement to your contract,
* which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
*/
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
    * @dev Deprecated. This function has issues similar to the ones found in
    * {IBEP20-approve}, and its usage is discouraged.
    *
    * Whenever possible, use {safeIncreaseAllowance} and
    * {safeDecreaseAllowance} instead.
    */
    function safeApprove(IBEP20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
    * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
    * on the return value: the return value is optional (but if data is returned, it must not be false).
    * @param token The token targeted by the call.
    * @param data The call data (encoded using abi.encode or one of its variants).
    */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {// Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

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
                set._indexes[lastvalue] = valueIndex;
                // Replace lastvalue's index to valueIndex
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

contract SignData {
    bytes32 public DOMAIN_SEPARATOR;
    string public NAME;
    bytes32 public DEPOSIT_HASH;
    bytes32 public WITHDRAW_HASH;
    mapping(address => uint) public nonces;


    function initData() internal {
        NAME = "KawaiiFarming";
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(NAME)),
                keccak256(bytes('1')),
                chainId,
                this
            )
        );


        DEPOSIT_HASH = keccak256("Data(uint256 pid,address sender,uint256 nonce)");
        WITHDRAW_HASH = keccak256("Data(uint256 pid,address sender,uint256 nonce)");
    }

    function verify(bytes32 data, address sender, uint8 v, bytes32 r, bytes32 s) internal view {
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                data
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == sender, "Invalid nonce");
    }
}

interface IBEP1155 {

    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;

}


contract KawaiiFarming is SignData {
    using SafeMath for uint256;
    using SafeERC20 for IBEP20;
    using EnumerableSet for EnumerableSet.UintSet;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 pendingRewards;
    }

    struct PoolInfo {
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accPerShare;
        uint256 balance;
    }

    IBEP20 public rewardToken;

    IBEP1155 public kawaiiCore;

    uint256 public perBlock;

    PoolInfo[] public poolInfo;

    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // user=> pid=> nftId
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) public userDataNFT;

    mapping(uint256 => EnumerableSet.UintSet) internal idOfPids;

    uint256 public totalAllocPoint;

    uint256 public startBlock;

    bool public initialized;

    address public owner;

    event PoolUpdated(uint256 indexed pid, uint256 allocPoint, uint256 lastRewardBlock, uint256 indexed accPerShare, uint256 indexed balance);
    event Deposit(address indexed _caller, uint256 indexed _pid, uint256[] _ids, uint256[] _amounts, uint256 userAmount, uint256 userPendingRewards, uint256 userRewardDebt);
    event Withdraw(address indexed _caller, uint256 indexed _pid, uint256[] _ids, uint256[] _amounts, uint256 userAmount, uint256 userPendingRewards, uint256 userRewardDebt);
    event Claim(address indexed user, uint256 indexed pid, uint256 claimedAmout, uint256 userAmount, uint256 userPendingRewards, uint256 userRewardDebt);

    function init(IBEP20 _rewardToken, uint256 _perBlock, uint256 _startBlock, IBEP1155 _kawaiCore) public {
        require(initialized == false);
        initData();
        rewardToken = _rewardToken;
        perBlock = _perBlock;
        startBlock = _startBlock;
        kawaiiCore = _kawaiCore;
        owner = msg.sender;
        initialized = true;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "!caller must owner");
        _;
    }


    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function setPerBlock(uint256 _perBlock) public onlyOwner {
        require(_perBlock > 0, "!perBlock-0");
        massUpdatePools();
        perBlock = _perBlock;
    }

    function setKawaiiCore(IBEP1155 _kawaiCore) public onlyOwner {
        kawaiiCore = _kawaiCore;
    }

    function setRewardToken(IBEP20 _rewardToken) public onlyOwner {
        rewardToken = _rewardToken;
    }

    function add(uint256 _allocPoint, bool _withUpdate, uint256[] calldata ids) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo(_allocPoint, lastRewardBlock, 0, 0));

        uint256 pid = poolInfo.length.sub(1);
        for (uint256 i = 0; i < ids.length; i++) {
            idOfPids[pid].add(ids[i]);
        }
    }

    function addIdOfPid(uint256 _pid, uint256[] calldata _ids) external onlyOwner {
        for (uint256 i = 0; i < _ids.length; i++) {
            idOfPids[_pid].add(_ids[i]);
        }
    }

    function removeIdOfPid(uint256 _pid, uint256[] calldata _ids) external onlyOwner {
        for (uint256 i = 0; i < _ids.length; i++) {
            idOfPids[_pid].remove(_ids[i]);
        }
    }

    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.balance;
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = block.number.sub(pool.lastRewardBlock);
        uint256 reward = multiplier.mul(perBlock).mul(pool.allocPoint).div(totalAllocPoint);

        pool.accPerShare = pool.accPerShare.add(reward.div(lpSupply));
        pool.lastRewardBlock = block.number;
        emit PoolUpdated(_pid, pool.allocPoint, pool.lastRewardBlock, pool.accPerShare, pool.balance);
    }

    function getIdOFPid(uint256 _pid, uint256 index) external view returns (uint256){
        return idOfPids[_pid].at(index);
    }

    function getLenIdOfPid(uint256 _pid) external view returns (uint256){
        return idOfPids[_pid].length();
    }

    function pending(uint256 _pid, address _user) external view returns (uint256){
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        uint256 accPerShare = pool.accPerShare;
        uint256 lpSupply = pool.balance;
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = block.number.sub(pool.lastRewardBlock);
            uint256 reward = multiplier.mul(perBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accPerShare = accPerShare.add(reward.div(lpSupply));
        }
        return user.amount.mul(accPerShare).sub(user.rewardDebt).add(user.pendingRewards);
    }

    function depositPermit(address sender, uint256 _pid, uint256[] calldata _ids, uint256[] calldata _amounts, uint8 v, bytes32 r, bytes32 s) public {
        verify(keccak256(abi.encode(DEPOSIT_HASH, _pid, sender, nonces[sender]++)), sender, v, r, s);
        _deposit(sender, _pid, _ids, _amounts);
    }

    function deposit(uint256 _pid, uint256[] calldata _ids, uint256[] calldata _amounts) external {
        _deposit(msg.sender, _pid, _ids, _amounts);
    }

    function _deposit(address _caller, uint256 _pid, uint256[] memory _ids, uint256[] memory _amounts) internal {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_caller];
        updatePool(_pid);
        require(_ids.length == _amounts.length, "input invalid");
        uint256 total;

        for (uint256 i = 0; i < _ids.length; i++) {
            require(idOfPids[_pid].contains(_ids[i]), "pid not support id");
            total = total.add(_amounts[i]);
            userDataNFT[_caller][_pid][_ids[i]] = userDataNFT[_caller][_pid][_ids[i]].add(_amounts[i]);
            kawaiiCore.safeTransferFrom(_caller, address(this), _ids[i], _amounts[i], "0x");
        }

        if (user.amount > 0) {
            uint256 _pending = user.amount.mul(pool.accPerShare).sub(user.rewardDebt).add(user.pendingRewards);
            if (_pending > 0) {
                user.pendingRewards = _pending;
            }
        }
        if (total > 0) {
            poolInfo[_pid].balance = pool.balance.add(total);
            user.amount = user.amount.add(total);
        }
        user.rewardDebt = user.amount.mul(pool.accPerShare);
        emit Deposit(_caller, _pid, _ids, _amounts, user.amount, user.pendingRewards, user.rewardDebt);
    }

    function withdrawPermit(address sender, uint256 _pid, uint256[] calldata _ids, uint256[] calldata _amounts, uint8 v, bytes32 r, bytes32 s) external {
        verify(keccak256(abi.encode(WITHDRAW_HASH, _pid, sender, nonces[sender]++)), sender, v, r, s);
        _withdraw(sender, _pid, _ids, _amounts);
    }

    function withdraw(uint256 _pid, uint256[] calldata _ids, uint256[] calldata _amounts) external {
        _withdraw(msg.sender, _pid, _ids, _amounts);
    }

    function _withdraw(address _caller, uint256 _pid, uint256[] memory _ids, uint256[] memory _amounts) internal {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_caller];
        updatePool(_pid);
        uint256 _pending = user.amount.mul(pool.accPerShare).sub(user.rewardDebt).add(user.pendingRewards);
        if (_pending > 0) {
            user.pendingRewards = _pending;
        }

        uint256 total;
        for (uint256 i = 0; i < _ids.length; i++) {
            userDataNFT[_caller][_pid][_ids[i]] = userDataNFT[_caller][_pid][_ids[i]].sub(_amounts[i], "amounts exceed deposited");
            total = total.add(_amounts[i]);
            kawaiiCore.safeTransferFrom(address(this), _caller, _ids[i], _amounts[i], "0x");
        }
        if (total > 0) {
            poolInfo[_pid].balance = pool.balance.sub(total);
            user.amount = user.amount.sub(total, "withdraw: not good");
        }
        user.rewardDebt = user.amount.mul(pool.accPerShare);
        emit  Withdraw(_caller, _pid, _ids, _amounts, user.amount, user.pendingRewards, user.rewardDebt);


    }

    function claim(uint256 _pid, address _account) public {
        UserInfo storage user = userInfo[_pid][_account];
        updatePool(_pid);
        uint256 _pending = user.amount.mul(poolInfo[_pid].accPerShare).sub(user.rewardDebt).add(user.pendingRewards);
        uint256 claimedReward;
        if (_pending > 0 || user.pendingRewards > 0) {
            claimedReward = safeTransferReward(_account, _pending);
            user.pendingRewards = _pending.sub(claimedReward);
        }
        user.rewardDebt = user.amount.mul(poolInfo[_pid].accPerShare);
        emit Claim(_account, _pid, claimedReward, user.amount, user.pendingRewards, user.rewardDebt);
    }


    function safeTransferReward(address _to, uint256 _amount) internal returns (uint256){
        uint256 poolBalance = rewardToken.balanceOf(address(this));
        if (_amount > poolBalance) {
            _amount = poolBalance;
        }
        IBEP20(rewardToken).safeTransfer(_to, _amount);
        return _amount;
    }


    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns (bytes4){
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external returns (bytes4){
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

}

