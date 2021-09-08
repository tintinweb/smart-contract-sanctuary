/**
 *Submitted for verification at Etherscan.io on 2021-09-08
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

interface IERC165 {
    
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC1155Receiver is IERC165 {
    
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);
    
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

library AddressUpgradeable {
    
    function isContract(address account) internal view returns (bool) {

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

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
        require(isContract(target), "Address: static call to non-contract");

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
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
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
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
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

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][account] = accountBalance - amount;
            }
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

interface ERC1888 is IERC1155 {

    struct Certificate {
        uint256 topic;
        address issuer;
        bytes validityData;
        bytes data;
    }

   event IssuanceSingle(address indexed _issuer, uint256 indexed _topic, uint256 _id, uint256 _value);
   event IssuanceBatch(address indexed _issuer, uint256 indexed _topic, uint256[] _ids, uint256[] _values);
   
   event ClaimSingle(address indexed _claimIssuer, address indexed _claimSubject, uint256 indexed _topic, uint256 _id, uint256 _value, bytes _claimData);
   event ClaimBatch(address indexed _claimIssuer, address indexed _claimSubject, uint256[] indexed _topics, uint256[] _ids, uint256[] _values, bytes[] _claimData);
   
   function issue(address _to, bytes calldata _validityData, uint256 _topic, uint256 _value, bytes calldata _issuanceData) external returns (uint256);
   function batchIssue(address _to, bytes memory _issuanceData, uint256 _topic, uint256[] memory _values, bytes[] memory _validityCalls) external returns(uint256[] memory);
   
   function safeTransferAndClaimFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data, bytes calldata _claimData) external;
   function safeBatchTransferAndClaimFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data, bytes[] calldata _claimData) external;

   function getCertificate(uint256 _id) external view returns (address issuer, uint256 topic, bytes memory validityCall, bytes memory data);
   function claimedBalanceOf(address _owner, uint256 _id) external view returns (uint256);
   function claimedBalanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);
}

contract PrivateIssuer is Initializable, OwnableUpgradeable, UUPSUpgradeable {

	// Public issuance contract
	Issuer public issuer;

    // ERC-1888 contract to issue certificates to
	Registry public registry;

	event PrivateCertificationRequestApproved(address indexed _owner, uint256 indexed _id, uint256 indexed _certificateId);
	event CommitmentUpdated(address indexed _owner, uint256 indexed _id, bytes32 _commitment);
	event MigrateToPublicRequested(address indexed _owner, uint256 indexed _id);
	event PrivateTransferRequested(address indexed _owner, uint256 indexed _certificateId);
	event CertificateMigratedToPublic(uint256 indexed _certificateId, address indexed _owner, uint256 indexed _amount);

	// Storage for RequestStateChange
	mapping(uint256 => RequestStateChange) private _requestMigrateToPublicStorage;

	// Storage for PrivateTransferRequest
	mapping(uint256 => PrivateTransferRequest) private _requestPrivateTransferStorage;

	// Mapping to keep track if a certification request has been migrated to public
	mapping(uint256 => bool) private _migrations;

	// Storing a commitment (proof) per certification request ID
	mapping(uint256 => bytes32) private _commitments;

	// Nonce for generating RequestStateChange IDs
	uint256 private _requestMigrateToPublicNonce;

	// Nonce for generating PrivateTransferRequest IDs
	uint256 private _requestPrivateTransferNonce;

    struct PrivateTransferRequest {
		address owner; // Address that requested a migration to public certificate
		bytes32 hash; // Commitment proof that
	}

	struct RequestStateChange {
		address owner; // Owner of the certificate
		uint256 certificateId; // ID of the issued certificate
		bytes32 hash; // Commitment (proof)
		bool approved;
	}

	struct Proof {
		bool left;
		bytes32 hash;
	}
	
    /// @notice Constructor.
    /// @dev Uses the OpenZeppelin `initializer` for upgradeability.
	/// @dev `_issuer` cannot be the zero address.
    function initialize(address _issuer) public initializer {
        require(_issuer != address(0), "PrivateIssuer::initialize: Cannot use address 0x0 as Issuer address.");

        issuer = Issuer(_issuer);
		registry = Registry(issuer.getRegistryAddress());

        OwnableUpgradeable.__Ownable_init();
		UUPSUpgradeable.__UUPSUpgradeable_init();
    }

	/*
		Certification requests
	*/

    /// @notice Get the commitment (proof) for a specific certificate.
    function getCertificateCommitment(uint256 certificateId) public view returns (bytes32) {
        return _commitments[certificateId];
    }

    function approveCertificationRequestPrivate(
        uint256 _requestId,
        bytes32 _commitment
    ) public onlyOwner returns (uint256) {
		uint256 certificateId = issuer.approveCertificationRequest(_requestId, 0);
        _updateCommitment(certificateId, 0x0, _commitment);

		Issuer.CertificationRequest memory request = issuer.getCertificationRequest(_requestId);

        emit PrivateCertificationRequestApproved(request.owner, _requestId, certificateId);

        return certificateId;
    }

	/// @notice Directly issue a private certificate.
    function issuePrivate(address _to, bytes32 _commitment, bytes memory _data) public onlyOwner returns (uint256) {
        require(_to != address(0x0), "PrivateIssuer::issuePrivate: Cannot use address 0x0 as _to address.");

        uint256 requestId = issuer.requestCertificationFor(_data, _to);

        return approveCertificationRequestPrivate(
            requestId,
            _commitment
        );
    }

	/// @notice Request transferring a certain amount of tokens.
	/// @param _certificateId Certificate that you want to change the balances of.
	/// @param _ownerAddressLeafHash New updated proof (balances per address).
	function requestPrivateTransfer(uint256 _certificateId, bytes32 _ownerAddressLeafHash) external {
		PrivateTransferRequest storage currentRequest = _requestPrivateTransferStorage[_certificateId];

		/*
		//RESTRICTION: There can only be one private transfer request at a time per certificate.
		 */
        require(currentRequest.owner == address(0x0), "PrivateIssuer::requestPrivateTransfer:Only one private transfer can be requested at a time.");

		_requestPrivateTransferStorage[_certificateId] = PrivateTransferRequest({
			owner: _msgSender(),
			hash: _ownerAddressLeafHash
		});

		emit PrivateTransferRequested(_msgSender(), _certificateId);
	}

	/// @notice Approve a private transfer of certificates.
	function approvePrivateTransfer(
        uint256 _certificateId,
        Proof[] calldata _proof,
        bytes32 _previousCommitment,
        bytes32 _commitment
    ) external onlyOwner returns (bool) {
		PrivateTransferRequest storage pendingRequest = _requestPrivateTransferStorage[_certificateId];

        require(pendingRequest.owner != address(0x0), "PrivateIssuer::approvePrivateTransfer: Can't approve a non-existing private transfer.");
		require(validateMerkle(pendingRequest.hash, _commitment, _proof), "PrivateIssuer::approvePrivateTransfer: Wrong merkle tree");

        _requestPrivateTransferStorage[_certificateId] = PrivateTransferRequest({
			owner: address(0x0),
			hash: ''
		});

		_updateCommitment(_certificateId, _previousCommitment, _commitment);

        return true;
	}

	/// @notice Request the certificate volumes to be migrated from private to public.
	/// @param _certificateId Certificate that you want to migrate to public.
	/// @param _ownerAddressLeafHash Final balance proof.
	function requestMigrateToPublic(uint256 _certificateId, bytes32 _ownerAddressLeafHash) external returns (uint256 _migrationRequestId) {
        return _requestMigrateToPublicFor(_certificateId, _ownerAddressLeafHash, _msgSender());
	}

	/// @notice Request the certificate volumes to be migrated from private to public for someone else.
	/// @param _certificateId Certificate that you want to migrate to public.
	/// @param _ownerAddressLeafHash Final balance proof.
	/// @param _forAddress Owner.
	function requestMigrateToPublicFor(uint256 _certificateId, bytes32 _ownerAddressLeafHash, address _forAddress) external onlyOwner returns (uint256 _migrationRequestId) {
        return _requestMigrateToPublicFor(_certificateId, _ownerAddressLeafHash, _forAddress);
	}

	/// @notice Get the private transfer request that is currently active for a specific certificate.
    function getPrivateTransferRequest(uint256 _certificateId) external view onlyOwner returns (PrivateTransferRequest memory) {
        return _requestPrivateTransferStorage[_certificateId];
    }

	/// @notice Get the migration request.
    function getMigrationRequest(uint256 _requestId) external view onlyOwner returns (RequestStateChange memory) {
        return _requestMigrateToPublicStorage[_requestId];
    }

	/// @notice Get the migration request ID for a specific certificate.
    function getMigrationRequestId(uint256 _certificateId) external view onlyOwner returns (uint256 _migrationRequestId) {
        bool found = false;

		for (uint256 i = 1; i <= _requestMigrateToPublicNonce; i++) {
            if (_requestMigrateToPublicStorage[i].certificateId == _certificateId) {
                found = true;
			    return i;
            }
		}

        require(found, "unable to find the migration request");
    }

	/// @notice Migrate a private certificate to be public.
	/// @param _requestId Migration Request ID.
	/// @param _volume Volume that should be minted.
	/// @param _salt Precise Proof salt.
	/// @param _proof Precise Proof.
	function migrateToPublic(
        uint256 _requestId,
        uint256 _volume,
        string calldata _salt,
        Proof[] calldata _proof
    ) external onlyOwner {
		RequestStateChange storage request = _requestMigrateToPublicStorage[_requestId];

		require(!request.approved, "PrivateIssuer::migrateToPublic: Request already approved");
        require(!_migrations[request.certificateId], "PrivateIssuer::migrateToPublic: certificate already migrated");
		require(request.hash == keccak256(abi.encodePacked(request.owner, _volume, _salt)), "PrivateIssuer::migrateToPublic: Requested hash does not match");
        require(validateOwnershipProof(request.owner, _volume, _salt, _commitments[request.certificateId], _proof), "PrivateIssuer::migrateToPublic: Invalid proof");

		request.approved = true;

        registry.mint(request.certificateId, request.owner, _volume);
        _migrations[request.certificateId] = true;

        _updateCommitment(request.certificateId, _commitments[request.certificateId], 0x0);

        emit CertificateMigratedToPublic(request.certificateId, request.owner, _volume);
	}

	/*
		Utils
	*/

	/// @notice Validates that a `_ownerAddress` actually owns `_volume` in a precise proof.
	/// @param _ownerAddress Owner blockchain address.
	/// @param _volume Volume that the owner should have.
	/// @param _salt Precise Proof salt.
	/// @param _rootHash Hash of the merkle tree root.
	/// @param _proof Full Precise Proof.
	function validateOwnershipProof(
        address _ownerAddress,
        uint256 _volume,
        string memory _salt,
        bytes32 _rootHash,
        Proof[] memory _proof
    ) private pure returns (bool) {
		bytes32 leafHash = keccak256(abi.encodePacked(_ownerAddress, _volume, _salt));

		return validateMerkle(leafHash, _rootHash, _proof);
	}

	/// @notice Validates that a `_leafHash` is a leaf in the `_proof` with a merkle root hash `_rootHash`.
	/// @param _leafHash Hash of the leaf in the merkle tree.
	/// @param _rootHash Hash of the merkle tree root.
	/// @param _proof Full Precise Proof.
	function validateMerkle(bytes32 _leafHash, bytes32 _rootHash, Proof[] memory _proof) private pure returns (bool) {
		bytes32 hash = _leafHash;

		for (uint256 i = 0; i < _proof.length; i++) {
			Proof memory p = _proof[i];
			if (p.left) {
				hash = keccak256(abi.encodePacked(p.hash, hash));
			} else {
				hash = keccak256(abi.encodePacked(hash, p.hash));
			}
		}

		return _rootHash == hash;
	}

	/*
		Private methods
	*/

	function _updateCommitment(uint256 _id, bytes32 _previousCommitment, bytes32 _commitment) private {
		require(_commitments[_id] == _previousCommitment, "PrivateIssuer::updateCommitment: previous commitment invalid");

		_commitments[_id] = _commitment;

		emit CommitmentUpdated(_msgSender(), _id, _commitment);
	}

    function _migrationRequestExists(uint256 _certificateId) private view returns (bool) {
        bool exists = false;

		for (uint256 i = 1; i <= _requestMigrateToPublicNonce; i++) {
            if (_requestMigrateToPublicStorage[i].certificateId == _certificateId) {
                exists = true;
                return exists;
            }
		}

        return exists;
    }

    function _requestMigrateToPublicFor(uint256 _certificateId, bytes32 _ownerAddressLeafHash, address _forAddress) private returns (uint256 _migrationRequestId) {
        bool exists = _migrationRequestExists(_certificateId);
        require(!exists, "PrivateIssuer::_requestMigrateToPublicFor: migration request for this certificate already exists");

		uint256 id = ++_requestMigrateToPublicNonce;

		_requestMigrateToPublicStorage[id] = RequestStateChange({
			owner: _forAddress,
			hash: _ownerAddressLeafHash,
			certificateId: _certificateId,
			approved: false
		});

		emit MigrateToPublicRequested(_forAddress, id);

        return id;
	}

	function _authorizeUpgrade(address) internal override onlyOwner {}

	/*
		Info
	*/

    function getIssuerAddress() external view returns (address) {
        return address(issuer);
    }

    function version() external pure returns (string memory) {
        return "v0.1";
    }
}

