pragma solidity ^0.4.24;

/**
 * @title IRegistry
 * @dev This contract represents the interface of a registry contract
 */
interface IRegistry {
    /**
    * @dev This event will be emitted every time a new proxy is created
    * @param proxy representing the address of the proxy created
    */
    event ProxyCreated(address proxy);

    /**
    * @dev This event will be emitted every time a new implementation is registered
    * @param version representing the version name of the registered implementation
    * @param implementation representing the address of the registered implementation
    */
    event VersionAdded(string version, address implementation);

    /**
    * @dev Registers a new version with its implementation address
    * @param version representing the version name of the new implementation to be registered
    * @param implementation representing the address of the new implementation to be registered
    */
    function addVersion(string version, address implementation) external;

    /**
    * @dev Tells the address of the implementation for a given version
    * @param version to query the implementation of
    * @return address of the implementation registered for the given version
    */
    function getVersion(string version) external view returns (address);
}

/**
 * @title Proxy
 * @dev Gives the possibility to delegate any call to a foreign implementation.
 */
contract Proxy {

    /**
    * @dev Tells the address of the implementation where every call will be delegated.
    * @return address of the implementation to which it will be delegated
    */
    function implementation() public view returns (address);

    /**
    * @dev Fallback function allowing to perform a delegatecall to the given implementation.
    * This function will return whatever the implementation call returns
    */
    function () payable public {
        address _impl = implementation();
        require(_impl != address(0));

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}



/**
 * @title UpgradeabilityStorage
 * @dev This contract holds all the necessary state variables to support the upgrade functionality
 */
contract UpgradeabilityStorage {
    // Versions registry
    IRegistry internal registry;

    // Address of the current implementation
    address internal _implementation;

    /**
    * @dev Tells the address of the current implementation
    * @return address of the current implementation
    */
    function implementation() public view returns (address) {
        return _implementation;
    }
}


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







/**
 * @title Upgradeable
 * @dev This contract holds all the minimum required functionality for a behavior to be upgradeable.
 * This means, required state variables for owned upgradeability purpose and simple initialization validation.
 */
contract Upgradeable is UpgradeabilityStorage {
    /**
    * @dev Validates the caller is the versions registry.
    * THIS FUNCTION SHOULD BE OVERRIDDEN CALLING SUPER
    * @param sender representing the address deploying the initial behavior of the contract
    */
    function initialize(address sender) public payable {
        require(msg.sender == address(registry));
    }
}







/**
 * @title UpgradeabilityProxy
 * @dev This contract represents a proxy where the implementation address to which it will delegate can be upgraded
 */
contract UpgradeabilityProxy is Proxy, UpgradeabilityStorage, Ownable {

    /**
    * @dev Constructor function
    */
    constructor(string _version) public {
        registry = IRegistry(msg.sender);
        upgradeTo(_version);
    }

    /**
    * @dev Upgrades the implementation to the requested version
    * @param _version representing the version name of the new implementation to be set
    */
    function upgradeTo(string _version) public onlyOwner {
        _implementation = registry.getVersion(_version);
    }

}


/**
 * @title Registry
 * @dev This contract works as a registry of versions, it holds the implementations for the registered versions.
 */
contract Registry is IRegistry, Ownable {
    // Mapping of versions to implementations of different functions
    mapping (string => address) internal versions;

    /**
    * @dev Registers a new version with its implementation address
    * @param version representing the version name of the new implementation to be registered
    * @param implementation representing the address of the new implementation to be registered
    */
    function addVersion(string version, address implementation) external onlyOwner {
        require(versions[version] == 0x0);
        versions[version] = implementation;
        emit VersionAdded(version, implementation);
    }

    /**
    * @dev Tells the address of the implementation for a given version
    * @param version to query the implementation of
    * @return address of the implementation registered for the given version
    */
    function getVersion(string version) external view returns (address) {
        return versions[version];
    }

    /**
    * @dev Creates an upgradeable proxy
    * @param version representing the first version to be set for the proxy
    * @return address of the new proxy created
    */
    function createProxy(string version) public payable onlyOwner returns (UpgradeabilityProxy) {
        UpgradeabilityProxy proxy = new UpgradeabilityProxy(version);
        Upgradeable(proxy).initialize.value(msg.value)(msg.sender);
        emit ProxyCreated(proxy);
        return proxy;
    }
}