pragma solidity ^0.4.24;

// File: node_modules/zos-lib/contracts/upgradeability/Proxy.sol

/**
 * @title Proxy
 * @dev Implements delegation of calls to other contracts, with proper
 * forwarding of return values and bubbling of failures.
 * It defines a fallback function that delegates all calls to the address
 * returned by the abstract _implementation() internal function.
 */
contract Proxy {
  /**
   * @dev Fallback function.
   * Implemented entirely in `_fallback`.
   */
  function () payable external {
    _fallback();
  }

  /**
   * @return The Address of the implementation.
   */
  function _implementation() internal view returns (address);

  /**
   * @dev Delegates execution to an implementation contract.
   * This is a low level function that doesn&#39;t return to its internal call site.
   * It will return to the external caller whatever the implementation returns.
   * @param implementation Address to delegate.
   */
  function _delegate(address implementation) internal {
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize)

      // Call the implementation.
      // out and outsize are 0 because we don&#39;t know the size yet.
      let result := delegatecall(gas, implementation, 0, calldatasize, 0, 0)

      // Copy the returned data.
      returndatacopy(0, 0, returndatasize)

      switch result
      // delegatecall returns 0 on error.
      case 0 { revert(0, returndatasize) }
      default { return(0, returndatasize) }
    }
  }

  /**
   * @dev Function that is run as the first thing in the fallback function.
   * Can be redefined in derived contracts to add functionality.
   * Redefinitions must call super._willFallback().
   */
  function _willFallback() internal {
  }

  /**
   * @dev fallback implementation.
   * Extracted to enable manual triggering.
   */
  function _fallback() internal {
    _willFallback();
    _delegate(_implementation());
  }
}

// File: openzeppelin-solidity/contracts/AddressUtils.sol

/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   * as the code is not actually created until after the constructor finishes.
   * @param addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

}

// File: node_modules/zos-lib/contracts/upgradeability/UpgradeabilityProxy.sol

/**
 * @title UpgradeabilityProxy
 * @dev This contract implements a proxy that allows to change the
 * implementation address to which it will delegate.
 * Such a change is called an implementation upgrade.
 */
