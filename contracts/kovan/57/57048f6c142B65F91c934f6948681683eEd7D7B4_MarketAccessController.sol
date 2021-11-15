// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './interfaces/IManagedMarketAccessController.sol';
import './AccessController.sol';
import './AccessFlags.sol';

/// @dev Main registry of addresses part of or connected to the protocol, including permissioned roles. Also acts a proxy factory.
contract MarketAccessController is AccessController, IManagedMarketAccessController {
  string private _marketId;

  constructor(string memory marketId) AccessController(AccessFlags.SINGLETONS, AccessFlags.ROLES, AccessFlags.PROXIES) {
    _marketId = marketId;
  }

  function getMarketId() external view override returns (string memory) {
    return _marketId;
  }

  function setMarketId(string memory marketId) external override onlyAdmin {
    _marketId = marketId;
    emit MarketIdSet(marketId);
  }

  function getLendingPool() external view override returns (address) {
    return getAddress(AccessFlags.LENDING_POOL);
  }

  function getPriceOracle() external view override returns (address) {
    return getAddress(AccessFlags.PRICE_ORACLE);
  }

  function getLendingRateOracle() external view override returns (address) {
    return getAddress(AccessFlags.LENDING_RATE_ORACLE);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './IMarketAccessController.sol';

interface IManagedMarketAccessController is IMarketAccessController {
  event MarketIdSet(string newMarketId);

  function setMarketId(string memory marketId) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../dependencies/openzeppelin/contracts/Address.sol';
import '../tools/SafeOwnable.sol';
import '../tools/Errors.sol';
import '../tools/math/BitUtils.sol';
import '../tools/upgradeability/TransparentProxy.sol';
import '../tools/upgradeability/IProxy.sol';
import './interfaces/IAccessController.sol';
import './interfaces/IManagedAccessController.sol';
import './AccessCallHelper.sol';

contract AccessController is SafeOwnable, IManagedAccessController {
  using BitUtils for uint256;

  AccessCallHelper private _callHelper;

  mapping(uint256 => address) private _addresses;
  mapping(address => uint256) private _masks;
  mapping(uint256 => address[]) private _grantees;
  uint256 private _nonSingletons;
  uint256 private _singletons;
  uint256 private _proxies;

  address private _tempAdmin;
  uint256 private _expiresAt;

  uint8 private constant anyRoleBlocked = 1;
  uint8 private constant anyRoleEnabled = 2;
  uint8 private _anyRoleMode;

  constructor(
    uint256 singletons,
    uint256 nonSingletons,
    uint256 proxies
  ) {
    require(singletons & nonSingletons == 0, 'mixed types');
    require(singletons & proxies == proxies, 'all proxies must be singletons');
    _singletons = singletons;
    _nonSingletons = nonSingletons;
    _proxies = proxies;
    _callHelper = new AccessCallHelper(address(this));
  }

  function _onlyAdmin() private view {
    require(
      msg.sender == owner() || (msg.sender == _tempAdmin && _expiresAt > block.number),
      Errors.TXT_OWNABLE_CALLER_NOT_OWNER
    );
  }

  modifier onlyAdmin() {
    _onlyAdmin();
    _;
  }

  function queryAccessControlMask(address addr, uint256 filter) external view override returns (uint256 flags) {
    flags = _masks[addr];
    if (filter == 0) {
      return flags;
    }
    return flags & filter;
  }

  function setTemporaryAdmin(address admin, uint32 expiryBlocks) external override onlyOwner {
    if (_tempAdmin != address(0)) {
      _revokeAllRoles(_tempAdmin);
    }
    if (admin != address(0)) {
      _expiresAt = block.number + expiryBlocks;
    }
    _tempAdmin = admin;
    emit TemporaryAdminAssigned(_tempAdmin, _expiresAt);
  }

  function getTemporaryAdmin() external view override returns (address admin, uint256 expiresAtBlock) {
    if (admin != address(0)) {
      return (_tempAdmin, _expiresAt);
    }
    return (address(0), 0);
  }

  /// @dev Renouncement has no time limit and can be done either by the temporary admin at any time, or by anyone after the expiry.
  function renounceTemporaryAdmin() external override {
    if (_tempAdmin == address(0)) {
      return;
    }
    if (msg.sender != _tempAdmin && _expiresAt > block.number) {
      return;
    }
    _revokeAllRoles(_tempAdmin);
    _tempAdmin = address(0);
    emit TemporaryAdminAssigned(address(0), 0);
  }

  function setAnyRoleMode(bool blockOrEnable) external onlyAdmin {
    require(_anyRoleMode != anyRoleBlocked);
    if (blockOrEnable) {
      _anyRoleMode = anyRoleEnabled;
      emit AnyRoleModeEnabled();
    } else {
      _anyRoleMode = anyRoleBlocked;
      emit AnyRoleModeBlocked();
    }
  }

  function grantRoles(address addr, uint256 flags) external onlyAdmin returns (uint256) {
    require(_singletons & flags == 0, 'singleton should use setAddress');
    return _grantRoles(addr, flags);
  }

  function grantAnyRoles(address addr, uint256 flags) external onlyAdmin returns (uint256) {
    require(_anyRoleMode == anyRoleEnabled);
    return _grantRoles(addr, flags);
  }

  function _grantRoles(address addr, uint256 flags) private returns (uint256) {
    uint256 m = _masks[addr];
    flags &= ~m;
    if (flags == 0) {
      return m;
    }

    _nonSingletons |= flags & ~_singletons;

    m |= flags;
    _masks[addr] = m;

    for (uint8 i = 0; i <= 255; i++) {
      uint256 mask = uint256(1) << i;
      if (mask & flags == 0) {
        if (mask > flags) {
          break;
        }
        continue;
      }
      address[] storage grantees = _grantees[mask];
      if (grantees.length == 0 || grantees[grantees.length - 1] != addr) {
        grantees.push(addr);
      }
    }

    emit RolesUpdated(addr, m);
    return m;
  }

  function revokeRoles(address addr, uint256 flags) external onlyAdmin returns (uint256) {
    require(_singletons & flags == 0, 'singleton should use setAddress');

    return _revokeRoles(addr, flags);
  }

  function revokeAllRoles(address addr) external onlyAdmin returns (uint256) {
    return _revokeAllRoles(addr);
  }

  function _revokeAllRoles(address addr) private returns (uint256) {
    uint256 m = _masks[addr];
    if (m == 0) {
      return 0;
    }
    delete (_masks[addr]);
    emit RolesUpdated(addr, 0);

    uint256 flags = m & _singletons;
    if (flags == 0) {
      return m;
    }

    for (uint8 i = 0; i <= 255; i++) {
      uint256 mask = uint256(1) << i;
      if (mask & flags == 0) {
        if (mask > flags) {
          break;
        }
        continue;
      }
      if (_addresses[mask] == addr) {
        delete (_addresses[mask]);
      }
    }
    return m;
  }

  function _revokeRoles(address addr, uint256 flags) private returns (uint256) {
    uint256 m = _masks[addr];
    if (m & flags != 0) {
      m &= ~flags;
      _masks[addr] = m;
      emit RolesUpdated(addr, m);
    }
    return m;
  }

  function revokeRolesFromAll(uint256 flags, uint256 limit) external onlyAdmin returns (bool all) {
    all = true;

    for (uint8 i = 0; i <= 255; i++) {
      uint256 mask = uint256(1) << i;
      if (mask & flags == 0) {
        if (mask > flags) {
          break;
        }
        continue;
      }
      if (mask & _singletons != 0 && _addresses[mask] != address(0)) {
        delete (_addresses[mask]);
        emit AddressSet(mask, address(0), _proxies & mask != 0);
      }

      if (!all) {
        continue;
      }

      address[] storage grantees = _grantees[mask];
      for (uint256 j = grantees.length; j > 0; ) {
        j--;
        if (limit == 0) {
          all = false;
          break;
        }
        limit--;
        _revokeRoles(grantees[j], mask);
        grantees.pop();
      }
    }
    return all;
  }

  function roleGrantees(uint256 id) external view returns (address[] memory addrList) {
    require(id.isPowerOf2nz(), 'only one role is allowed');

    if (_singletons & id == 0) {
      return _grantees[id];
    }

    address singleton = _addresses[id];
    if (singleton == address(0)) {
      return _grantees[id];
    }

    address[] storage grantees = _grantees[id];

    addrList = new address[](1 + grantees.length);
    addrList[0] = singleton;
    for (uint256 i = 1; i < addrList.length; i++) {
      addrList[i] = grantees[i - 1];
    }
    return addrList;
  }

  function roleActiveGrantees(uint256 id) external view returns (address[] memory addrList, uint256 count) {
    require(id.isPowerOf2nz(), 'only one role is allowed');

    address addr;
    if (_singletons & id != 0) {
      addr = _addresses[id];
    }

    address[] storage grantees = _grantees[id];

    if (addr == address(0)) {
      addrList = new address[](grantees.length);
    } else {
      addrList = new address[](1 + grantees.length);
      addrList[0] = addr;
      count++;
    }

    for (uint256 i = 0; i < grantees.length; i++) {
      addr = grantees[i];
      if (_masks[addr] & id != 0) {
        addrList[count] = addr;
        count++;
      }
    }
    return (addrList, count);
  }

  /**
   * @dev Sets a sigleton address, replaces previous value
   * IMPORTANT Use this function carefully, as it does a hard replacement
   * @param id The id
   * @param newAddress The address to set
   */
  function setAddress(uint256 id, address newAddress) public override onlyAdmin {
    require(_proxies & id == 0, 'setAddressAsProxy is required');
    _internalSetAddress(id, newAddress);
    emit AddressSet(id, newAddress, false);
  }

  function _internalSetAddress(uint256 id, address newAddress) private {
    require(id.isPowerOf2nz(), 'invalid singleton id');
    if (_singletons & id == 0) {
      require(_nonSingletons & id == 0, 'id is not a singleton');
      _singletons |= id;
    }

    address prev = _addresses[id];
    if (prev != address(0)) {
      _masks[prev] = _masks[prev] & ~id;
    }
    if (newAddress != address(0)) {
      require(Address.isContract(newAddress), 'must be contract');
      _masks[newAddress] = _masks[newAddress] | id;
    }
    _addresses[id] = newAddress;
  }

  /**
   * @dev Returns a singleton address by id
   * @return addr The address
   */
  function getAddress(uint256 id) public view override returns (address addr) {
    addr = _addresses[id];

    if (addr == address(0)) {
      require(id.isPowerOf2nz(), 'invalid singleton id');
      require((_singletons & id != 0) || (_nonSingletons & id == 0), 'id is not a singleton');
    }
    return addr;
  }

  function isAddress(uint256 id, address addr) public view returns (bool) {
    // require(id.isPowerOf2nz(), 'only singleton id is accepted');
    return _masks[addr] & id != 0;
  }

  function markProxies(uint256 id) external onlyAdmin {
    _proxies |= id;
  }

  function unmarkProxies(uint256 id) external onlyAdmin {
    _proxies &= ~id;
  }

  /**
   * @dev General function to update the implementation of a proxy registered with
   * certain `id`. If there is no proxy registered, it will instantiate one and
   * set as implementation the `implAddress`
   * @param id The id
   * @param implAddress The address of the new implementation
   */
  function setAddressAsProxy(uint256 id, address implAddress) public override onlyAdmin {
    _updateImpl(id, implAddress, abi.encodeWithSignature('initialize(address)', address(this)));
    emit AddressSet(id, implAddress, true);
  }

  function setAddressAsProxyWithInit(
    uint256 id,
    address implAddress,
    bytes calldata params
  ) public override onlyAdmin {
    _updateImpl(id, implAddress, params);
    emit AddressSet(id, implAddress, true);
  }

  /**
   * @dev Internal function to update the implementation of a specific proxied component of the protocol
   * - If there is no proxy registered in the given `id`, it creates the proxy setting `newAdress`
   *   as implementation and calls a function on the proxy.
   * - If there is already a proxy registered, it updates the implementation to `newAddress` by
   *   the upgradeToAndCall() of the proxy.
   * @param id The id of the proxy to be updated
   * @param newAddress The address of the new implementation
   * @param params The address of the new implementation
   **/
  function _updateImpl(
    uint256 id,
    address newAddress,
    bytes memory params
  ) private {
    require(id.isPowerOf2nz(), 'invalid singleton id');
    address payable proxyAddress = payable(getAddress(id));

    if (proxyAddress != address(0)) {
      require(_proxies & id != 0, 'use of setAddress is required');
      TransparentProxy(proxyAddress).upgradeToAndCall(newAddress, params);
      return;
    }

    proxyAddress = payable(address(_createProxy(address(this), newAddress, params)));
    _internalSetAddress(id, proxyAddress);
    _proxies |= id;
    emit ProxyCreated(id, proxyAddress);
  }

  function _createProxy(
    address adminAddress,
    address implAddress,
    bytes memory params
  ) private returns (TransparentProxy) {
    TransparentProxy proxy = new TransparentProxy(adminAddress, implAddress, params);
    return proxy;
  }

  function createProxy(
    address adminAddress,
    address implAddress,
    bytes calldata params
  ) public override returns (IProxy) {
    return _createProxy(adminAddress, implAddress, params);
  }

  function directCallWithRoles(
    uint256 flags,
    address addr,
    bytes calldata data
  ) external override onlyAdmin returns (bytes memory result) {
    require(addr != address(this) && Address.isContract(addr), 'must be another contract');

    (bool restoreMask, uint256 oldMask) = _beforeDirectCallWithRoles(flags, addr);

    result = Address.functionCall(addr, data);

    if (restoreMask) {
      _afterDirectCallWithRoles(addr, oldMask);
    }
    return result;
  }

  function _beforeDirectCallWithRoles(uint256 flags, address addr) private returns (bool restoreMask, uint256 oldMask) {
    if (_singletons & flags != 0) {
      require(_anyRoleMode == anyRoleEnabled, 'singleton should use setAddress');
      _nonSingletons |= flags & ~_singletons;
    } else {
      _nonSingletons |= flags;
    }

    oldMask = _masks[addr];
    if (flags & ~oldMask != 0) {
      _masks[addr] = oldMask | flags;
      emit RolesUpdated(addr, oldMask | flags);
      return (true, oldMask);
    }
    return (false, oldMask);
  }

  function _afterDirectCallWithRoles(address addr, uint256 oldMask) private {
    _masks[addr] = oldMask;
    emit RolesUpdated(addr, oldMask);
  }

  function callWithRoles(CallParams[] calldata params) external override onlyAdmin returns (bytes[] memory results) {
    address callHelper = address(_callHelper);

    results = new bytes[](params.length);

    for (uint256 i = 0; i < params.length; i++) {
      (bool restoreMask, ) = _beforeDirectCallWithRoles(params[i].accessFlags, callHelper);

      address callAddr = params[i].callAddr == address(0) ? getAddress(params[i].callFlag) : params[i].callAddr;
      results[i] = AccessCallHelper(callHelper).doCall(callAddr, params[i].callData);

      if (restoreMask) {
        _afterDirectCallWithRoles(callHelper, 0); // call helper can't have any default roles
      }
    }
    return results;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

library AccessFlags {
  // roles that can be assigned to multiple addresses - use range [0..15]
  uint256 public constant EMERGENCY_ADMIN = 1 << 0;
  uint256 public constant POOL_ADMIN = 1 << 1;
  uint256 public constant TREASURY_ADMIN = 1 << 2;
  uint256 public constant REWARD_CONFIG_ADMIN = 1 << 3;
  uint256 public constant REWARD_RATE_ADMIN = 1 << 4;
  uint256 public constant STAKE_ADMIN = 1 << 5;
  uint256 public constant REFERRAL_ADMIN = 1 << 6;
  uint256 public constant LENDING_RATE_ADMIN = 1 << 7;
  uint256 public constant SWEEP_ADMIN = 1 << 8;
  uint256 public constant ORACLE_ADMIN = 1 << 9;

  uint256 public constant ROLES = (uint256(1) << 16) - 1;

  // singletons - use range [16..64] - can ONLY be assigned to a single address
  uint256 public constant SINGLETONS = ((uint256(1) << 64) - 1) & ~ROLES;

  // proxied singletons
  uint256 public constant LENDING_POOL = 1 << 16;
  uint256 public constant LENDING_POOL_CONFIGURATOR = 1 << 17;
  uint256 public constant LIQUIDITY_CONTROLLER = 1 << 18;
  uint256 public constant TREASURY = 1 << 19;
  uint256 public constant REWARD_TOKEN = 1 << 20;
  uint256 public constant REWARD_STAKE_TOKEN = 1 << 21;
  uint256 public constant REWARD_CONTROLLER = 1 << 22;
  uint256 public constant REWARD_CONFIGURATOR = 1 << 23;
  uint256 public constant STAKE_CONFIGURATOR = 1 << 24;
  uint256 public constant REFERRAL_REGISTRY = 1 << 25;

  uint256 public constant PROXIES = ((uint256(1) << 26) - 1) & ~ROLES;

  // non-proxied singletons, numbered down from 31 (as JS has problems with bitmasks over 31 bits)
  uint256 public constant WETH_GATEWAY = 1 << 27;
  uint256 public constant DATA_HELPER = 1 << 28;
  uint256 public constant PRICE_ORACLE = 1 << 29;
  uint256 public constant LENDING_RATE_ORACLE = 1 << 30;

  // any other roles - use range [64..]
  // these roles can be assigned to multiple addresses

  uint256 public constant TRUSTED_FLASHLOAN = 1 << 66;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './IAccessController.sol';

/// @dev Main registry of addresses part of or connected to the protocol, including permissioned roles. Also acts a proxy factory.
interface IMarketAccessController is IAccessController {
  function getMarketId() external view returns (string memory);

  function getLendingPool() external view returns (address);

  function getPriceOracle() external view returns (address);

  function getLendingRateOracle() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './IRemoteAccessBitmask.sol';
import '../../tools/upgradeability/IProxy.sol';

/// @dev Main registry of permissions and addresses
interface IAccessController is IRemoteAccessBitmask {
  function getAddress(uint256 id) external view returns (address);

  function createProxy(
    address admin,
    address impl,
    bytes calldata params
  ) external returns (IProxy);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IRemoteAccessBitmask {
  /**
   * @dev Returns access flags granted to the given address and limited by the filterMask. filterMask == 0 has a special meaning.
   * @param addr an to get access perfmissions for
   * @param filterMask limits a subset of flags to be checked.
   * NB! When filterMask == 0 then zero is returned no flags granted, or an unspecified non-zero value otherwise.
   * @return Access flags currently granted
   */
  function queryAccessControlMask(address addr, uint256 filterMask) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IProxy {
  function upgradeToAndCall(address newImplementation, bytes calldata data) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// solhint-disable no-inline-assembly, avoid-low-level-calls

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

  bytes32 private constant accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

  function isExternallyOwned(address account) internal view returns (bool) {
    // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
    // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
    // for accounts without code, i.e. `keccak256('')`
    bytes32 codehash;
    uint256 size;
    assembly {
      codehash := extcodehash(account)
      size := extcodesize(account)
    }
    return codehash == accountHash && size == 0;
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
   * taken to not create reentrancy vulnerabilities. Consider using {ReentrancyGuard}.
   */
  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, 'Address: insufficient balance');

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{value: amount}('');
    require(success, 'Address: unable to send value, recipient may have reverted');
  }

  /**
   * @dev Performs a Solidity function call using a low level `call`. A
   * plain `call` is an unsafe replacement for a function call: use this
   * function instead.
   *
   * If `target` reverts with a revert reason, it is bubbled up by this
   * function (like regular Solidity function calls).
   *
   * Returns the raw returned data.
   *
   * Requirements:
   *
   * - `target` must be a contract.
   * - calling `target` with `data` must not revert.
   *
   * _Available since v3.1._
   */
  function functionCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionCall(target, data, 'Address: low-level call failed');
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
    return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
    require(address(this).balance >= value, 'Address: insufficient balance for call');
    require(isContract(target), 'Address: call to non-contract');

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
    return functionStaticCall(target, data, 'Address: low-level static call failed');
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
    require(isContract(target), 'Address: static call to non-contract');

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
    return functionDelegateCall(target, data, 'Address: low-level delegate call failed');
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
    require(isContract(target), 'Address: delegate call to non-contract');

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

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * Ownership is transferred in 2 phases: current owner calls {transferOwnership}
 * then the new owner calls {acceptOwnership}.
 * The last owner can recover ownership with {recoverOwnership} before {acceptOwnership} is called by the new owner.
 *
 * When ownership transfer was initiated, this module behaves like there is no owner, until
 * either acceptOwnership() or recoverOwnership() is called.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract SafeOwnable {
  address private _lastOwner;
  address private _activeOwner;
  address private _pendingOwner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event OwnershipTransferring(address indexed previousOwner, address indexed pendingOwner);

  /// @dev Initializes the contract setting the deployer as the initial owner.
  constructor() {
    _activeOwner = msg.sender;
    _pendingOwner = msg.sender;
    emit OwnershipTransferred(address(0), msg.sender);
  }

  /// @dev Returns active owner
  function owner() public view returns (address) {
    return _activeOwner;
  }

  function owners()
    public
    view
    returns (
      address lastOwner,
      address activeOwner,
      address pendingOwner
    )
  {
    return (_lastOwner, _activeOwner, _pendingOwner);
  }

  /// @dev Reverts if called by any account other than the owner.
  /// Will also revert after transferOwnership() when neither acceptOwnership() nor recoverOwnership() was called.
  modifier onlyOwner() {
    require(
      _activeOwner == msg.sender,
      _pendingOwner == msg.sender ? 'Ownable: caller is not the owner (pending)' : 'Ownable: caller is not the owner'
    );
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() external onlyOwner {
    emit OwnershipTransferred(_activeOwner, address(0));
    _activeOwner = address(0);
    _pendingOwner = address(0);
    _lastOwner = address(0);
  }

  /// @dev Initiates ownership transfer of the contract to a new account `newOwner`.
  /// Can only be called by the current owner. The new owner must call acceptOwnership() to get the ownership.
  function transferOwnership(address newOwner) external onlyOwner {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferring(msg.sender, newOwner);
    _pendingOwner = newOwner;
    _lastOwner = _activeOwner;
    _activeOwner = address(0);
  }

  /// @dev Accepts ownership of this contract. Can only be called by the new owner set with transferOwnership().
  function acceptOwnership() external {
    require(_activeOwner == address(0) && _pendingOwner == msg.sender, 'SafeOwnable: caller is not the pending owner');

    emit OwnershipTransferred(_lastOwner, msg.sender);
    _lastOwner = address(0);
    _activeOwner = msg.sender;
  }

  /// @dev Recovers ownership of this contract to the last owner after transferOwnership(),
  /// unless acceptOwnership() was already called by the new owner.
  function recoverOwnership() external {
    require(_activeOwner == address(0) && _lastOwner == msg.sender, 'SafeOwnable: caller can not recover ownership');
    emit OwnershipTransferring(msg.sender, address(0));
    emit OwnershipTransferred(msg.sender, msg.sender);
    _pendingOwner = msg.sender;
    _lastOwner = address(0);
    _activeOwner = msg.sender;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

/**
 * @title Errors library
 * @notice Defines the error messages emitted by the different contracts
 * @dev Error messages prefix glossary:
 *  - VL = ValidationLogic
 *  - MATH = Math libraries
 *  - CT = Common errors between tokens (DepositToken, VariableDebtToken and StableDebtToken)
 *  - AT = DepositToken
 *  - SDT = StableDebtToken
 *  - VDT = VariableDebtToken
 *  - LP = LendingPool
 *  - LPAPR = AddressesProviderRegistry
 *  - LPC = LendingPoolConfiguration
 *  - RL = ReserveLogic
 *  - LPCM = LendingPoolExtension
 *  - ST = Stake
 */
library Errors {
  //contract specific errors
  string public constant VL_INVALID_AMOUNT = '1'; // Amount must be greater than 0
  string public constant VL_NO_ACTIVE_RESERVE = '2'; // Action requires an active reserve
  string public constant VL_RESERVE_FROZEN = '3'; // Action cannot be performed because the reserve is frozen
  string public constant VL_UNKNOWN_RESERVE = '4'; // Action requires an active reserve
  string public constant VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE = '5'; // User cannot withdraw more than the available balance (above min limit)
  string public constant VL_TRANSFER_NOT_ALLOWED = '6'; // Transfer cannot be allowed.
  string public constant VL_BORROWING_NOT_ENABLED = '7'; // Borrowing is not enabled
  string public constant VL_INVALID_INTEREST_RATE_MODE_SELECTED = '8'; // Invalid interest rate mode selected
  string public constant VL_COLLATERAL_BALANCE_IS_0 = '9'; // The collateral balance is 0
  string public constant VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD = '10'; // Health factor is lesser than the liquidation threshold
  string public constant VL_COLLATERAL_CANNOT_COVER_NEW_BORROW = '11'; // There is not enough collateral to cover a new borrow
  string public constant VL_STABLE_BORROWING_NOT_ENABLED = '12'; // stable borrowing not enabled
  string public constant VL_COLLATERAL_SAME_AS_BORROWING_CURRENCY = '13'; // collateral is (mostly) the same currency that is being borrowed
  string public constant VL_AMOUNT_BIGGER_THAN_MAX_LOAN_SIZE_STABLE = '14'; // The requested amount is exceeds max size of a stable loan
  string public constant VL_NO_DEBT_OF_SELECTED_TYPE = '15'; // to repay a debt, user needs to specify a correct debt type (variable or stable)
  string public constant VL_NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF = '16'; // To repay on behalf of an user an explicit amount to repay is needed
  string public constant VL_NO_STABLE_RATE_LOAN_IN_RESERVE = '17'; // User does not have a stable rate loan in progress on this reserve
  string public constant VL_NO_VARIABLE_RATE_LOAN_IN_RESERVE = '18'; // User does not have a variable rate loan in progress on this reserve
  string public constant VL_UNDERLYING_BALANCE_NOT_GREATER_THAN_0 = '19'; // The collateral balance needs to be greater than 0
  string public constant VL_DEPOSIT_ALREADY_IN_USE = '20'; // User deposit is already being used as collateral
  string public constant VL_RESERVE_MUST_BE_COLLATERAL = '21'; // This reserve must be enabled as collateral
  string public constant LP_INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET = '22'; // Interest rate rebalance conditions were not met
  string public constant AT_OVERDRAFT_DISABLED = '23'; // User doesn't accept allocation of overdraft
  string public constant VL_INVALID_SUB_BALANCE_ARGS = '24';
  string public constant AT_INVALID_SLASH_DESTINATION = '25';

  string public constant LP_CALLER_NOT_LENDING_POOL_CONFIGURATOR = '27'; // The caller of the function is not the lending pool configurator

  string public constant LENDING_POOL_REQUIRED = '28'; // The caller of this function must be a lending pool
  string public constant CALLER_NOT_LENDING_POOL = '29'; // The caller of this function must be a lending pool
  string public constant AT_SUB_BALANCE_RESTIRCTED_FUNCTION = '30'; // The caller of this function must be a lending pool or a sub-balance operator

  string public constant RL_RESERVE_ALREADY_INITIALIZED = '32'; // Reserve has already been initialized
  string public constant CALLER_NOT_POOL_ADMIN = '33'; // The caller must be the pool admin
  string public constant LPC_RESERVE_LIQUIDITY_NOT_0 = '34'; // The liquidity of the reserve needs to be 0

  string public constant LPAPR_PROVIDER_NOT_REGISTERED = '41'; // Provider is not registered
  string public constant LPCM_HEALTH_FACTOR_NOT_BELOW_THRESHOLD = '42'; // Health factor is not below the threshold
  string public constant LPCM_COLLATERAL_CANNOT_BE_LIQUIDATED = '43'; // The collateral chosen cannot be liquidated
  string public constant LPCM_SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = '44'; // User did not borrow the specified currency
  string public constant LPCM_NOT_ENOUGH_LIQUIDITY_TO_LIQUIDATE = '45'; // There isn't enough liquidity available to liquidate

  string public constant MATH_MULTIPLICATION_OVERFLOW = '48';
  string public constant MATH_ADDITION_OVERFLOW = '49';
  string public constant MATH_DIVISION_BY_ZERO = '50';
  string public constant RL_LIQUIDITY_INDEX_OVERFLOW = '51'; //  Liquidity index overflows uint128
  string public constant RL_VARIABLE_BORROW_INDEX_OVERFLOW = '52'; //  Variable borrow index overflows uint128
  string public constant RL_LIQUIDITY_RATE_OVERFLOW = '53'; //  Liquidity rate overflows uint128
  string public constant RL_VARIABLE_BORROW_RATE_OVERFLOW = '54'; //  Variable borrow rate overflows uint128
  string public constant RL_STABLE_BORROW_RATE_OVERFLOW = '55'; //  Stable borrow rate overflows uint128
  string public constant CT_INVALID_MINT_AMOUNT = '56'; //invalid amount to mint
  string public constant CALLER_NOT_STAKE_ADMIN = '57';
  string public constant CT_INVALID_BURN_AMOUNT = '58'; //invalid amount to burn
  string public constant BORROW_ALLOWANCE_NOT_ENOUGH = '59'; // User borrows on behalf, but allowance are too small
  string public constant CALLER_NOT_LIQUIDITY_CONTROLLER = '60';
  string public constant CALLER_NOT_REF_ADMIN = '61';
  string public constant VL_INSUFFICIENT_REWARD_AVAILABLE = '62';
  string public constant LP_CALLER_MUST_BE_DEPOSIT_TOKEN = '63';
  string public constant LP_IS_PAUSED = '64'; // Pool is paused
  string public constant LP_NO_MORE_RESERVES_ALLOWED = '65';
  string public constant LP_INVALID_FLASH_LOAN_EXECUTOR_RETURN = '66';
  string public constant RC_INVALID_LTV = '67';
  string public constant RC_INVALID_LIQ_THRESHOLD = '68';
  string public constant RC_INVALID_LIQ_BONUS = '69';
  string public constant RC_INVALID_DECIMALS = '70';
  string public constant RC_INVALID_RESERVE_FACTOR = '71';
  string public constant LPAPR_INVALID_ADDRESSES_PROVIDER_ID = '72';
  string public constant VL_INCONSISTENT_FLASHLOAN_PARAMS = '73';
  string public constant VL_TREASURY_REQUIRED = '74';
  string public constant LPC_INVALID_CONFIGURATION = '75'; // Invalid risk parameters for the reserve
  string public constant CALLER_NOT_EMERGENCY_ADMIN = '76'; // The caller must be the emergency admin
  string public constant UL_INVALID_INDEX = '77';
  string public constant VL_CONTRACT_REQUIRED = '78';
  string public constant SDT_STABLE_DEBT_OVERFLOW = '79';
  string public constant SDT_BURN_EXCEEDS_BALANCE = '80';
  string public constant CALLER_NOT_REWARD_CONFIG_ADMIN = '81'; // The caller of this function must be a reward admin
  string public constant LP_INVALID_PERCENTAGE = '82'; // Percentage can't be more than 100%
  string public constant LP_IS_NOT_TRUSTED_FLASHLOAN = '83';
  string public constant CALLER_NOT_SWEEP_ADMIN = '84';
  string public constant LP_TOO_MANY_NESTED_CALLS = '85';
  string public constant LP_RESTRICTED_FEATURE = '86';
  string public constant LP_TOO_MANY_FLASHLOAN_CALLS = '87';
  string public constant RW_BASELINE_EXCEEDED = '88';
  string public constant CALLER_NOT_REWARD_RATE_ADMIN = '89';
  string public constant CALLER_NOT_REWARD_CONTROLLER = '90';
  string public constant RW_REWARD_PAUSED = '91';
  string public constant CALLER_NOT_TEAM_MANAGER = '92';
  string public constant STK_REDEEM_PAUSED = '93';
  string public constant STK_INSUFFICIENT_COOLDOWN = '94';
  string public constant STK_UNSTAKE_WINDOW_FINISHED = '95';
  string public constant STK_INVALID_BALANCE_ON_COOLDOWN = '96';
  string public constant STK_EXCESSIVE_SLASH_PCT = '97';
  string public constant STK_WRONG_COOLDOWN_OR_UNSTAKE = '98';
  string public constant STK_PAUSED = '99';

  string public constant TXT_OWNABLE_CALLER_NOT_OWNER = 'Ownable: caller is not the owner';
  string public constant TXT_CALLER_NOT_PROXY_OWNER = 'ProxyOwner: caller is not the owner';
  string public constant TXT_ACCESS_RESTRICTED = 'RESTRICTED';
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

library BitUtils {
  function isBit(uint256 v, uint8 index) internal pure returns (bool) {
    return (v >> index) & 1 != 0;
  }

  function nextPowerOf2(uint256 v) internal pure returns (uint256) {
    if (v == 0) {
      return 1;
    }
    v--;
    v |= v >> 1;
    v |= v >> 2;
    v |= v >> 4;
    v |= v >> 8;
    v |= v >> 16;
    v |= v >> 32;
    v |= v >> 64;
    v |= v >> 128;
    return v + 1;
  }

  function isPowerOf2(uint256 v) internal pure returns (bool) {
    return (v & (v - 1)) == 0;
  }

  function isPowerOf2nz(uint256 v) internal pure returns (bool) {
    return (v != 0) && (v & (v - 1) == 0);
  }

  function bitLength(uint256 v) internal pure returns (uint256 len) {
    if (v == 0) {
      return 0;
    }
    if (v > type(uint128).max) {
      v >>= 128;
      len += 128;
    }
    if (v > type(uint64).max) {
      v >>= 64;
      len += 64;
    }
    if (v > type(uint32).max) {
      v >>= 32;
      len += 32;
    }
    if (v > type(uint16).max) {
      v >>= 16;
      len += 16;
    }
    if (v > type(uint8).max) {
      v >>= 8;
      len += 8;
    }
    if (v > 15) {
      v >>= 4;
      len += 4;
    }
    if (v > 3) {
      v >>= 2;
      len += 2;
    }
    if (v > 1) {
      len += 1;
    }
    return len + 1;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../dependencies/openzeppelin/contracts/Address.sol';
import '../../dependencies/openzeppelin/upgradeability/BaseUpgradeabilityProxy.sol';
import './TransparentProxyBase.sol';

/// @dev This contract is a transparent upgradeability proxy with admin. The admin role is immutable.
contract TransparentProxy is TransparentProxyBase {
  constructor(
    address admin,
    address logic,
    bytes memory data
  ) TransparentProxyBase(admin) {
    _setImplementation(logic);
    if (data.length > 0) {
      Address.functionDelegateCall(logic, data);
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './IRemoteAccessBitmask.sol';
import './IAccessController.sol';

interface IManagedAccessController is IAccessController {
  function setTemporaryAdmin(address admin, uint32 expiryBlocks) external;

  function getTemporaryAdmin() external view returns (address admin, uint256 expiresAtBlock);

  function renounceTemporaryAdmin() external;

  function setAddress(uint256 id, address newAddress) external;

  function setAddressAsProxy(uint256 id, address impl) external;

  function setAddressAsProxyWithInit(
    uint256 id,
    address impl,
    bytes calldata initCall
  ) external;

  function directCallWithRoles(
    uint256 flags,
    address addr,
    bytes calldata data
  ) external returns (bytes memory result);

  struct CallParams {
    uint256 accessFlags;
    uint256 callFlag;
    address callAddr;
    bytes callData;
  }

  function callWithRoles(CallParams[] calldata params) external returns (bytes[] memory result);

  event ProxyCreated(uint256 indexed id, address indexed newAddress);
  event AddressSet(uint256 indexed id, address indexed newAddress, bool hasProxy);
  event RolesUpdated(address indexed addr, uint256 flags);
  event TemporaryAdminAssigned(address indexed admin, uint256 expiresAt);
  event AnyRoleModeEnabled();
  event AnyRoleModeBlocked();
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../dependencies/openzeppelin/contracts/Address.sol';
import '../tools/Errors.sol';

contract AccessCallHelper {
  address private _owner;

  constructor(address owner) {
    require(owner != address(0));
    _owner = owner;
  }

  function doCall(address callAddr, bytes calldata callData) external returns (bytes memory result) {
    require(msg.sender == _owner, Errors.TXT_OWNABLE_CALLER_NOT_OWNER);
    return Address.functionCall(callAddr, callData);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './Proxy.sol';
import '../contracts/Address.sol';

/**
 * @title BaseUpgradeabilityProxy
 * @dev This contract implements a proxy that allows to change the
 * implementation address to which it will delegate.
 * Such a change is called an implementation upgrade.
 */
contract BaseUpgradeabilityProxy is Proxy {
  /**
   * @dev Emitted when the implementation is upgraded.
   * @param implementation Address of the new implementation.
   */
  event Upgraded(address indexed implementation);

  /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  /**
   * @dev Returns the current implementation.
   * @return impl Address of the current implementation
   */
  function _implementation() internal view override returns (address impl) {
    bytes32 slot = IMPLEMENTATION_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      impl := sload(slot)
    }
  }

  /**
   * @dev Upgrades the proxy to a new implementation.
   * @param newImplementation Address of the new implementation.
   */
  function _upgradeTo(address newImplementation) internal {
    _setImplementation(newImplementation);
    emit Upgraded(newImplementation);
  }

  /**
   * @dev Sets the implementation address of the proxy.
   * @param newImplementation Address of the new implementation.
   */
  function _setImplementation(address newImplementation) internal {
    require(Address.isContract(newImplementation), 'Cannot set a proxy implementation to a non-contract address');

    bytes32 slot = IMPLEMENTATION_SLOT;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, newImplementation)
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../dependencies/openzeppelin/contracts/Address.sol';
import '../../dependencies/openzeppelin/upgradeability/BaseUpgradeabilityProxy.sol';
import './IProxy.sol';

/// @dev This contract is a transparent upgradeability proxy with admin. The admin role is immutable.
abstract contract TransparentProxyBase is BaseUpgradeabilityProxy, IProxy {
  bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

  constructor(address admin) {
    require(admin != address(0));
    assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1));
    assert(ADMIN_SLOT == bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1));

    bytes32 slot = ADMIN_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, admin)
    }
  }

  modifier ifAdmin() {
    if (msg.sender == _admin()) {
      _;
    } else {
      _fallback();
    }
  }

  function _admin() internal view returns (address impl) {
    bytes32 slot = ADMIN_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      impl := sload(slot)
    }
  }

  /// @return impl The address of the implementation.
  function implementation() external ifAdmin returns (address impl) {
    return _implementation();
  }

  /// @dev Upgrade the backing implementation of the proxy and call a function on it.
  function upgradeToAndCall(address logic, bytes calldata data) external payable override ifAdmin {
    _upgradeTo(logic);
    Address.functionDelegateCall(logic, data);
  }

  /// @dev Only fall back when the sender is not the admin.
  function _willFallback() internal virtual override {
    require(msg.sender != _admin(), 'Cannot call fallback function from the proxy admin');
    super._willFallback();
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

/**
 * @title Proxy
 * @dev Implements delegation of calls to other contracts, with proper
 * forwarding of return values and bubbling of failures.
 * It defines a fallback function that delegates all calls to the address
 * returned by the abstract _implementation() internal function.
 */
abstract contract Proxy {
  /**
   * @dev Fallback function.
   * Implemented entirely in `_fallback`.
   */
  fallback() external payable {
    _fallback();
  }

  receive() external payable {
    _fallback();
  }

  /**
   * @return The Address of the implementation.
   */
  function _implementation() internal view virtual returns (address);

  /**
   * @dev Delegates execution to an implementation contract.
   * This is a low level function that doesn't return to its internal call site.
   * It will return to the external caller whatever the implementation returns.
   * @param implementation Address to delegate.
   */
  function _delegate(address implementation) internal {
    // solhint-disable-next-line no-inline-assembly
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
   * @dev Function that is run as the first thing in the fallback function.
   * Can be redefined in derived contracts to add functionality.
   * Redefinitions must call super._willFallback().
   */
  function _willFallback() internal virtual {}

  /**
   * @dev fallback implementation.
   * Extracted to enable manual triggering.
   */
  function _fallback() internal {
    _willFallback();
    _delegate(_implementation());
  }
}

