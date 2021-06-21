// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "./IOptIn.sol";

contract OptIn is IOptIn, Ownable {
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    event OptedIn(address account, address to);
    event OptedOut(address account, address to);

    // Indicates whether the contract is in boost-mode or not. Upon first deploy,
    // it has to be activated by the owner of the contract. Once activated,
    // it cannot be deactivated again and the owner automatically renounces ownership
    // leaving the contract without an owner.
    //
    // Boost mode means that contracts who leverage opt-in functionality can impose more constraints on
    // how users perform state changes in order to e.g. provide better services off-chain.
    bool private _permaBoostActive;

    // The opt-out period is 1 day (in seconds).
    uint32 private constant _OPT_OUT_PERIOD = 86400;

    // The address every account is opted-in to by default
    address private immutable _defaultOptInAddress;

    // For each account, a mapping to a boolean indicating whether they
    // did anything that deviates from the default state or not. Used to
    // minimize reads when nothing changed.
    mapping(address => bool) private _dirty;

    // For each account, a mapping to the address it is opted-in.
    // By default every account is opted-in to `defaultOptInAddress`. Any account can opt-out
    // at any time and opt-in to a different address.
    // These non-default addresses are tracked in this mapping.
    mapping(address => address) private _optedIn;

    // A map containing all opted-in addresses that are
    // waiting to be opted-out. They are still considered opted-in
    // until the time period passed.
    // We store the timestamp of when the opt-out was initiated. An address
    // is considered opted-out when `optOutTimestamp + _optOutPeriod < block.timestamp` yields true.
    mapping(address => uint256) private _optOutPending;

    constructor(address defaultOptInAddress) public Ownable() {
        _defaultOptInAddress = defaultOptInAddress;
    }

    function getPermaBoostActive() public view returns (bool) {
        return _permaBoostActive;
    }

    /**
     * @dev Activate the perma-boost and renounce ownership leaving the contract
     * without an owner. This will irrevocably change the behavior of dependent-contracts.
     */
    function activateAndRenounceOwnership() external onlyOwner {
        _permaBoostActive = true;
        renounceOwnership();
    }

    /**
     * @dev Returns the opt-out period.
     */
    function getOptOutPeriod() external pure returns (uint32) {
        return _OPT_OUT_PERIOD;
    }

    /**
     * @dev Returns the address `account` opted-in to if any.
     */
    function getOptedInAddressOf(address account)
        public
        view
        returns (address)
    {
        (, address optedInTo, ) = _getOptInStatus(account);
        return optedInTo;
    }

    /**
     * @dev Get the OptInStatus for two accounts at once.
     */
    function getOptInStatusPair(address accountA, address accountB)
        external
        override
        view
        returns (OptInStatus memory, OptInStatus memory)
    {
        (bool isOptedInA, address optedInToA, ) = _getOptInStatus(accountA);
        (bool isOptedInB, address optedInToB, ) = _getOptInStatus(accountB);

        bool permaBoostActive = _permaBoostActive;

        return (
            OptInStatus({
                isOptedIn: isOptedInA,
                optedInTo: optedInToA,
                permaBoostActive: permaBoostActive,
                optOutPeriod: _OPT_OUT_PERIOD
            }),
            OptInStatus({
                isOptedIn: isOptedInB,
                optedInTo: optedInToB,
                permaBoostActive: permaBoostActive,
                optOutPeriod: _OPT_OUT_PERIOD
            })
        );
    }

    /**
     * @dev Use this function to get the opt-in status of a given address.
     * Returns to the caller an `OptInStatus` object that also contains whether
     * the permaboost is active or not (e.g. to create pending ops).
     */
    function getOptInStatus(address account)
        external
        override
        view
        returns (OptInStatus memory)
    {
        (bool optedIn, address optedInTo, ) = _getOptInStatus(account);

        return
            OptInStatus({
                isOptedIn: optedIn,
                optedInTo: optedInTo,
                permaBoostActive: _permaBoostActive,
                optOutPeriod: _OPT_OUT_PERIOD
            });
    }

    /**
     * @dev Opts in the caller.
     * @param to the address to opt-in to
     */
    function optIn(address to) external {
        require(to != address(0), "OptIn: address cannot be zero");
        require(to != msg.sender, "OptIn: cannot opt-in to self");
        require(
            !address(msg.sender).isContract(),
            "OptIn: sender is a contract"
        );
        require(
            msg.sender != _defaultOptInAddress,
            "OptIn: default address cannot opt-in"
        );
        (bool optedIn, , ) = _getOptInStatus(msg.sender);
        require(!optedIn, "OptIn: sender already opted-in");

        _optedIn[msg.sender] = to;

        // Always > 0 since by default anyone is opted-in
        _optOutPending[msg.sender] = 0;

        emit OptedIn(msg.sender, to);
    }

    /**
     * @dev Returns the remaining opt-out period (in seconds, if any) for the given `account`.
     * A return value > 0 means that `account` opted-in, then opted-out and is
     * still considered opted-in for the remaining period. If the return value is 0, then `account`
     * could be either: opted-in or not, but guaranteed to not be pending.
     */
    function getPendingOptOutRemaining(address account)
        external
        view
        returns (uint256)
    {
        bool dirty = _dirty[account];

        uint256 optOutPeriodRemaining = _getOptOutPeriodRemaining(
            account,
            dirty
        );
        return optOutPeriodRemaining;
    }

    function _getOptInStatus(address account)
        internal
        view
        returns (
            bool, // isOptedIn
            address, // optedInTo
            bool // dirty
        )
    {
        bool dirty = _dirty[account];
        // Take a shortcut if `account` never changed anything
        if (!dirty) {
            return (
                true, /* isOptedIn */
                _defaultOptInAddress,
                dirty
            );
        }

        address optedInTo = _getOptedInTo(account, dirty);

        // Returns 0 if `account` never opted-out or opted-in again (which resets `optOutPending`).
        uint256 optOutStartedAt = _optOutPending[account];
        bool optOutPeriodActive = block.timestamp <
            optOutStartedAt + _OPT_OUT_PERIOD;

        if (optOutStartedAt == 0 || optOutPeriodActive) {
            return (true, optedInTo, dirty);
        }

        return (false, address(0), dirty);
    }

    /**
     * @dev Returns the remaining opt-out period of `account` relative to the given
     * `optedInTo` address.
     */
    function _getOptOutPeriodRemaining(address account, bool dirty)
        private
        view
        returns (uint256)
    {
        if (!dirty) {
            // never interacted with opt-in contract
            return 0;
        }

        uint256 optOutPending = _optOutPending[account];
        if (optOutPending == 0) {
            // Opted-out and/or opted-in again to someone else
            return 0;
        }

        uint256 optOutPeriodEnd = optOutPending + _OPT_OUT_PERIOD;
        if (block.timestamp >= optOutPeriodEnd) {
            // Period is over
            return 0;
        }

        // End is still in the future, so the difference to block.timestamp is the remaining
        // duration in seconds.
        return optOutPeriodEnd - block.timestamp;
    }

    function _getOptedInTo(address account, bool dirty)
        internal
        view
        returns (address)
    {
        if (!dirty) {
            return _defaultOptInAddress;
        }

        // Might be dirty, but never opted-in to someone else and/or simply pending.
        // We need to return the default address if the mapping is zero.
        address optedInTo = _optedIn[account];
        if (optedInTo == address(0)) {
            return _defaultOptInAddress;
        }

        return optedInTo;
    }

    /**
     * @dev Opts out the caller. The opt-out does not immediately take effect.
     * Instead, the caller is marked pending and only after a 30-day period ended since
     * the call to this function he is no longer considered opted-in.
     *
     * Requirements:
     *
     * - the caller is opted-in
     */
    function optOut() external {
        (bool isOptedIn, address optedInTo, ) = _getOptInStatus(msg.sender);

        require(isOptedIn, "OptIn: sender not opted-in");
        require(
            _optOutPending[msg.sender] == 0,
            "OptIn: sender not opted-in or opt-out pending"
        );

        _optOutPending[msg.sender] = block.timestamp;

        // NOTE: we do not delete the `optedInTo` address yet, because we still need it
        // for e.g. checking `isOptedInBy` while the opt-out period is not over yet.

        emit OptedOut(msg.sender, optedInTo);

        _dirty[msg.sender] = true;
    }

    /**
     * @dev An opted-in address can opt-out an `account` instantly, so that the opt-out period
     * is skipped.
     */
    function instantOptOut(address account) external {
        (bool isOptedIn, address optedInTo, bool dirty) = _getOptInStatus(
            account
        );

        require(
            isOptedIn,
            "OptIn: cannot instant opt-out not opted-in account"
        );
        require(
            optedInTo == msg.sender,
            "OptIn: account must be opted-in to msg.sender"
        );

        emit OptedOut(account, msg.sender);

        // To make the opt-out happen instantly, subtract the waiting period of `msg.sender` from `block.timestamp` -
        // effectively making `account` having waited for the opt-out period time.
        _optOutPending[account] = block.timestamp - _OPT_OUT_PERIOD - 1;

        if (!dirty) {
            _dirty[account] = true;
        }
    }

    /**
     * @dev Check if the given `_sender` has been opted-in by `_account` and that `_account`
     * is still opted-in.
     *
     * Returns a tuple (bool,uint256) where the latter is the optOutPeriod of the address
     * `account` is opted-in to.
     */
    function isOptedInBy(address _sender, address _account)
        external
        override
        view
        returns (bool, uint256)
    {
        require(_sender != address(0), "OptIn: sender cannot be zero address");
        require(
            _account != address(0),
            "OptIn: account cannot be zero address"
        );

        (bool isOptedIn, address optedInTo, ) = _getOptInStatus(_account);
        if (!isOptedIn || _sender != optedInTo) {
            return (false, 0);
        }

        return (true, _OPT_OUT_PERIOD);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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
contract Ownable is Context {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
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

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

struct Signature {
    bytes32 r;
    bytes32 s;
    uint8 v;
}

interface IOptIn {
    struct OptInStatus {
        bool isOptedIn;
        bool permaBoostActive;
        address optedInTo;
        uint32 optOutPeriod;
    }

    function getOptInStatusPair(address accountA, address accountB)
        external
        view
        returns (OptInStatus memory, OptInStatus memory);

    function getOptInStatus(address account)
        external
        view
        returns (OptInStatus memory);

    function isOptedInBy(address _sender, address _account)
        external
        view
        returns (bool, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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