contract UpgradeabilityProxy is Proxy {
  /**
   * @dev Emitted when the implementation is upgraded.
   * @param implementation Address of the new implementation.
   */
  event Upgraded(address implementation);

  /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "org.zeppelinos.proxy.implementation", and is
   * validated in the constructor.
   */
  bytes32 private constant IMPLEMENTATION_SLOT = 0x7050c9e0f4ca769c69bd3a8ef740bc37934f8e2c036e5a723fd8ee048ed3f8c3;

  /**
   * @dev Contract constructor.
   * @param _implementation Address of the initial implementation.
   */
  constructor(address _implementation) public {
    assert(IMPLEMENTATION_SLOT == keccak256("org.zeppelinos.proxy.implementation"));

    _setImplementation(_implementation);
  }

  /**
   * @dev Returns the current implementation.
   * @return Address of the current implementation
   */
  function _implementation() internal view returns (address impl) {
    bytes32 slot = IMPLEMENTATION_SLOT;
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
  function _setImplementation(address newImplementation) private {
    require(AddressUtils.isContract(newImplementation), "Cannot set a proxy implementation to a non-contract address");

    bytes32 slot = IMPLEMENTATION_SLOT;

    assembly {
      sstore(slot, newImplementation)
    }
  }
}

// File: node_modules/zos-lib/contracts/upgradeability/AdminUpgradeabilityProxy.sol

/**
 * @title AdminUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with an authorization
 * mechanism for administrative tasks.
 * All external functions in this contract must be guarded by the
 * `ifAdmin` modifier. See ethereum/solidity#3864 for a Solidity
 * feature proposal that would enable this to be done automatically.
 */
contract AdminUpgradeabilityProxy is UpgradeabilityProxy {
  /**
   * @dev Emitted when the administration has been transferred.
   * @param previousAdmin Address of the previous admin.
   * @param newAdmin Address of the new admin.
   */
  event AdminChanged(address previousAdmin, address newAdmin);

  /**
   * @dev Storage slot with the admin of the contract.
   * This is the keccak-256 hash of "org.zeppelinos.proxy.admin", and is
   * validated in the constructor.
   */
  bytes32 private constant ADMIN_SLOT = 0x10d6a54a4754c8869d6886b5f5d7fbfa5b4522237ea5c60d11bc4e7a1ff9390b;

  /**
   * @dev Modifier to check whether the `msg.sender` is the admin.
   * If it is, it will run the function. Otherwise, it will delegate the call
   * to the implementation.
   */
  modifier ifAdmin() {
    if (msg.sender == _admin()) {
      _;
    } else {
      _fallback();
    }
  }

  /**
   * Contract constructor.
   * It sets the `msg.sender` as the proxy administrator.
   * @param _implementation address of the initial implementation.
   */
  constructor(address _implementation) UpgradeabilityProxy(_implementation) public {
    assert(ADMIN_SLOT == keccak256("org.zeppelinos.proxy.admin"));

    _setAdmin(msg.sender);
  }

  /**
   * @return The address of the proxy admin.
   */
  function admin() external view ifAdmin returns (address) {
    return _admin();
  }

  /**
   * @return The address of the implementation.
   */
  function implementation() external view ifAdmin returns (address) {
    return _implementation();
  }

  /**
   * @dev Changes the admin of the proxy.
   * Only the current admin can call this function.
   * @param newAdmin Address to transfer proxy administration to.
   */
  function changeAdmin(address newAdmin) external ifAdmin {
    require(newAdmin != address(0), "Cannot change the admin of a proxy to the zero address");
    emit AdminChanged(_admin(), newAdmin);
    _setAdmin(newAdmin);
  }

  /**
   * @dev Upgrade the backing implementation of the proxy.
   * Only the admin can call this function.
   * @param newImplementation Address of the new implementation.
   */
  function upgradeTo(address newImplementation) external ifAdmin {
    _upgradeTo(newImplementation);
  }

  /**
   * @dev Upgrade the backing implementation of the proxy and call a function
   * on the new implementation.
   * This is useful to initialize the proxied contract.
   * @param newImplementation Address of the new implementation.
   * @param data Data to send as msg.data in the low level call.
   * It should include the signature and the parameters of the function to be
   * called, as described in
   * https://solidity.readthedocs.io/en/develop/abi-spec.html#function-selector-and-argument-encoding.
   */
  function upgradeToAndCall(address newImplementation, bytes data) payable external ifAdmin {
    _upgradeTo(newImplementation);
    require(address(this).call.value(msg.value)(data));
  }

  /**
   * @return The admin slot.
   */
  function _admin() internal view returns (address adm) {
    bytes32 slot = ADMIN_SLOT;
    assembly {
      adm := sload(slot)
    }
  }

  /**
   * @dev Sets the address of the proxy admin.
   * @param newAdmin Address of the new proxy admin.
   */
  function _setAdmin(address newAdmin) internal {
    bytes32 slot = ADMIN_SLOT;

    assembly {
      sstore(slot, newAdmin)
    }
  }

  /**
   * @dev Only fall back when the sender is not the admin.
   */
  function _willFallback() internal {
    require(msg.sender != _admin(), "Cannot call fallback function from the proxy admin");
    super._willFallback();
  }
}

// File: node_modules/zos-lib/contracts/upgradeability/UpgradeabilityProxyFactory.sol

/**
 * @title UpgradeabilityProxyFactory
 * @dev Factory to create upgradeability proxies.
 */
contract UpgradeabilityProxyFactory {
  /**
   * @dev Emitted when a new proxy is created.
   * @param proxy Address of the created proxy.
   */
  event ProxyCreated(address proxy);

  /**
   * @dev Creates an upgradeability proxy with an initial implementation.
   * @param admin Address of the proxy admin.
   * @param implementation Address of the initial implementation.
   * @return Address of the new proxy.
   */
  function createProxy(address admin, address implementation) public returns (AdminUpgradeabilityProxy) {
    AdminUpgradeabilityProxy proxy = _createProxy(implementation);
    proxy.changeAdmin(admin);
    return proxy;
  }

  /**
   * @dev Creates an upgradeability proxy with an initial implementation and calls it.
   * This is useful to initialize the proxied contract.
   * @param admin Address of the proxy admin.
   * @param implementation Address of the initial implementation.
   * @param data Data to send as msg.data in the low level call.
   * It should include the signature and the parameters of the function to be
   * called, as described in
   * https://solidity.readthedocs.io/en/develop/abi-spec.html#function-selector-and-argument-encoding.
   * @return Address of the new proxy.
   */
  function createProxyAndCall(address admin, address implementation, bytes data) public payable returns (AdminUpgradeabilityProxy) {
    AdminUpgradeabilityProxy proxy = _createProxy(implementation);
    proxy.changeAdmin(admin);
    require(address(proxy).call.value(msg.value)(data));
    return proxy;
  }

  /**
   * @dev Internal function to create an upgradeable proxy.
   * @param implementation Address of the initial implementation.
   * @return Address of the new proxy.
   */
  function _createProxy(address implementation) internal returns (AdminUpgradeabilityProxy) {
    AdminUpgradeabilityProxy proxy = new AdminUpgradeabilityProxy(implementation);
    emit ProxyCreated(proxy);
    return proxy;
  }
}

// File: node_modules/zos-lib/contracts/application/versioning/ImplementationProvider.sol

/**
 * @title ImplementationProvider
 * @dev Interface for providing implementation addresses for other contracts by name.
 */
interface ImplementationProvider {
  /**
   * @dev Abstract function to return the implementation address of a contract.
   * @param contractName Name of the contract.
   * @return Implementation address of the contract.
   */
  function getImplementation(string contractName) public view returns (address);
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: node_modules/zos-lib/contracts/application/BaseApp.sol

/**
 * @title BaseApp
 * @dev Abstract base contract for upgradeable applications.
 * It handles the creation and upgrading of proxies.
 */
contract BaseApp is Ownable {
  /// @dev Factory that creates proxies.
  UpgradeabilityProxyFactory public factory;

  /**
   * @dev Constructor function
   * @param _factory Proxy factory
   */
  constructor(UpgradeabilityProxyFactory _factory) public {
    require(address(_factory) != address(0), "Cannot set the proxy factory of an app to the zero address");
    factory = _factory;
  }

  /**
   * @dev Abstract function to return the implementation provider.
   * @return The implementation provider.
   */
  function getProvider() internal view returns (ImplementationProvider);

  /**
   * @dev Returns the implementation address for a given contract name, provided by the `ImplementationProvider`.
   * @param contractName Name of the contract.
   * @return Address where the contract is implemented.
   */
  function getImplementation(string contractName) public view returns (address) {
    return getProvider().getImplementation(contractName);
  }

  /**
   * @dev Creates a new proxy for the given contract.
   * @param contractName Name of the contract.
   * @return Address of the new proxy.
   */
  function create(string contractName) public returns (AdminUpgradeabilityProxy) {
    address implementation = getImplementation(contractName);
    return factory.createProxy(this, implementation);
  }

  /**
   * @dev Creates a new proxy for the given contract and forwards a function call to it.
   * This is useful to initialize the proxied contract.
   * @param contractName Name of the contract.
   * @param data Data to send as msg.data in the low level call.
   * It should include the signature and the parameters of the function to be
   * called, as described in
   * https://solidity.readthedocs.io/en/develop/abi-spec.html#function-selector-and-argument-encoding.
   * @return Address of the new proxy.
   */
   function createAndCall(string contractName, bytes data) payable public returns (AdminUpgradeabilityProxy) {
    address implementation = getImplementation(contractName);
    return factory.createProxyAndCall.value(msg.value)(this, implementation, data);
  }

  /**
   * @dev Upgrades a proxy to the newest implementation of a contract.
   * @param proxy Proxy to be upgraded.
   * @param contractName Name of the contract.
   */
  function upgrade(AdminUpgradeabilityProxy proxy, string contractName) public onlyOwner {
    address implementation = getImplementation(contractName);
    proxy.upgradeTo(implementation);
  }

  /**
   * @dev Upgrades a proxy to the newest implementation of a contract and forwards a function call to it.
   * This is useful to initialize the proxied contract.
   * @param proxy Proxy to be upgraded.
   * @param contractName Name of the contract.
   * @param data Data to send as msg.data in the low level call.
   * It should include the signature and the parameters of the function to be
   * called, as described in
   * https://solidity.readthedocs.io/en/develop/abi-spec.html#function-selector-and-argument-encoding.
   */
  function upgradeAndCall(AdminUpgradeabilityProxy proxy, string contractName, bytes data) payable public onlyOwner {
    address implementation = getImplementation(contractName);
    proxy.upgradeToAndCall.value(msg.value)(implementation, data);
  }

  /**
   * @dev Returns the current implementation of a proxy.
   * This is needed because only the proxy admin can query it.
   * @return The address of the current implementation of the proxy.
   */
  function getProxyImplementation(AdminUpgradeabilityProxy proxy) public view returns (address) {
    return proxy.implementation();
  }

  /**
   * @dev Returns the admin of a proxy.
   * Only the admin can query it.
   * @return The address of the current admin of the proxy.
   */
  function getProxyAdmin(AdminUpgradeabilityProxy proxy) public view returns (address) {
    return proxy.admin();
  }

  /**
   * @dev Changes the admin of a proxy.
   * @param proxy Proxy to change admin.
   * @param newAdmin Address to transfer proxy administration to.
   */
  function changeProxyAdmin(AdminUpgradeabilityProxy proxy, address newAdmin) public onlyOwner {
    proxy.changeAdmin(newAdmin);
  }
}

// File: node_modules/zos-lib/contracts/application/versioning/Package.sol

/**
 * @title Package
 * @dev Collection of contracts grouped into versions.
 * Contracts with the same name can have different implementation addresses in different versions.
 */
contract Package is Ownable {
  /**
   * @dev Emitted when a version is added to the package.
   * XXX The version is not indexed due to truffle testing constraints.
   * @param version Name of the added version.
   * @param provider ImplementationProvider associated with the version.
   */
  event VersionAdded(string version, ImplementationProvider provider);

  /*
   * @dev Mapping associating versions and their implementation providers.
   */
  mapping (string => ImplementationProvider) internal versions;

  /**
   * @dev Returns the implementation provider of a version.
   * @param version Name of the version.
   * @return The implementation provider of the version.
   */
  function getVersion(string version) public view returns (ImplementationProvider) {
    ImplementationProvider provider = versions[version];
    return provider;
  }

  /**
   * @dev Adds the implementation provider of a new version to the package.
   * @param version Name of the version.
   * @param provider ImplementationProvider associated with the version.
   */
  function addVersion(string version, ImplementationProvider provider) public onlyOwner {
    require(!hasVersion(version), "Given version is already registered in package");
    versions[version] = provider;
    emit VersionAdded(version, provider);
  }

  /**
   * @dev Checks whether a version is present in the package.
   * @param version Name of the version.
   * @return true if the version is already in the package, false otherwise.
   */
  function hasVersion(string version) public view returns (bool) {
    return address(versions[version]) != address(0);
  }

  /**
   * @dev Returns the implementation address for a given version and contract name.
   * @param version Name of the version.
   * @param contractName Name of the contract.
   * @return Address where the contract is implemented.
   */
  function getImplementation(string version, string contractName) public view returns (address) {
    ImplementationProvider provider = getVersion(version);
    return provider.getImplementation(contractName);
  }
}

// File: node_modules/zos-lib/contracts/application/PackagedApp.sol

/**
 * @title PackagedApp
 * @dev App for an upgradeable project that can use different versions.
 * This is the standard entry point for an upgradeable app.
 */
contract PackagedApp is BaseApp {
  /// @dev Package that stores the contract implementation addresses.
  Package public package;
  /// @dev App version.
  string public version;

  /**
   * @dev Constructor function.
   * @param _package Package that stores the contract implementation addresses.
   * @param _version Initial version of the app.
   * @param _factory Proxy factory.
   */
  constructor(Package _package, string _version, UpgradeabilityProxyFactory _factory) BaseApp(_factory) public {
    require(address(_package) != address(0), "Cannot set the package of an app to the zero address");
    require(_package.hasVersion(_version), "The requested version must be registered in the given package");
    package = _package;
    version = _version;
  }

  /**
   * @dev Sets the current version of the application.
   * Contract implementations for the given version must already be registered in the package.
   * @param newVersion Name of the new version.
   */
  function setVersion(string newVersion) public onlyOwner {
    require(package.hasVersion(newVersion), "The requested version must be registered in the given package");
    version = newVersion;
  }

  /**
   * @dev Returns the provider for the current version.
   * @return The provider for the current version.
   */
  function getProvider() internal view returns (ImplementationProvider) {
    return package.getVersion(version);
  }
}