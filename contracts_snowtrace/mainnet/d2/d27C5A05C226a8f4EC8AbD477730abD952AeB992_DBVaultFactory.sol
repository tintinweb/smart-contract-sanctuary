// SPDX-License-Identifier: AGPL-3.0-or-later
// DegenBlue Contracts v0.0.1 (contracts/DBVaultFactory.sol)

pragma solidity ^0.8.0;

import "BeaconProxy.sol";
import "UpgradeableBeacon.sol";
import "Ownable.sol";
import "DBPersonalVault.sol";
import "IBondingHQ.sol";

/**
 *  @title DBVaultFactory
 *  @author pbnather
 *  @dev This contract is a factory for Degen Blue Personal Vaults.
 *  It also stores bond depositories information and can update vaults'
 *  underlying implementation to the new vault contract.
 *
 *  @notice Owner should be set to a timelocked contract, controlled by the multisig.
 *  Otherwise owner is able to steal users' funds by changing vault implementation or
 *  adding a fake bond depository.
 */
contract DBVaultFactory is UpgradeableBeacon {
    /* ======== STATE VARIABLES ======== */
    address public immutable asset;
    address public immutable stakedAsset;
    address public immutable wrappedAsset;
    address public immutable stakingContract;
    address public manager;
    address public feeHarvester;
    address[] public users;
    address[] public depositories;
    mapping(address => address) public userVaults;
    mapping(address => Depository) public depositoryInfo;
    uint256 public fee;
    uint256 public vaultLimit;

    /* ======== STRUCTS ======== */

    struct Depository {
        address principle; // Principle token used for bonding
        address router; // AMM Router to use
        address tokenA; // If LP, token A
        address tokenB; // If LP, token B
        address[] path; // best trade path
        bool isLpToken; // If token is LP
        bool usingWrapped; // If using wrapped token
        bool active; // If depository is active
    }

    /* ======== EVENTS ======== */

    event DepositoryAdded(address indexed depository, Depository info);
    event DepositoryRemoved(address indexed depository);
    event DepositoryDisabled(address indexed depository);
    event DepositoryEnabled(address indexed depository);
    event DepositoryPathUpdated(address indexed depository, address[] path);
    event FeeChanged(uint256 indexed old, uint256 indexed manager);
    event FeeHarvesterChanged(address indexed old, address indexed harvester);
    event ManagerChanged(address indexed old, address indexed manager);
    event VaultCreated(address indexed user, address indexed vault);
    event VaultLimitChanged(uint256 old, uint256 limit);

    /* ======== INITIALIZATION ======== */

    constructor(
        address _implementation,
        address _manager,
        address _asset,
        address _stakedAsset,
        address _wrappedAsset,
        address _stakingContract,
        address _feeHarvester,
        uint256 _fee,
        uint256 _vaultLimit
    ) UpgradeableBeacon(_implementation) {
        require(_manager != address(0));
        manager = _manager;
        require(_asset != address(0));
        asset = _asset;
        require(_stakedAsset != address(0));
        stakedAsset = _stakedAsset;
        require(_wrappedAsset != address(0));
        wrappedAsset = _wrappedAsset;
        require(_stakingContract != address(0));
        stakingContract = _stakingContract;
        require(_feeHarvester != address(0));
        feeHarvester = _feeHarvester;
        require(_fee <= 100, "Fee cannot be greater than 1%");
        fee = _fee;
        vaultLimit = _vaultLimit;
    }

    /* ======== ADMIN FUNCTIONS ======== */

    function addDepository(
        address _depository,
        address _principle,
        address _router,
        address _tokenA,
        address _tokenB,
        address[] memory _path,
        bool _isLPToken,
        bool _usingWrapped,
        bool _active
    ) external onlyOwner {
        require(_depository != address(0));
        require(_principle != address(0));
        require(_router != address(0));
        require(_tokenA != address(0));
        require(_tokenB != address(0));
        require(depositoryInfo[_depository].principle == address(0));
        depositoryInfo[_depository] = Depository({
            principle: _principle,
            router: _router,
            tokenA: _tokenA,
            tokenB: _tokenB,
            path: _path,
            isLpToken: _isLPToken,
            usingWrapped: _usingWrapped,
            active: _active
        });
        depositories.push(_depository);
        emit DepositoryAdded(_depository, depositoryInfo[_depository]);
    }

    function RemoveDepository(address _depository) external onlyOwner {
        require(
            depositoryInfo[_depository].principle != address(0) &&
                !depositoryInfo[_depository].active
        );
        depositoryInfo[_depository].principle = address(0);
        for (uint256 i = 0; i < depositories.length; i++) {
            if (depositories[i] == _depository) {
                depositories[i] = depositories[depositories.length - 1];
                depositories.pop();
                break;
            }
        }
        emit DepositoryRemoved(_depository);
    }

    function EnableDepository(address _depository) external onlyOwner {
        require(
            depositoryInfo[_depository].principle != address(0) &&
                !depositoryInfo[_depository].active
        );
        depositoryInfo[_depository].active = true;
        emit DepositoryEnabled(_depository);
    }

    function DisableDepository(address _depository) external onlyOwner {
        require(
            depositoryInfo[_depository].principle != address(0) &&
                depositoryInfo[_depository].active
        );
        depositoryInfo[_depository].active = false;
        emit DepositoryDisabled(_depository);
    }

    function UpdateDepositoryPath(address _depository, address[] memory _path)
        external
        onlyOwner
    {
        require(depositoryInfo[_depository].principle != address(0));
        depositoryInfo[_depository].path = _path;
        emit DepositoryPathUpdated(_depository, _path);
    }

    function setVaultLimit(uint256 _limit) external onlyOwner {
        uint256 old = vaultLimit;
        vaultLimit = _limit;
        emit VaultLimitChanged(old, _limit);
    }

    /**
     *  @notice Changing fees only affects new vaults.
     *  All exisitng vaults retain their fee.
     */
    function setFee(uint256 _fee) external onlyOwner {
        require(_fee < 10000, "Fee should be less than 100%");
        uint256 old = fee;
        fee = _fee;
        emit FeeChanged(old, _fee);
    }

    function changeManager(address _manager) external onlyOwner {
        require(_manager != address(0));
        address old = manager;
        manager = _manager;
        emit ManagerChanged(old, _manager);
    }

    function changeFeeHarvester(address _feeHarvester) external onlyOwner {
        require(_feeHarvester != address(0));
        address old = feeHarvester;
        manager = _feeHarvester;
        emit FeeHarvesterChanged(old, _feeHarvester);
    }

    function batchChangeManager(address[] memory _users) external onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            require(userVaults[_users[i]] != address(0));
            DBPersonalVault(userVaults[_users[i]]).changeManager(manager);
        }
    }

    function batchChangeFeeHarvester(address[] memory _users)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _users.length; i++) {
            require(userVaults[_users[i]] != address(0));
            DBPersonalVault(userVaults[_users[i]]).changeFeeHarvester(
                feeHarvester
            );
        }
    }

    /* ======== USER FUNCTIONS ======== */

    function createVault(uint256 _minimumBondDiscount, bool _isManaged)
        external
        returns (address)
    {
        require(userVaults[msg.sender] == address(0));
        BeaconProxy vault = new BeaconProxy(
            address(this),
            abi.encodeWithSelector(
                DBPersonalVault(address(0)).init.selector,
                address(this),
                asset,
                stakedAsset,
                wrappedAsset,
                stakingContract,
                manager,
                address(this),
                feeHarvester,
                msg.sender,
                fee,
                _minimumBondDiscount,
                _isManaged
            )
        );
        users.push(msg.sender);
        userVaults[msg.sender] = address(vault);
        emit VaultCreated(msg.sender, address(vault));
        return address(vault);
    }

    /* ======== MANAGER FUNCTIONS ======== */

    function batchRedeemVaultBonds(address[] memory _users) external {
        for (uint256 i = 0; i < _users.length; i++) {
            require(userVaults[_users[i]] != address(0));
            DBPersonalVault(userVaults[_users[i]]).redeemAllBonds();
        }
    }

    /* ======== VIEW FUNCTIONS ======== */

    function getVaults(bool _onlyManaged)
        external
        view
        returns (address[] memory _users, address[] memory _vaults)
    {
        uint256 index = 0;
        for (uint256 i = 0; i < users.length; i++) {
            if (
                _onlyManaged &&
                !(DBPersonalVault(userVaults[users[i]]).isManaged())
            ) {
                continue;
            }
            _vaults[index] = userVaults[users[i]];
            _users[index] = users[i];
            index += 1;
        }
    }

    function getDepositories(bool _onlyActive)
        external
        view
        returns (address[] memory _depositories)
    {
        uint256 index = 0;
        for (uint256 i = 0; i < depositories.length; i++) {
            if (_onlyActive && !depositoryInfo[depositories[i]].active) {
                continue;
            }
            _depositories[index] = depositories[i];
            index += 1;
        }
    }

    function getAllBondedFunds() external view returns (uint256 _funds) {
        _funds = 0;
        for (uint256 i = 0; i < users.length; i++) {
            _funds += DBPersonalVault(userVaults[users[i]]).getBondedFunds();
        }
    }

    function getAllManagedFunds() external view returns (uint256 _funds) {
        _funds = 0;
        for (uint256 i = 0; i < users.length; i++) {
            _funds += DBPersonalVault(userVaults[users[i]]).getAllManagedFunds();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/beacon/BeaconProxy.sol)

pragma solidity ^0.8.0;

import "IBeacon.sol";
import "Proxy.sol";
import "ERC1967Upgrade.sol";

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from a {UpgradeableBeacon}.
 *
 * The beacon address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
 * conflict with the storage layout of the implementation behind the proxy.
 *
 * _Available since v3.4._
 */
contract BeaconProxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializating the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     */
    constructor(address beacon, bytes memory data) payable {
        assert(_BEACON_SLOT == bytes32(uint256(keccak256("eip1967.proxy.beacon")) - 1));
        _upgradeBeaconToAndCall(beacon, data, false);
    }

    /**
     * @dev Returns the current beacon address.
     */
    function _beacon() internal view virtual returns (address) {
        return _getBeacon();
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation() internal view virtual override returns (address) {
        return IBeacon(_getBeacon()).implementation();
    }

    /**
     * @dev Changes the proxy to use a new beacon. Deprecated: see {_upgradeBeaconToAndCall}.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon.
     *
     * Requirements:
     *
     * - `beacon` must be a contract.
     * - The implementation returned by `beacon` must be a contract.
     */
    function _setBeacon(address beacon, bytes memory data) internal virtual {
        _upgradeBeaconToAndCall(beacon, data, false);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "IBeacon.sol";
import "Address.sol";
import "StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
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
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
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
            Address.functionDelegateCall(newImplementation, data);
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
            Address.functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlot.BooleanSlot storage rollbackTesting = StorageSlot.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            Address.functionDelegateCall(
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
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
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
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
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
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/StorageSlot.sol)

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
library StorageSlot {
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
// OpenZeppelin Contracts v4.4.0 (proxy/beacon/UpgradeableBeacon.sol)

pragma solidity ^0.8.0;

import "IBeacon.sol";
import "Ownable.sol";
import "Address.sol";

/**
 * @dev This contract is used in conjunction with one or more instances of {BeaconProxy} to determine their
 * implementation contract, which is where they will delegate all function calls.
 *
 * An owner is able to change the implementation the beacon points to, thus upgrading the proxies that use this beacon.
 */
contract UpgradeableBeacon is IBeacon, Ownable {
    address private _implementation;

    /**
     * @dev Emitted when the implementation returned by the beacon is changed.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Sets the address of the initial implementation, and the deployer account as the owner who can upgrade the
     * beacon.
     */
    constructor(address implementation_) {
        _setImplementation(implementation_);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function implementation() public view virtual override returns (address) {
        return _implementation;
    }

    /**
     * @dev Upgrades the beacon to a new implementation.
     *
     * Emits an {Upgraded} event.
     *
     * Requirements:
     *
     * - msg.sender must be the owner of the contract.
     * - `newImplementation` must be a contract.
     */
    function upgradeTo(address newImplementation) public virtual onlyOwner {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Sets the implementation contract address for this beacon
     *
     * Requirements:
     *
     * - `newImplementation` must be a contract.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableBeacon: implementation is not a contract");
        _implementation = newImplementation;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: AGPL-3.0-or-later
// DegenBlue Contracts v0.0.1 (contracts/DBPersonalVault.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "SafeERC20.sol";
import "Initializable.sol";
import "Ownable.sol";
import "ITimeBondDepository.sol";
import "IJoeRouter01.sol";
import "IBondingHQ.sol";
import "IPersonalVault.sol";
import "IwMEMO.sol";

/**
 *  @title DBPersonalVault
 *  @author pbnather
 *  @dev This contract is an implemention for the proxy persoanl vaults for 'hyperbinding' in ohm-forks.
 *
 *  User, aka `depositor`, despostis TIME or MEMO to the contract, which can be managed by `manager` address.
 *  If estimated bond 5-day ROI is better than staking 5-day ROI, manager can create a bond.
 *  Estimated 5-day ROI assumes that claimable bond rewards are redeemed close to, but before, each TIME rebase.
 *
 *  Contract has price checks, so that the bond which yields worse estimated 5-day ROI than just staking MEMO
 *  will be reverted (it accounts for the fees and slippage taken).
 *
 *  Manager has only access to functions allowing creating a bond, reedeming a bond, and staking TIME for MEMO.
 *  User has only access to functions allowing depositing, withdrawing, and redeeming a bond.
 *  Contract takes information about bonds depositories from BondingHQ contract
 *
 *  If contract is in MANUAL mode, then only user can make bonds, otherwise, in MANAGED mode, only `manager` can
 *  make bonds. User can also set `minimumBondingDiscount` to only take bonds e.g. above 7% (~11.7% hyperbonding).
 *
 *  Fees are sent to `feeHarvester` on each bond redeem. Admin can change the `feeHarvester` and `manager` addresses.
 *
 *  NOTE: This contract needs to be deployed individually for each user, with `depositor` set for her address.
 */
contract DBPersonalVault is Initializable, Ownable, IPersonalVault {
    using SafeERC20 for IERC20;

    /* ======== STATE VARIABLES ======== */

    IERC20 public asset; // e.g. TIME
    IERC20 public stakedAsset; // e.g. MEMO
    IwMEMO public wrappedAsset; // e.g. wMEMO
    IStaking public stakingContract; // Staking contract
    IBondingHQ public bondingHQ; // Bonding HQ

    address public manager; // Address which can manage bonds
    address public admin; // Address to send fees
    address public feeHarvester;
    uint256 public fee; // Fee taken from each redeem
    uint256 public minimumBondDiscount; // 1% = 100
    bool public isManaged; // If vault is in managed mode

    mapping(address => BondInfo) public bonds;
    address[] public activeBonds;

    /* ======== STRUCTS ======== */

    struct BondInfo {
        uint256 payout; // Time remaining to be paid
        uint256 assetUsed; // Asset amount used
        uint256 vestingEndTime; // Timestamp of bond end
        uint256 maturing; // How much MEMO is maturing
    }

    /* ======== EVENTS ======== */

    event BondCreated(
        uint256 indexed amount,
        address indexed bondedWith,
        uint256 indexed payout
    );
    event BondingDiscountChanged(
        uint256 indexed oldDiscount,
        uint256 indexed newDiscount
    );
    event BondRedeemed(address indexed bondedWith, uint256 indexed payout);
    event AssetsStaked(uint256 indexed amount);
    event AssetsUnstaked(uint256 indexed amount);
    event Withdrawal(uint256 indexed amount);
    event Deposit(uint256 indexed amount);
    event ManagedChanged(bool indexed managed);
    event ManagerChanged(
        address indexed oldManager,
        address indexed newManager
    );
    event FeeHarvesterChanged(
        address indexed oldManager,
        address indexed newManager
    );

    /* ======== INITIALIZATION ======== */

    function init(
        address _bondingHQ,
        address _asset,
        address _stakedAsset,
        address _wrappedAsset,
        address _stakingContract,
        address _manager,
        address _admin,
        address _feeHarvester,
        address _user,
        uint256 _fee,
        uint256 _minimumBondDiscount,
        bool _isManaged
    ) external initializer {
        require(_bondingHQ != address(0));
        bondingHQ = IBondingHQ(_bondingHQ);
        require(_asset != address(0));
        asset = IERC20(_asset);
        require(_stakedAsset != address(0));
        stakedAsset = IERC20(_stakedAsset);
        require(_wrappedAsset != address(0));
        wrappedAsset = IwMEMO(_wrappedAsset);
        require(_stakingContract != address(0));
        stakingContract = IStaking(_stakingContract);
        require(_admin != address(0));
        admin = _admin;
        require(_manager != address(0));
        manager = _manager;
        require(_feeHarvester != address(0));
        feeHarvester = _feeHarvester;
        require(_fee < 10000, "Fee should be less than 100%");
        fee = _fee;
        minimumBondDiscount = _minimumBondDiscount;
        isManaged = _isManaged;
        _transferOwnership(_user);
    }

    /* ======== MODIFIERS ======== */

    modifier managed() {
        if (isManaged) {
            require(
                msg.sender == manager,
                "Only manager can call managed vaults"
            );
        } else {
            require(
                msg.sender == owner(),
                "Only depositor can call manual vaults"
            );
        }
        _;
    }

    /* ======== ADMIN FUNCTIONS ======== */

    function changeManager(address _address) external {
        require(msg.sender == admin);
        require(_address != address(0));
        address old = manager;
        manager = _address;
        emit ManagerChanged(old, _address);
    }

    function changeFeeHarvester(address _address) external {
        require(msg.sender == admin);
        require(_address != address(0));
        address old = feeHarvester;
        feeHarvester = _address;
        emit FeeHarvesterChanged(old, _address);
    }

    /* ======== MANAGER FUNCTIONS ======== */

    function bond(
        address _depository,
        uint256 _amount,
        uint256 _slippage
    ) external override managed returns (uint256) {
        (
            address principle,
            address router,
            address tokenA,
            address tokenB,
            address[] memory path,
            bool isLpToken,
            bool usingWrapped,
            bool active
        ) = bondingHQ.depositoryInfo(_depository);
        require(
            principle != address(0) && active,
            "Depository doesn't exist or is inactive"
        );
        if (isLpToken) {
            return
                _bondWithAssetTokenLp(
                    IERC20(tokenA),
                    IERC20(principle),
                    ITimeBondDepository(_depository),
                    IJoeRouter01(router),
                    _amount,
                    _slippage,
                    usingWrapped,
                    path
                );
        } else {
            return
                _bondWithToken(
                    IERC20(principle),
                    ITimeBondDepository(_depository),
                    IJoeRouter01(router),
                    _amount,
                    _slippage,
                    usingWrapped,
                    path
                );
        }
    }

    function stakeAssets(uint256 _amount) public override managed {
        require(asset.balanceOf(address(this)) >= _amount, "Not enough tokens");
        asset.approve(address(stakingContract), _amount);
        stakingContract.stake(_amount, address(this));
        stakingContract.claim(address(this));
        emit AssetsStaked(_amount);
    }

    /* ======== USER FUNCTIONS ======== */

    function setManaged(bool _managed) external override onlyOwner {
        require(isManaged != _managed, "Cannot set mode to current mode");
        isManaged = _managed;
        emit ManagedChanged(_managed);
    }

    function setMinimumBondingDiscount(uint256 _discount)
        external
        override
        onlyOwner
    {
        require(
            minimumBondDiscount != _discount,
            "New discount value is the same as current one"
        );
        uint256 old = minimumBondDiscount;
        minimumBondDiscount = _discount;
        emit BondingDiscountChanged(old, _discount);
    }

    function withdraw(uint256 _amount) external override onlyOwner {
        require(
            stakedAsset.balanceOf(address(this)) >= _amount,
            "Not enough tokens"
        );
        stakedAsset.safeTransfer(owner(), _amount);
        emit Withdrawal(_amount);
    }

    /**
     *  @notice Anybody can top up the vault, but only depositor will be able to withdraw.
     *  For personal vaults it's the same as sending stakedAsset to the contract address.
     */
    function deposit(uint256 _amount) external override {
        require(
            stakedAsset.balanceOf(msg.sender) >= _amount,
            "Not enough tokens"
        );
        stakedAsset.safeTransferFrom(msg.sender, address(this), _amount);
        emit Deposit(_amount);
    }

    /**
     *  @notice This function is callable by anyone just in case manager is not working.
     */
    function redeem(address _depository) external override {
        (address principle, , , , , , , ) = bondingHQ.depositoryInfo(
            _depository
        );
        require(principle != address(0));
        _redeemBondFrom(ITimeBondDepository(_depository));
    }

    /**
     *  @notice This function is callable by anyone just in case manager is not working.
     */
    function redeemAllBonds() external override {
        for (uint256 i = 0; i < activeBonds.length; i++) {
            _redeemBondFrom(ITimeBondDepository(activeBonds[i]));
        }
    }

    /* ======== VIEW FUNCTIONS ======== */

    /**
     *  @dev this function checks if taken bond is profitable after fees.
     *  It estimates using precomputed magic number what's the minimum viable 5-day ROI
     *  (assmuing redeemeing before all the rebases), versus staking MEMO.
     *  It also checks if minimum bonding discount set by the user is reached.
     */
    function isBondProfitable(uint256 _bonded, uint256 _payout)
        public
        view
        returns (bool _profitable)
    {
        uint256 bondingROI = ((10000 * _payout) / _bonded) - 10000; // 1% = 100
        require(
            bondingROI >= minimumBondDiscount,
            "Bonding discount lower than threshold"
        );
        (, uint256 stakingReward, , ) = stakingContract.epoch();
        IMemories memories = IMemories(address(stakedAsset));
        uint256 circualtingSupply = memories.circulatingSupply();
        uint256 stakingROI = (100000 * stakingReward) / circualtingSupply;
        uint256 magicNumber = 2 * (60 + (stakingROI / 100));
        uint256 minimumBonding = (100 * stakingROI) / magicNumber;
        _profitable = bondingROI >= minimumBonding;
    }

    function getBondedFunds() public view override returns (uint256 _funds) {
        for (uint256 i = 0; i < activeBonds.length; i++) {
            _funds += bonds[activeBonds[i]].payout;
        }
    }

    function getAllManagedFunds()
        external
        view
        override
        returns (uint256 _funds)
    {
        _funds += getBondedFunds();
        _funds += stakedAsset.balanceOf(address(this));
        _funds += asset.balanceOf(address(this));
    }

    /* ======== INTERNAL FUNCTIONS ======== */

    function _bondWithToken(
        IERC20 _token,
        ITimeBondDepository _depository,
        IJoeRouter01 _router,
        uint256 _amount,
        uint256 _slippage,
        bool _usingWrapped,
        address[] memory _path
    ) internal returns (uint256) {
        uint256 amount;
        if (_usingWrapped) {
            stakedAsset.approve(address(wrappedAsset), _amount);
            amount = wrappedAsset.wrap(_amount);
        } else {
            _unstakeAssets(_amount);
            amount = _amount;
        }
        uint256 received = _sellAssetFor(
            _usingWrapped ? IERC20(address(wrappedAsset)) : asset,
            _token,
            _router,
            amount,
            _slippage,
            _path
        );
        uint256 payout = _bondWith(_token, received, _depository);
        require(
            isBondProfitable(_amount, payout),
            "Bonding rate worse than staking"
        );
        _addBondInfo(address(_depository), payout, _amount);
        emit BondCreated(_amount, address(_token), payout);
        return payout;
    }

    function _bondWithAssetTokenLp(
        IERC20 _token,
        IERC20 _lpToken,
        ITimeBondDepository _depository,
        IJoeRouter01 _router,
        uint256 _amount,
        uint256 _slippage,
        bool _usingWrapped,
        address[] memory _path
    ) internal returns (uint256) {
        uint256 amount;
        if (_usingWrapped) {
            stakedAsset.approve(address(wrappedAsset), _amount);
            amount = wrappedAsset.wrap(_amount);
        } else {
            _unstakeAssets(_amount);
            amount = _amount;
        }
        uint256 received = _sellAssetFor(
            _usingWrapped ? IERC20(address(wrappedAsset)) : asset,
            _token,
            _router,
            amount / 2,
            _slippage,
            _path
        );
        uint256 remaining = amount - (amount / 2);
        uint256 usedAsset = _addLiquidityFor(
            _token,
            _usingWrapped ? IERC20(address(wrappedAsset)) : asset,
            received,
            remaining,
            _router
        );

        // Stake not used assets
        if (usedAsset < remaining) {
            if (_usingWrapped) {
                usedAsset = wrappedAsset.unwrap(remaining - usedAsset);
            } else {
                stakeAssets(remaining - usedAsset);
                usedAsset = remaining - usedAsset;
            }
        }

        uint256 lpAmount = _lpToken.balanceOf(address(this));
        uint256 payout = _bondWith(_lpToken, lpAmount, _depository);
        require(
            isBondProfitable(amount - usedAsset, payout),
            "Bonding rate worse than staking"
        );
        _addBondInfo(address(_depository), payout, amount - usedAsset);
        emit BondCreated(amount - usedAsset, address(_lpToken), payout);
        return payout;
    }

    /**
     *  @dev This function swaps assets for sepcified token via TraderJoe.
     *  @notice Slippage cannot exceed 1.5%.
     */
    function _sellAssetFor(
        IERC20 _asset,
        IERC20 _token,
        IJoeRouter01 _router,
        uint256 _amount,
        uint256 _slippage,
        address[] memory _path
    ) internal returns (uint256) {
        require(_path[0] == address(_asset));
        require(_path[_path.length - 1] == address(_token));
        uint256[] memory amounts = _router.getAmountsOut(_amount, _path);
        uint256 minOutput = (amounts[amounts.length - 1] *
            (10000 - _slippage)) / 10000;
        _asset.approve(address(_router), _amount);
        uint256[] memory results = _router.swapExactTokensForTokens(
            _amount,
            minOutput,
            _path,
            address(this),
            block.timestamp + 60
        );
        return results[results.length - 1];
    }

    /**
     *  @dev This function adds liquidity for specified tokens on TraderJoe.
     *  @notice This function tries to maximize usage of first token {_tokenA}.
     */
    function _addLiquidityFor(
        IERC20 _tokenA,
        IERC20 _tokenB,
        uint256 _amountA,
        uint256 _amountB,
        IJoeRouter01 _router
    ) internal returns (uint256) {
        _tokenA.approve(address(_router), _amountA);
        _tokenB.approve(address(_router), _amountB);
        (, uint256 assetSent, ) = _router.addLiquidity(
            address(_tokenA),
            address(_tokenB),
            _amountA,
            _amountB,
            (_amountA * 995) / 1000,
            (_amountB * 995) / 1000,
            address(this),
            block.timestamp + 60
        );
        return assetSent;
    }

    /**
     * @dev This function adds liquidity for specified tokens on TraderJoe.
     */
    function _bondWith(
        IERC20 _token,
        uint256 _amount,
        ITimeBondDepository _depository
    ) internal returns (uint256 _payout) {
        require(
            _token.balanceOf(address(this)) >= _amount,
            "Not enough tokens"
        );
        _token.approve(address(_depository), _amount);
        uint256 maxBondPrice = _depository.bondPrice();
        _payout = _depository.deposit(_amount, maxBondPrice, address(this));
    }

    function _redeemBondFrom(ITimeBondDepository _depository)
        internal
        returns (uint256)
    {
        uint256 amount = _depository.redeem(address(this), true);
        uint256 feeValue = (amount * fee) / 10000;
        uint256 redeemed = amount - feeValue;
        bonds[address(_depository)].payout -= amount;
        if (block.timestamp >= bonds[address(_depository)].vestingEndTime) {
            _removeBondInfo(address(_depository));
        }
        stakedAsset.safeTransfer(feeHarvester, feeValue);
        emit BondRedeemed(address(_depository), redeemed);
        return redeemed;
    }

    function _unstakeAssets(uint256 _amount) internal {
        stakedAsset.approve(address(stakingContract), _amount);
        stakingContract.unstake(_amount, false);
        emit AssetsUnstaked(_amount);
    }

    function _addBondInfo(
        address _depository,
        uint256 _payout,
        uint256 _assetsUsed
    ) internal {
        if (bonds[address(_depository)].payout == 0) {
            activeBonds.push(address(_depository));
        }
        bonds[address(_depository)] = BondInfo({
            payout: bonds[address(_depository)].payout + _payout,
            assetUsed: bonds[address(_depository)].assetUsed + _assetsUsed,
            vestingEndTime: block.timestamp + 5 days,
            maturing: 0 // not used yet
        });
    }

    function _removeBondInfo(address _depository) internal {
        require(bonds[address(_depository)].vestingEndTime >= block.timestamp);
        bonds[address(_depository)].payout = 0;
        for (uint256 i = 0; i < activeBonds.length; i++) {
            if (activeBonds[i] == _depository) {
                activeBonds[i] = activeBonds[activeBonds.length - 1];
                activeBonds.pop();
                break;
            }
        }
    }

    /* ======== AUXILLIARY ======== */

    /**
     *  @notice allow anyone to send lost tokens (stakedAsset) to the vault owner
     *  @return bool
     */
    function recoverLostToken(IERC20 _token) external returns (bool) {
        require(_token != stakedAsset, "Use withdraw function");
        uint256 balance = _token.balanceOf(address(this));
        _token.safeTransfer(admin, balance);
        return true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Address.sol";

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "IERC20.sol";
import "SafeERC20.sol";

interface ITreasury {
    function deposit(
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external returns (bool);

    function valueOf(address _token, uint256 _amount)
        external
        view
        returns (uint256 value_);
}

interface IBondCalculator {
    function valuation(address _LP, uint256 _amount)
        external
        view
        returns (uint256);

    function markdown(address _LP) external view returns (uint256);
}

interface IMemories {
    function circulatingSupply() external view returns (uint256);
}

interface IStaking {
    function epoch()
        external
        view
        returns (
            uint256 number,
            uint256 distribute,
            uint32 length,
            uint32 endTime
        );

    function claim(address _recipient) external;

    function stake(uint256 _amount, address _recipient) external returns (bool);

    function unstake(uint256 _amount, bool _trigger) external;
}

interface IStakingHelper {
    function stake(uint256 _amount, address _recipient) external;
}

interface ITimeBondDepository {
    /* ======== STRUCTS ======== */

    // Info for creating new bonds
    struct Terms {
        uint256 controlVariable; // scaling variable for price
        uint256 minimumPrice; // vs principle value
        uint256 maxPayout; // in thousandths of a %. i.e. 500 = 0.5%
        uint256 fee; // as % of bond payout, in hundreths. ( 500 = 5% = 0.05 for every 1 paid)
        uint256 maxDebt; // 9 decimal debt ratio, max % total supply created as debt
        uint32 vestingTerm; // in seconds
    }

    // Info for bond holder
    struct Bond {
        uint256 payout; // Time remaining to be paid
        uint256 pricePaid; // In DAI, for front end viewing
        uint32 lastTime; // Last interaction
        uint32 vesting; // Seconds left to vest
    }

    // Info for incremental adjustments to control variable
    struct Adjust {
        bool add; // addition or subtraction
        uint256 rate; // increment
        uint256 target; // BCV when adjustment finished
        uint32 buffer; // minimum length (in seconds) between adjustments
        uint32 lastTime; // time when last adjustment made
    }

    /* ======== USER FUNCTIONS ======== */

    /**
     *  @notice deposit bond
     *  @param _amount uint
     *  @param _maxPrice uint
     *  @param _depositor address
     *  @return uint
     */
    function deposit(
        uint256 _amount,
        uint256 _maxPrice,
        address _depositor
    ) external returns (uint256);

    /**
     *  @notice redeem bond for user
     *  @param _recipient address
     *  @param _stake bool
     *  @return uint
     */
    function redeem(address _recipient, bool _stake) external returns (uint256);

    /* ======== VIEW FUNCTIONS ======== */

    /**
     *  @notice determine maximum bond size
     *  @return uint
     */
    function maxPayout() external view returns (uint256);

    /**
     *  @notice calculate interest due for new bond
     *  @param _value uint
     *  @return uint
     */
    function payoutFor(uint256 _value) external view returns (uint256);

    /**
     *  @notice calculate current bond premium
     *  @return price_ uint
     */
    function bondPrice() external view returns (uint256 price_);

    /**
     *  @notice converts bond price to DAI value
     *  @return price_ uint
     */
    function bondPriceInUSD() external view returns (uint256 price_);

    /**
     *  @notice calculate current ratio of debt to Time supply
     *  @return debtRatio_ uint
     */
    function debtRatio() external view returns (uint256 debtRatio_);

    /**
     *  @notice debt ratio in same terms for reserve or liquidity bonds
     *  @return uint
     */
    function standardizedDebtRatio() external view returns (uint256);

    /**
     *  @notice calculate debt factoring in decay
     *  @return uint
     */
    function currentDebt() external view returns (uint256);

    /**
     *  @notice amount to decay total debt by
     *  @return decay_ uint
     */
    function debtDecay() external view returns (uint256 decay_);

    /**
     *  @notice calculate how far into vesting a depositor is
     *  @param _depositor address
     *  @return percentVested_ uint
     */
    function percentVestedFor(address _depositor)
        external
        view
        returns (uint256 percentVested_);

    /**
     *  @notice calculate amount of Time available for claim by depositor
     *  @param _depositor address
     *  @return pendingPayout_ uint
     */
    function pendingPayoutFor(address _depositor)
        external
        view
        returns (uint256 pendingPayout_);

    /* ======= AUXILLIARY ======= */

    /**
     *  @notice allow anyone to send lost tokens (excluding principle or Time) to the DAO
     *  @return bool
     */
    function recoverLostToken(IERC20 _token) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

interface IJoeRouter01 {
    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountAVAX,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAXWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
// DegenBlue Contracts v0.0.1 (interfaces/IBondingHQ.sol)

/**
 *  @title IBondingHQ
 *  @author pbnather
 *
 *  This interface is meant to be used to interact with the vault contract
 *  by it's `manager`, wich manages bonding and redeeming operations.
 */
pragma solidity ^0.8.0;

interface IBondingHQ {
    function depositoryInfo(address _depository)
        external
        view
        returns (
            address principle,
            address router,
            address tokenA,
            address tokenB,
            address[] memory path,
            bool isLpToken,
            bool usingWrapped,
            bool active
        );
}

// SPDX-License-Identifier: AGPL-3.0-or-later
// DegenBlue Contracts v0.0.1 (interfaces/IPersonalVault.sol)

/**
 *  @title IPersonalVault
 *  @author pbnather
 *
 *  This interface is meant to be used to interact with the vault contract
 *  by it's `manager`, wich manages bonding and redeeming operations.
 */
pragma solidity ^0.8.0;

interface IPersonalVault {
    function bond(
        address _depository,
        uint256 _amount,
        uint256 _slippage
    ) external returns (uint256);

    function stakeAssets(uint256 _amount) external;

    function setManaged(bool _managed) external;

    function setMinimumBondingDiscount(uint256 _discount) external;

    function withdraw(uint256 _amount) external;

    function deposit(uint256 _amount) external;

    function redeem(address _depository) external;

    function redeemAllBonds() external;

    function getBondedFunds() external view returns (uint256 _funds);

    function getAllManagedFunds() external view returns (uint256 _funds);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
// DegenBlue Contracts v0.0.1 (interfaces/IwMEMO.sol)

/**
 *  @title IwMEMO
 *  @author pbnather
 *
 *  This interface is meant to be used to interact with the vault contract
 *  by it's `manager`, wich manages bonding and redeeming operations.
 */
pragma solidity ^0.8.0;

interface IwMEMO {
    function wrap(uint256 _amount) external returns (uint256);

    function unwrap(uint256 _amount) external returns (uint256);
}