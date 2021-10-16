/**
 *Submitted for verification at BscScan.com on 2021-10-16
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
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

abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

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
        assembly {
            size := extcodesize(account)
        }
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
        require(address(this).balance >= amount);

        (bool success, ) = recipient.call{value: amount}("");
        require(success);
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
        return functionCall(target, data);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value);
        require(isContract(target));

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target));

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
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
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0);
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

/**
 * @dev Collection of functions related to array types.
 */
library ArraysUpgradeable {
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
            uint256 mid = MathUpgradeable.average(low, high);

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

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal initializer {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation));
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation());
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0));
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon));
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation())
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal initializer {
    }
    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, bytes(""), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        require(owner() == _msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0));
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused());
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused());
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  )
    internal
    pure
    returns (
      uint256
    )
  {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash,
    uint256 _vRFInputSeed
  )
    internal
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}

abstract contract VRFConsumerBase is Initializable, VRFRequestIDBase {
   
  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(
      bytes32 requestId,
      uint256 randomness
      )
    internal 
    virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(
    bytes32 _keyHash,
    uint256 _fee
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal LINK;
  address private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  


  function __VRFConsumerBase_init(address _vrfCoordinator, address _link) internal initializer {
      __VRFConsumerBase_init_unchained(_vrfCoordinator, _link);
  }
  function __VRFConsumerBase_init_unchained(address _vrfCoordinator, address _link) internal initializer {
      vrfCoordinator = _vrfCoordinator;
      LINK = LinkTokenInterface(_link);
  }



  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    external
  {
    require(msg.sender == vrfCoordinator);
    fulfillRandomness(requestId, randomness);
  }
}

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IMoneyTreeNFT {
    function buyNFT(address purchaser, uint256 tokenID) external returns (uint256);
    function Lootbox(address purchaser, uint256 randomNumber, uint numberOfLootBoxes) external returns (uint256[] memory);
    function transferOwnership(address newOwner) external; 
    function upgradeNFT(address purchaser, uint256 tokenId1, uint256 tokenId2, uint256 randomNumber) external returns (uint256);
}

contract MoneyTreeToken is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable,  OwnableUpgradeable, PausableUpgradeable, UUPSUpgradeable, VRFConsumerBase {
    
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;    
    using ArraysUpgradeable for uint256[];
    using CountersUpgradeable for CountersUpgradeable.Counter;
    
    //----------------------Declarations-------------------//
    
    //ERC20 standards
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    
    //allow this contract to receive BNB for the swap functionality 
    receive() external payable {}
    
    //flag for if the transaction tax is active
    bool public taxActive;
    
    //Chainlink variables
    mapping(bytes32 => uint256) internal requestIdToRandomNumber;
    mapping(address => bytes32) internal addressToRequestID;
    bytes32 internal keyHash;
    uint256 internal fee;
    
    //NFT contract variables
    address nftAddress;
    mapping(address => uint) public _owedLootBoxes;
    mapping(address => uint) public _owedLootPrizes;
    mapping(address => uint256) internal _owedLootPrizeRandomNumber;
    mapping(address => uint256) public _owedUpgrade;
    
    //special wallets
    address payable internal mWallet;
    address payable internal nWallet; 
    address payable internal vsWallet;
    address payable internal dWallet;
    address payable internal tWallet;
    
    //Numberdome mappings
    mapping(uint => mapping(uint256 => address[])) internal _numberdomeEntries;
    mapping(uint => mapping(uint256 => uint)) internal _numberdomeEntrants;
    mapping(uint => mapping(uint256 => mapping(address => bool))) internal _numberdomeNumbersPlayed;
    mapping(uint => uint256) public _numberdomeWinningNumber;
    
    //Numberdome variables
    uint public numberdomeCurrentID;
    bytes32 internal numberdomeLastRequestID;
    bool public numberdomeActive;
    
    //VS Mode mappings
    mapping(uint => mapping(uint => mapping(address => uint256))) public _vsModeSideEntries;
    mapping(uint => mapping(uint => uint256)) public _vsModeSideTotals;
    mapping(uint => uint) public _vsModeResult;
    
    //VS Mode variables
    uint public vsModeCurrentID;
    bool public isVSModeActive;
    bool internal vsModeNoMoreBets;
    string public vsModeTeam1;
    string public vsModeTeam2;
    
    //Gridlock mappings
    mapping(address => mapping(uint => mapping(uint => uint256))) public _gridlockEntries;
    mapping(uint => uint) public _gridlockWinningNumber;
    
    //Gridlock variables
    uint public gridlockCurrentID;
    bytes32 internal gridlockLastRequestID;
    bool public gridlockActive;
    
    //lottery mappings
    mapping(address => bool) internal _isHolder;
    mapping (address => bool) private _isExcludedPool;
    mapping (address => uint256) internal _addressPool;
    mapping(uint256 => mapping(address => address)) _nextHolderPool;
    mapping (uint256 => uint256) internal _poolNumHolders;
    mapping (uint256 => uint256) public _poolTokenAmount;
    
    //lottery variables
    uint256 winningLotteryNumber;
    address public lotteryWinner;
    uint256 public numHolders;
    uint256 public totalPooledTokens;
    uint256 public lotteryAmount;
    address constant GUARD = address(1);
    bytes32 internal lotteryLastRequestID;
    
    //tax rates
    uint internal liqTaxRate;
    uint internal marketingTaxRate;
    uint internal lotteryTaxRate;
    uint public overallTaxRate;
    
    //set number of tokens
    uint256 internal minTokensForSwap;
    uint256 internal antiWhaleLimit;
    
    //addresses exempt from any active tax
    mapping (address => bool) internal _isExcludedTax;
    
    //uniswap addresses
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    //dividend & snapshot variables
    struct Snapshots {
        uint256[] ids;
        uint256[] values;}
    mapping (address => Snapshots) private _accountBalanceSnapshots;
    
    mapping(uint => uint256) public _dWalletSnapshotTotal;
    mapping(address => uint) internal _dWalletNextClaimableSnapshot;
    
    Snapshots private _totalSupplySnapshots;
    CountersUpgradeable.Counter private _currentSnapshotId; //starts at 1
    event Snapshot(uint256 id);

    //----------------------End Of Declarations-------------------//
    
    
    //----------------------Initializer-------------------//
    
    function initialize() public virtual initializer {
        
        //initialize all neccessary contracts
        __ERC1967Upgrade_init();
        __Context_init();
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        __VRFConsumerBase_init(0x747973a5A2a4Ae1D3a8fDF5479f1514F65Db9C31, 0x404460C6A5EdE2D891e8297795264fDe62ADBB75);
    
        keyHash = 0xc251acd21ec4fb7f31bb8868288bfdbaeb4fbfec2df3735ddbd4f7dc8d60103c;
        fee = 0.2 * 10 ** 18; // 0.2 LINK   

        _name = "MoneyTree";
        _symbol = "MONEY";
        
        mWallet = payable(0x9584AeeC19BEF61d284f590B71C564f363d84895);
        nWallet = payable(0x43158D2c0932972000281fc9cE93750a658212fF);
        vsWallet = payable(0xcb5c44369095B7FCc4aB10bA1C090E8DA630a9BE);
        dWallet = payable(0x73ef41B761A9FD80C327F885Cd6dD08c30D05812);
        tWallet = payable(0xb43cF85a531Eb975c87EE81aAd56Bb799E401466);
    
        minTokensForSwap = 10000 * 10 ** decimals();
        antiWhaleLimit = 1000000000 * 10 ** decimals();    
        
        liqTaxRate = 2;
        marketingTaxRate = 1;
        lotteryTaxRate = 2;
        overallTaxRate = liqTaxRate + marketingTaxRate + lotteryTaxRate;
        
        //pancakeswap v2 router address
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        
        //create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
            
        //set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        
        //exclude addresses from any tax
        _isExcludedTax[owner()] = true;
        _isExcludedTax[mWallet] = true;
        _isExcludedTax[nWallet] = true;
        _isExcludedTax[dWallet] = true;
        _isExcludedTax[tWallet] = true;
        _isExcludedTax[address(this)] = true;
 
        //exclude addresses from any pools
        _isExcludedPool[owner()] = true;
        _isExcludedPool[mWallet] = true;
        _isExcludedPool[nWallet] = true;
        _isExcludedPool[dWallet] = true;
        _isExcludedPool[tWallet] = true;
        _isExcludedPool[address(0)] = true;
        _isExcludedPool[address(this)] = true;
        _isExcludedPool[uniswapV2Pair] = true;
    
        //mint the starting supply
        _mint(_msgSender(), 1000000000 * 10 ** decimals());
        emit Transfer(address(0), _msgSender(), 1000000000 * 10 ** decimals());
    }
    
    //----------------------End Of Initializer-------------------//

    
    //----------------------Transaction Tax Functions-------------------//
    
    //turn tax on/off
    function toggleTaxActive(bool toggler) public onlyOwner {
        taxActive = toggler;
    }
    
    //adjust tax rates
    function TaxRateAdjuster(uint liqTax, uint markTax, uint lotTax) public onlyOwner {
        liqTaxRate = liqTax;
        marketingTaxRate = markTax;
        lotteryTaxRate = lotTax;
        overallTaxRate = liqTaxRate + marketingTaxRate + lotteryTaxRate;
    }
    
    //adjust minimum number of tokens needed for a dex swap to occur
    function minTokensForSwapAdjuster(uint tokens) public onlyOwner {
        minTokensForSwap = tokens * 10 ** decimals();
    }
    
    //adjust anti whale measure max amount transferred
    function maxTokensForTransferAdjuster(uint tokens) public onlyOwner {
        antiWhaleLimit = tokens * 10 ** decimals();
    }
    
    //withdraw BNB (to buy link)
    function withdrawBNB(uint bnbAmount) public onlyOwner {
        payable(_msgSender()).transfer(bnbAmount);
    }
    
    //----------------------End Of Transaction Tax Functions-------------------//    


    //----------------------Transfer Functions-------------------//
    
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
        require(currentAllowance >= amount);
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        return true;
    }
    
    //convert the tax wallet to usdc and distribute to relevant wallets
    function depositSplitAndLiquify() internal {
        
        uint256 taxAmount = _balances[tWallet];
        
        _balances[address(this)] += taxAmount;
        _balances[tWallet] = 0;
        emit Transfer(tWallet, address(this), taxAmount);
            
        uint256 taxAmountKeep = taxAmount.div(5);
        uint256 taxAmountSwap = taxAmount - taxAmountKeep;

        uint256 currentBNBBalance = address(this).balance;

        swapTokensForBNB(taxAmountSwap);
        
        uint256 newBNBBalance = address(this).balance;
        uint256 newBNBGained = newBNBBalance - currentBNBBalance;
        
        uint256 newBNBLottery = newBNBGained.div(2);
        lotteryAmount = lotteryAmount + newBNBLottery;
        
        uint256 newBNBMarketing = (newBNBGained - newBNBLottery).div(2);
        mWallet.transfer(newBNBMarketing);
        
        uint256 newBNBLiquidity = newBNBGained - newBNBLottery - newBNBMarketing;
        addLiquidity(taxAmountKeep, newBNBLiquidity);
    }
    
    //base transfer function
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0));
        require(recipient != address(0));
        
        if(sender != owner()){
            require(amount <= antiWhaleLimit);
        }

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount);
        
        unchecked {
            _balances[sender] = senderBalance - amount;            
            //adjust senders pools balance and check if sender has balance 0 and needs to be removed from pool
            adjustSendersPool(sender, amount);
        }
        
        uint256 receiveAmount = amount;
        
        if(taxActive && !_isExcludedTax[sender] && !_isExcludedTax[recipient]){
            uint256 taxAmount = amount.div(20);
            receiveAmount = amount - taxAmount;
            _balances[tWallet] = _balances[tWallet] + taxAmount;
            emit Transfer(sender, tWallet, taxAmount);
        }
        
        if(recipient == uniswapV2Pair && !_isExcludedTax[sender] && _balances[tWallet]>=minTokensForSwap){
            depositSplitAndLiquify();
        }
        
        _balances[recipient] += receiveAmount;
        //adjust recipient pools balance and check if recipient is new and needs to be added to pool
        adjustRecipientsPool(recipient, receiveAmount);
        
        emit Transfer(sender, recipient, receiveAmount);
        _afterTokenTransfer(sender, recipient, receiveAmount);        
        
        }
        
    //----------------------End Of Transfer Functions-------------------//
    
    
    //----------------------Uniswap Interaction Functions-------------------//

    //swap BNB for USDC
    function swapBNBForTokens(address _winner) internal {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH(); //WETH
        path[1] = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; //change to USDC

        // make the swap
        uniswapV2Router.swapExactETHForTokens{value:lotteryAmount}(
            0, 
            path,
            _winner,
            block.timestamp
        );
    }

    //swap MONEY for BNB
    function swapTokensForBNB(uint256 tokenAmount) internal {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    //add tokens and BNB held on contract as liquidity
    function addLiquidity(uint256 tokenAmount, uint256 BNBAmount) internal {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: BNBAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp
        );
    }
    
    //----------------------End Of Uniswap Interaction Functions-------------------// 


    //---------------------------NFT Contract Intergration------------------------//
    
    //set NFT contract address
    function setNFTAddress(address _NFTAddress) public onlyOwner {
       nftAddress = _NFTAddress;
    }    
    
    //convert token ID to rarity 
    function tokenIDToRarity(uint256 tokenID) internal pure returns(uint){
        
        uint randomNFTRarity;
        
        if(tokenID <= 549999){
            randomNFTRarity = 0;
        } else if (tokenID <= 789999){
            randomNFTRarity = 1;
        } else if (tokenID <= 909999){
            randomNFTRarity = 2;
        } else if (tokenID <= 969999){
            randomNFTRarity = 3;
        } else if (tokenID <= 999999){
            randomNFTRarity = 4;
        }
        return(randomNFTRarity);
    }
    
    //buy NFT using BNB
    function buyNFTBNB(uint256 tokenID) payable public {
        
        uint rarityCheck = tokenIDToRarity(tokenID);

        if(rarityCheck == 1){
            require(msg.value == 0.1 ether);
        } else if(rarityCheck == 2){
            require(msg.value == 0.2 ether);
        } else if(rarityCheck == 3){
            require(msg.value == 0.4 ether);
        } else {
            require(msg.value == 10000 ether);
        }
        
        uint halfBNBOwed = msg.value / 2;
        lotteryAmount = lotteryAmount + halfBNBOwed; //add half bnb sale to the lottery
        payable(owner()).transfer(halfBNBOwed); //add half bnb sale to the dev wallet
        
        IMoneyTreeNFT(nftAddress).buyNFT(_msgSender(),tokenID);
    }
    
    //buy NFT using MONEY
    function buyNFTTokens(uint tokenID) public {
        
        uint rarityCheck = tokenIDToRarity(tokenID);
        uint256 tokensOwed = _totalSupply;
        
        require(rarityCheck == 0);

        tokensOwed = 10000 * 10 ** decimals();
        
        uint256 burnTokens = tokensOwed.div(10);
        _burn(_msgSender(), burnTokens);
        
        uint256 dividendTokens = tokensOwed - burnTokens;
        _transfer(_msgSender(), dWallet, dividendTokens);
        _dWalletSnapshotTotal[_currentSnapshotId.current()+1] += dividendTokens;

        IMoneyTreeNFT(nftAddress).buyNFT(_msgSender(), tokenID);
    }
    
    //buy a lootbox with BNB and pay for VRF
    function buyLootBoxBNB(uint numLootBoxes) payable public {
        
        require(_owedLootBoxes[_msgSender()] == 0);
        
        if(numLootBoxes == 1){
            require(msg.value == 0.15 ether);
        } else if(numLootBoxes == 3){
            require(msg.value == 0.4 ether);
        } else if(numLootBoxes == 5){
            require(msg.value == 0.64 ether);
        } else if(numLootBoxes == 10){
            require(msg.value == 1.13 ether);
        } else {
            require(msg.value == 10000 ether);
        }

        uint halfBNBOwed = msg.value / 2;
        lotteryAmount = lotteryAmount + halfBNBOwed;
        payable(owner()).transfer(halfBNBOwed);
        
        bytes32 requestID = getRandomNumber();
        addressToRequestID[_msgSender()] = requestID;
        
        _owedLootBoxes[_msgSender()] = numLootBoxes;
    }

    //buy a lootbox with MONEY and pay for VRF 
    function buyLootBoxTokens(uint numLootBoxes) payable public {
        
        require(msg.value == 0.01 ether);
        require(_owedLootBoxes[_msgSender()] == 0);

        uint256 tokensOwed = _totalSupply;
        
        if(numLootBoxes == 1){
            tokensOwed = 30000;
        } else if(numLootBoxes == 3){
            tokensOwed = 80000;
        } else if(numLootBoxes == 5){
            tokensOwed = 128000;
        } else if(numLootBoxes == 10){
            tokensOwed = 226000;
        }
        
        tokensOwed = tokensOwed * 10 ** decimals();
        
        uint256 burnTokens = tokensOwed.div(10);
        _burn(_msgSender(), burnTokens);

        uint256 dividendTokens = tokensOwed - burnTokens;
        _transfer(_msgSender(), dWallet, dividendTokens);
        _dWalletSnapshotTotal[_currentSnapshotId.current()+1] += dividendTokens;
        
        bytes32 requestID = getRandomNumber();
        addressToRequestID[_msgSender()] = requestID;
        
        _owedLootBoxes[_msgSender()] = numLootBoxes;
    }

    //mint a purchased and unopened loot box
    function mintOwedLootBoxes() public {
        
        require(_owedLootBoxes[_msgSender()] != 0);
        require(requestIdToRandomNumber[addressToRequestID[_msgSender()]] != 0);
        
        IMoneyTreeNFT(nftAddress).Lootbox(_msgSender(), 
                                            requestIdToRandomNumber[addressToRequestID[_msgSender()]],
                                            _owedLootBoxes[_msgSender()]);
        
        _owedLootBoxes[_msgSender()] = 0;
    }

    //mint a won and unopened loot box
    function mintOwedLootPrizes() public {
        
        require(_owedLootPrizes[_msgSender()] != 0);
        require(_owedLootPrizeRandomNumber[_msgSender()] != 0);
        
        IMoneyTreeNFT(nftAddress).Lootbox(_msgSender(), 
                                            _owedLootPrizeRandomNumber[_msgSender()],
                                            _owedLootPrizes[_msgSender()]);
        
        _owedLootPrizes[_msgSender()] = 0;
        _owedLootPrizeRandomNumber[_msgSender()] = 0;
    }
    
    //buy an NFT upgrade snd pay for VRF
    function buyUpgradeNFT() payable public {
        require(msg.value == 0.01 ether);
        require(_owedUpgrade[_msgSender()] == 0);
        
        bytes32 requestID = getRandomNumber();
        addressToRequestID[_msgSender()] = requestID;
        _owedUpgrade[_msgSender()] = 1;
    }
    
    //mint a purchased and unused NFT upgrade
    function mintOwedUpgrade(uint256 tokenId1, uint256 tokenId2) public {
        require(requestIdToRandomNumber[addressToRequestID[_msgSender()]] != 0);
        require(_owedUpgrade[_msgSender()] != 0);

        IMoneyTreeNFT(nftAddress).upgradeNFT(_msgSender(), 
                                            tokenId1,
                                            tokenId2,
                                            requestIdToRandomNumber[addressToRequestID[_msgSender()]]);
                                            
        _owedUpgrade[_msgSender()] = 0;
    }
    
    //change the NFT contract owner - for emergencies
    function changeNFTContractOwner(address newOwner) public onlyOwner{
        IMoneyTreeNFT(nftAddress).transferOwnership(newOwner);
    }
    
    //airdrop a random loot box nft for a user
    function airdropLootBox(address airdropAddress, uint256 airdropNumber, uint airdropSize) public onlyOwner {
        IMoneyTreeNFT(nftAddress).Lootbox(airdropAddress,
                                            airdropNumber,
                                            airdropSize);
    }
    
    //----------------------End Of NFT Contract Intergration-------------------//

    
    //----------------------Numberdome-------------------//
    
    //set numberdome as active/unactive
    function numberdomeActiveToggle(bool toggler) public onlyOwner {
        numberdomeActive = toggler;
    }
    
    //make a numberdome selection for active gameID
    function playNumberdome(uint256 luckyPicks) public {
        require(numberdomeActive && 111 <= luckyPicks && luckyPicks <=555 && _numberdomeNumbersPlayed[numberdomeCurrentID][luckyPicks][_msgSender()] == false);
        _transfer(_msgSender(), nWallet, 10000 * 10 ** decimals());
        _numberdomeEntries[numberdomeCurrentID][luckyPicks].push(_msgSender());
        _numberdomeNumbersPlayed[numberdomeCurrentID][luckyPicks][_msgSender()] = true;
        _numberdomeEntrants[numberdomeCurrentID][luckyPicks] = _numberdomeEntrants[numberdomeCurrentID][luckyPicks] + 1; 
        
    }
    
    //call VRF for numberdome results
    function drawNumberdome1() public onlyOwner {
        require(numberdomeActive);
        
        bytes32 requestID = getRandomNumber();
	    numberdomeLastRequestID = requestID;
        
        numberdomeActive = false;

    }
    
    //check winners from VRF number and pay any winners
    function drawNumberdome2() public onlyOwner {
        require(!numberdomeActive && requestIdToRandomNumber[numberdomeLastRequestID] != 0);
        uint256 numberdomeResult = uint256(requestIdToRandomNumber[numberdomeLastRequestID]);

        uint[] memory numberdomeNumbers = new uint[](3);
        for (uint256 i = 0; i < numberdomeNumbers.length; i++) {
            numberdomeNumbers[i] = uint256(keccak256(abi.encode(numberdomeResult, i)))%5+1;
        }
            
        numberdomeResult = numberdomeNumbers[0]*100 + numberdomeNumbers[1]*10 + numberdomeNumbers[2];
        
        _numberdomeWinningNumber[numberdomeCurrentID] = numberdomeResult;
        
        uint numberdomeNumberOfWinners = _numberdomeEntrants[numberdomeCurrentID][numberdomeResult];
        if(numberdomeNumberOfWinners != 0){
            uint256 numberdomePrizePerPerson = _balances[nWallet].div(numberdomeNumberOfWinners);
            for (uint i=0; i<numberdomeNumberOfWinners; i++) {
                
                address currentWinner = _numberdomeEntries[numberdomeCurrentID][numberdomeResult][i];
                
                _transfer(nWallet, currentWinner, numberdomePrizePerPerson);
                _owedLootPrizeRandomNumber[currentWinner] = requestIdToRandomNumber[numberdomeLastRequestID];
                
                _owedLootPrizes[currentWinner] = _owedLootPrizes[currentWinner] + 1;
            }
        }
        numberdomeCurrentID++;
        numberdomeActive = true;
    }
    
    //----------------------End Of Numberdome-------------------//
    
    
    //----------------------VS Mode-------------------//
    
    //set vs mode active and enter the event details
    function setVSModeActive (string memory team1Selection, string memory team2Selection) public onlyOwner {
        require(!isVSModeActive);
        vsModeTeam1 = team1Selection;
        vsModeTeam2 = team2Selection;
        vsModeCurrentID++;
        isVSModeActive = true;
        vsModeNoMoreBets = false;
    }

    //make a VS mode selection for active gameID
    function playVSMode(uint chosenTeam, uint256 tokensStaked) public {
        require(isVSModeActive && !vsModeNoMoreBets);
        require(chosenTeam == 1 || chosenTeam == 2);        
        _transfer(_msgSender(), vsWallet, tokensStaked);
        _vsModeSideEntries[vsModeCurrentID][chosenTeam][_msgSender()] = _vsModeSideEntries[vsModeCurrentID][chosenTeam][_msgSender()] + tokensStaked;
        _vsModeSideTotals[vsModeCurrentID][chosenTeam] = _vsModeSideTotals[vsModeCurrentID][chosenTeam] + tokensStaked;
    }
    
    //set VS mode to no more bets an hour before the event starts
    function setVSModeNoMoreBets() public onlyOwner {
        vsModeNoMoreBets =  true;
    }
    
    //set vs mode as unactive and enter the events outcome
    function setVSModeUnactive(uint winningTeam) public onlyOwner {
        require(isVSModeActive);
        require(winningTeam == 1 || winningTeam == 2 || winningTeam == 3);   
        _vsModeResult[vsModeCurrentID] = winningTeam;
        isVSModeActive = false;
        vsModeTeam1 = "empty";
        vsModeTeam2 = "empty";
    }
    
    //claim prize owed from vs mode result
    function claimVSMode(uint vsModeID) public {
        uint vsModeIDResult = _vsModeResult[vsModeID];
        require(vsModeIDResult != 0 && _vsModeSideEntries[vsModeID][vsModeIDResult][_msgSender()] != 0);
        uint256 totalTokensWinningTeam = _vsModeSideTotals[vsModeID][vsModeIDResult];
        uint256 totalTokensLosingTeam = 0;
        
        if(vsModeIDResult == 3){
            
            _vsModeSideEntries[vsModeID][vsModeIDResult][_msgSender()] = 0;
            _transfer(vsWallet, _msgSender(), _vsModeSideEntries[vsModeID][vsModeIDResult][_msgSender()]);
            
        } else {
            
            if(vsModeIDResult == 1){
                totalTokensLosingTeam = _vsModeSideTotals[vsModeID][2];
                
            } else if(vsModeIDResult == 2){
                totalTokensLosingTeam = _vsModeSideTotals[vsModeID][1];
                
            }
        
            uint256 tokensWon = _vsModeSideEntries[vsModeID][vsModeIDResult][_msgSender()].mul(totalTokensLosingTeam).div(totalTokensWinningTeam) + _vsModeSideEntries[vsModeID][vsModeIDResult][_msgSender()];
            _vsModeSideEntries[vsModeID][vsModeIDResult][_msgSender()] = 0;
            _transfer(vsWallet, _msgSender(), tokensWon);
        
        }
    }
    
    //----------------------End Of VS Mode-------------------//

    
    //----------------------Gridlock-------------------//
    
    //set gridlock as active/unactive
    function gridlockActiveToggle(bool toggler) public onlyOwner {
        gridlockActive = toggler;
    }
    
    //make selection for gridlock current gameID
    function playGridlock(uint256[] memory tokensPlaced) public {
       require(gridlockActive && tokensPlaced.length == 12);
	   uint256 totalTokensPlaced;
	   for (uint i=0; i<tokensPlaced.length; i++) {
	        _gridlockEntries[_msgSender()][gridlockCurrentID][i+1] +=  (tokensPlaced[i]  * 10 ** decimals());
	        totalTokensPlaced += (tokensPlaced[i]  * 10 ** decimals());
	   }
	   _burn(_msgSender(), totalTokensPlaced);
    }

    //call VRF to pick a gridlock winning number
    function drawGridlock1() public onlyOwner {
        require(gridlockActive);
        
        bytes32 requestID = getRandomNumber();
	    gridlockLastRequestID = requestID;
	    
        gridlockActive = false;

    }
    
    //store VRF winning number and let winners claim prizes
    function drawGridlock2() public onlyOwner {
        require(!gridlockActive && requestIdToRandomNumber[gridlockLastRequestID] != 0);
        uint256 gridlockResult = requestIdToRandomNumber[gridlockLastRequestID] % 12 + 1;
        _gridlockWinningNumber[gridlockCurrentID] = gridlockResult;
        gridlockCurrentID++;
        gridlockActive = true;
    }
    
    //claim gridlock prize owed for a given gameID
    function claimGridlock(uint gridlockID) public {
        uint gridlockIDResult = _gridlockWinningNumber[gridlockID];
        require(gridlockIDResult != 0 && _gridlockEntries[_msgSender()][gridlockID][gridlockIDResult] != 0);
        uint256 tokensStakedOnWinningPlace = _gridlockEntries[_msgSender()][gridlockID][gridlockIDResult];
        uint256 tokensWon = tokensStakedOnWinningPlace.mul(12);
        _gridlockEntries[_msgSender()][gridlockID][gridlockIDResult] = 0;
        _mint(_msgSender(), tokensWon);
    }
    
    //----------------------End Of Gridlock-------------------//


    //----------------------Lottery Pool Functions-------------------//

    function addHolderToPool(address holder) internal {
        require(!_isHolder[holder]);
        
        //check which pool has less than 100 holders
        uint poolID = 1;
        while(_poolNumHolders[poolID] >=100){
            poolID++;
        }
        //if this is a new pool then initiate the guard
        if(_nextHolderPool[poolID][GUARD] == address(0)){
            _nextHolderPool[poolID][GUARD] = GUARD;
        }
        //set holders link as the guards current link
        _nextHolderPool[poolID][holder] = _nextHolderPool[poolID][GUARD];
        //set guards link as holder
        _nextHolderPool[poolID][GUARD] = holder;
        //set holder to current pool
        _addressPool[holder] = poolID;
        
        //add holder to lists
        _isHolder[holder] = true;
        _poolNumHolders[poolID] = _poolNumHolders[poolID] +1;
        numHolders++;
    }
    
    function getPreviouHolderInPool(address holder) internal view returns(address){
        //start at the guard
        address currentAddress = GUARD;
        //check the holders pool
        uint poolID = _addressPool[holder];
        //loop through all linked addresses until the next link in the pool is either the holder or it cycles back to guard
        while(_nextHolderPool[poolID][currentAddress] != GUARD){
            if(_nextHolderPool[poolID][currentAddress] == holder){
                return(currentAddress);
            }
            currentAddress = _nextHolderPool[poolID][currentAddress];
        }
        return(address(0));
    }
    
    function removeHolderFromPool(address holder) internal {
        require(_isHolder[holder]);
        
        //check the holders pool and the holders previous link
        uint poolID = _addressPool[holder];
        address prevHolder = getPreviouHolderInPool(holder);
        //set the holders previous link to the holders current link
        _nextHolderPool[poolID][prevHolder] = _nextHolderPool[poolID][holder];
        //sets the holders link to 0
        _nextHolderPool[poolID][holder] = address(0);
        //set holders pool to 0
        _addressPool[holder] = 0;
        //remove holder from lists
        _isHolder[holder] = false;
        _poolNumHolders[poolID] = _poolNumHolders[poolID] -1;
        numHolders--;
    }
    
    function getHoldersInPool(uint poolID) public view returns (address[] memory){
        //create placeholder list of lengeth = to the provided pool ID
        address[] memory holdersInPool = new address[](_poolNumHolders[poolID]);
        //start with the guards linked address
        address currentAddress = _nextHolderPool[poolID][GUARD];
        //loop through all linked addresses and add to holdersInPool until the guard is returned
        for(uint256 i=0; currentAddress != GUARD; ++i){
            holdersInPool[i] = currentAddress;
            currentAddress = _nextHolderPool[poolID][currentAddress];
        }
        return(holdersInPool);
    }
    
    function adjustRecipientsPool(address recipient, uint256 tokenAmount) internal {
        if (!_isExcludedPool[recipient]){
                        
            if(!_isHolder[recipient] && _balances[recipient] > 0){
                addHolderToPool(recipient);
            }

            _poolTokenAmount[_addressPool[recipient]] = _poolTokenAmount[_addressPool[recipient]] + tokenAmount;
            totalPooledTokens = totalPooledTokens + tokenAmount;
        }
    }
    
    function adjustSendersPool(address sender, uint256 tokenAmount) internal {
        if (!_isExcludedPool[sender]){
            
            _poolTokenAmount[_addressPool[sender]] = _poolTokenAmount[_addressPool[sender]] - tokenAmount;
            totalPooledTokens = totalPooledTokens - tokenAmount;
            
            if(_balances[sender] == 0){
                removeHolderFromPool(sender);
            }
        } 
    }
    
    function pickLotteryWinningNumber() public onlyOwner {
        
        bytes32 requestID = getRandomNumber();
	    lotteryLastRequestID = requestID;
	  
        pause();
    }
    
    function payLotteryWinner() public onlyOwner {
        require(requestIdToRandomNumber[lotteryLastRequestID] != 0);
        uint256 currentTotal;
        uint poolID = 1;
                
        unpause();
        
        winningLotteryNumber = requestIdToRandomNumber[lotteryLastRequestID] % totalPooledTokens;

        
        //loop through each pool and check if the winning number is in the pool
        while(currentTotal + _poolTokenAmount[poolID] < winningLotteryNumber){
            currentTotal = currentTotal + _poolTokenAmount[poolID];
            poolID++;
        }
        uint winningPool = poolID;
        //produce a list of holders in the winning pool to find the individual winning holder
        address [] memory winningPoolHolders = getHoldersInPool(winningPool);
        //loop through the holders list in the pool and return the winner
        for (uint i=0; i<winningPoolHolders.length; i++) {
            if(currentTotal + _balances[winningPoolHolders[i]] < winningLotteryNumber){
                currentTotal = currentTotal + _balances[winningPoolHolders[i]];
            } else {
                lotteryWinner = winningPoolHolders[i];
                break;
            }
        }
        
        ////// take lottery amount and do uniswap to usdc and send usdc to lottery winner
        swapBNBForTokens(lotteryWinner);
        
        lotteryAmount = 0;
        
        _owedLootPrizeRandomNumber[lotteryWinner] = requestIdToRandomNumber[lotteryLastRequestID];
        _owedLootPrizes[lotteryWinner] = _owedLootPrizes[lotteryWinner] + 1;

    }
    
    //----------------------End Of Lottery Pool Functions-------------------//
    
    
    //----------------------Dividend Functions-------------------//
    
    //checks how many dividends are owed for a holder since they last claimed
    function checkDividendsOwed(address addressCheck) public view returns(uint256){
        
        uint lastClaimedID = _dWalletNextClaimableSnapshot[addressCheck];
        
        if(lastClaimedID == 0){
            lastClaimedID = 1;
        }
        
        uint currentID = _currentSnapshotId.current();
    
        require(lastClaimedID <= currentID);
        
        uint256 dividendOwed;
        
        for (uint i= lastClaimedID; i<=currentID; i++) {
            
            uint256 balanceAt = balanceOfAt(addressCheck,i);
            
            if (balanceAt != 0 && _dWalletSnapshotTotal[i] != 0) {
                
                uint256 eligbleSupplyAt = totalSupplyAt(i) - balanceOfAt(uniswapV2Pair, i) - balanceOfAt(owner(), i) - balanceOfAt(tWallet, i) - balanceOfAt(nWallet, i) - balanceOfAt(vsWallet, i) -balanceOfAt(dWallet, i); 
                
                dividendOwed = dividendOwed + _dWalletSnapshotTotal[i].mul(balanceAt).div(eligbleSupplyAt);
            }
        }
        return(dividendOwed);
    }
    
    //claim all dividends owed since last claim
    function claimAllDividends() public {
        
        require(!_isExcludedTax[_msgSender()]);
        
        uint256 dividendOwed = checkDividendsOwed(_msgSender());
        
        require(dividendOwed > 0);
        
        _transfer(dWallet, _msgSender(), dividendOwed);
        
        _dWalletNextClaimableSnapshot[_msgSender()] = _currentSnapshotId.current()+1;
        
    }
    
    //return current dividend ID
    function currentDividendsID() public view returns(uint){
        return(_currentSnapshotId.current());
    }
    
    //----------------------End Of Dividend Functions-------------------//
    
    
    //----------------------Snapshot Functions-------------------//
    
    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     *
     * Emits a {Snapshot} event that contains the same id.
     *
     */
    function _snapshot() public virtual onlyOwner returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = _currentSnapshotId.current();
        emit Snapshot(currentId);
        return currentId;
    }

    /**
     * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
     */
    function balanceOfAt(address account, uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account]);

        return snapshotted ? value : balanceOf(account);
    }

    /**
     * @dev Retrieves the total supply at the time `snapshotId` was created.
     */
    function totalSupplyAt(uint256 snapshotId) public view virtual returns(uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _totalSupplySnapshots);

        return snapshotted ? value : totalSupply();
    }
    

    function _valueAt(uint256 snapshotId, Snapshots storage snapshots)
        private view returns (bool, uint256)
    {
        require(snapshotId > 0);
        // solhint-disable-next-line max-line-length
        require(snapshotId <= _currentSnapshotId.current());

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
    
    //---------------------End Of Snapshot Functions--------------------//
    
    
    //---------------------ERC20 Standard Functions--------------------//

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
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
        require(currentAllowance >= subtractedValue);
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0));

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        
        //adjust recipient pools balance and check if recipient is new and needs to be added to pool
        adjustRecipientsPool(account, amount);
        
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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
        require(account != address(0));

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount);
        unchecked {
            _balances[account] = accountBalance - amount;
            //adjust senders pools balance and check if sender has balance 0 and needs to be removed from pool
            adjustSendersPool(account, amount);
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
        require(owner != address(0));
        require(spender != address(0));

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
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual whenNotPaused {

      if (from == address(0)) {
        // mint
        _updateAccountSnapshot(to);
        _updateTotalSupplySnapshot();
      } else if (to == address(0) && amount != 0) {
        // burn
        _updateAccountSnapshot(from);
        _updateTotalSupplySnapshot();
      } else {
        // transfer
        _updateAccountSnapshot(from);
        _updateAccountSnapshot(to);
      }
    }

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {
         
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation) internal onlyOwner override {
        
    }
    
    /** 
     * Requests randomness 
     */
    function getRandomNumber() public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee);
        return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        requestIdToRandomNumber[requestId] = randomness;
    }
    
    uint256[45] private __gap;
}