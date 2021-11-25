/**
 *Submitted for verification at BscScan.com on 2021-11-25
*/

// File: DefiPlayground/IStakingRewards.sol

pragma solidity >=0.5.0 <0.9.0;

// https://docs.synthetix.io/contracts/source/interfaces/istakingrewards
interface IStakingRewards {
    // Views

    function rewards(address account) external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function rewardsDistribution() external view returns (address);

    function stakingToken() external view returns (address);

    function rewardsToken() external view returns (address);

    function totalSupply() external view returns (uint256);

    // Mutative

    function exit() external;

    function getReward() external;

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;
}
// File: DefiPlayground/IPancakePair.sol

pragma solidity >=0.5.0 <0.9.0;

interface IPancakePair {
    function token0() external returns (address);
    function token1() external returns (address);
}
// File: DefiPlayground/IConverter.sol

pragma solidity >=0.5.0 <0.9.0;


interface IConverter {
    function convert(
        address _inTokenAddress,
        uint256 _amount,
        uint256 _convertPercentage,
        address _outTokenAddress,
        uint256 _minReceiveAmount,
        address _recipient
    ) external;
    function convertAndAddLiquidity(
        address _inTokenAddress,
        uint256 _amount,
        address _outTokenAddress,
        uint256 _minReceiveAmountSwap,
        uint256 _minInTokenAmountAddLiq,
        uint256 _minOutTokenAmountAddLiq,
        address _recipient
    ) external;
    function removeLiquidityAndConvert(
        IPancakePair _lp,
        uint256 _lpAmount,
        uint256 _minToken0Amount,
        uint256 _minToken1Amount,
        uint256 _token0Percentage,
        address _recipient
    ) external;
}
// File: DefiPlayground/cake/IMasterChef.sol

pragma solidity >=0.5.0 <0.9.0;

interface IMasterChef {
    // Views

    function getMultiplier(uint256 _from, uint256 _to) external view returns (uint256);

    function poolLength() external view returns (uint256);

    function pendingCake(uint256 _pid, address _user) external view returns (uint256);

    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);

    function poolInfo(uint256 _pid) external view returns (address, uint256, uint256, uint256);

    function cakePerBlock() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    // Mutative

    function updatePool(uint256 _pid) external;

    function add(uint256 _allocPoint, address _lpToken, bool _withUpdate) external;

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;
}
// File: DefiPlayground/upgrade/ReentrancyGuard.sol


pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the `nonReentrant` modifier
 * available, which can be aplied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    /// @dev Change constructor to initialize function for upgradeable contract
    function initializeReentrancyGuard() internal {
        require(_guardCounter == 0, "Already initialized");
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}
// File: DefiPlayground/upgrade/Owned.sol


pragma solidity ^0.8.0;

