// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2Upgradeable {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(uint256 amount, bytes32 salt, bytes memory bytecode) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) internal pure returns (address) {
        bytes32 _data = keccak256(
            abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash)
        );
        return address(uint160(uint256(_data)));
    }
}

// SPDX-License-Identifier: MIT

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
library EnumerableSetUpgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts-upgradeable/utils/Create2Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "./Battle.sol";
import "./structs/RangeType.sol";

pragma solidity ^0.8.0;

contract Arena {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    EnumerableSetUpgradeable.AddressSet private battleSet;

    function battleLength() public view returns (uint256 len) {

        len = battleSet.length();
    }

    function addBattle(address _battle) public {
        battleSet.add(_battle);
    }

    function getBattle(uint index) public view returns(address _battle) {
        _battle = battleSet.at(index);
    } 

    function removeBattle(address _battle) public {
        battleSet.remove(_battle);
    }

    function containBattle(address _battle) public view returns(bool){
        return battleSet.contains(_battle);
    }

    function createBattle(
        address  _collateral,
        IOracle _oracle,
        string memory _trackName,
        string memory _priceName,
        uint256 amount,
        uint256 _spearPrice,
        uint256 _shieldPrice,
        uint256 _range,
        RangeType _ry,
        uint durType
    ) public {
        IERC20Upgradeable(_collateral).safeTransferFrom(msg.sender, address(this), amount);
        // bytes32 salt = keccak256(abi.encodePacked(_collateral, _trackName, block.timestamp));
        // address battle =
        //     Create2Upgradeable.deploy(
        //         0,
        //         salt,
        //         type(Battle).creationCode
        //     );
        Battle battle = new Battle(_collateral, _oracle, _trackName, _priceName);
        IERC20Upgradeable(_collateral).safeTransfer(address(this), amount);
        battle.init(msg.sender, amount, _spearPrice, _shieldPrice, _range, _ry, durType);
        battleSet.add(address(battle));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IBattle.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./lib/SafeDecimalMath.sol";
import "./lib/DMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IOracle.sol";
import "./structs/RoundInfo.sol";
import "./algo/Pricing.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// import "hardhat/console.sol";

/**@title Battle contains multi-round */
contract Battle is Ownable, Initializable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeDecimalMath for uint256;
    using DMath for uint256;

    IOracle public oracle;

    /// @dev user's lp balance per round
    mapping(uint256 => mapping(address => uint256)) public lpBalanceOf;
    mapping(uint256 => uint256) public lpTotalSupply;
    /// @dev user's spear balance per round
    mapping(uint256 => mapping(address => uint256)) public spearBalanceOf;
    mapping(uint256 => uint256) public totalSpear;
    /// @dev user's shield balance per round
    mapping(uint256 => mapping(address => uint256)) public shieldBalanceOf;
    mapping(uint256 => uint256) public totalShield;
    /// @dev collateral token belong to spear side
    mapping(uint256 => uint256) public collateralSpear;
    /// @dev collateral token belong to shield side
    mapping(uint256 => uint256) public collateralShield;
    /// @dev collateral token belong to non-spear and non-shield
    mapping(uint256 => uint256) public collateralSurplus;
    /// @dev spear amount belong to the battle contract per round
    // mapping(uint => uint) public spearNum;
    /// @dev shield amount belong to the battle contract per round
    // mapping(uint => uint) public shieldNum;
    mapping(uint256 => uint256) public spearPrice;
    mapping(uint256 => uint256) public shieldPrice;
    mapping(address => uint256) public userStartRoundSS;
    mapping(address => uint256) public userStartRoundLP;

    string public trackName;
    string public priceName;

    uint256 public currentRoundId;
    uint256[] public roundIds;
    mapping(uint256 => RoundInfo) public rounds;

    IERC20 public collateralToken;

    mapping(uint256 => uint256) public sqrt_k_spear;
    mapping(uint256 => uint256) public sqrt_k_shield;

    bool public isFirst = true;
    uint256 public battleDur;

    function roundIdsLen() public view returns (uint256) {
        return roundIds.length;
    }

    constructor(
        address _collateral,
        IOracle _oracle,
        string memory _trackName,
        string memory _priceName
    ) {
        collateralToken = IERC20(_collateral);
        oracle = _oracle;
        trackName = _trackName;
        priceName = _priceName;
    }

    /// @dev init the battle and set the first round's params
    /// this function will become the start point
    /// @param amount The amount of collateral, the collateral can be any ERC20 token contract, such as dai
    /// @param _spearPrice Init price of spear
    /// @param _shieldPrice Init price of shield
    /// @param _range The positive and negative range of price changes
    function init(
        address creater,
        uint256 amount,
        uint256 _spearPrice,
        uint256 _shieldPrice,
        uint256 _range,
        RangeType _ry,
        uint256 _battleDur
    ) external {
        require(isFirst, "not first init");
        require(
            _battleDur == 0 || _battleDur == 1 || _battleDur == 2,
            "Not support battle duration"
        );
        battleDur = _battleDur;
        isFirst = false;
        require(
            _spearPrice.add(_shieldPrice) == 1e18,
            "Battle::init:spear + shield should 1"
        );
        // require(block.timestamp <= _startTS, "Battle::_startTS should in future");
        (uint256 _startTS, uint256 _endTS) = getDurationTs();
        currentRoundId = _startTS;
        roundIds.push(_startTS);
        uint256 price = oracle.price(priceName);
        // uint priceUnder = price.multiplyDecimal(uint(1e18).sub(_range));
        // uint priceSuper = price.multiplyDecimal(uint(1e18).add(_range));
        rounds[_startTS] = RoundInfo({
            spearPrice: _spearPrice,
            shieldPrice: _shieldPrice, // todo
            startPrice: price,
            endPrice: 0,
            startTS: _startTS,
            endTS: _endTS,
            range: _range,
            ry: _ry, // targetPriceUnder: priceUnder,
            targetPriceUnder: price.multiplyDecimal(uint256(1e18).sub(_range)), // targetPriceSuper: priceSuper,
            targetPriceSuper: price.multiplyDecimal(uint256(1e18).add(_range)),
            roundResult: RoundResult.NonResult
        });

        spearBalanceOf[currentRoundId][address(this)] = amount;
        totalSpear[currentRoundId] = totalSpear[currentRoundId].add(amount);
        shieldBalanceOf[currentRoundId][address(this)] = amount;
        totalShield[currentRoundId] = totalShield[currentRoundId].add(amount);
        collateralSpear[currentRoundId] = _spearPrice.multiplyDecimal(amount);
        collateralShield[currentRoundId] = _shieldPrice.multiplyDecimal(amount);
        spearPrice[currentRoundId] = _spearPrice;
        shieldPrice[currentRoundId] = _shieldPrice;
        lpBalanceOf[currentRoundId][creater] = amount;
        userStartRoundLP[creater] = currentRoundId;
        lpTotalSupply[currentRoundId] = lpTotalSupply[currentRoundId].add(
            amount
        );

        // collateralToken.safeTransferFrom(creater, address(this), amount);
    }

    /// @dev The price of spear will not exceed 0.99. When the price is less than 0.99, amm satisfies x*y=k, and when the price exceeds 0.99, it satisfies x+y=k.
    /// @param amount the amount of collateral token, collateral token should a ERC20 token
    /// @dev user has three status: has spear before this round, first this round , not first for this round
    function buySpear(uint256 amount) external {
        if (userStartRoundSS[msg.sender] < currentRoundId) {
            claim();
        }
        userStartRoundSS[msg.sender] = currentRoundId;
        collateralToken.safeTransferFrom(msg.sender, address(this), amount);
        (uint256 spearOut, bool isBigger, uint256 pre_k) =
            getAmountOut(
                amount,
                collateralSpear[currentRoundId],
                spearBalanceOf[currentRoundId][address(this)],
                sqrt_k_spear[currentRoundId]
            );
        sqrt_k_spear[currentRoundId] = pre_k;
        collateralSpear[currentRoundId] = collateralSpear[currentRoundId].add(
            amount
        );
        spearBalanceOf[currentRoundId][address(this)] = spearBalanceOf[
            currentRoundId
        ][address(this)]
            .sub(spearOut);
        spearBalanceOf[currentRoundId][msg.sender] = spearBalanceOf[
            currentRoundId
        ][msg.sender]
            .add(spearOut);
        if (isBigger) {
            collateralShield[currentRoundId] = shieldBalanceOf[currentRoundId][
                address(this)
            ]
                .div(100);
        } else {
            collateralShield[currentRoundId] = spearBalanceOf[currentRoundId][
                address(this)
            ]
                .sub(collateralSpear[currentRoundId])
                .multiplyDecimal(shieldBalanceOf[currentRoundId][address(this)])
                .divideDecimal(spearBalanceOf[currentRoundId][address(this)]);
        }
        _setPrice();
    }

    function _setPrice() internal {
        uint256 spearPriceNow =
            collateralSpear[currentRoundId].divideDecimal(
                spearBalanceOf[currentRoundId][address(this)]
            );
        uint256 shieldPriceNow =
            collateralShield[currentRoundId].divideDecimal(
                shieldBalanceOf[currentRoundId][address(this)]
            );
        if (spearPriceNow >= 99e16 || shieldPriceNow >= 99e16) {
            if (spearPriceNow >= 99e16) {
                spearPrice[currentRoundId] = 99e16;
                shieldPrice[currentRoundId] = 1e16;
            } else {
                spearPrice[currentRoundId] = 1e16;
                shieldPrice[currentRoundId] = 99e16;
            }
        } else {
            spearPrice[currentRoundId] = spearPriceNow;
            shieldPrice[currentRoundId] = shieldPriceNow;
        }
    }

    function spearSold(uint256 _roundId) public view returns (uint256) {
        return
            totalSpear[_roundId].sub(spearBalanceOf[_roundId][address(this)]);
    }

    function buySpearOut(uint256 amount) public view returns (uint256) {
        (uint256 spearOut, , ) =
            getAmountOut(
                amount,
                collateralSpear[currentRoundId],
                spearBalanceOf[currentRoundId][address(this)],
                sqrt_k_spear[currentRoundId]
            );
        return spearOut;
    }

    /// @dev sell spear to battle contract, amm satisfies x*y=k. if the price exceeds 0.99, the price will start form last sqrt(k)
    /// @param amount amount of spear to sell
    function sellSpear(uint256 amount) external {
        uint256 userSpearAmount = spearBalanceOf[currentRoundId][msg.sender];
        require(
            userSpearAmount >= amount,
            "sellSpear::msg.sender has not enough spear to sell"
        );
        uint256 amountOut = sellSpearOut(amount);
        spearBalanceOf[currentRoundId][msg.sender] = userSpearAmount.sub(
            amount
        );
        spearBalanceOf[currentRoundId][address(this)] = spearBalanceOf[
            currentRoundId
        ][address(this)]
            .add(amount);
        _setPrice();
        collateralToken.safeTransfer(msg.sender, amountOut);
    }

    function shieldSold(uint256 _roundId) public view returns (uint256) {
        return
            totalShield[_roundId].sub(shieldBalanceOf[_roundId][address(this)]);
    }

    function sellSpearOut(uint256 amount)
        public
        view
        returns (uint256 amountOut)
    {
        // todo
        if (
            collateralSpear[currentRoundId] >=
            spearBalanceOf[currentRoundId][address(this)].mul(99).div(100)
        ) {
            amountOut = sellAmount(
                amount,
                sqrt_k_spear[currentRoundId],
                sqrt_k_spear[currentRoundId]
            );
        } else {
            amountOut = sellAmount(
                amount,
                spearBalanceOf[currentRoundId][address(this)],
                collateralSpear[currentRoundId]
            );
        }
    }

    /// @dev The price of shield will not exceed 0.99. When the price is less than 0.99, amm satisfies x*y=k, and when the price exceeds 0.99, it satisfies x+y=k.
    /// @param amount the amount of energy token, energy token should a ERC20 token
    function buyShield(uint256 amount) external {
        collateralToken.safeTransferFrom(msg.sender, address(this), amount);
        (uint256 shieldOut, bool isBigger, uint256 pre_k) =
            getAmountOut(
                amount,
                collateralShield[currentRoundId],
                shieldBalanceOf[currentRoundId][address(this)],
                sqrt_k_shield[currentRoundId]
            );
        sqrt_k_shield[currentRoundId] = pre_k;
        collateralShield[currentRoundId] = collateralShield[currentRoundId].add(
            amount
        );
        shieldBalanceOf[currentRoundId][address(this)] = shieldBalanceOf[
            currentRoundId
        ][address(this)]
            .sub(shieldOut);
        shieldBalanceOf[currentRoundId][msg.sender] = shieldBalanceOf[
            currentRoundId
        ][msg.sender]
            .add(shieldOut);
        if (isBigger) {
            collateralSpear[currentRoundId] = spearBalanceOf[currentRoundId][
                address(this)
            ]
                .div(100);
        } else {
            collateralSpear[currentRoundId] = shieldBalanceOf[currentRoundId][
                address(this)
            ]
                .sub(collateralShield[currentRoundId])
                .multiplyDecimal(spearBalanceOf[currentRoundId][address(this)])
                .divideDecimal(shieldBalanceOf[currentRoundId][address(this)]);
        }
        _setPrice();
    }

    function buyShieldOut(uint256 amount) public view returns (uint256) {
        //todo
        (uint256 shieldOut, , ) =
            getAmountOut(
                amount,
                collateralShield[currentRoundId],
                shieldBalanceOf[currentRoundId][address(this)],
                sqrt_k_shield[currentRoundId]
            );
        return shieldOut;
    }

    /// @dev sell spear to battle contract, amm satisfies x*y=k. if the price exceeds 0.99, the price will start form last sqrt(k)
    function sellShield(uint256 amount) external {
        uint256 userShieldAmount = shieldBalanceOf[currentRoundId][msg.sender];
        require(
            userShieldAmount >= amount,
            "sellShield::msg.sender has not enough shield to sell"
        );
        uint256 amountOut = sellShieldOut(amount);
        shieldBalanceOf[currentRoundId][msg.sender] = userShieldAmount.sub(
            amount
        );
        shieldBalanceOf[currentRoundId][address(this)] = shieldBalanceOf[
            currentRoundId
        ][address(this)]
            .add(amount);
        _setPrice();
        collateralToken.safeTransfer(msg.sender, amountOut);
    }

    function sellShieldOut(uint256 amount)
        public
        view
        returns (uint256 amountOut)
    {
        //todo
        if (
            collateralShield[currentRoundId] >=
            shieldBalanceOf[currentRoundId][address(this)].mul(99).div(100)
        ) {
            amountOut = sellAmount(
                amount,
                sqrt_k_shield[currentRoundId],
                sqrt_k_shield[currentRoundId]
            );
        } else {
            amountOut = sellAmount(
                amount,
                shieldBalanceOf[currentRoundId][address(this)],
                collateralShield[currentRoundId]
            );
        }
    }

    function getDurationTs()
        internal
        view
        returns (uint256 start, uint256 end)
    {
        if (battleDur == 0) {
            start = block.timestamp - (block.timestamp % 86400);
            end = start + 86400;
        } else if (battleDur == 1) {
            start = block.timestamp - ((block.timestamp + 259200) % 604800);
            end = start + 604800;
        } else if (battleDur == 2) {}
    }

    /// @dev Announce the results of this round
    /// The final price will be provided by an external third party Oracle
    function settle() external {
        require(
            block.timestamp >= rounds[currentRoundId].endTS,
            "too early to settle"
        );
        require(
            rounds[currentRoundId].roundResult == RoundResult.NonResult,
            "round had settled"
        );
        uint256 price = oracle.price(priceName);
        rounds[currentRoundId].endPrice = price;
        uint256 _range = rounds[currentRoundId].range;
        uint256 priceUnder = price.multiplyDecimal(uint256(1e18).sub(_range));
        uint256 priceSuper = price.multiplyDecimal(uint256(1e18).add(_range));
        (uint256 start_ts, uint256 end_ts) = getDurationTs();
        rounds[block.timestamp] = RoundInfo({
            spearPrice: rounds[roundIds[0]].spearPrice,
            shieldPrice: rounds[roundIds[0]].shieldPrice, // todo
            startPrice: price,
            endPrice: 0,
            startTS: start_ts,
            endTS: end_ts,
            range: _range,
            ry: rounds[currentRoundId].ry,
            targetPriceUnder: priceUnder,
            targetPriceSuper: priceSuper,
            roundResult: RoundResult.NonResult
        });

        // new round
        uint256 collateralAmount;
        if (rounds[currentRoundId].ry == RangeType.TwoWay) {
            if (
                price <= rounds[currentRoundId].targetPriceUnder ||
                price >= rounds[currentRoundId].targetPriceSuper
            ) {
                // spear win
                rounds[currentRoundId].roundResult = RoundResult.SpearWin;
            } else {
                rounds[currentRoundId].roundResult = RoundResult.ShieldWin;
            }
        } else if (rounds[currentRoundId].ry == RangeType.Positive) {
            if (price >= rounds[currentRoundId].targetPriceSuper) {
                rounds[currentRoundId].roundResult = RoundResult.SpearWin;
            } else {
                rounds[currentRoundId].roundResult = RoundResult.ShieldWin;
            }
        } else {
            if (price <= rounds[currentRoundId].targetPriceUnder) {
                rounds[currentRoundId].roundResult = RoundResult.SpearWin;
            } else {
                rounds[currentRoundId].roundResult = RoundResult.ShieldWin;
            }
        }
        if (rounds[currentRoundId].roundResult == RoundResult.SpearWin) {
            spearBalanceOf[block.timestamp][address(this)] = spearBalanceOf[
                currentRoundId
            ][address(this)];
            shieldBalanceOf[block.timestamp][address(this)] = spearBalanceOf[
                currentRoundId
            ][address(this)];
            collateralAmount = spearBalanceOf[currentRoundId][address(this)];
        } else {
            spearBalanceOf[block.timestamp][address(this)] = shieldBalanceOf[
                currentRoundId
            ][address(this)];
            shieldBalanceOf[block.timestamp][address(this)] = shieldBalanceOf[
                currentRoundId
            ][address(this)];
            collateralAmount = shieldBalanceOf[currentRoundId][address(this)];
        }
        spearPrice[block.timestamp] = spearPrice[currentRoundId];
        shieldPrice[block.timestamp] = shieldPrice[currentRoundId];
        collateralSpear[block.timestamp] = spearPrice[block.timestamp]
            .multiplyDecimal(collateralAmount);
        collateralShield[block.timestamp] = shieldPrice[block.timestamp]
            .multiplyDecimal(collateralAmount);
        currentRoundId = block.timestamp;
        roundIds.push(block.timestamp);
    }

    // function needTokenLiqui(uint amount) public view returns(uint _energy0, uint _energy1, uint _reserve0, uint _reserve1) {
    //     _energy0 = energy0.divideDecimal(energy0.add(energy1)).multiplyDecimal(amount);
    //     _energy1 = energy1.divideDecimal(energy0.add(energy1)).multiplyDecimal(amount);
    //     uint per = amount.divideDecimal(energy0.add(energy1));
    //     _reserve0 = per.multiplyDecimal(energy0);
    //     _reserve1 = per.multiplyDecimal(energy1);
    // }

    /// @dev The user adds energy token by calling this function, as well as the corresponding number of spear and shield
    /// @param amount of energy token transfer to battle contract
    function addLiquility(uint256 amount) external {
        if (userStartRoundLP[msg.sender] < currentRoundId) {
            removeLiquility(0);
        }
        // new
        uint256 collateralSS =
            collateralSpear[currentRoundId].add(
                collateralShield[currentRoundId]
            );
        uint256 deltaCollateralSpear =
            collateralSpear[currentRoundId]
                .multiplyDecimal(amount)
                .divideDecimal(collateralSS);
        uint256 deltaCollateralShield =
            collateralShield[currentRoundId]
                .multiplyDecimal(amount)
                .divideDecimal(collateralSS);
        uint256 deltaSpear =
            spearBalanceOf[currentRoundId][address(this)]
                .multiplyDecimal(amount)
                .divideDecimal(collateralSS);
        uint256 deltaShield =
            shieldBalanceOf[currentRoundId][address(this)]
                .multiplyDecimal(amount)
                .divideDecimal(collateralSS);

        collateralSpear[currentRoundId] = collateralSpear[currentRoundId].add(
            deltaCollateralSpear
        );
        collateralShield[currentRoundId] = collateralShield[currentRoundId].add(
            deltaCollateralShield
        );
        spearBalanceOf[currentRoundId][address(this)] = spearBalanceOf[
            currentRoundId
        ][address(this)]
            .add(deltaSpear);
        shieldBalanceOf[currentRoundId][address(this)] = shieldBalanceOf[
            currentRoundId
        ][address(this)]
            .add(deltaShield);

        totalSpear[currentRoundId] = totalSpear[currentRoundId].add(deltaSpear);
        totalShield[currentRoundId] = totalShield[currentRoundId].add(
            deltaShield
        );

        collateralToken.safeTransferFrom(msg.sender, address(this), amount);
        userStartRoundLP[msg.sender] = currentRoundId;
        lpTotalSupply[currentRoundId] = lpTotalSupply[currentRoundId].add(
            amount
        );
        lpBalanceOf[currentRoundId][msg.sender] = lpBalanceOf[currentRoundId][
            msg.sender
        ]
            .add(amount);
    }

    function addLiquilityIn(uint256 amount)
        public
        view
        returns (uint256, uint256)
    {
        uint256 collateralSS =
            collateralSpear[currentRoundId].add(
                collateralShield[currentRoundId]
            );
        uint256 deltaSpear =
            spearBalanceOf[currentRoundId][address(this)]
                .multiplyDecimal(amount)
                .divideDecimal(collateralSS);
        uint256 deltaShield =
            shieldBalanceOf[currentRoundId][address(this)]
                .multiplyDecimal(amount)
                .divideDecimal(collateralSS);
        return (deltaSpear, deltaShield);
    }

    function removeLiquilityOut(uint256 amount) public view returns (uint256) {
        uint256 spearSoldAmount = spearSold(currentRoundId);
        uint256 shieldSoldAmount = shieldSold(currentRoundId);
        uint256 maxSold =
            spearSoldAmount > shieldSoldAmount
                ? spearSoldAmount
                : shieldSoldAmount;
        uint256 deltaCollateral =
            lpTotalSupply[currentRoundId]
                .sub(maxSold)
                .multiplyDecimal(amount)
                .divideDecimal(lpTotalSupply[currentRoundId]);
        return deltaCollateral;
    }

    /// @dev The user retrieves the energy token
    /// @param amount of energy token to msg.sender, if msg.sender don't have enought spear and shield, the transaction
    /// will failed
    function removeLiquility(uint256 amount) public {
        // require(userStartRoundLP[msg.sender] !=0, "user dont have liquility");
        if (userStartRoundLP[msg.sender] == 0) {
            return;
        }
        uint256 lpAmount;
        if (userStartRoundLP[msg.sender] == currentRoundId) {
            // dont have history
            lpAmount = lpBalanceOf[currentRoundId][msg.sender];
        } else {
            // history handle
            lpAmount = pendingLP(msg.sender);
        }
        require(lpAmount >= amount, "not enough lp to burn");
        uint256 spearSoldAmount = spearSold(currentRoundId);
        uint256 shieldSoldAmount = shieldSold(currentRoundId);
        uint256 maxSold =
            spearSoldAmount > shieldSoldAmount
                ? spearSoldAmount
                : shieldSoldAmount;
        uint256 deltaCollateral =
            lpTotalSupply[currentRoundId]
                .sub(maxSold)
                .multiplyDecimal(amount)
                .divideDecimal(lpTotalSupply[currentRoundId]);
        uint256 deltaSpear =
            deltaCollateral
                .multiplyDecimal(collateralSpear[currentRoundId])
                .divideDecimal(lpTotalSupply[currentRoundId]);
        uint256 deltaShield =
            deltaCollateral
                .multiplyDecimal(collateralShield[currentRoundId])
                .divideDecimal(lpTotalSupply[currentRoundId]);
        uint256 deltaCollateralSpear =
            collateralSpear[currentRoundId]
                .multiplyDecimal(deltaCollateral)
                .divideDecimal(lpTotalSupply[currentRoundId]);
        uint256 deltaCollateralShield =
            collateralShield[currentRoundId]
                .multiplyDecimal(deltaCollateral)
                .divideDecimal(lpTotalSupply[currentRoundId]);
        uint256 deltaCollateralSurplus =
            collateralSurplus[currentRoundId]
                .multiplyDecimal(deltaCollateral)
                .divideDecimal(lpTotalSupply[currentRoundId]);

        spearBalanceOf[currentRoundId][address(this)] = spearBalanceOf[
            currentRoundId
        ][address(this)]
            .sub(deltaSpear);
        shieldBalanceOf[currentRoundId][address(this)] = shieldBalanceOf[
            currentRoundId
        ][address(this)]
            .sub(deltaShield);
        collateralSpear[currentRoundId] = collateralSpear[currentRoundId].sub(
            deltaCollateralSpear
        );
        collateralShield[currentRoundId] = collateralShield[currentRoundId].sub(
            deltaCollateralShield
        );
        collateralSurplus[currentRoundId] = collateralSurplus[currentRoundId]
            .sub(deltaCollateralSurplus);

        totalSpear[currentRoundId] = totalSpear[currentRoundId].sub(deltaSpear);
        totalShield[currentRoundId] = totalShield[currentRoundId].sub(
            deltaShield
        );

        userStartRoundLP[msg.sender] = currentRoundId;
        lpTotalSupply[currentRoundId] = lpTotalSupply[currentRoundId].sub(
            amount
        );
        lpBalanceOf[currentRoundId][msg.sender] = lpAmount.sub(amount);
        collateralToken.safeTransfer(msg.sender, deltaCollateral);
    }

    function pendingClaim(address acc) public view returns (uint256 amount) {
        uint256 userRoundId = userStartRoundSS[acc];
        if (userRoundId != 0 && userRoundId < currentRoundId) {
            if (rounds[userRoundId].roundResult == RoundResult.SpearWin) {
                amount = spearBalanceOf[userRoundId][acc];
            } else if (
                rounds[userRoundId].roundResult == RoundResult.ShieldWin
            ) {
                amount = shieldBalanceOf[userRoundId][acc];
            }
        }
    }

    function pendingLP(address acc) public view returns (uint256 lpAmount) {
        uint256 userRoundId = userStartRoundLP[acc];
        if (userRoundId != 0 && userRoundId <= currentRoundId) {
            // future round
            lpAmount = lpBalanceOf[userRoundId][acc];
            for (uint256 i; i < roundIds.length - 1; i++) {
                if (roundIds[i] >= userRoundId) {
                    // user's all round
                    uint256 newLpAmount =
                        nextRoundLP(roundIds[i], acc, lpAmount);
                    lpAmount = newLpAmount;
                }
            }
        }
    }

    function nextRoundLP(
        uint256 roundId,
        address acc,
        uint256 lpAmount
    ) public view returns (uint256 amount) {
        if (roundId == currentRoundId) {
            return lpBalanceOf[roundId][acc];
        }
        if (rounds[roundId].roundResult == RoundResult.SpearWin) {
            uint256 spearAmountTotal = spearBalanceOf[roundId][address(this)];
            amount = lpAmount.multiplyDecimal(spearAmountTotal).divideDecimal(
                lpTotalSupply[roundId]
            );
        } else {
            uint256 shieldAmountTotal = shieldBalanceOf[roundId][address(this)];
            amount = lpAmount.multiplyDecimal(shieldAmountTotal).divideDecimal(
                lpTotalSupply[roundId]
            );
        }
    }

    /// @dev normal users get back their profits
    function claim() public {
        uint256 amount = pendingClaim(msg.sender);
        if (amount != 0) {
            spearBalanceOf[userStartRoundSS[msg.sender]][msg.sender] = 0;
            shieldBalanceOf[userStartRoundSS[msg.sender]][msg.sender] = 0;
            delete userStartRoundSS[msg.sender];
            collateralToken.safeTransfer(msg.sender, amount);
        }
    }

    /// @dev Calculate how many spears and shields can be obtained
    /// @param amountIn amount transfer to battle contract
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 _pre_k
    )
        public
        pure
        returns (
            uint256 amountOut,
            bool e,
            uint256 pre_k
        )
    {
        (uint256 _amountOut, bool _e, uint256 k) =
            Pricing.getAmountOut(amountIn, reserveIn, reserveOut, _pre_k);
        amountOut = _amountOut;
        e = _e;
        pre_k = k;
    }

    function sellAmount(
        uint256 amountToSell,
        uint256 reserve,
        uint256 energy
    ) public pure returns (uint256 amount) {
        uint256 amountInWithFee = amountToSell.mul(1000);
        uint256 numerator = amountInWithFee.mul(energy);
        uint256 denominator = reserve.mul(1000).add(amountInWithFee);
        amount = numerator / denominator;
    }

    function test() public {}

    // // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    // function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) public pure returns (uint amountIn) {
    //     require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
    //     require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
    //     uint numerator = reserveIn.multiplyDecimal(amountOut).mul(1000);
    //     uint denominator = reserveOut.sub(amountOut).mul(1000);
    //     amountIn = (numerator / denominator).add(1);
    // }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../lib/DMath.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library Pricing {
    
    using SafeMath for uint;

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint _pre_k) internal pure returns(uint amountOut, bool e, uint pre_k) {
        require(amountIn > 0, 'Battle: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'Battle: INSUFFICIENT_LIQUIDITY');
        if (reserveIn >= reserveOut.mul(99).div(100)) {
            amountOut = amountIn;
            e = true;
            return (amountOut, e, _pre_k);
        }
        // if amountIn > sqrt(reserveIn)
        uint maxAmount = DMath.sqrt(reserveIn*reserveOut.mul(100).div(99));
        pre_k = maxAmount;
        // console.log("maxAmount %s and amountIn %s, reserveIn %s, reserveOut %s", maxAmount, amountIn, reserveIn);
        if (amountIn.add(reserveIn) > maxAmount) {
            uint maxAmountIn = maxAmount.sub(reserveIn);
            uint amountInWithFee = maxAmountIn.mul(1000);
            uint numerator = amountInWithFee.mul(reserveOut);
            uint denominator = reserveIn.mul(1000).add(amountInWithFee);
            amountOut = numerator / denominator;
            amountOut = amountOut.add(amountIn.sub(maxAmountIn));
            e = true;
        } else {
            uint amountInWithFee = amountIn.mul(1000);
            uint numerator = amountInWithFee.mul(reserveOut);
            uint denominator = reserveIn.mul(1000).add(amountInWithFee);
            amountOut = numerator / denominator;
        }
    }

    function getAmountIn() internal view {

    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBattle {
    function init(uint amount, uint price0, uint pirce1, uint price2, uint endTs) external;
    function buySpear(uint amount) external;
    function sellSpear(uint amount) external;
    function buyShield(uint amount) external;
    function sellShield(uint amount) external;
    function settle(uint price) external;
    function addLiqui(uint amount) external;
    function removeLiqui(uint amount) external;
    function withdraw() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOracle {
   function price(string memory symbol) external returns(uint); 
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

// a library for performing various math operations

library DMath {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
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
pragma solidity ^0.8.0;

// Libraries
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// https://docs.synthetix.io/contracts/SafeDecimalMath
library SafeDecimalMath {
    using SafeMath for uint;

    /* Number of decimal places in the representations. */
    uint8 public constant decimals = 18;
    uint8 public constant highPrecisionDecimals = 27;

    /* The number representing 1.0. */
    uint public constant UNIT = 10**uint(decimals);

    /* The number representing 1.0 for higher fidelity numbers. */
    uint public constant PRECISE_UNIT = 10**uint(highPrecisionDecimals);
    uint private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR = 10**uint(highPrecisionDecimals - decimals);

    /**
     * @return Provides an interface to UNIT.
     */
    function unit() external pure returns (uint) {
        return UNIT;
    }

    /**
     * @return Provides an interface to PRECISE_UNIT.
     */
    function preciseUnit() external pure returns (uint) {
        return PRECISE_UNIT;
    }

    /**
     * @return The result of multiplying x and y, interpreting the operands as fixed-point
     * decimals.
     *
     * @dev A unit factor is divided out after the product of x and y is evaluated,
     * so that product must be less than 2**256. As this is an integer division,
     * the internal division always rounds down. This helps save on gas. Rounding
     * is more expensive on gas.
     */
    function multiplyDecimal(uint x, uint y) internal pure returns (uint) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return x.mul(y) / UNIT;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of the specified precision unit.
     *
     * @dev The operands should be in the form of a the specified unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function _multiplyDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        uint quotientTimesTen = x.mul(y) / (precisionUnit / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a precise unit.
     *
     * @dev The operands should be in the precise unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _multiplyDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a standard unit.
     *
     * @dev The operands should be in the standard unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRound(uint x, uint y) internal pure returns (uint) {
        return _multiplyDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is a high
     * precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and UNIT must be less than 2**256. As
     * this is an integer division, the result is always rounded down.
     * This helps save on gas. Rounding is more expensive on gas.
     */
    function divideDecimal(uint x, uint y) internal pure returns (uint) {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return x.mul(UNIT).div(y);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * decimal in the precision unit specified in the parameter.
     *
     * @dev y is divided after the product of x and the specified precision unit
     * is evaluated, so the product of x and the specified precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function _divideDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        uint resultTimesTen = x.mul(precisionUnit * 10).div(y);

        if (resultTimesTen % 10 >= 5) {
            resultTimesTen += 10;
        }

        return resultTimesTen / 10;
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * standard precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and the standard precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRound(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * high precision decimal.
     *
     * @dev y is divided after the product of x and the high precision unit
     * is evaluated, so the product of x and the high precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @dev Convert a standard decimal representation to a high precision one.
     */
    function decimalToPreciseDecimal(uint i) internal pure returns (uint) {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

    /**
     * @dev Convert a high precision decimal to a standard decimal representation.
     */
    function preciseDecimalToDecimal(uint i) internal pure returns (uint) {
        uint quotientTimesTen = i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

enum RoundResult {
    NonResult, // 0
    SpearWin, // 1
    ShieldWin //2
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

enum RangeType {
    TwoWay, // 0
    Positive, // 1
    negative // 2
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./RangeType.sol";
import "./RangeResult.sol";

struct RoundInfo {
    uint256 spearPrice;
    uint256 shieldPrice;
    uint256 startPrice;
    uint256 endPrice;
    uint256 startTS;
    uint256 endTS;
    uint256 range;
    RangeType ry;
    uint256 targetPriceUnder;
    uint256 targetPriceSuper;
    RoundResult roundResult;
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}