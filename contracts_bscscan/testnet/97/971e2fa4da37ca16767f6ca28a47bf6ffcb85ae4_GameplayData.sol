/**
 *Submitted for verification at BscScan.com on 2021-08-17
*/

// SPDX-License-Identifier: 
// Sources flattened with hardhat v2.4.0 https://hardhat.org

// File contracts/shared/interfaces/IAdminProjectRouter.sol

pragma solidity 0.6.6;

interface IAdminProjectRouter {
  function isSuperAdmin(address _addr, string calldata _project) external view returns (bool);

  function isAdmin(address _addr, string calldata _project) external view returns (bool);
}


// File contracts/proxy/AuthorizationUpgradeable.sol

pragma solidity 0.6.6;

abstract contract AuthorizationUpgradeable {
  IAdminProjectRouter public adminRouter;
  string public PROJECT;

  modifier onlySuperAdmin() {
    require(adminRouter.isSuperAdmin(msg.sender, PROJECT), "Restricted only super admin");
    _;
  }

  modifier onlyAdmin() {
    require(adminRouter.isAdmin(msg.sender, PROJECT), "Restricted only admin");
    _;
  }

  function setAdmin(address _adminRouter) external onlySuperAdmin {
    adminRouter = IAdminProjectRouter(_adminRouter);
  }
}


// File contracts/shared/interfaces/IBeacon.sol

pragma solidity 0.6.6;

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


// File contracts/shared/utils/Address.sol

pragma solidity 0.6.6;

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

    (bool success, ) = recipient.call{ value: amount }("");
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
  function functionStaticCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    require(isContract(target), "Address: static call to non-contract");

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
  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), "Address: delegate call to non-contract");

    (bool success, bytes memory returndata) = target.delegatecall(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  function _verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) private pure returns (bytes memory) {
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


// File contracts/shared/utils/StorageSlot.sol

pragma solidity 0.6.6;

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
      r_slot := slot
    }
  }

  /**
   * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
   */
  function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
    assembly {
      r_slot := slot
    }
  }

  /**
   * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
   */
  function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
    assembly {
      r_slot := slot
    }
  }

  /**
   * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
   */
  function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
    assembly {
      r_slot := slot
    }
  }
}


// File contracts/proxy/Initializable.sol

pragma solidity 0.6.6;

