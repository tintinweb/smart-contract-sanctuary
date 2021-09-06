/**
 *Submitted for verification at BscScan.com on 2021-09-05
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-05
*/

// File: @openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol



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

// File: @openzeppelin/contracts-upgradeable/proxy/beacon/IBeaconUpgradeable.sol



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

// File: @openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol



pragma solidity ^0.8.2;





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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol



pragma solidity ^0.8.0;



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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol




// File: PurseTokenMultiSigUpgradable.sol

pragma solidity ^0.8.0;



abstract contract ERC20Interface {

    function transfer(address to, uint tokens) public virtual returns (bool success);

}

contract PurseTokenMultiSigUpgradable is Initializable, UUPSUpgradeable {
    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint8 public decimals;
    uint8 public numConfirmationsRequired;
    uint256 private minimumSupply;
    address[] public owners;
    address public liqPool;
    address public redPool;
    uint256 public mintIndex;
    uint256 public burnPercent;
    uint256 public liqPercent;
    uint256 public redPercent;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Burn(address indexed _from, address indexed _to, uint256 _value);
    event Mint(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event SubmitMint(address indexed owner, uint256 indexed txIndex, address indexed to, uint256 value);
    event ConfirmMint(address indexed owner, uint256 indexed txIndex);
    event RevokeConfirmMint(address indexed owner, uint256 indexed txIndex);
    event ExecuteMint(address indexed owner, uint256 indexed txIndex);

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier mintExists(uint256 _mintIndex) {
        require(mintExist[_mintIndex], "mint does not exist");
        _;
    }

    modifier mintNotExecuted(uint256 _txIndex) {
        require(!mints[_txIndex].executed, "tx already executed");
        _;
    }

    modifier mintNotConfirmed(uint256 _txIndex) {
        require(!mintIsConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public isOwner;
    // mapping for Mint from mint index => owner => bool
    mapping(uint256 => mapping(address => bool)) public mintIsConfirmed;
    mapping(uint256 => bool) public mintExist;
    mapping(uint256 => MintInfo) public mints;
    mapping(address => bool) public isWhitelistedTo;
    mapping(address => bool) public isWhitelistedFrom;

    struct MintInfo {
        address to;
        uint256 value;
        bool executed;
        uint256 numConfirmations;
    }

    function addOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        require(!isOwner[newOwner]);

        isOwner[newOwner] = true;
        owners.push(newOwner);
    }

    function setWhitelistedTo(address newWhitelist) external onlyOwner {
        require(newWhitelist != address(0));
        require(!isWhitelistedTo[newWhitelist]);

        isWhitelistedTo[newWhitelist] = true;
    }

    function removeWhitelistedTo(address newWhitelist) external onlyOwner {
        require(newWhitelist != address(0));
        require(isWhitelistedTo[newWhitelist]);

        isWhitelistedTo[newWhitelist] = false;
    }

    function setWhitelistedFrom(address newWhitelist) external onlyOwner {
        require(newWhitelist != address(0));
        require(!isWhitelistedFrom[newWhitelist]);

        isWhitelistedFrom[newWhitelist] = true;
    }

    function removeWhitelistedFrom(address newWhitelist) external onlyOwner {
        require(newWhitelist != address(0));
        require(isWhitelistedFrom[newWhitelist]);

        isWhitelistedFrom[newWhitelist] = false;
    }

    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        require(_value >= 0);
        require(balanceOf[msg.sender] >= _value);
        if (isWhitelistedTo[_to] || isWhitelistedFrom[msg.sender]) {
            balanceOf[msg.sender] -= _value;
            balanceOf[_to] += _value;

            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {
            uint256 transferValue = _partialBurn(_value, msg.sender);
            balanceOf[msg.sender] -= transferValue;
            balanceOf[_to] += transferValue;

            emit Transfer(msg.sender, _to, transferValue);
            return true;
        }
    }

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(_value >= 0);
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        if (isWhitelistedTo[_to] || isWhitelistedFrom[msg.sender]) {
            allowance[_from][msg.sender] -= _value;
            balanceOf[_from] -= _value;
            balanceOf[_to] += _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else {
            allowance[_from][msg.sender] -= _value;
            uint256 transferValue = _partialBurn(_value, _from);
            balanceOf[_from] -= transferValue;
            balanceOf[_to] += transferValue;
            emit Transfer(_from, _to, transferValue);
            return true;
        }
    }

    function mint(address _account, uint256 _amount) internal onlyOwner {
        require(_account != address(0));

        balanceOf[_account] += _amount;
        totalSupply += _amount;
        emit Mint(address(0), _account, _amount);
    }

    function submitMint(address _to, uint256 _value) public onlyOwner {
        mints[mintIndex] = MintInfo(_to, _value, false, 0);
        mintExist[mintIndex] = true;
        emit SubmitMint(msg.sender, mintIndex, _to, _value);
        mintIndex += 1;
    }

    function confirmMint(uint256 _mintIndex)
        public
        onlyOwner
        mintExists(_mintIndex)
        mintNotExecuted(_mintIndex)
        mintNotConfirmed(_mintIndex)
    {
        mints[_mintIndex].numConfirmations += 1;
        mintIsConfirmed[_mintIndex][msg.sender] = true;

        emit ConfirmMint(msg.sender, _mintIndex);
    }

    function executeMint(uint256 _mintIndex)
        public
        onlyOwner
        mintExists(_mintIndex)
        mintNotExecuted(_mintIndex)
    {
        require(mints[_mintIndex].numConfirmations >= numConfirmationsRequired);
        mints[_mintIndex].executed = true;
        mint(mints[_mintIndex].to, mints[_mintIndex].value);

        emit ExecuteMint(msg.sender, _mintIndex);
    }

    function revokeMintConfirmation(uint256 _mintIndex)
        public
        onlyOwner
        mintExists(_mintIndex)
        mintNotExecuted(_mintIndex)
    {
        require(mintIsConfirmed[_mintIndex][msg.sender]);

        mints[_mintIndex].numConfirmations -= 1;
        mintIsConfirmed[_mintIndex][msg.sender] = false;

        emit RevokeConfirmMint(msg.sender, _mintIndex);
    }

    function burn(address _account, uint256 _amount) public onlyOwner {
        require(_account != address(0));
        uint256 accountBalance = balanceOf[_account];
        require(accountBalance >= _amount);
        balanceOf[_account] -= _amount;
        totalSupply -= _amount;
        emit Burn(_account, address(0), _amount);
    }

    function _partialBurn(uint256 _amount, address _from)
        internal
        returns (uint256)
    {
        uint256 transferAmount = 0;
        uint256 burnAmount;
        uint256 liqAmount;
        uint256 redAmount;
        (
            burnAmount,
            liqAmount,
            redAmount
        ) = _calculateDeductAmount(_amount);

        if (burnAmount >= 0 || liqAmount >= 0 || redAmount >= 0) {
            burnPrivate(_from, burnAmount, liqAmount, redAmount);
        }
        transferAmount = _amount - burnAmount - liqAmount - redAmount;

        return transferAmount;
    }

    function _calculateDeductAmount(uint256 _amount)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 burnAmount;
        uint256 liqAmount;
        uint256 redAmount;

        if (totalSupply > minimumSupply) {
            burnAmount = (_amount * burnPercent) / 100;
            liqAmount = (_amount * liqPercent) / 100;
            redAmount = (_amount * redPercent) / 100;
            uint256 availableBurn = totalSupply - minimumSupply;
            if (burnAmount > availableBurn) {
                burnAmount = availableBurn;
            }
        }
        return (burnAmount, liqAmount, redAmount);
    }

    function burnPrivate(
        address _account,
        uint256 _burnAmount,
        uint256 _liqAmount,
        uint256 _redAmount
    ) private {
        require(_account != address(0));
        uint256 accountBalance = balanceOf[_account];
        uint256 deductAmount = _burnAmount + _liqAmount + _redAmount;
        require(accountBalance >= deductAmount);
        balanceOf[_account] -= _burnAmount;
        balanceOf[_account] -= _liqAmount;
        balanceOf[_account] -= _redAmount;

        totalSupply -= _burnAmount;
        balanceOf[liqPool] += _liqAmount;
        balanceOf[redPool] += _redAmount;
        emit Burn(_account, address(0), _burnAmount);
        emit Transfer(msg.sender, liqPool, _liqAmount);
        emit Transfer(msg.sender, redPool, _redAmount);
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function updateLPoolAdd(address _newLPool) public onlyOwner {
        require(_newLPool != address(0));
        require(_newLPool != liqPool);

        liqPool = _newLPool;
    }

    function updateRPoolAdd(address _newRPool) public onlyOwner {
        require(_newRPool != address(0));
        require(_newRPool != redPool);

        redPool = _newRPool;
    }

    function updateBurnPercent(uint256 _newBurnPercent) public onlyOwner {
        require(_newBurnPercent >= 0 && _newBurnPercent <= 100);
        require(_newBurnPercent != burnPercent);

        burnPercent = _newBurnPercent;
    }

    function updateLiqPercent(uint256 _newLiqPercent) public onlyOwner {
        require(_newLiqPercent >= 0 && _newLiqPercent <= 100);
        require(_newLiqPercent != liqPercent);

        liqPercent = _newLiqPercent;
    }

    function updateRedPercent(uint256 _newRedPercent) public onlyOwner {
        require(_newRedPercent >= 0 && _newRedPercent <= 100);
        require(_newRedPercent != redPercent);

        redPercent = _newRedPercent;
    }
    
    function returnAnyToken(address token, uint256 amount, address _to) public onlyOwner{
        require(_to != address(0), "send to the zero address");
        ERC20Interface(token).transfer(_to, amount);
    } 

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function initialize(
        address _to,
        address[] memory _owners,
        uint8 _numConfirmationsRequired,
        address _lPool,
        address _rPool,
        uint256 _burnPercent,
        uint256 _liqPercent,
        uint256 _redPercent
    ) public initializer {
        name = "PURSE";
        symbol = "PR";
        totalSupply = 64000000000 * (10**18); // 64 billion tokens
        decimals = 18;
        minimumSupply = 20000 * (10**18);

        require(_owners.length > 0);
        require(_lPool != address(0));
        require(_rPool != address(0));
        require(_burnPercent >= 0);
        require(_liqPercent >= 0);
        require(_redPercent >= 0);
        require(_numConfirmationsRequired > 0 && _numConfirmationsRequired <= _owners.length);

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0));
            require(!isOwner[owner]);

            isOwner[owner] = true;
            owners.push(owner);
        }
        
        numConfirmationsRequired = _numConfirmationsRequired;
        liqPool = _lPool;
        redPool = _rPool;
        burnPercent = _burnPercent;
        liqPercent = _liqPercent;
        redPercent = _redPercent;

        balanceOf[_to] = totalSupply;
        emit Mint(address(0), _to, totalSupply);
    }
}