contract Issuer is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    event CertificationRequested(address indexed _owner, uint256 indexed _id);
    event CertificationRequestedBatch(address[] indexed _owners, uint256[] indexed _id);
    event CertificationRequestApproved(address indexed _owner, uint256 indexed _id, uint256 indexed _certificateId);
    event CertificationRequestBatchApproved(address[] indexed _owners, uint256[] indexed _ids, uint256[] indexed _certificateIds);
    event CertificationRequestRevoked(address indexed _owner, uint256 indexed _id);

    event CertificateRevoked(uint256 indexed _certificateId);

    // Certificate topic - check ERC-1888 topic description
    uint256 public certificateTopic;

    // ERC-1888 contract to issue certificates to
    Registry public registry;

    // Optional: Private Issuance contract
    address public privateIssuer;

    // Storage for CertificationRequest structs
    mapping(uint256 => CertificationRequest) private _certificationRequests;

    // Mapping from request ID to certificate ID
    mapping(uint256 => uint256) private requestToCertificate;

    // Incrementing nonce, used for generating certification request IDs
    uint256 private _latestCertificationRequestId;

    // Mapping to whether a certificate with a specific ID has been revoked by the Issuer
    mapping(uint256 => bool) private _revokedCertificates;

    struct CertificationRequest {
        address owner; // Owner of the request
        bytes data;
        bool approved;
        bool revoked;
        address sender;  // User that triggered the request creation
    }

	/// @notice Contructor.
    /// @dev Uses the OpenZeppelin `initializer` for upgradeability.
    /// @dev `_registry` cannot be the zero address.
    function initialize(uint256 _certificateTopic, address _registry) public initializer {
        require(_registry != address(0), "Issuer::initialize: Cannot use address 0x0 as registry address.");

        certificateTopic = _certificateTopic;

        registry = Registry(_registry);
        OwnableUpgradeable.__Ownable_init();
        UUPSUpgradeable.__UUPSUpgradeable_init();
    }

	/// @notice Attaches a private issuance contract to this issuance contract.
    /// @dev `_privateIssuer` cannot be the zero address.
    function setPrivateIssuer(address _privateIssuer) public onlyOwner {
        require(_privateIssuer != address(0), "Issuer::setPrivateIssuer: Cannot use address 0x0 as the private issuer address.");
        require(privateIssuer == address(0), "Issuer::setPrivateIssuer: private issuance contract already set.");

        privateIssuer = _privateIssuer;
    }

	/*
		Certification requests
	*/

    function getCertificationRequest(uint256 _requestId) public view returns (CertificationRequest memory) {
        return _certificationRequests[_requestId];
    }

    function requestCertificationFor(bytes memory _data, address _owner) public returns (uint256) {
        uint256 id = ++_latestCertificationRequestId;

        _certificationRequests[id] = CertificationRequest({
            owner: _owner,
            data: _data,
            approved: false,
            revoked: false,
            sender: _msgSender()
        });

        emit CertificationRequested(_owner, id);

        return id;
    }

    function requestCertificationForBatch(bytes[] memory _data, address[] memory _owners) public returns (uint256[] memory) {
        uint256[] memory requestIds = new uint256[](_data.length);

        for (uint256 i = 0; i < _data.length; i++) {
            uint256 id = i + _latestCertificationRequestId + 1;

            _certificationRequests[id] = CertificationRequest({
                owner: _owners[i],
                data: _data[i],
                approved: false,
                revoked: false,
                sender: _msgSender()
            });

            requestIds[i] = id;
        }

        emit CertificationRequestedBatch(_owners, requestIds);

        _latestCertificationRequestId = requestIds[requestIds.length - 1];

        return requestIds;
    }

    function requestCertification(bytes calldata _data) external returns (uint256) {
        return requestCertificationFor(_data, _msgSender());
    }

    function revokeRequest(uint256 _requestId) external {
        CertificationRequest storage request = _certificationRequests[_requestId];

        require(_msgSender() == request.owner || _msgSender() == OwnableUpgradeable.owner(), "Issuer::revokeRequest: Only the request creator can revoke the request.");
        require(!request.revoked, "Issuer::revokeRequest: Already revoked");
        require(!request.approved, "Issuer::revokeRequest: You can't revoke approved requests");

        request.revoked = true;

        emit CertificationRequestRevoked(request.owner, _requestId);
    }

    function revokeCertificate(uint256 _certificateId) external onlyOwner {
        require(!_revokedCertificates[_certificateId], "Issuer::revokeCertificate: Already revoked");
        _revokedCertificates[_certificateId] = true;

        emit CertificateRevoked(_certificateId);
    }

    function approveCertificationRequest(
        uint256 _requestId,
        uint256 _value
    ) public returns (uint256) {
        require(_msgSender() == owner() || _msgSender() == privateIssuer, "Issuer::approveCertificationRequest: caller is not the owner or private issuer contract");
        require(_requestNotApprovedOrRevoked(_requestId), "Issuer::approveCertificationRequest: request already approved or revoked");

        CertificationRequest storage request = _certificationRequests[_requestId];
        request.approved = true;

        uint256 certificateId = registry.issue(
            request.owner,
            abi.encodeWithSignature("isRequestValid(uint256)",_requestId),
            certificateTopic,
            _value,
            request.data
        );

        requestToCertificate[_requestId] = certificateId;

        emit CertificationRequestApproved(request.owner, _requestId, certificateId);

        return certificateId;
    }

    function approveCertificationRequestBatch(
        uint256[] memory _requestIds,
        uint256[] memory _values
    ) public returns (uint256[] memory) {
        require(_msgSender() == owner() || _msgSender() == privateIssuer, "Issuer::approveCertificationRequestBatch: caller is not the owner or private issuer contract");

		for (uint256 i = 0; i < _requestIds.length; i++) {
            require(_requestNotApprovedOrRevoked(_requestIds[i]), "Issuer::approveCertificationRequestBatch: request already approved or revoked");
		}

        address[] memory owners = new address[](_requestIds.length);
        bytes[] memory data = new bytes[](_requestIds.length);
        bytes[] memory validityData = new bytes[](_requestIds.length);

        for (uint256 i = 0; i < _requestIds.length; i++) {
            CertificationRequest storage request = _certificationRequests[_requestIds[i]];
            request.approved = true;

            owners[i] = request.owner;
            data[i] = request.data;
            validityData[i] = abi.encodeWithSignature("isRequestValid(uint256)",_requestIds[i]);
        }

        uint256[] memory certificateIds = registry.batchIssueMultiple(
            owners,
            data,
            certificateTopic,
            _values,
            validityData
        );

        for (uint256 i = 0; i < _requestIds.length; i++) {
            requestToCertificate[_requestIds[i]] = certificateIds[i];
        }

        emit CertificationRequestBatchApproved(owners, _requestIds, certificateIds);

        return certificateIds;
    }

    /// @notice Directly issue a certificate without going through the request/approve procedure manually.
    function issue(address _to, uint256 _value, bytes memory _data) public onlyOwner returns (uint256) {
        uint256 requestId = requestCertificationFor(_data, _to);

        return approveCertificationRequest(
            requestId,
            _value
        );
    }

    /// @notice Directly issue a batch of certificates without going through the request/approve procedure manually.
    function issueBatch(address[] memory _to, uint256[] memory _values, bytes[] memory _data) public onlyOwner returns (uint256[] memory) {
        uint256[] memory requestIds = requestCertificationForBatch(_data, _to);

        return approveCertificationRequestBatch(
            requestIds,
            _values
        );
    }

    /// @notice Validation for certification requests.
    /// @dev Used by other contracts to validate the token.
    /// @dev `_requestId` has to be an existing ID.
    function isRequestValid(uint256 _requestId) external view returns (bool) {
        require(_requestId <= _latestCertificationRequestId, "Issuer::isRequestValid: certification request ID out of bounds");

        CertificationRequest memory request = _certificationRequests[_requestId];
        uint256 certificateId = requestToCertificate[_requestId];

        return request.approved
            && !request.revoked
            && !_revokedCertificates[certificateId];
    }

    function getRegistryAddress() external view returns (address) {
        return address(registry);
    }

    function getPrivateIssuerAddress() external view returns (address) {
        return privateIssuer;
    }

    function version() external pure returns (string memory) {
        return "v0.1";
    }
    
    function _requestNotApprovedOrRevoked(uint256 _requestId) internal view returns (bool) {
        CertificationRequest memory request = _certificationRequests[_requestId];

        return !request.approved && !request.revoked;
    }
    
    /// @notice Needed for OpenZeppelin contract upgradeability.
    /// @dev Allow only to the owner of the contract.
	function _authorizeUpgrade(address) internal override onlyOwner {}
}