// Modified from https://docs.synthetix.io/contracts/source/contracts/owned
contract Owned {
    address public owner;
    address public nominatedOwner;

    /// @dev Change constructor to initialize function for upgradeable contract
    function initializeOwner(address _owner) internal {
        require(owner == address(0), "Already initialized");
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}
// File: DefiPlayground/upgrade/Pausable.sol


pragma solidity ^0.8.0;


// Modified from https://docs.synthetix.io/contracts/source/contracts/pausable
contract Pausable is Owned {
    uint public lastPauseTime;
    bool public paused;

    /// @dev Change constructor to initialize function for upgradeable contract
    function initializePausable(address _owner) internal {
        super.initializeOwner(_owner);

        require(owner != address(0), "Owner must be set");
        // Paused will be false, and lastPauseTime will be 0 upon initialisation
    }

    /**
     * @notice Change the paused state of the contract
     * @dev Only the contract owner may call this.
     */
    function setPaused(bool _paused) external onlyOwner {
        // Ensure we're actually changing the state before we do anything
        if (_paused == paused) {
            return;
        }

        // Set our paused state.
        paused = _paused;

        // If applicable, set the last pause time.
        if (paused) {
            lastPauseTime = block.timestamp;
        }

        // Let everyone know that our pause state has changed.
        emit PauseChanged(paused);
    }

    event PauseChanged(bool isPaused);

    modifier notPaused {
        require(!paused, "This action cannot be performed while the contract is paused");
        _;
    }
}
// File: @openzeppelin/contracts/utils/StorageSlot.sol



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

// File: @openzeppelin/contracts/proxy/beacon/IBeacon.sol



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

// File: @openzeppelin/contracts/utils/Address.sol



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

// File: @openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol



pragma solidity ^0.8.2;




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

// File: @openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol



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
abstract contract UUPSUpgradeable is ERC1967Upgrade {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
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
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol



pragma solidity ^0.8.0;



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

// File: DefiPlayground/cake/BaseSingleTokenStakingCakeFarm.sol

pragma solidity ^0.8.0;








// Modified from https://docs.synthetix.io/contracts/source/contracts/stakingrewards
// and adjusted based on https://github.com/pancakeswap/pancake-farm/blob/master/contracts/MasterChef.sol
/// @title A wrapper contract over MasterChef contract that allows single asset in/out.
/// 1. User provide token0 or token1
/// 2. contract converts half to the other token and provide liquidity
/// 3. stake into underlying MasterChef contract
/// @notice Asset tokens are token0 and token1. Staking token is the LP token of token0/token1.
abstract contract BaseSingleTokenStakingCakeFarm is ReentrancyGuard, Pausable, UUPSUpgradeable {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    string public name;
    uint256 public pid; //Pool ID in MasterChef
    address public BCNT;
    IERC20 public cake;
    IERC20 public lp;
    IERC20 public token0;
    IERC20 public token1;
    IConverter public converter;
    IMasterChef public masterChef;


    /// @dev Piggyback on MasterChef' reward accounting
    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt.
        uint256 accruedReward;
    }

    mapping(address => UserInfo) public userInfo;

    /* ========== VIEWS ========== */

    /// @dev Get the implementation contract of this proxy contract.
    /// Only to be used on the proxy contract. Otherwise it would return zero address.
    function implementation() external view returns (address) {
        return _getImplementation();
    }

    function totalSupply() external view returns (uint256) {
        return userInfo[address(this)].amount;
    }

    function balanceOf(address account) external view returns (uint256) {
        return userInfo[account].amount;
    }

    function _debtOf(address account) external view returns (uint256) {
        return userInfo[account].rewardDebt;
    }

    /// @notice Get the reward earned by specified account.
    function earned(address account) public virtual view returns (uint256) {}

    function _getAccCakePerShare() public view returns (uint256) {
        (, , , uint256 accCakePerShare) = masterChef.poolInfo(pid);
        return accCakePerShare;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function _convertAndAddLiquidity(
        bool isToken0,
        uint256 amount,
        uint256 minReceivedTokenAmountSwap,
        uint256 minToken0AmountAddLiq,
        uint256 minToken1AmountAddLiq
    ) internal returns (uint256 lpAmount) {
        require(amount > 0, "Cannot stake 0");
        uint256 lpAmountBefore = lp.balanceOf(address(this));
        uint256 token0AmountBefore = token0.balanceOf(address(this));
        uint256 token1AmountBefore = token1.balanceOf(address(this));

        // Convert and add liquidity
        uint256 prevBalance;
        uint256 postBalance;
        uint256 actualAmount;
        if (isToken0) {
            prevBalance = token0.balanceOf(address(this));
            token0.safeTransferFrom(msg.sender, address(this), amount);
            postBalance = token0.balanceOf(address(this));
            actualAmount = postBalance - prevBalance;

            token0.safeApprove(address(converter), actualAmount);
            converter.convertAndAddLiquidity(
                address(token0),
                actualAmount,
                address(token1),
                minReceivedTokenAmountSwap,
                minToken0AmountAddLiq,
                minToken1AmountAddLiq,
                address(this)
            );
        } else {
            prevBalance = token1.balanceOf(address(this));
            token1.safeTransferFrom(msg.sender, address(this), amount);
            postBalance = token1.balanceOf(address(this));
            actualAmount = postBalance - prevBalance;

            token1.safeApprove(address(converter), actualAmount);
            converter.convertAndAddLiquidity(
                address(token1),
                actualAmount,
                address(token0),
                minReceivedTokenAmountSwap,
                minToken0AmountAddLiq,
                minToken1AmountAddLiq,
                address(this)
            );
        }

        uint256 lpAmountAfter = lp.balanceOf(address(this));
        uint256 token0AmountAfter = token0.balanceOf(address(this));
        uint256 token1AmountAfter = token1.balanceOf(address(this));

        lpAmount = (lpAmountAfter - lpAmountBefore);

        // Return leftover token to msg.sender
        if ((token0AmountAfter - token0AmountBefore) > 0) {
            token0.safeTransfer(msg.sender, (token0AmountAfter - token0AmountBefore));
        }
        if ((token1AmountAfter - token1AmountBefore) > 0) {
            token1.safeTransfer(msg.sender, (token1AmountAfter - token1AmountBefore));
        }
    }

    /// @notice Taken token0 or token1 in, convert half to the other token, provide liquidity and stake
    /// the LP tokens into MasterChef contract. Leftover token0 or token1 will be returned to msg.sender.
    /// @param isToken0 Determine if token0 is the token msg.sender going to use for staking, token1 otherwise
    /// @param amount Amount of token0 or token1 to stake
    /// @param minReceivedTokenAmountSwap Minimum amount of token0 or token1 received when swapping one for the other
    /// @param minToken0AmountAddLiq The minimum amount of token0 received when adding liquidity
    /// @param minToken1AmountAddLiq The minimum amount of token1 received when adding liquidity
    function stake(
        bool isToken0,
        uint256 amount,
        uint256 minReceivedTokenAmountSwap,
        uint256 minToken0AmountAddLiq,
        uint256 minToken1AmountAddLiq
    ) public virtual nonReentrant notPaused updateReward(msg.sender) {
        uint256 lpAmount = _convertAndAddLiquidity(isToken0, amount, minReceivedTokenAmountSwap, minToken0AmountAddLiq, minToken1AmountAddLiq);
        lp.safeApprove(address(masterChef), lpAmount);
        masterChef.deposit(pid, lpAmount);

        // Top up msg.sender's balance
        uint256 accCakePerShare = _getAccCakePerShare();
        userInfo[address(this)].amount = userInfo[address(this)].amount + lpAmount;
        userInfo[msg.sender].amount = userInfo[msg.sender].amount + lpAmount;
        emit Staked(msg.sender, lpAmount);
    }

    /// @notice Take LP tokens and stake into MasterChef contract.
    /// @param lpAmount Amount of LP tokens to stake
    function stakeWithLP(uint256 lpAmount) public nonReentrant notPaused updateReward(msg.sender) {
        lp.safeTransferFrom(msg.sender, address(this), lpAmount);
        lp.safeApprove(address(masterChef), lpAmount);
        masterChef.deposit(pid, lpAmount);

        // Top up msg.sender's balance
        uint256 accCakePerShare = _getAccCakePerShare();
        userInfo[address(this)].amount = userInfo[address(this)].amount + lpAmount;
        userInfo[msg.sender].amount = userInfo[msg.sender].amount + lpAmount;
        emit Staked(msg.sender, lpAmount);
    }

    /// @notice Withdraw stake from MasterChef, remove liquidity and convert to BCNT
    function withdraw(uint256 minToken0AmountConverted, uint256 minToken1AmountConverted, uint256 minBCNTAmountConverted, uint256 amount) public virtual nonReentrant updateReward(msg.sender) {}

    /// @notice Withdraw LP tokens from MasterChef and return to user.
    /// @param lpAmount Amount of LP tokens to withdraw
    function withdrawWithLP(uint256 lpAmount) public virtual nonReentrant notPaused updateReward(msg.sender) {}

    /// @notice Get the reward out and convert one asset to another.
    function getReward(uint256 minToken0AmountConverted, uint256 minToken1AmountConverted, uint256 minBCNTAmountConverted) public virtual nonReentrant updateReward(msg.sender) {}

    /// @notice Withdraw all stake from MasterChef, remove liquidity and convert to BCNT. Get the reward out and convert one asset to another.
    function exit(uint256 minToken0AmountConverted, uint256 minToken1AmountConverted, uint256 minBCNTAmountConverted, uint256 token0Percentage) external virtual {}

    /// @notice Withdraw LP tokens from MasterChef and return to user. Get the reward out and convert one asset to another.
    function exitWithLP(uint256 minToken0AmountConverted, uint256 minToken1AmountConverted, uint256 minBCNTAmountConverted) external virtual {}

    /* ========== RESTRICTED FUNCTIONS ========== */

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAddress != address(lp), "Cannot withdraw the staking token");
        IERC20(tokenAddress).safeTransfer(owner, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner {}

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) virtual {
        masterChef.updatePool(pid);
        uint256 accCakePerShare = _getAccCakePerShare();
        UserInfo storage user = userInfo[account];
        UserInfo storage total = userInfo[address(this)];

        if (account != address(0)) {
            uint256 userPending = user.amount * accCakePerShare / 1e12 - user.rewardDebt;
            user.accruedReward = user.accruedReward + userPending;
            uint256 totalPending = total.amount * accCakePerShare / 1e12 - total.rewardDebt;
            total.accruedReward = total.accruedReward + totalPending;
        }

        _;

        if (account != address(0)) {
            user.rewardDebt = user.amount * accCakePerShare / 1e12;
            total.rewardDebt = total.amount * accCakePerShare / 1e12;
        }
    }

    /* ========== EVENTS ========== */

    event Staked(address indexed user, uint256 amount);
    event Recovered(address token, uint256 amount);
}
// File: DefiPlayground/cake/RewardCompoundCakeFarm.sol

pragma solidity ^0.8.0;



/// @title A wrapper contract over StakingRewards contract that allows single asset in/out,
/// with autocompound functionality. Autocompound function collects the reward earned, convert
/// them to staking token and stake.
/// @notice Asset tokens are token0 and token1. Staking token is the LP token of token0/token1.
/// User will be earning LP tokens compounded, not the reward token from StakingRewards contract.
contract RewardCompoundCakeFarm is BaseSingleTokenStakingCakeFarm {
    using SafeERC20 for IERC20;

    struct BalanceDiff {
        uint256 balBefore;
        uint256 balAfter;
        uint256 balDiff;
    }

    struct minAmountVars {
        uint256 cakeToStakingTokenSwap;
        uint256 rewardToToken0Swap;
        uint256 tokenInToTokenOutSwap;
        uint256 tokenInAddLiq;
        uint256 tokenOutAddLiq;
    }

    /* ========== STATE VARIABLES ========== */

    IStakingRewards public stakingRewards;
    IERC20 public stakingRewardsStakingToken;
    IERC20 public stakingRewardsRewardsToken;
    uint256 public lpAmountCompounded;
    address public operator;

    /* ========== CONSTRUCTOR ========== */

    function initialize(
        string memory _name,
        address _owner,
        address _operator,
        address _BCNT,
        IERC20 _cake,
        uint256 _pid,
        IPancakePair _lp,
        IConverter _converter,
        address _masterChef,
        IStakingRewards _stakingRewards
    ) external {
        require(keccak256(abi.encodePacked(name)) == keccak256(abi.encodePacked("")), "Already initialized");
        super.initializePausable(_owner);
        super.initializeReentrancyGuard();

        name = _name;
        operator = _operator;
        BCNT = _BCNT;
        cake = _cake;
        pid = _pid;
        lp = IERC20(address(_lp));
        token0 = IERC20(_lp.token0());
        token1 = IERC20(_lp.token1());
        converter = _converter;
        masterChef = IMasterChef(_masterChef);
        stakingRewards = _stakingRewards;
        stakingRewardsStakingToken = IERC20(stakingRewards.stakingToken());
        stakingRewardsRewardsToken = IERC20(stakingRewards.rewardsToken());

        (address _poolLP, , ,) = masterChef.poolInfo(_pid);
        require(_poolLP == address(_lp), "Wrong LP token");
    }

    /* ========== VIEWS ========== */

    /// @notice Get the reward share earned by specified account.
    function _share(address account) public view returns (uint256) {
        UserInfo memory user = userInfo[account];

        uint256 totalAllocPoint = masterChef.totalAllocPoint();
        uint256 cakePerBlock = masterChef.cakePerBlock();
        (, uint256 allocPoint, uint256 lastRewardBlock, uint256 accCakePerShare) = masterChef.poolInfo(pid);
        uint256 lpSupply = lp.balanceOf(address(masterChef));
        if (block.number > lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = masterChef.getMultiplier(lastRewardBlock, block.number);
            uint256 cakeReward = (multiplier * cakePerBlock * allocPoint) / totalAllocPoint;
            accCakePerShare = accCakePerShare + ((cakeReward * 1e12) / lpSupply);
        }
        return user.amount * accCakePerShare / 1e12 - user.rewardDebt + user.accruedReward;
    }

    /// @notice Get the total reward share in this contract.
    /// @notice Total reward is tracked with `_rewards[address(this)]` and `_userRewardPerTokenPaid[address(this)]`
    function _shareTotal() public view returns (uint256) {
        return _share(address(this));
    }

    /// @notice Get the compounded LP amount earned by specified account.
    function earned(address account) public override view returns (uint256) {
        uint256 rewardsShare;
        if (account == address(this)){
            rewardsShare = _shareTotal();
        } else {
            rewardsShare = _share(account);
        }

        uint256 earnedCompoundedLPAmount;
        if (rewardsShare > 0) {
            uint256 totalShare = _shareTotal();
            // Earned compounded LP amount is proportional to how many rewards this account has
            // among total rewards
            earnedCompoundedLPAmount = lpAmountCompounded * rewardsShare / totalShare;
        }
        return earnedCompoundedLPAmount;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function _withdrawFromStakingRewards(uint256 amount, uint256 totalAmount) internal returns (uint256) {
        uint256 reward = userInfo[msg.sender].accruedReward;
        uint256 totalReward = userInfo[address(this)].accruedReward;
        uint256 stakingRewardsBalance = stakingRewards.balanceOf(address(this));
        uint256 amountToWithdrawFromStakingRewards;
        if (totalReward > 0 && reward > 0 && stakingRewardsBalance > 0) {
            // Amount to withdraw from StakingRewards is proportional to user's reward portion and amount portion
            // relative to total reward and total amount
            amountToWithdrawFromStakingRewards = stakingRewardsBalance * reward * amount / totalReward / totalAmount;
            stakingRewards.withdraw(amountToWithdrawFromStakingRewards);
            stakingRewardsStakingToken.safeTransfer(msg.sender, amountToWithdrawFromStakingRewards);
        }
        return amountToWithdrawFromStakingRewards;
    }

    /// @notice Withdraw stake from StakingRewards, remove liquidity and convert one asset to another.
    /// @param minToken0AmountConverted The minimum amount of token0 received when removing liquidity
    /// @param minToken1AmountConverted The minimum amount of token1 received when removing liquidity
    /// @param token0Percentage Determine what percentage of token0 to return to user. Any number between 0 to 100
    /// @param amount Amount of stake to withdraw
    function withdraw(
        uint256 minToken0AmountConverted,
        uint256 minToken1AmountConverted,
        uint256 token0Percentage,
        uint256 amount
    ) public override nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        uint256 userTotalAmount = userInfo[msg.sender].amount;

        // Update records:
        // substract withdrawing LP amount from total LP amount staked
        userInfo[address(this)].amount = (userInfo[address(this)].amount - amount);
        // substract withdrawing LP amount from user's balance
        userInfo[msg.sender].amount = (userInfo[msg.sender].amount - amount);

        // Withdraw from Master Chef
        masterChef.withdraw(pid, amount);

        lp.safeApprove(address(converter), amount);
        converter.removeLiquidityAndConvert(
            IPancakePair(address(lp)),
            amount,
            minToken0AmountConverted,
            minToken1AmountConverted,
            token0Percentage,
            msg.sender
        );

        // Withdraw from StakingRewards
        uint256 amountToWithdrawFromStakingRewards = _withdrawFromStakingRewards(amount, userTotalAmount);

        emit Withdrawn(msg.sender, amount, amountToWithdrawFromStakingRewards);
    }

    /// @notice Withdraw LP tokens from StakingRewards contract and return to user.
    /// @param lpAmount Amount of LP tokens to withdraw
    function withdrawWithLP(uint256 lpAmount) public override nonReentrant notPaused updateReward(msg.sender) {
        require(lpAmount > 0, "Cannot withdraw 0");
        uint256 userTotalAmount = userInfo[msg.sender].amount;

        // Update records:
        // substract withdrawing LP amount from total LP amount staked
        userInfo[address(this)].amount = (userInfo[address(this)].amount - lpAmount);
        // substract withdrawing LP amount from user's balance
        userInfo[msg.sender].amount = (userInfo[msg.sender].amount - lpAmount);

        // Withdraw from Master Chef
        masterChef.withdraw(pid, lpAmount);
        lp.safeTransfer(msg.sender, lpAmount);

        // Withdraw from StakingRewards
        uint256 amountToWithdrawFromStakingRewards = _withdrawFromStakingRewards(lpAmount, userTotalAmount);

        emit Withdrawn(msg.sender, lpAmount, amountToWithdrawFromStakingRewards);
    }

    /// @notice Get the reward out and convert one asset to another. Note that reward is LP token.
    /// @param minToken0AmountConverted The minimum amount of token0 received when removing liquidity
    /// @param minToken1AmountConverted The minimum amount of token1 received when removing liquidity
    /// @param minBCNTAmountConverted The minimum amount of BCNT received swapping token0 for BCNT
    function getReward(
        uint256 minToken0AmountConverted,
        uint256 minToken1AmountConverted,
        uint256 minBCNTAmountConverted
    ) public override updateReward(msg.sender) {
        uint256 reward = userInfo[msg.sender].accruedReward;
        uint256 totalReward = userInfo[address(this)].accruedReward;
        if (reward > 0) {
            // compoundedLPRewardAmount: based on user's reward and totalReward,
            // determine how many compouned(read: extra) LP amount can user take away.
            // NOTE: totalReward = _rewards[address(this)];
            uint256 compoundedLPRewardAmount = lpAmountCompounded * reward / totalReward;

            // Update records:
            // add user's claimed rewards to rewardDebt
            userInfo[msg.sender].accruedReward = 0;
            userInfo[address(this)].accruedReward = userInfo[address(this)].accruedReward - reward;
            // substract compoundedLPRewardAmount from lpAmountCompounded
            lpAmountCompounded = (lpAmountCompounded - compoundedLPRewardAmount);

            // Withdraw from compounded LP
            masterChef.withdraw(pid, compoundedLPRewardAmount);

            lp.safeApprove(address(converter), compoundedLPRewardAmount);
            converter.removeLiquidityAndConvert(
                IPancakePair(address(lp)),
                compoundedLPRewardAmount,
                minToken0AmountConverted,
                minToken1AmountConverted,
                100, // Convert 100% to token0
                address(this) // Need to send token0 here to convert them to BCNT
            );

            // Convert token0 to BCNT
            uint256 token0Balance = token0.balanceOf(address(this));
            token0.safeApprove(address(converter), token0Balance);
            converter.convert(
                address(token0),
                token0Balance,
                100, // Convert 100% to BCNT
                BCNT,
                minBCNTAmountConverted,
                msg.sender
            );

            emit RewardPaid(msg.sender, compoundedLPRewardAmount);
        }
    }

    /// @notice Withdraw all stake from StakingRewards, remove liquidity, get the reward out and convert one asset to another.
    /// @param minToken0AmountConverted The minimum amount of token0 received when removing liquidity
    /// @param minToken1AmountConverted The minimum amount of token1 received when removing liquidity
    /// @param minBCNTAmountConverted The minimum amount of BCNT received swapping token0 for BCNT
    /// @param token0Percentage Determine what percentage of token0 to return to user. Any number between 0 to 100
    function exit(uint256 minToken0AmountConverted, uint256 minToken1AmountConverted, uint256 minBCNTAmountConverted, uint256 token0Percentage) external override {
        withdraw(minToken0AmountConverted, minToken1AmountConverted, token0Percentage, userInfo[msg.sender].amount);
        getReward(minToken0AmountConverted, minToken1AmountConverted, minBCNTAmountConverted);
    }

    /// @notice Withdraw all stake from StakingRewards, remove liquidity, get the reward out and convert one asset to another.
    /// @param minToken0AmountConverted The minimum amount of token0 received when removing liquidity
    /// @param minToken1AmountConverted The minimum amount of token1 received when removing liquidity
    /// @param minBCNTAmountConverted The minimum amount of BCNT received swapping token0 for BCNT
    function exitWithLP(uint256 minToken0AmountConverted, uint256 minToken1AmountConverted, uint256 minBCNTAmountConverted) external override {
        withdrawWithLP(userInfo[msg.sender].amount);
        getReward(minToken0AmountConverted, minToken1AmountConverted, minBCNTAmountConverted);
    }

    function _convertCakeToStakingToken(uint256 cakeLeft, minAmountVars memory minAmounts) internal {
        masterChef.deposit(pid, 0);

        // Convert Cake to stakingRewardsStakingToken
        BalanceDiff memory stakingTokenDiff;
        stakingTokenDiff.balBefore = stakingRewardsStakingToken.balanceOf(address(this));
        cake.safeApprove(address(converter), cakeLeft);
        converter.convert(address(cake), cakeLeft, 100, address(stakingRewardsStakingToken), minAmounts.cakeToStakingTokenSwap, address(this));
        stakingTokenDiff.balAfter = stakingRewardsStakingToken.balanceOf(address(this));
        stakingTokenDiff.balDiff = (stakingTokenDiff.balAfter - stakingTokenDiff.balBefore);

        stakingRewardsStakingToken.safeApprove(address(stakingRewards), stakingTokenDiff.balDiff);
        stakingRewards.stake(stakingTokenDiff.balDiff);

        emit StakedToStakingReward(stakingTokenDiff.balDiff);
    }

    function _convertRewardsTokenToLPToken(uint256 rewardsLeft, minAmountVars memory minAmounts) internal {
        stakingRewards.getReward();

        // Convert rewards to token0
        BalanceDiff memory token0Diff;
        token0Diff.balBefore = token0.balanceOf(address(this));
        stakingRewardsRewardsToken.safeApprove(address(converter), rewardsLeft);
        converter.convert(address(stakingRewardsRewardsToken), rewardsLeft, 100, address(token0), minAmounts.rewardToToken0Swap, address(this));
        token0Diff.balAfter = token0.balanceOf(address(this));
        token0Diff.balDiff = (token0Diff.balAfter - token0Diff.balBefore);

        // Convert converted token0 to LP tokens
        BalanceDiff memory lpAmountDiff;
        lpAmountDiff.balBefore = lp.balanceOf(address(this));
        token0.safeApprove(address(converter), token0Diff.balDiff);
        converter.convertAndAddLiquidity(
            address(token0),
            token0Diff.balDiff,
            address(token1),
            minAmounts.tokenInToTokenOutSwap,
            minAmounts.tokenInAddLiq,
            minAmounts.tokenOutAddLiq,
            address(this)
        );

        lpAmountDiff.balAfter = lp.balanceOf(address(this));
        lpAmountDiff.balDiff = (lpAmountDiff.balAfter - lpAmountDiff.balBefore);
        // Add compounded LP tokens to lpAmountCompounded
        lpAmountCompounded = lpAmountCompounded + lpAmountDiff.balDiff;

        // Stake the compounded LP tokens back in
        lp.safeApprove(address(masterChef), lpAmountDiff.balDiff);
        masterChef.deposit(pid, lpAmountDiff.balDiff);

        emit Compounded(lpAmountDiff.balDiff);
    }

    /// @notice compound is split into two parts but pipelined, both part will be exectued each time:
    /// First part: get all Cake out from MasterChef contract, convert all to staking token of StakingRewards contract
    /// Second part: get all rewards out from StakingReward, convert rewards to both token0 and token1 and provide liquidity and stake
    /// the LP tokens back into MasterChef contract.
    /// @dev LP tokens staked this way will be tracked in `lpAmountCompounded`.
    /// @param minAmounts The minimum amounts of
    /// 1. stakingRewardsStakingToken expected to receive when swapping Cake for stakingRewardsStakingToken
    /// 2. token0 expected to receive when swapping stakingRewardsRewardsToken for token0
    /// 3. tokenOut expected to receive when swapping inToken for outToken
    /// 4. tokenIn expected to add when adding liquidity
    /// 5. tokenOut expected to add when adding liquidity
    function compound(
        minAmountVars memory minAmounts
    ) external nonReentrant updateReward(address(0)) onlyOperator {
        // Get cake from MasterChef plus remaining cake on this contract
        // NOTE: cake is collected everytime the contract deposit to/withdraw from MasterChef
        // so pendingCake is not all the cake collected.
        uint256 pendingCakeLeft = masterChef.pendingCake(pid, address(this));
        uint256 cakeLeft = pendingCakeLeft + cake.balanceOf(address(this));
        if (cakeLeft > 0) {
            _convertCakeToStakingToken(cakeLeft, minAmounts);
        }

        // Get this contract's reward from StakingRewards
        uint256 rewardsLeft = stakingRewards.earned(address(this));
        if (rewardsLeft > 0) {
            _convertRewardsTokenToLPToken(rewardsLeft, minAmounts);
        }
    }

    function updateOperator(address newOperator) external onlyOwner {
        operator = newOperator;
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) override {
        masterChef.updatePool(pid);
        uint256 accCakePerShare = _getAccCakePerShare();
        UserInfo storage user = userInfo[account];
        UserInfo storage total = userInfo[address(this)];

        if (account != address(0)) {
            uint256 userPending = user.amount * accCakePerShare / 1e12 - user.rewardDebt;
            user.accruedReward = user.accruedReward + userPending;
            uint256 totalPending = total.amount * accCakePerShare / 1e12 - total.rewardDebt;
            total.accruedReward = total.accruedReward + totalPending;
        }

        _;

        if (account != address(0)) {
            user.rewardDebt = user.amount * accCakePerShare / 1e12;
            total.rewardDebt = total.amount * accCakePerShare / 1e12;
        }
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "Only the contract operator may perform this action");
        _;
    }

    /* ========== EVENTS ========== */

    event Withdrawn(address indexed user, uint256 autoCompoundStakingTokenAmount, uint256 stakingRewardsStakingTokenAmount);
    event StakedToStakingReward(uint256 stakeAmount);
    event Compounded(uint256 lpAmount);
    event RewardPaid(address indexed user, uint256 rewardLPAmount);
}