abstract contract Initializable {
  bool private _initialized;

  bool private _initializing;

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


// File contracts/proxy/ERC1967Upgrade.sol

pragma solidity 0.6.6;




/* *
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
      Address.functionDelegateCall(newImplementation, abi.encodeWithSignature("upgradeTo(address)", oldImplementation));
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


// File contracts/proxy/UUPSUpgradeable.sol

pragma solidity 0.6.6;


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
  function upgradeToAndCall(address newImplementation, bytes calldata data) external payable virtual {
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


// File contracts/shared/libraries/BitUtils.sol

pragma solidity 0.6.6;

library BitUtils {
  uint256 private constant _ALLONES = uint256(-1);
  uint256 private constant _MAX_LENGTH = 256;

  modifier checkBitInputs(uint16 _bitLoc, uint16 _bits) {
    require(_bitLoc + _bits <= _MAX_LENGTH, "BitUtils: Invalid inputs");
    _;
  }

  function extractBits(
    uint256 _data,
    uint16 _bitLoc,
    uint16 _bits
  ) internal pure checkBitInputs(_bitLoc, _bits) returns (uint256) {
    return (_data << (_MAX_LENGTH - (_bitLoc + _bits))) >> (_MAX_LENGTH - _bits);
    // return (_data << _bitLoc) >> (_MAX_LENGTH - (_bitLoc + _bits));
  }

  function setBits(
    uint256 _data,
    uint16 _bitLoc,
    uint16 _bits,
    uint256 _setData
  ) internal pure checkBitInputs(_bitLoc, _bits) returns (uint256) {
    // Ex. [0000 0001 << 3] -> [0000 1000 - 1] -> 0000 0111
    uint256 ones = (uint256(1) << _bits) - 1;
    require(ones >= _setData, "BitUtils: setData input overflow");

    // Ex. [0000 0111 << 4] -> [0111 0000 XOR 1111 1111] -> 1000 1111
    uint256 bitMask = (ones << _bitLoc) ^ _ALLONES;

    // Ex. [x011 xxxx AND 1000 1111] -> [x000 xxxx OR 0101 0000] -> x101 xxxx
    return (_data & bitMask) | (_setData << _bitLoc);
  }

  // function setBits(
  //   uint256 _data,
  //   uint16 _bitLoc,
  //   uint16 _bits,
  //   uint256 _setData
  // ) internal pure checkBitInputs(_bitLoc, _bits) returns (uint256) {
  //   // Ex. [0000 0001 << 3] -> [0000 1000 - 1] -> 0000 0111
  //   uint256 ones = (uint256(1) << _bits) - 1;
  //   require(ones >= _setData, "BitUtils: setData input overflow");

  //   uint256 bitLocFromRight = _MAX_LENGTH - (_bitLoc + _bits);

  //   // Ex. [0000 0111 << 4] -> [0111 0000 XOR 1111 1111] -> 1000 1111
  //   uint256 bitMask = (ones << bitLocFromRight) ^ _ALLONES;

  //   // Ex. [x011 xxxx AND 1000 1111] -> [x000 xxxx OR 0101 0000] -> x101 xxxx
  //   return (_data & bitMask) | (_setData << bitLocFromRight);
  // }

  function subBits(
    uint256 _data,
    uint16 _bitLoc,
    uint16 _bits,
    uint256 _subAmount
  ) internal pure checkBitInputs(_bitLoc, _bits) returns (uint256) {
    uint256 amount = extractBits(_data, _bitLoc, _bits);
    require(_subAmount <= amount, "BitUtils: subtraction overflow");

    return setBits(_data, _bitLoc, _bits, amount - _subAmount);
  }

  function addBits(
    uint256 _data,
    uint16 _bitLoc,
    uint16 _bits,
    uint256 _addAmount
  ) internal pure checkBitInputs(_bitLoc, _bits) returns (uint256) {
    uint256 amount = extractBits(_data, _bitLoc, _bits);
    uint256 bitMask = (uint256(1) << _bits) - 1;
    require(bitMask >= _addAmount, "BitUtils: addAmount input overflow");

    uint256 result = (amount + _addAmount) & bitMask;
    require(result >= amount, "BitUtils: addition overflow");

    return setBits(_data, _bitLoc, _bits, result);
  }

  // function setBits(
  //   uint256 _data,
  //   uint16 _bitLoc,
  //   uint16 _bits,
  //   uint256 _setData
  // ) internal pure checkBitInputs(_bitLoc, _bits) returns (uint256) {
  //   // Ex. [0000 0001 << 3] -> [0000 1000 - 1] -> 0000 0111
  //   uint256 ones = (uint256(1) << _bits) - 1;

  //   // Ex. [0000 0111 << 4] -> [0111 0000 XOR 1111 1111] -> 1000 1111
  //   uint256 bitMask = (ones << _bitLoc) ^ _ALLONES;

  //   // Ex. [x011 xxxx AND 1000 1111] -> [x000 xxxx OR 0101 0000] -> x101 xxxx
  //   return (_data & bitMask) | ((_setData & ones) << _bitLoc);
  // }

  // function addBits(
  //   uint256 _data,
  //   uint16 _bitLoc,
  //   uint16 _bits,
  //   uint256 _addAmount
  // ) internal pure checkBitInputs(_bitLoc, _bits) returns (uint256) {
  //   uint256 amount = extractBits(_data, _bitLoc, _bits);
  //   uint256 bitMask = (uint256(1) << _bits) - 1;

  //   uint256 result = (amount + (_addAmount & bitMask)) & bitMask;
  //   require(result >= amount, "BitUtils: addition overflow");

  //   return setBits(_data, _bitLoc, _bits, result);
  // }
}


// File contracts/shared/libraries/GameplayDataTools.sol

pragma solidity 0.6.6;

library GameplayDataTools {
  // LastEnergy Amount 8
  // LastEnergy Regenerated Time 32
  // Resource Amount 1 10
  // Resource Amount 2 10
  // Resource Amount 3 10
  // Resource Amount 4 10
  // Resource Amount 5 10
  // Resource Amount 6 10
  // Resource Amount 7 10
  // Resource Amount 8 10
  // Resource Amount 9 10
  // Resource Amount 10 10
  // Resource Amount 11 10
  // Resource Amount 12 10
  // Resource Amount 13 10
  // Resource Amount 14 10
  // Resource Amount 15 10
  // Resource Amount 16 10
  // Reserved 56

  uint16 private constant _MAX_LENGTH = 256;

  uint16 private constant _LASTENERGY_AMOUNT_BIT_LOC = 248;
  uint16 private constant _LASTENERGY_AMOUNT_BITS = 8;

  uint16 private constant _LASTENERGY_REGEN_TIME_BIT_LOC = 216;
  uint16 private constant _LASTENERGY_REGEN_TIME_BITS = 32;

  uint16 private constant _RESC_AMOUNT_BIT_START_LOC = 206;
  uint16 private constant _RESC_AMOUNT_BITS = 10;
  uint16 private constant _RESC_SLOTS = 16;

  uint16 private constant _RESERVED_BIT_LOC = 0;
  uint16 private constant _RESERVED_BITS = 56;

  modifier notExceedSlotAmount(uint16 _slot, uint16 _slotAmount) {
    require(_slot < _RESC_SLOTS, "GamePlayDataTools: Invalid slot");
    _;
  }

  function getLastEnergyAmount(uint256 _gamePlayData) internal pure returns (uint256) {
    return BitUtils.extractBits(_gamePlayData, _LASTENERGY_AMOUNT_BIT_LOC, _LASTENERGY_AMOUNT_BITS);
  }

  function getLastEnergyRegenTime(uint256 _gamePlayData) internal pure returns (uint256) {
    return BitUtils.extractBits(_gamePlayData, _LASTENERGY_REGEN_TIME_BIT_LOC, _LASTENERGY_REGEN_TIME_BITS);
  }

  function getResourceAmountBySlot(uint256 _gamePlayData, uint16 _slot)
    internal
    pure
    notExceedSlotAmount(_slot, _RESC_SLOTS)
    returns (uint256)
  {
    uint16 rescAmountBitLoc = _RESC_AMOUNT_BIT_START_LOC - (_slot * _RESC_AMOUNT_BITS);
    return BitUtils.extractBits(_gamePlayData, rescAmountBitLoc, _RESC_AMOUNT_BITS);
  }

  function setResourceAmountBySlot(
    uint256 _gamePlayData,
    uint16 _slot,
    uint256 _setData
  ) internal pure notExceedSlotAmount(_slot, _RESC_SLOTS) returns (uint256) {
    uint16 rescAmountBitLoc = _RESC_AMOUNT_BIT_START_LOC - (_slot * _RESC_AMOUNT_BITS);
    return BitUtils.setBits(_gamePlayData, rescAmountBitLoc, _RESC_AMOUNT_BITS, _setData);
  }

  function addResourceAmountBySlot(
    uint256 _gamePlayData,
    uint16 _slot,
    uint256 _amount
  ) internal pure notExceedSlotAmount(_slot, _RESC_SLOTS) returns (uint256) {
    uint16 rescAmountBitLoc = _RESC_AMOUNT_BIT_START_LOC - (_slot * _RESC_AMOUNT_BITS);
    return BitUtils.addBits(_gamePlayData, rescAmountBitLoc, _RESC_AMOUNT_BITS, _amount);
  }

  function decreaseResourceAmountBySlot(
    uint256 _gamePlayData,
    uint16 _slot,
    uint256 _amount
  ) internal pure notExceedSlotAmount(_slot, _RESC_SLOTS) returns (uint256) {
    uint16 rescAmountBitLoc = _RESC_AMOUNT_BIT_START_LOC - (_slot * _RESC_AMOUNT_BITS);
    return BitUtils.subBits(_gamePlayData, rescAmountBitLoc, _RESC_AMOUNT_BITS, _amount);
  }

  function getReserved(uint256 _gamePlayData) internal pure returns (uint256) {
    return BitUtils.extractBits(_gamePlayData, _RESERVED_BIT_LOC, _RESERVED_BITS);
  }
}


// File contracts/shared/libraries/SafeMath.sol

pragma solidity 0.6.6;

library SafeMath {
  function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    uint256 c = a + b;
    if (c < a) return (false, 0);
    return (true, c);
  }

  function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    if (b > a) return (false, 0);
    return (true, a - b);
  }

  function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    if (a == 0) return (true, 0);
    uint256 c = a * b;
    if (c / a != b) return (false, 0);
    return (true, c);
  }

  function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    if (b == 0) return (false, 0);
    return (true, a / b);
  }

  function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    if (b == 0) return (false, 0);
    return (true, a % b);
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    return a - b;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) return 0;
    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "SafeMath: division by zero");
    return a / b;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "SafeMath: modulo by zero");
    return a % b;
  }

  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    return a - b;
  }

  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    return a / b;
  }

  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    return a % b;
  }
}


// File contracts/GameplayData.sol

pragma solidity 0.6.6;



contract GameplayData is Initializable, AuthorizationUpgradeable, UUPSUpgradeable {
  using SafeMath for uint256;

  mapping(address => uint256) public usersHistory;

  function initialize(address _adminRouter) public initializer {
    adminRouter = IAdminProjectRouter(_adminRouter);
    PROJECT = "morning-moon";
  }

  modifier onlySuperAdminOrAdmin() {
    require(
      adminRouter.isSuperAdmin(msg.sender, PROJECT) || adminRouter.isAdmin(msg.sender, PROJECT),
      "Restricted only super admin or admin"
    );
    _;
  }

  function _authorizeUpgrade(address) internal override onlySuperAdmin {}

  function _validate(address _user, uint256 _history) internal view returns (bool) {
    return true;
    // some code for validate
  }

  function setUserHistory(address _user, uint256 _history) external onlySuperAdminOrAdmin {
    require(_validate(_user, _history), "The history is not valid");
    usersHistory[_user] = _history;
  }

  function getResourceAmountByType(address _user, uint256 _type) external view returns (uint256) {
    return GameplayDataTools.getResourceAmountBySlot(usersHistory[_user], uint16(_type));
  }

  // function batchSetUserHistory(address[] calldata _user, uint256[] calldata _history) external onlySuperAdmin {
  //   require(_user.length == _history.length, "The input arrays must have same length");
  //   for (uint256 i = 0; i < _user.length; i++) {
  //     if (!_validate(_user[i], _history[i])) {
  //       continue;
  //     }
  //     usersHistory[_user[i]] = _history[i];
  //   }
  // }

  function decreaseResource(
    address _user,
    uint256 _type,
    uint256 _amount
  ) external onlySuperAdminOrAdmin {
    usersHistory[_user] = GameplayDataTools.decreaseResourceAmountBySlot(usersHistory[_user], uint16(_type), _amount);
  }

  function increaseResource(
    address _user,
    uint256 _type,
    uint256 _amount
  ) external onlySuperAdminOrAdmin {
    uint256 _lastAmount = GameplayDataTools.getResourceAmountBySlot(usersHistory[_user], uint16(_type));
    if (_lastAmount.add(_amount) <= 999) {
      usersHistory[_user] = GameplayDataTools.addResourceAmountBySlot(usersHistory[_user], uint16(_type), _amount);
    } else {
      usersHistory[_user] = GameplayDataTools.setResourceAmountBySlot(usersHistory[_user], uint16(_type), 999);
    }
  }
}