/// @title Implementation of the Transferable Certificate standard ERC-1888.
/// @dev Also complies to ERC-1155: https://eips.ethereum.org/EIPS/eip-1155.
contract Registry is ERC1155, ERC1888 {

	// Storage for the Certificate structs
	mapping(uint256 => Certificate) public certificateStorage;

	// Mapping from token ID to account balances
	mapping(uint256 => mapping(address => uint256)) public claimedBalances;

	// Incrementing nonce, used for generating certificate IDs
    uint256 private _latestCertificateId;

	constructor(string memory _uri) public ERC1155(_uri) {}

	/// @notice See {IERC1888-issue}.
    /// @dev `_to` cannot be the zero address.
	function issue(address _to, bytes calldata _validityData, uint256 _topic, uint256 _value, bytes calldata _issuanceData) external override returns (uint256) {
		require(_to != address(0x0), "Registry::issue: to must be non-zero.");
		
		_validate(_msgSender(), _validityData);

		uint256 id = ++_latestCertificateId;
		ERC1155._mint(_to, id, _value, _issuanceData);

		certificateStorage[id] = Certificate({
			topic: _topic,
			issuer: _msgSender(),
			validityData: _validityData,
			data: _issuanceData
		});

		emit IssuanceSingle(_msgSender(), _topic, id, _value);

		return id;
	}

	/// @notice See {IERC1888-batchIssue}.
    /// @dev `_to` cannot be the zero address.
    /// @dev `_issuanceData`, `_values` and `_validityCalls` must have the same length.
	function batchIssue(address _to, bytes memory _issuanceData, uint256 _topic, uint256[] memory _values, bytes[] memory _validityCalls) external override returns (uint256[] memory) {
		require(_to != address(0x0), "Registry::issue: to must be non-zero.");
		require(_issuanceData.length == _values.length, "Registry::batchIssueMultiple: _issuanceData and _values arrays have to be the same length");
		require(_values.length == _validityCalls.length, "Registry::batchIssueMultiple: _values and _validityCalls arrays have to be the same length");

		uint256[] memory ids = new uint256[](_values.length);

		address operator = _msgSender();

		for (uint256 i = 0; i <= _values.length; i++) {
			ids[i] = i + _latestCertificateId + 1;
			_validate(operator, _validityCalls[i]);
		}
			
		ERC1155._mintBatch(_to, ids, _values, _issuanceData);

		for (uint256 i = 0; i < ids.length; i++) {
			certificateStorage[ids[i]] = Certificate({
				topic: _topic,
				issuer: operator,
				validityData: _validityCalls[i],
				data: _issuanceData
			});
		}

		emit IssuanceBatch(operator, _topic, ids, _values);

		return ids;
	}

	/// @notice Similar to {IERC1888-batchIssue}, but not a part of the ERC-1888 standard.
    /// @dev Allows batch issuing to an array of _to addresses.
    /// @dev `_to` cannot be the zero addresses.
    /// @dev `_to`, `_issuanceData`, `_values` and `_validityCalls` must have the same length.
	function batchIssueMultiple(address[] memory _to, bytes[] memory _issuanceData, uint256 _topic, uint256[] memory _values, bytes[] memory _validityCalls) external returns (uint256[] memory) {
		require(_to.length == _issuanceData.length, "Registry::batchIssueMultiple: _to and _issuanceData arrays have to be the same length");
		require(_issuanceData.length == _values.length, "Registry::batchIssueMultiple: _issuanceData and _values arrays have to be the same length");
		require(_values.length == _validityCalls.length, "Registry::batchIssueMultiple: _values and _validityCalls arrays have to be the same length");

		uint256[] memory ids = new uint256[](_values.length);

		address operator = _msgSender();

		for (uint256 i = 0; i < _values.length; i++) {
			ids[i] = i + _latestCertificateId + 1;
			_validate(operator, _validityCalls[i]);
		}
			
		for (uint256 i = 0; i < ids.length; i++) {
			require(_to[i] != address(0x0), "Registry::issue: to must be non-zero.");
			ERC1155._mint(_to[i], ids[i], _values[i], _issuanceData[i]);

			certificateStorage[ids[i]] = Certificate({
				topic: _topic,
				issuer: operator,
				validityData: _validityCalls[i],
				data: _issuanceData[i]
			});
		}

		_latestCertificateId = ids[ids.length - 1];

		emit IssuanceBatch(operator, _topic, ids, _values);

		return ids;
	}

	/// @notice Allows the issuer to mint more fungible tokens for existing ERC-188 certificates.
    /// @dev Allows batch issuing to an array of _to addresses.
    /// @dev `_to` cannot be the zero address.
	function mint(uint256 _id, address _to, uint256 _quantity) external {
		require(_to != address(0x0), "Registry::issue: to must be non-zero.");
		require(_quantity > 0, "Registry::mint: _quantity must be higher than 0.");

		Certificate memory cert = certificateStorage[_id];
		require(_msgSender() == cert.issuer, "Registry::mint: only the original certificate issuer can mint more tokens");

		ERC1155._mint(_to, _id, _quantity, new bytes(0));
	}

	/// @notice See {IERC1888-safeTransferAndClaimFrom}.
    /// @dev `_to` cannot be the zero address.
    /// @dev `_from` has to have a balance above or equal `_value`.
	function safeTransferAndClaimFrom(
		address _from,
		address _to,
		uint256 _id,
		uint256 _value,
		bytes calldata _data,
		bytes calldata _claimData
	) external override {
		Certificate memory cert = certificateStorage[_id];

		_validate(cert.issuer,  cert.validityData);

        require(_to != address(0x0), "Registry::safeTransferAndClaimFrom: _to must be non-zero.");
		require(_from != address(0x0), "Registry::safeBatchTransferAndClaimFrom: _from address must be non-zero.");

        require(_from == _msgSender() || ERC1155.isApprovedForAll(_from, _msgSender()), "safeTransferAndClaimFrom: Need operator approval for 3rd party claims.");
        require(ERC1155.balanceOf(_from, _id) >= _value, "Registry::safeTransferAndClaimFrom: _from balance has to be higher or equal _value");

		if (_from != _to) {
			safeTransferFrom(_from, _to, _id, _value, _data);
		}

		_burn(_to, _id, _value);

		emit ClaimSingle(_from, _to, cert.topic, _id, _value, _claimData); //_claimSubject address ??
	}

	/// @notice See {IERC1888-safeBatchTransferAndClaimFrom}.
    /// @dev `_to` and `_from` cannot be the zero addresses.
    /// @dev `_from` has to have a balance above 0.
	function safeBatchTransferAndClaimFrom(
		address _from,
		address _to,
		uint256[] calldata _ids,
		uint256[] calldata _values,
		bytes calldata _data,
		bytes[] calldata _claimData
	) external override {
		uint256 numberOfClaims = _ids.length;

        require(_to != address(0x0), "Registry::safeBatchTransferAndClaimFrom: _to address must be non-zero.");
		require(_from != address(0x0), "Registry::safeBatchTransferAndClaimFrom: _from address must be non-zero.");

        require(_ids.length == _values.length, "Registry::safeBatchTransferAndClaimFrom: _ids and _values array length must match.");
        require(_from == _msgSender() || ERC1155.isApprovedForAll(_from, _msgSender()), "Registry::safeBatchTransferAndClaimFrom: Need operator approval for 3rd party transfers.");

		require(numberOfClaims > 0, "Registry::safeBatchTransferAndClaimFrom: at least one certificate has to be present.");
		require(
			_values.length == numberOfClaims && _claimData.length == numberOfClaims,
			"Registry::safeBatchTransferAndClaimFrom: not all arrays are of the same length."
		);

		uint256[] memory topics = new uint256[](numberOfClaims);

		for (uint256 i = 0; i < numberOfClaims; i++) {
			Certificate memory cert = certificateStorage[_ids[i]];
			_validate(cert.issuer,  cert.validityData);
			topics[i] = cert.topic;
		}

		if (_from != _to) {
			safeBatchTransferFrom(_from, _to, _ids, _values, _data);
		}

		for (uint256 i = 0; i < numberOfClaims; i++) {
			_burn(_to, _ids[i], _values[i]);
		}

		emit ClaimBatch(_from, _to, topics, _ids, _values, _claimData);
	}

	/// @notice See {IERC1888-getCertificate}.
	function getCertificate(uint256 _id) public view override returns (address issuer, uint256 topic, bytes memory validityCall, bytes memory data) {
		require(_id <= _latestCertificateId, "Registry::getCertificate: _id out of bounds");

		Certificate memory certificate = certificateStorage[_id];
		return (certificate.issuer, certificate.topic, certificate.validityData, certificate.data);
	}

	/// @notice See {IERC1888-claimedBalanceOf}.
	function claimedBalanceOf(address _owner, uint256 _id) external override view returns (uint256) {
		return claimedBalances[_id][_owner];
	}

	/// @notice See {IERC1888-claimedBalanceOfBatch}.
	function claimedBalanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external override view returns (uint256[] memory) {
        require(_owners.length == _ids.length, "Registry::ERC1155: _owners and ids length mismatch");

        uint256[] memory batchClaimBalances = new uint256[](_owners.length);

        for (uint256 i = 0; i < _owners.length; i++) {
            batchClaimBalances[i] = this.claimedBalanceOf(_owners[i], _ids[i]);
        }

        return batchClaimBalances;
	}

	/// @notice Burn certificates after they've been claimed, and increase the claimed balance.
	function _burn(address _from, uint256 _id, uint256 _value) internal override {
		ERC1155._burn(_from, _id, _value);

		claimedBalances[_id][_from] = claimedBalances[_id][_from] + _value;
	}

	/// @notice Validate if the certificate is valid against an external `_verifier` contract.
	function _validate(address _verifier, bytes memory _validityData) internal view {
		(bool success, bytes memory result) = _verifier.staticcall(_validityData);

		require(
			success && abi.decode(result, (bool)),
			"Registry::_validate: Request/certificate invalid, please check with your issuer."
		);
	}
}