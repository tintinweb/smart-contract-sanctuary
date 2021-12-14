/**
 *Submitted for verification at FtmScan.com on 2021-12-14
*/

// Dependency file: contracts/interfaces/IRegistry.sol

// SPDX-License-Identifier: Apache-2.0
// pragma solidity >=0.8.4 <0.9.0;

interface IRegistry {
  event Registered(bytes32 domain, bytes32 indexed name, address indexed addr);

  function isExistRecord(bytes32 domain, bytes32 name) external view returns (bool);

  function set(
    bytes32 domain,
    bytes32 name,
    address addr
  ) external returns (bool);

  function batchSet(
    bytes32[] calldata domains,
    bytes32[] calldata names,
    address[] calldata addrs
  ) external returns (bool);

  function getAddress(bytes32 domain, bytes32 name) external view returns (address);

  function getDomainAndName(address addr) external view returns (bytes32, bytes32);
}


// Dependency file: contracts/libraries/RegistryUser.sol

// pragma solidity >=0.8.4 <0.9.0;

// import 'contracts/interfaces/IRegistry.sol';

abstract contract RegistryUser {
  // Registry contract
  IRegistry internal _registry;

  // Active domain
  bytes32 internal _domain;

  // Initialized
  bool private _initialized = false;

  // Allow same domain calls
  modifier onlyAllowSameDomain(bytes32 name) {
    require(msg.sender == _registry.getAddress(_domain, name), 'UserRegistry: Only allow call from same domain');
    _;
  }

  // Allow cross domain call
  modifier onlyAllowCrossDomain(bytes32 fromDomain, bytes32 name) {
    require(
      msg.sender == _registry.getAddress(fromDomain, name),
      'UserRegistry: Only allow call from allowed cross domain'
    );
    _;
  }

  /*******************************************************
   * Internal section
   ********************************************************/

  // Constructing with registry address and its active domain
  function _registryUserInit(address registry_, bytes32 domain_) internal returns (bool) {
    require(!_initialized, "UserRegistry: It's only able to initialize once");
    _registry = IRegistry(registry_);
    _domain = domain_;
    _initialized = true;
    return true;
  }

  // Get address in the same domain
  function _getAddressSameDomain(bytes32 name) internal view returns (address) {
    return _registry.getAddress(_domain, name);
  }

  /*******************************************************
   * View section
   ********************************************************/

  // Return active domain
  function getDomain() external view returns (bytes32) {
    return _domain;
  }

  // Return registry address
  function getRegistry() external view returns (address) {
    return address(_registry);
  }
}


// Root file: contracts/infrastructure/Registry.sol

pragma solidity >=0.8.4 <0.9.0;

// import 'contracts/interfaces/IRegistry.sol';
// import 'contracts/libraries/RegistryUser.sol';

/**
 * DKDAO domain name system
 * Name: Registry
 * Domain: Infrastructure
 */
contract Registry is RegistryUser, IRegistry {
  // Mapping domain -> name -> address
  mapping(bytes32 => mapping(bytes32 => address)) private registered;

  // Mapping address -> bytes32 name
  mapping(address => bytes32) private revertedName;

  // Mapping address -> bytes32 domain
  mapping(address => bytes32) private revertedDomain;

  // Event when new address registered
  event RecordSet(bytes32 domain, bytes32 indexed name, address indexed addr);

  constructor() {
    // Set the operator
    _set('Infrastructure', 'Operator', msg.sender);
    _set('Infrastructure', 'Registry', address(this));
    _registryUserInit(address(this), 'Infrastructure');
  }

  /*******************************************************
   * Operator section
   ********************************************************/

  // Set a record
  function set(
    bytes32 domain,
    bytes32 name,
    address addr
  ) external override onlyAllowSameDomain('Operator') returns (bool) {
    return _set(domain, name, addr);
  }

  // Set many records at once
  function batchSet(
    bytes32[] calldata domains,
    bytes32[] calldata names,
    address[] calldata addrs
  ) external override onlyAllowSameDomain('Operator') returns (bool) {
    require(
      domains.length == names.length && names.length == addrs.length,
      'Registry: Number of records and addreses must be matched'
    );
    for (uint256 i = 0; i < names.length; i += 1) {
      require(_set(domains[i], names[i], addrs[i]), 'Registry: Unable to set records');
    }
    return true;
  }

  /*******************************************************
   * Private section
   ********************************************************/

  // Set record internally
  function _set(
    bytes32 domain,
    bytes32 name,
    address addr
  ) private returns (bool) {
    require(addr != address(0), "Registry: We don't allow zero address");
    registered[domain][name] = addr;
    revertedName[addr] = name;
    revertedDomain[addr] = domain;
    emit RecordSet(domain, name, addr);
    return true;
  }

  /*******************************************************
   * View section
   ********************************************************/

  // Check is record existed
  function isExistRecord(bytes32 domain, bytes32 name) external view override returns (bool) {
    return registered[domain][name] != address(0);
  }

  // Get address by name
  function getAddress(bytes32 domain, bytes32 name) external view override returns (address) {
    return registered[domain][name];
  }

  // Get name by address
  function getDomainAndName(address addr) external view override returns (bytes32, bytes32) {
    return (revertedDomain[addr], revertedName[addr]);
  }
}