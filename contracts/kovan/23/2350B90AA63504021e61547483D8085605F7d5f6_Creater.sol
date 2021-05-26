// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

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
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
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
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(address newImplementation, bytes memory data, bool forceCall) internal {
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
                abi.encodeWithSignature(
                    "upgradeTo(address)",
                    oldImplementation
                )
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _setImplementation(newImplementation);
            emit Upgraded(newImplementation);
        }
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
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
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
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
        require(
            AddressUpgradeable.isContract(newBeacon),
            "ERC1967: new beacon is not a contract"
        );
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /*
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, "Address: low-level delegate call failed");
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
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev Base contract for building openzeppelin-upgrades compatible implementations for the {ERC1967Proxy}. It includes
 * publicly available upgrade functions that are called by the plugin and by the secure upgrade mechanism to verify
 * continuation of the upgradability.
 *
 * The {_authorizeUpgrade} function MUST be overridden to include access restriction to the upgrade mechanism.
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
    function upgradeTo(address newImplementation) external virtual {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, bytes(""), false);
    }

    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
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
import "../proxy/utils/Initializable.sol";

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
contract ERC20 is Context, IERC20, IERC20Metadata {
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
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
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
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

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

import "./BattleReady.sol";
import "./interfaces/IArena.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./structs/SettleType.sol";
import "./structs/PeroidType.sol";
import "./structs/RoundResult.sol";
import "./lib/SafeDecimalMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./structs/RoundInfo.sol";
import "./structs/BattleInfo.sol";
import "./structs/UserInfo.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./oracle/Oracle.sol";

contract Battle is BattleReady, Ownable, Initializable {
    using SafeDecimalMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    address public feeTo;
    uint public feeRatio;

    uint256 public cri;
    uint256[] public roundIds;

    IArena public arena;
    IERC20 public collateralToken;

    string public trackName;
    string public priceName;

    PeroidType public peroidType;
    SettleType public settleType;
    uint256 public settleValue;

    uint256 public spearStartPrice;
    uint256 public shieldStartPrice;

    mapping(address => uint256) public enterRoundId;
    mapping(address => EnumerableSet.UintSet) internal userRoundIds;

    uint public nextRoundSpearPrice;
    uint public preLPAmount;

    Oracle public oracle;
    bool public isInit0;
    bool public isInit;

    function init0(
        address _collateral,
        address _arena,
        string memory _trackName,
        string memory _priceName,
        PeroidType _peroidType,
        SettleType _settleType,
        uint256 _settleValue
    ) public {
        require(isInit0 == false, "init0");
        isInit0 = true;
        collateralToken = IERC20(_collateral);
        arena = IArena(_arena);
        trackName = _trackName;
        priceName = _priceName;
        peroidType = _peroidType;
        settleType = _settleType;
        settleValue = _settleValue;
    }

    function init(
        address creater,
        uint256 cAmount,
        uint256 _spearPrice,
        uint256 _shieldPrice,
        address _oracle
    ) public addUserRoundId(creater) {
        require(isInit==false, "init");
        isInit = true;
        spearStartPrice = _spearPrice;
        shieldStartPrice = _shieldPrice;
        initNewRound(cAmount);
        enterRoundId[creater] = cri;
        _mint(creater, cAmount);
        oracle = Oracle(_oracle);
    }

    function setArena(address _arena) public onlyOwner {
        arena = IArena(_arena);
    }

    function setFeeTo(address _feeTo) public onlyOwner {
        feeTo = _feeTo;
    }

    function setFeeRatio(uint _feeRatio) public onlyOwner {
        feeRatio = _feeRatio;
    }

    function setNextRoundSpearPrice(uint price) public {
        require(balanceOf(msg.sender) >= preLPAmount, "not enough lp");
        require(price < 1e18, "price error");
        spearStartPrice = price;
        shieldStartPrice = 1e18 - price;
        emit SetVPrice(msg.sender, spearStartPrice, shieldStartPrice);
    }

    function tryBuySpear(uint cDeltaAmount) public view returns(uint) {
        return tryBuySpear(cri, cDeltaAmount);
    }

    function buySpear(uint256 cDeltaAmount) public handleHistoryVirtual addUserRoundId(msg.sender){
        uint fee = cDeltaAmount.multiplyDecimal(feeRatio);
        buySpear(cri, cDeltaAmount-fee);
        collateralToken.safeTransferFrom(
            msg.sender,
            address(this),
            cDeltaAmount-fee
        );
        collateralToken.safeTransferFrom(msg.sender, feeTo, fee);
    }

    function trySellSpear(uint vDeltaAmount) public view returns(uint) {
        return trySellSpear(cri, vDeltaAmount);
    }

    function sellSpear(uint256 vDeltaAmount) public handleHistoryVirtual{
        uint256 out = sellSpear(cri, vDeltaAmount);
        uint fee = out.multiplyDecimal(feeRatio);
        collateralToken.safeTransfer(msg.sender, out-fee);
        collateralToken.safeTransfer(feeTo, fee);
    }

    function buyShield(uint cDeltaAmount) public handleHistoryVirtual addUserRoundId(msg.sender) {
        uint fee = cDeltaAmount.multiplyDecimal(feeRatio);
        buyShield(cri, cDeltaAmount-fee);
        collateralToken.safeTransferFrom(msg.sender, address(this), cDeltaAmount-fee); 
        collateralToken.safeTransferFrom(msg.sender, feeTo, fee);
    }

    function tryBuyShield(uint cDeltaAmount) public view returns(uint){
        return tryBuyShield(cri, cDeltaAmount);
    }

    function trySellShield(uint vDeltaAmount) public view returns(uint) {
        return trySellShield(cri, vDeltaAmount);
    }

    function sellShield(uint vDeltaAmount) public handleHistoryVirtual {
        uint out = sellShield(cri, vDeltaAmount);
        uint fee = out.multiplyDecimal(feeRatio);
        collateralToken.safeTransfer(msg.sender, out-fee);
        collateralToken.safeTransfer(feeTo, fee);
    }

    function tryAddLiquidity(uint cDeltaAmount) public view returns(uint cDeltaSpear, uint cDeltaShield, uint deltaSpear, uint deltaShield, uint lpDelta) {
        return tryAddLiquidity(cri, cDeltaAmount);
    }

    function addLiquidity(uint256 cDeltaAmount) public addUserRoundId(msg.sender){
        addLiquidity(cri, cDeltaAmount);
        collateralToken.safeTransferFrom(
            msg.sender,
            address(this),
            cDeltaAmount
        );
    }

    function tryRemoveLiquidity(uint lpDeltaAmount) public view returns(uint cDelta, uint deltaSpear, uint deltaShield) {
        return tryRemoveLiquidity(cri, lpDeltaAmount);
    }

    function removeLiquidity(uint256 lpDeltaAmount) public {
        uint256 cDelta = removeLiquidity(cri, lpDeltaAmount);
        collateralToken.safeTransfer(msg.sender, cDelta);
    }

    function settle() public {
        require(block.timestamp >= endTS[cri], "too early");
        require(roundResult[cri] == RoundResult.Non, "settled");
        uint256 price = oracle.historyPrice(priceName, endTS[cri]);
        require(price != 0, "price error");
        endPrice[cri] = price;
        updateRoundResult();
        // handle collateral
        uint256 cRemain = getCRemain();
        initNewRound(cRemain);
    }

    // uri => userRoundId
    // rr => roundResult
    function tryClaim(address user) public view returns(uint uri, RoundResult rr, uint amount) {
        uri = enterRoundId[user];
        rr = roundResult[uri];
        if (uri != 0 && uri < cri) {
            if (rr == RoundResult.SpearWin) {
                amount = spearBalance[uri][user];
            } else if (rr == RoundResult.ShieldWin) {
                amount = shieldBalance[uri][user];
            }
        }
    }

    function claim() public {
        (uint uri, , uint amount) = tryClaim(msg.sender);
        require(amount != 0, "spear/shield zero");
        burnSpear(uri, msg.sender, amount);
        burnShield(uri, msg.sender, amount);
        delete enterRoundId[msg.sender];
        collateralToken.safeTransfer(msg.sender, amount);
    }

    function updateRoundResult() internal {
        if (settleType == SettleType.TwoWay) {
            if (
                endPrice[cri] >= strikePriceOver[cri] ||
                endPrice[cri] <= strikePriceUnder[cri]
            ) {
                roundResult[cri] = RoundResult.SpearWin;
            } else {
                roundResult[cri] = RoundResult.ShieldWin;
            }
        } else if (settleType == SettleType.Positive) {
            if (endPrice[cri] >= strikePriceOver[cri]) {
                roundResult[cri] = RoundResult.SpearWin;
            } else {
                roundResult[cri] = RoundResult.ShieldWin;
            }
        } else if (settleType == SettleType.Negative) {
            if (endPrice[cri] >= strikePriceUnder[cri]) {
                roundResult[cri] = RoundResult.SpearWin;
            } else {
                roundResult[cri] = RoundResult.ShieldWin;
            }
        } else if (settleType == SettleType.Specific) {
            if (endPrice[cri] >= strikePrice[cri]) {
                roundResult[cri] = RoundResult.SpearWin;
            } else {
                roundResult[cri] = RoundResult.ShieldWin;
            }
        } else {
            revert("unknown settle type");
        }
    }

    function getCRemain() internal view returns (uint256 cRemain) {
        if (roundResult[cri] == RoundResult.SpearWin) {
            cRemain = collateral[cri] - spearTotal[cri];
        } else if (roundResult[cri] == RoundResult.ShieldWin) {
            cRemain = collateral[cri] - shieldTotal[cri];
        } else {
            revert("not correct round result");
        }
    }

    function initNewRound(uint256 cAmount) internal {
        (uint256 _startTS, uint256 _endTS) = oracle.getPeroidTS(uint(peroidType));
        cri = _startTS;
        roundIds.push(_startTS);
        (
            uint256 _startPrice,
            uint256 _strikePrice,
            uint256 _strikePriceOver,
            uint256 _strikePriceUnder
        ) =
            oracle.getStrikePrice(
                priceName,
                uint(peroidType),
                uint(settleType),
                settleValue
            );
        mintSpear(cri, address(this), cAmount);
        mintShield(cri, address(this), cAmount);
        addCSpear(cri, spearStartPrice.multiplyDecimal(cAmount));
        addCShield(cri, shieldStartPrice.multiplyDecimal(cAmount));
        // startPrice endPrice
        startPrice[cri] = _startPrice;
        startTS[cri] = _startTS;
        endTS[cri] = _endTS;
        strikePrice[cri] = _strikePrice;
        strikePriceOver[cri] = _strikePriceOver;
        strikePriceUnder[cri] = _strikePriceUnder;
        roundResult[cri] = RoundResult.Non;
    }

    function getBattleInfo() public view returns(BattleInfo memory) {
        return BattleInfo({
            trackName: trackName ,
            priceName: priceName,
            peroidType: peroidType,
            settleType: settleType,
            settleValue: settleValue
        });
    }

    function getCurrentRoundInfo() public view returns(RoundInfo memory) {
        return getRoundInfo(cri);
    }

    function getRoundInfo(uint ri) public view returns(RoundInfo memory) {
        return RoundInfo({
            spearPrice: spearPrice(ri),
            shieldPrice: shieldPrice(ri),
            strikePrice: strikePrice[ri],
            strikePriceOver: strikePriceOver[ri],
            strikePriceUnder: strikePriceUnder[ri],
            startTS: startTS[ri],
            endTS: endTS[ri]
        });
    }

    function getUserInfo(address user) public view returns(UserInfo memory) {
    }

    modifier addUserRoundId(address user) {
        if(!userRoundIds[user].contains(cri)) {
            userRoundIds[user].add(cri);
        }
        _;
    }

    modifier handleHistoryVirtual() {
        if (enterRoundId[msg.sender] != 0) {
            claim();
        }
        _;
    }

    event SetVPrice(address acc, uint spearPrice, uint shieldPrice);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./BondingCurve.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./lib/SafeDecimalMath.sol";
import "./structs/RoundResult.sol";

contract BattleReady is BondingCurve, ERC20 {

    using SafeDecimalMath for uint;

    mapping(uint=>uint) public startPrice;
    mapping(uint=>uint) public endPrice;

    mapping(uint=>uint) public startTS;
    mapping(uint=>uint) public endTS;

    mapping(uint=>uint) public strikePrice;
    mapping(uint=>uint) public strikePriceOver;
    mapping(uint=>uint) public strikePriceUnder;

    mapping(uint=>RoundResult) public roundResult;

    constructor() ERC20("Battle Liquilidity Token", "BLP") {

    }

    function tryAddLiquidity(uint ri, uint cDeltaAmount) public view returns(uint cDeltaSpear, uint cDeltaShield, uint deltaSpear, uint deltaShield, uint lpDelta) {
        uint cVirtual = cSpear[ri] + cShield[ri];
        cDeltaSpear = cSpear[ri].multiplyDecimal(cDeltaAmount).divideDecimal(cVirtual);
        cDeltaShield = cShield[ri].multiplyDecimal(cDeltaAmount).divideDecimal(cVirtual);
        deltaSpear = spearBalance[ri][address(this)].multiplyDecimal(cDeltaAmount).divideDecimal(cVirtual);
        deltaShield = shieldBalance[ri][address(this)].multiplyDecimal(cDeltaAmount).divideDecimal(cVirtual);
        if(totalSupply() == 0) {
            lpDelta = cDeltaAmount;
        } else {
            lpDelta = cDeltaAmount.multiplyDecimal(totalSupply()).divideDecimal(collateral[ri]);
        }
    }

    function addLiquidity(uint ri, uint cDeltaAmount) internal {
        (uint cDeltaSpear, uint cDeltaShield, uint deltaSpear, uint deltaShield, uint lpDelta) = tryAddLiquidity(ri, cDeltaAmount);
        addCSpear(ri, cDeltaSpear);
        addCShield(ri, cDeltaShield);
        mintSpear(ri, msg.sender, deltaSpear);
        mintShield(ri, msg.sender, deltaShield);
        // mint lp
        _mint(msg.sender, lpDelta);
    }

    function tryRemoveLiquidity(uint ri, uint lpDeltaAmount) public view returns(uint cDelta, uint deltaSpear, uint deltaShield){
        uint spSold = spearSold(ri);
        uint shSold = shieldSold(ri);
        uint maxSold = spSold > shSold ? spSold:shSold;
        cDelta = (collateral[ri] - maxSold).multiplyDecimal(lpDeltaAmount).divideDecimal(totalSupply());
        deltaSpear = spearBalance[ri][address(this)].multiplyDecimal(lpDeltaAmount).divideDecimal(totalSupply());
        deltaShield = shieldBalance[ri][address(this)].multiplyDecimal(lpDeltaAmount).divideDecimal(totalSupply());
    }

    function removeLiquidity(uint ri, uint lpDeltaAmount) internal returns(uint) {
        (uint cDelta, uint deltaSpear, uint deltaShield) = tryRemoveLiquidity(ri, lpDeltaAmount);
        uint cDeltaSpear = cDelta.multiplyDecimal(cSpear[ri]).divideDecimal(collateral[ri]);
        uint cDeltaShield = cDelta.multiplyDecimal(cShield[ri]).divideDecimal(collateral[ri]);
        uint cDeltaSurplus = cDelta.multiplyDecimal(cSurplus(ri)).divideDecimal(collateral[ri]);
        subCSpear(ri, cDeltaSpear);
        subCShield(ri, cDeltaShield);
        subCSurplus(ri, cDeltaSurplus);
        burnSpear(ri, address(this), deltaSpear);
        burnShield(ri, address(this), deltaShield);
        _burn(msg.sender, lpDeltaAmount);
        return cDelta;
    }

    function _afterAddLiquidity(uint ri, uint cDeltaAmount) internal virtual {}
    function _afterRemoveLiquidity(uint ri, uint lpDeltaAmount) internal virtual {}

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./VirtualToken.sol";
import "./lib/SafeDecimalMath.sol";
import "./algo/Pricing.sol";

contract BondingCurve is VirtualToken {

    using SafeDecimalMath for uint;

    uint maxPrice = 0.9999 * 1e18;
    uint minPrice = 1e18 - maxPrice;

    function spearPrice(uint roundId) public view returns(uint) {
        uint spPrice = cSpear[roundId].divideDecimal(spearBalance[roundId][address(this)]);
        return spPrice;
    }

    function shieldPrice(uint roundId) public view returns(uint) {
        uint shPrice = cShield[roundId].divideDecimal(shieldBalance[roundId][address(this)]);
        return shPrice;
    }

    function buySpear(uint roundId, uint cDeltaAmount) internal {
        uint out = tryBuySpear(roundId, cDeltaAmount);
        uint spearInContract = spearBalance[roundId][address(this)];
        uint shieldInContract = shieldBalance[roundId][address(this)];
        if ((cDeltaAmount + cSpear[roundId]).divideDecimal(spearInContract-out) >= maxPrice) {
            setCSpear(roundId, maxPrice.multiplyDecimal(spearInContract));
            addCollateral(roundId, cDeltaAmount);
            // handle shield
            transferSpear(roundId, address(this), msg.sender, out);
            setCShield(roundId, minPrice.multiplyDecimal(shieldInContract));
        } else {
            addCSpear(roundId, cDeltaAmount);
            transferSpear(roundId, address(this), msg.sender, out);
            setCShield(roundId, (1e18 - spearPrice(roundId)).multiplyDecimal(shieldInContract));
        }
    }

    function tryBuySpear(uint roundId, uint cDeltaAmount) internal view returns(uint out){
        out = Pricing.getVirtualOut(cDeltaAmount, cSpear[roundId], spearBalance[roundId][address(this)]);
    }

    function tryBuyShield(uint roundId, uint cDeltaAmount) internal view returns(uint out) {
        out = Pricing.getVirtualOut(cDeltaAmount, cShield[roundId], shieldBalance[roundId][address(this)]);
    }


    function buyShield(uint roundId, uint cDeltaAmount) internal {
        uint out = tryBuyShield(roundId, cDeltaAmount);
        uint spearInContract = spearBalance[roundId][address(this)];
        uint shieldInContract = shieldBalance[roundId][address(this)];
        if ((cDeltaAmount + cShield[roundId]).divideDecimal(shieldInContract-out) >= maxPrice) {
            setCShield(roundId, maxPrice.multiplyDecimal(shieldInContract));
            addCollateral(roundId, cDeltaAmount);
            // handle shield
            transferShield(roundId, address(this), msg.sender, out);
            setCSpear(roundId, minPrice.multiplyDecimal(spearInContract));
        } else {
            addCShield(roundId, cDeltaAmount);
            transferShield(roundId, address(this), msg.sender, out);
            setCSpear(roundId, (1e18 - shieldPrice(roundId)).multiplyDecimal(shieldInContract));
        }
    }

   

    function sellSpear(uint roundId, uint vDeltaAmount) internal returns(uint out) {
        uint shieldInContract = shieldBalance[roundId][address(this)];
        out = trySellSpear(roundId, vDeltaAmount);
        subCSpear(roundId, out);
        transferSpear(roundId, msg.sender, address(this), vDeltaAmount);
        setCShield(roundId, (1e18 - spearPrice(roundId)).multiplyDecimal(shieldInContract));
    }

    function trySellSpear(uint roundId, uint vDeltaAmount) internal view returns(uint out) {
        uint spearInContract = spearBalance[roundId][address(this)];
        out = Pricing.getCollateralOut(vDeltaAmount, spearInContract, cSpear[roundId]);
    }

     function trySellShield(uint roundId, uint vDeltaAmount) internal view returns(uint out) {
        uint shieldInContract = shieldBalance[roundId][address(this)];
        out = Pricing.getCollateralOut(vDeltaAmount, shieldInContract, cShield[roundId]);
    }

    function sellShield(uint roundId, uint vDeltaAmount) internal returns(uint out) {
        out = trySellShield(roundId, vDeltaAmount);
        uint spearInContract = spearBalance[roundId][address(this)];
        subCShield(roundId, out);
        transferShield(roundId, msg.sender, address(this), vDeltaAmount);
        setCSpear(roundId, (1e18 - shieldPrice(roundId)).multiplyDecimal(spearInContract));
    }

    function _afterBuySpear(uint roundId, uint cDeltaAmount) internal virtual {}
    function _afterSellSpear(uint roundId, uint vDeltaAmount) internal virtual {}
    function _afterBuyShield(uint roundId, uint cDeltaAmount) internal virtual {}
    function _afterSellShield(uint roundId, uint vDeltaAmount) internal virtual {}

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Battle.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

contract Creater {
    
    function getBattleAddress(
        address _collateral,
        string memory _trackName,
        uint _peroidType,
        uint _settleType,
        uint256 _settleValue
    ) public view returns(address, bytes32){
         bytes32 salt =
            keccak256(
                abi.encodePacked(
                    _collateral,
                    _trackName,
                    _peroidType,
                    _settleType,
                    _settleValue
                )
            );
        bytes32 bytecodeHash = keccak256(type(Battle).creationCode);
        address battleAddr = Create2.computeAddress(salt, bytecodeHash);
        return (battleAddr, salt);
    }

    function createBattle(bytes32 salt) public {
        Create2.deploy(0, salt, type(Battle).creationCode);
    }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract VirtualToken {
    mapping (uint=>uint) public spearTotal;
    mapping(uint => mapping(address=>uint)) public spearBalance;


    mapping (uint=>uint) public shieldTotal;
    mapping(uint => mapping(address=>uint)) public shieldBalance;


    mapping(uint=>uint) public cSpear;
    mapping(uint=>uint) public cShield;
    mapping(uint=>uint) public collateral;

    // 0 => spear; 1 => shield
    event Transfer(uint spearOrShield, address from, address to, uint amount);
    event Mint(uint spearOrShield, address to, uint amount);
    event Burn(uint spearOrShield, address from, uint amount);

    // view
    function spearSold(uint roundId) public view returns(uint){
        return spearTotal[roundId] - spearBalance[roundId][address(this)];
    }

    function shieldSold(uint roundId) public view returns(uint) {
        return shieldTotal[roundId] - shieldBalance[roundId][address(this)];
    }

    function cSurplus(uint roundId) public view returns(uint amount) {
        amount = collateral[roundId] - cSpear[roundId] - cShield[roundId];
    }

    // mut
    function addCSpear(uint roundId, uint amount) internal {
        cSpear[roundId] += amount;
        collateral[roundId] += amount;
    }

    function addCShield(uint roundId, uint amount) internal {
        cShield[roundId] += amount;
        collateral[roundId] += amount;
    }

    function subCSpear(uint roundId, uint amount) internal {
        cSpear[roundId] -= amount;
        collateral[roundId] -= amount;
    }

    function subCShield(uint roundId, uint amount) internal {
        cShield[roundId] -= amount;
        collateral[roundId] -= amount;
    }

    function subCSurplus(uint roundId, uint amount) internal {
        collateral[roundId] -= amount;
    }

    function setCSpear(uint roundId, uint amount) internal {
        cSpear[roundId] = amount;
    }

    function setCShield(uint roundId, uint amount) internal {
        cShield[roundId] = amount;
    }

    function addCollateral(uint roundId, uint amount) internal {
        collateral[roundId] += amount;
    }

    function transferSpear(uint roundId, address from, address to, uint amount) internal {
        require(from != address(0), "from should not be address(0)");
        require(to != address(0), "to should not be address(0)");
        spearBalance[roundId][from] -= amount;
        spearBalance[roundId][to] += amount;
        emit Transfer(0, from, to, amount);
    }

    function transferShield(uint roundId, address from, address to, uint amount) internal {
        require(from != address(0), "from should not be address(0)");
        require(to != address(0), "to should not be address(0)");
        shieldBalance[roundId][from] -= amount;
        shieldBalance[roundId][to] += amount;
        emit Transfer(1, from, to, amount);
    }

    function burnSpear(uint roundId, address acc, uint amount) internal {
        spearBalance[roundId][acc] -= amount;
        spearTotal[roundId] -= amount;
        emit Burn(0, acc, amount);
    }

    function burnShield(uint roundId, address acc, uint amount) internal {
        shieldBalance[roundId][acc] -= amount;
        shieldTotal[roundId] -= amount;
        emit Burn(1, acc, amount);
    }

    function mintSpear(uint roundId, address acc, uint amount) internal {
        spearBalance[roundId][acc] += amount;
        spearTotal[roundId] += amount;
        emit Mint(0, acc, amount);
    }

    function mintShield(uint roundId, address acc, uint amount) internal {
        shieldBalance[roundId][acc] += amount;
        shieldTotal[roundId] += amount;
        emit Mint(1, acc, amount);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../lib/DMath.sol";
import "../lib/SafeDecimalMath.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library Pricing {
    
    using SafeMath for uint;
    using SafeDecimalMath for uint;

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

    function getVirtualOut(uint cDeltaAmount, uint cAmount, uint vAmount) internal pure returns(uint) {
        if (cAmount.divideDecimal(vAmount) >= 0.9999 * 1e18) {
            return cDeltaAmount;
        }
        uint cLimitAmount = DMath.sqrt(cAmount*vAmount.mul(9999).div(10000));
        uint vLimitAmount = DMath.sqrt(cAmount*vAmount.mul(10000).div(9999));
        if (cDeltaAmount + cAmount > cLimitAmount) {
            return vAmount - vLimitAmount + cDeltaAmount - cLimitAmount + cAmount;
        } else {
            uint numerator = vAmount * cDeltaAmount;
            uint denominator = cAmount + cDeltaAmount;
            return numerator / denominator;
        }
    }

    function getCollateralOut(uint vDeltaAmount, uint vAmount, uint cAmount) internal pure returns(uint) {
        uint numerator = cAmount * vDeltaAmount;
        uint denominator = vAmount + vDeltaAmount;
        return numerator / denominator;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../structs/PeroidType.sol";
import "../structs/SettleType.sol";

interface IArena {
//     function getPeroidTS(PeroidType peroidType)
//         external
//         view
//         returns (uint256, uint256);

//     function getSpacePrice(uint256 oraclePrice, uint256 rawPrice)
//         external
//         pure
//         returns (uint256 price);

//     function getStrikePrice(
//         string memory symbol,
//         PeroidType _peroidType,
//         SettleType _settleType,
//         uint256 _settleValue
//     )
//         external
//         returns (
//             uint256 startPrice,
//             uint256 strikePrice,
//             uint256 strikePriceOver,
//             uint256 strikePriceUnder
//         );

//    function getPriceByTS(string memory symbol, uint ts) external view returns(uint);
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

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "../structs/SettleType.sol";
import "../lib/SafeDecimalMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Oracle is Initializable, UUPSUpgradeable, OwnableUpgradeable{
    using SafeDecimalMath for uint;

    mapping(string=>uint) public price;
    mapping(string=>mapping(uint=>uint)) public historyPrice;
    // bytes32 public ORACLE_ROLE;

    uint[] public monSTS;
    uint[] public monETS;

    function initialize() public initializer {
        // _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // _setupRole(ORACLE_ROLE, msg.sender);
        // ORACLE_ROLE = "oracle_role";
        __Ownable_init_unchained();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function setPrice(string memory symbol, uint ts, uint _price) public onlyOwner{
        // require(hasRole(ORACLE_ROLE, msg.sender), "caller not oracle");
        price[symbol] = _price;
        historyPrice[symbol][ts] = _price;
    }

    function setMultiPrice(string memory symbol, uint[] memory ts, uint[] memory _prices) public {
        require(ts.length == _prices.length, "length should match");
        for(uint i; i < ts.length; i++) {
            setPrice(symbol, ts[i], _prices[i]);
        }
    }
    // 0 => day; 1 => week; 2 => month
    function getPeroidTS(uint _peroidType) public view returns (uint start, uint end) {
        // 0 => day
        if (_peroidType == 0) {
            start = block.timestamp - (block.timestamp % 86400);
            end = start + 86400;
        } else if (_peroidType == 2) {
            // 1 => week
            start = block.timestamp - ((block.timestamp + 259200) % 604800);
            end = start + 604800;
        } else if (_peroidType == 3) {
            // 2 => month
            for (uint256 i; i < monSTS.length; i++) {
                if (
                    monSTS[i] >= block.timestamp &&
                    monETS[i] <= block.timestamp
                ) {
                    start = monSTS[i];
                    end = monETS[i];
                }
            }
            require(start != 0, "not known start ts");
            require(end != 0, "not known end ts");
        }
    }

    function setMonthTS(uint256[] memory starts, uint256[] memory ends) public {
        require(starts.length == ends.length, "starts and ends should match");
        for (uint256 i; i < starts.length; i++) {
            monSTS.push(starts[i]);
            monETS.push(ends[i]);
        }
    }

    // peroidType: 
    // settleType: 
    // TwoWay, // 0
    // Positive, // 1
    // Negative, // 2
    // Specific // 3
    function getStrikePrice(
        string memory symbol,
        uint _peroidType,
        uint _settleType,
        uint256 _settleValue
    )
        public
        view
        returns (
            uint256 startPrice,
            uint256 strikePrice,
            uint256 strikePriceOver,
            uint256 strikePriceUnder
        )
    {
        (uint256 startTS, ) = getPeroidTS(_peroidType);
        startPrice = historyPrice[symbol][startTS];
        uint256 settlePrice;
        uint256 settlePriceOver;
        uint256 settlePriceUnder;
        if (_settleType == 3) {
            settlePrice = _settleValue;
        } else if (_settleType == 0) {
            settlePriceOver = startPrice.multiplyDecimal(1e18 + _settleValue);
            settlePriceUnder = startPrice.multiplyDecimal(1e18 - _settleValue);
        } else if (_settleType == 1) {
            settlePriceOver = startPrice.multiplyDecimal(1e18 + _settleValue);
        } else if (_settleType == 2) {
            settlePriceUnder = startPrice.multiplyDecimal(1e18 - _settleValue);
        } else {
            revert("unknown Settle Type");
        }
        strikePrice = getSpacePrice(startPrice, settlePrice);
        strikePriceOver = getSpacePrice(startPrice, settlePriceOver);
        strikePriceUnder = getSpacePrice(startPrice, settlePriceUnder);
    }

    function getSpacePrice(uint256 oraclePrice, uint256 rawPrice)
        public
        pure
        returns (uint256 price_)
    {
        uint256 i = 12;
        while (oraclePrice / 10**i >= 10) {
            i += 1;
        }
        uint256 minI = i - 2;
        uint256 maxI = i - 1;
        uint256 unit0 = 10**minI;
        uint256 unit1 = 10**maxI;

        uint256 overBound = (oraclePrice * 130) / 100;
        uint256 underBound = (oraclePrice * 70) / 100;
        if (rawPrice >= underBound || rawPrice <= overBound) {
            price_ = (rawPrice / unit0) * unit0;
        } else {
            price_ = (rawPrice / unit1) * unit1;
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PeroidType.sol";
import "./SettleType.sol";

struct BattleInfo {
    string trackName;
    string priceName;
    PeroidType peroidType;
    SettleType settleType;
    uint settleValue;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

enum PeroidType {
    Day, // 0 
    Week, // 1
    Month // 2
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PeroidType.sol";
import "./SettleType.sol";

struct RoundInfo {
    uint spearPrice;
    uint shieldPrice;
    uint strikePrice;
    uint strikePriceOver;
    uint strikePriceUnder;
    uint startTS;
    uint endTS;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

enum RoundResult {
    Non, // 0
    SpearWin, // 1
    ShieldWin //2
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

enum SettleType {
    TwoWay, // 0
    Positive, // 1
    Negative, // 2
    Specific // 3

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

struct UserInfo {
    uint[] roundIds;
    uint[] spearBalances;
    uint[] shieldBalances;
    uint lpBalance;
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
    "runs": 100
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