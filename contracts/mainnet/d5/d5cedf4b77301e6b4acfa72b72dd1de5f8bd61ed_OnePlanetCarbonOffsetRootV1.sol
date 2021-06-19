/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

// Sources flattened with hardhat v2.3.0 https://hardhat.org
// SPDX-License-Identifier: MIT
// File contracts/IBeacon.sol


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


// File contracts/Address.sol

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


// File contracts/StorageSlot.sol

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


// File contracts/ERC1967Upgrade.sol

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
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
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
            Address.functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlot.BooleanSlot storage rollbackTesting = StorageSlot.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            Address.functionDelegateCall(
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
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
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
        require(
            Address.isContract(newBeacon),
            "ERC1967: new beacon is not a contract"
        );
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }
}


// File contracts/UUPSUpgradeable.sol


pragma solidity ^0.8.0;

/**
 * @dev Base contract for building openzeppelin-upgrades compatible implementations for the {ERC1967Proxy}. It includes
 * publicly available upgrade functions that are called by the plugin and by the secure upgrade mechanism to verify
 * continuation of the upgradability.
 *
 * The {_authorizeUpgrade} function MUST be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is ERC1967Upgrade {
    function upgradeTo(address newImplementation) external virtual {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, bytes(""), false);
    }

    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    function _authorizeUpgrade(address newImplementation) internal virtual;
}


// File contracts/Initializable.sol

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


// File contracts/ContextUpgradeable.sol

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


// File contracts/2StepOwnableUpgradeable.sol

pragma solidity ^0.8.0;


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
    address private _newOwner;

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
     * @dev Transfers ownership of the contract to a new account (`newOwner`) 
     * Can only be called by the current owner.
     * NewOwner must call acceptOwnership function to complete ownership transfer.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _newOwner = newOwner;
    }

    function acceptOwnership() public virtual {
        require(msg.sender == _newOwner);
        emit OwnershipTransferred(_owner, _newOwner);
        _owner = _newOwner;
        _newOwner = address(0);
    }

    uint256[48] private __gap;
}


// File contracts/1PLCO2ImplementationChildV4.sol

pragma solidity >=0.8.0;
/*
                                                    ./>.
                                    .<.           ./>>>>>.            .-
                                    (>>>>><....<>>>>>>>>>>>>><...><>>>>>
                                   (>>>>>>>>===   ........   ====>>>>>>>>
                                 ./>>>== ..<>>>==============>>>>>. ==>>>>>
                              .<>>=  (>>==                        ==>>>. =\>><.
                      (>>>>>>>>= ./>=       ..<>>>>>>>>>>>>>>>>..      =\>< =\>>>>>>>>
                      (>>>>>= ./>=     .<>>>>>>>>>>>>>>>>>>>>>>>>>>>>.    =\>> =\>>>>=
                      (>>>= </=-    <>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>.    =\> =\>>>
                     ./>= (/=    (>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>.   =\> =\>+
                    (/= (/=    (>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>+   =\> (>>
                 .<>>= (=    (>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>.   (> (\>>.
            (>>>>>>/ ./=   ./>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>   (\-.(>>>>>>+
             (\>>>>=./=   (>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>=   =>>>>>>>>>>>.  =\> (>>>>=
              (>>>=./=   (>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>=       \>>>>>>>>>>-  (\>.\>>=
               (>= (=   (>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>          \>>>>>>>>>>   (> (>>
               (>-(/   ./>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>=            (>>>>>>>>>>   (> (>
              (>= (=   (>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>=     .<>>     (>>>>>>>>>>  (> (>>
             (>>= /=   (>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>=     (>====>>    (>>>>>>>>>   (> (>>.
          ./>>>>-(>   (>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>=    .<========>.   (>>>>>>>>   (> (>>>>.
         =\>>>>>-(>   (>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>=     />==========>>   =>>>>>>>   (= (>>>>>=
            =>>>-(>   (>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>=    .>=====<<<<<<===>.   \>>>>>   (= (>>=
              (>) (>   (>>>>>>>>>>>>>>>>>>>>>>>>>>>>=    .>=====(<<<<<<<<</==>.  =\>>=  (/=(>>=
               (> (>   (>>>>>>>>>>>>>>>>>>>>>>>>>=.    .>====\(<<<<<<<<<<<<</==>.  ==-  (/ (>=
               (>=(\=   (>>>>>>>>>>>>>>>>>>>==      .<>====\/<<<<<<<<<<<<<<<<<</=>>.    /=(/>
               (>> (>   (>>>>>>>>>>>====        ./>>====\<<<<<<<<<<<<<<<<<<<<<<<<</=   (= (>>
              (>>>> (>                   ...<>>>====\<<<<<<<<<<<<<<<<<<<<<<<<<<<<</   (> (>>>\
             (>>>>>> (>    ..../<<<>==========\\<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<=   (= (>>>>>>
              ===>>>> (>.   ======<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<=  ./= (>>>===
                   =\>.=\>   =\<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<=   (/= (>=
                     (>> (\<   =\<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<=   ./= (//
                      (>>> (>>   =<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<=   ./= ./>>
                      (>>>>< =\>.    =<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<=   .</=../>>>=
                      (>>>>>>>. =>>.    ==<<<<<<<<<<<<<<<<<<<<<<<<==    .<>= .<>>>>>>>
                      (======>>>>. =\>>.      ====<<<<<<<<=====     .<>>= .(>>>=======
                                =\>>>. ==>>>>..              ...<>>== ..>>>=
                                  (>>>>>>>... =====>>>>>>======...<>>>>>>=
                                   (\>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>=
                                    (>==         =>>>>>>>>==       .==>=
                                                   =\>>>=
                                                     ==
                                                     
     
             ▄▄▄▄     ▄▄▄▄▄▄▄▄▄▄▄  ▄▄           ▄▄▄▄▄▄▄▄▄▄▄   ▄▄▄▄▄▄▄▄▄▄   ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄
             ████     ██▀▀▀▀▀▀▀██  ██           ███▀▀▀▀████  ▐██▀▀▀▀▀▀██▌  ██▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀██▀▀▀▀
               ██     ███████████  ██           ███████████  ▐██      ██▌  ███████████       ██
               ██     ████         ██           ██▌    ████  ▐████    ██▌  ████              ████
               ██     ████         ███████████  ██▌    ████  ▐████    ██▌  ████              ████
           ████████▌  ████         ███████████  ███    ████  ▐████    ██▌  ███████████       ████
*/


// ---------------------------------------------------------------------------------------------------------------
// '1PLCO2' token contract
//  1PLCO2 is a tokenized Carbon Credit.
//  1PLCO2 = 1 Carbon Credit = 1 metric ton of CO2
//  This 1PLANET contract also offers direct offsetting functions for dApps and Smart Contracts such as NFT minting.
//  When 1PLCO2 is burned/retired then carbon credits are also permenantly burned/retired for carbon offsetting.
//  Use the dApp at www.1PLANET.app for verification and see www.climatefutures.io for more information.
//------------------------------------------------------------------------------------------------------------------

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
abstract contract ERC20Interface {
    function totalSupply() public virtual view returns (uint);
    function balanceOf(address tokenOwner) public virtual view returns (uint balance);
    function allowance(address tokenOwner, address spender) public virtual view returns (uint remaining);
    function transfer(address to, uint tokens) public virtual returns (bool success);
    function approve(address spender, uint tokens) public virtual returns (bool success);
    function transferFrom(address from, address to, uint tokens) public virtual returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
abstract contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public virtual;
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract OnePlanetCarbonOffsetRootV1 is ERC20Interface, OwnableUpgradeable, UUPSUpgradeable {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    uint public startDate;
    uint public endDate;
    uint public _maxSupply;
    uint public updateInterval;
    uint public currentIntervalRound;
    AggregatorV3Interface internal priceFeed;
    uint public ethPrice;
    uint public ethAmount;
    uint public ethPrice1PL;
    uint public sigDigits;
    uint public offsetSigDigits;
    uint public tokenPrice;
	address payable public oracleAddress;
	address payable public daiAddress;
	address payable public tetherAddress;
    address payable public usdcAddress;
	address public retireAddress;
	uint256 public gasCO2factor;
	uint256 public CO2factor1; // for future use cases
	uint256 public CO2factor2;
	uint256 public CO2factor3;
	uint256 public CO2factor4;
	uint256 public CO2factor5;
	uint256 public gasEst;
	// Matic Variable
	address public MintableERC20PredicateProxy;
	
    event CarbonOffset(string message);
    event ApprovedDaiPurchase(address buyer, uint256 ApprovedAmount, bool success, bytes data);
    event Deposit(address indexed sender, uint value);
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    
    // ------------------------------------------------------------------------
    // Initializer
    // ------------------------------------------------------------------------
function initialize() public initializer {
        symbol = "1PLCO2";
        name = "1PLANET Carbon Credit";
        decimals = 18;
        sigDigits = 100;
        offsetSigDigits = 1e15; // to 1 kg CO2e
        tokenPrice = 1000;
        updateInterval = 1;
        endDate = block.timestamp + 2000 weeks;
        _maxSupply = 150000000000000000000000000; // 150M metric tons CO2e
		oracleAddress = payable(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
		retireAddress = 0x0000000000000000000000000000000000000000;
		daiAddress = payable(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        tetherAddress = payable(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        usdcAddress = payable(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
		priceFeed = AggregatorV3Interface(oracleAddress);
        gasCO2factor = 380000000000;
        __Ownable_init();
        
        //Matic PoS Bridge
        MintableERC20PredicateProxy = 0x9923263fA127b3d1484cFD649df8f1831c2A74e4;
    }

    // ------------------------------------------------------------------------
    // Overwrite of _authorizeUpgrade for UUPSUpgradeable functions
    // ------------------------------------------------------------------------

    ///@dev upgradeTo and upgradeToAndCall will revert if caller is not the contract owner
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
    
    modifier onlyPredicate {
        require(msg.sender == MintableERC20PredicateProxy);
        _;
    }

    modifier estGas {
        uint256 gasAtStart = gasleft();
        _;
        gasEst = gasAtStart - gasleft();
    }
    
    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public override view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
	
    function maxSupply() public view returns (uint) {
        return _maxSupply;
    }

    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public override view returns (uint balance) {
        return balances[tokenOwner];
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to `to` account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public override returns (bool success) {
        balances[msg.sender] -= tokens;
        balances[to] += tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    //
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
        balances[from] -= tokens;
        allowed[from][msg.sender] -= tokens;
        balances[to] += tokens;
        emit Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }

    // ------------------------------------------------------------------------
    // Send ETH to get 1PLCO2 tokens
    // ------------------------------------------------------------------------
    receive() external payable {
        require(block.timestamp >= startDate && block.timestamp <= endDate);
        uint256 weiAmount = msg.value;
        uint256 tokens = _getTokenAmount(weiAmount);
        balances[msg.sender] += tokens;
        _totalSupply += tokens;
        emit Transfer(address(0), msg.sender, tokens);
        payable(owner()).transfer(msg.value);
        currentIntervalRound += 1;
        if(currentIntervalRound == updateInterval) {
            getLatestPrice();
            currentIntervalRound = 0;
        }
    
    }

    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        uint256 temp = weiAmount * ethPrice;
        temp /= sigDigits;
        temp /= tokenPrice;
        temp *= 100;
        return temp;
    }
    
    //-------------------------------------------------------------------------------------------
    // Enables user to purchase 1PLCO2 carbon credits with DAI stable coins
    // Buyer must first APPROVE the DAI amount transfer directly with the DAI contract
    //-------------------------------------------------------------------------------------------
    function buy1PLwithDAI(uint256 daiAmount) public returns (bool success) {
        
        ERC20Interface DAIpaymentInstance = ERC20Interface(daiAddress);
        
        require(daiAmount > 0, "You need to send at least some DAI");
        require(DAIpaymentInstance.balanceOf(address(msg.sender)) >= daiAmount, "Not enough DAI");
        uint256 daiAllowance = DAIpaymentInstance.allowance(msg.sender, address(this));
        require(daiAllowance >= daiAmount, "You need to approve more DAI to be spent");
        
        uint256 tokens = daiAmount / tokenPrice;
        tokens *= 100;
        
        DAIpaymentInstance.transferFrom(msg.sender, address(this), daiAmount);
        
        balances[msg.sender] += tokens;
        _totalSupply += tokens;
        
        emit Transfer(address(0), msg.sender, tokens);
        return true;
    }

    //-------------------------------------------------------------------------------------------
    // Enables user to purchase 1PLCO2 carbon credits with Tether stable coins
    // Buyer must first APPROVE the Tether amount transfer directly with the Tether contract
    //-------------------------------------------------------------------------------------------
    function buy1PLwithUSDT(uint256 tetherAmount) public returns (bool success) {
        
        ERC20Interface TETHERpaymentInstance = ERC20Interface(tetherAddress);
        
        require(tetherAmount > 0, "You need to send at least some TETHER");
        require(TETHERpaymentInstance.balanceOf(address(msg.sender)) >= tetherAmount, "Not enough TETHER");
        uint256 tetherAllowance = TETHERpaymentInstance.allowance(msg.sender, address(this));
        require(tetherAllowance >= tetherAmount, "You need to approve more TETHER to be spent");
        
        uint256 tokens = tetherAmount / tokenPrice;
        tokens *= 100;
        
        TETHERpaymentInstance.transferFrom(msg.sender, address(this), tetherAmount);
        
        balances[msg.sender] += tokens;
        _totalSupply += tokens;
        
        emit Transfer(address(0), msg.sender, tokens);
        return true;
    }

    //-------------------------------------------------------------------------------------------
    // Enables user to purchase 1PLCO2 carbon credits with USDC stable coins
    // Buyer must first APPROVE the USDC amount transfer directly with the USDC contract
    //-------------------------------------------------------------------------------------------
    function buy1PLwithUSDC(uint256 usdcAmount) public returns (bool success) {
        
        ERC20Interface USDCpaymentInstance = ERC20Interface(usdcAddress);
        
        require(usdcAmount > 0, "You need to send at least some USDC");
        require(USDCpaymentInstance.balanceOf(address(msg.sender)) >= usdcAmount, "Not enough USDC");
        uint256 usdcAllowance = USDCpaymentInstance.allowance(msg.sender, address(this));
        require(usdcAllowance >= usdcAmount, "You need to approve more USDC to be spent");
        
        uint256 tokens = usdcAmount / tokenPrice;
        tokens *= 100;
        
        USDCpaymentInstance.transferFrom(msg.sender, address(this), usdcAmount);
        
        balances[msg.sender] += tokens;
        _totalSupply += tokens;
        
        emit Transfer(address(0), msg.sender, tokens);
        return true;
    }
    
    //-------------------------------------------------------------------------------------------
    // Enables dApps to perform carbon offsetting applications with 1PLCO2 carbon credits
    // Can be used by third-party developers and it will log custom messages
    // Verify transaction details at www.1PLANET.app
    //-------------------------------------------------------------------------------------------
    function retire1PLCO2(uint tokens, string calldata message) external returns (bool success) {
        require(tokens > offsetSigDigits, "Retire at least 0.001 (1kg) 1PLCO2");
        tokens /= offsetSigDigits;
        tokens *= offsetSigDigits; // retire in kg
        transfer(retireAddress, tokens);
        emit CarbonOffset(message);
        return true;
    }
    
    //-------------------------------------------------------------------------------------------
    // Enables dApps to perform carbon offsetting applications with ETH
    // Users pay current spot price here for 1PLCO2 carbon credits
    // Verify transaction details at www.1PLANET.app
    //-------------------------------------------------------------------------------------------
    function offsetDirect(string calldata message) external payable returns (bool success) {
        
        require(msg.value > 0, "You need to send at least some ETH");
        ethAmount = msg.value * (1e18 / offsetSigDigits);
        uint tokens = ethAmount / ethPrice1PL;
        tokens *= offsetSigDigits; // only retire in kg
        balances[retireAddress] += tokens;
        emit Transfer(address(0), retireAddress, tokens);
        emit CarbonOffset(message);
        _totalSupply += tokens;
        getLatestPrice();
        return true;
    }
        
    function update1PLpriceInt(uint price) public onlyOwner {
        tokenPrice = price;
    }
	
	function setOracleAddress(address payable newOracleAddress) public onlyOwner {
        oracleAddress = newOracleAddress;
        priceFeed = AggregatorV3Interface(oracleAddress);
	}

    function setRetireAddress(address newAddress) public onlyOwner {
        retireAddress = newAddress;
    }
    
    function updateGasCO2factor (uint256 CO2factor) external onlyOwner {
        gasCO2factor = CO2factor;
    }
    
    function updateCO2factor1 (uint256 CO2factor) external onlyOwner {
        CO2factor1 = CO2factor;
    }
    
    function updateCO2factor2 (uint256 CO2factor) external onlyOwner {
        CO2factor2 = CO2factor;
    }
    
    function updateCO2factor3 (uint256 CO2factor) external onlyOwner {
        CO2factor3 = CO2factor;
    }
    
    function updateCO2factor4 (uint256 CO2factor) external onlyOwner {
        CO2factor4 = CO2factor;
    }
    
    function updateCO2factor5 (uint256 CO2factor) external onlyOwner {
        CO2factor5 = CO2factor;
    }
    
    
    function setOracleUpdateInterval(uint interval) public onlyOwner {
        updateInterval = interval;
    }

    function genAndSendTokens(address to, uint tokens) external onlyOwner returns (bool success) {
        require(block.timestamp >= startDate && block.timestamp <= endDate);
        require(_maxSupply >= (_totalSupply + tokens));
        balances[to] += tokens;
        _totalSupply += tokens;
        emit Transfer(address(0), to, tokens);
        
        return true;
    }

    //-----------------------------------------------------
    // Returns the latest Chainlink Oracle ETH USD price
    //-----------------------------------------------------
    function getLatestPrice() public {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        // If the round is not complete yet, timestamp is 0
        require(timeStamp > 0, "Round not complete");
        ethPrice = uint(price) / 1000000;
        uint256 temp = tokenPrice * 1e18;
        ethPrice1PL = temp / ethPrice;
    }

    function updateEthPriceManually(uint price) external onlyOwner {
        ethPrice = price;
    }
    
    function update1PLethPriceManually(uint price) external onlyOwner {
        ethPrice1PL = price;
    }
    
    
    //--------------------------------------------------------------------------------------
    // Added due to Matic <-> Ethereum PoS transfer requiring 1PLCO2 on Matic network to be
    // burned or minted. Eth supply can be increased if it is ever necessary.
    //--------------------------------------------------------------------------------------
    function setMaxVolume(uint maxVolume) external onlyOwner {
        _maxSupply = maxVolume;
    }
    
    //--------------------------------------------------------------------------------------
    // Oracle returns price in decimal cents to 2 decimal places. If this changes it can
    // be adjusted by changing this significant digit value.
    // Should be a power of 10.
    //--------------------------------------------------------------------------------------
    function setSigDigits(uint digits) external onlyOwner {
        sigDigits = digits;
    }
    
    function setOffsetSigDigits(uint digits) external onlyOwner {
        offsetSigDigits = digits;
    }


    function topUpBalance() public payable {
    }

    function withdrawFromBalance() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    
    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) external onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(payable(owner()), tokens);
    }
    
    
    function removePermanently(address account, uint256 amount) external onlyOwner returns (bool success) {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        balances[account] -= amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
        
        return true;
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
    
        // Matic L2 Bridge functions
    
    // ------------------------------------------------------------------------
    // Matic Mint Function
    // ------------------------------------------------------------------------
    function mint(address user, uint256 amount) external onlyPredicate {
        _mint(user, amount);
    }
    
    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */

    function _mint(address to, uint256 tokens) internal virtual estGas {
        require(to != address(0), "ERC20: mint to the zero address");
        require(block.timestamp >= startDate && block.timestamp <= endDate);
        require(_maxSupply >= (_totalSupply + tokens));
        _beforeTokenTransfer(address(0), to, tokens);
        balances[to] += tokens;
        _totalSupply += tokens;
        emit Transfer(address(0), to, tokens);
    }
    
    // ------------------------------------------------------------------------
    // Matic Predicate Address
    // ------------------------------------------------------------------------
    // being proxified smart contract, most probably childChainManagerProxy contract's address
    // is not going to change ever, but still, lets keep it 
	
    function updatePredicate(address payable newERC20PredicateProxy) external onlyOwner {
        require(newERC20PredicateProxy != address(0), "Bad ERC20PredicateProxy address");
        MintableERC20PredicateProxy = newERC20PredicateProxy;
    }
    
}