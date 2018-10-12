pragma solidity ^0.4.24;

// File: contracts/eternal_storage/EternalStorage.sol

/**
 * @title EternalStorage
 * @dev This contract holds all the necessary state variables to carry out the storage of any contract.
 */
contract EternalStorage {

  mapping(bytes32 => uint256) internal uintStorage;
  mapping(bytes32 => string) internal stringStorage;
  mapping(bytes32 => address) internal addressStorage;
  mapping(bytes32 => bytes) internal bytesStorage;
  mapping(bytes32 => bool) internal boolStorage;
  mapping(bytes32 => int256) internal intStorage;

}

// File: contracts/eternal_storage/Proxy.sol

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

// File: contracts/eternal_storage/UpgradeabilityStorage.sol

/**
 * @title UpgradeabilityStorage
 * @dev This contract holds all the necessary state variables to support the upgrade functionality
 */
contract UpgradeabilityStorage {
  // Version name of the current implementation
  string internal _version;

  // Address of the current implementation
  address internal _implementation;

  /**
  * @dev Tells the version name of the current implementation
  * @return string representing the name of the current version
  */
  function version() public view returns (string) {
    return _version;
  }

  /**
  * @dev Tells the address of the current implementation
  * @return address of the current implementation
  */
  function implementation() public view returns (address) {
    return _implementation;
  }
}

// File: contracts/eternal_storage/UpgradeabilityProxy.sol

/**
 * @title UpgradeabilityProxy
 * @dev This contract represents a proxy where the implementation address to which it will delegate can be upgraded
 */
contract UpgradeabilityProxy is Proxy, UpgradeabilityStorage {
  /**
  * @dev This event will be emitted every time the implementation gets upgraded
  * @param version representing the version name of the upgraded implementation
  * @param implementation representing the address of the upgraded implementation
  */
  event Upgraded(string version, address indexed implementation);

  /**
  * @dev Upgrades the implementation address
  * @param version representing the version name of the new implementation to be set
  * @param implementation representing the address of the new implementation to be set
  */
  function _upgradeTo(string version, address implementation) internal {
    require(_implementation != implementation);
    _version = version;
    _implementation = implementation;
    emit Upgraded(version, implementation);
  }
}

// File: contracts/eternal_storage/UpgradeabilityOwnerStorage.sol

/**
 * @title UpgradeabilityOwnerStorage
 * @dev This contract keeps track of the upgradeability owner
 */
contract UpgradeabilityOwnerStorage {
  // Owner of the contract
  address private _upgradeabilityOwner;

  /**
   * @dev Tells the address of the owner
   * @return the address of the owner
   */
  function upgradeabilityOwner() public view returns (address) {
    return _upgradeabilityOwner;
  }

  /**
   * @dev Sets the address of the owner
   */
  function setUpgradeabilityOwner(address newUpgradeabilityOwner) internal {
    _upgradeabilityOwner = newUpgradeabilityOwner;
  }
}

// File: contracts/eternal_storage/OwnedUpgradeabilityProxy.sol

/**
 * @title OwnedUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with basic authorization control functionalities
 */
contract OwnedUpgradeabilityProxy is UpgradeabilityOwnerStorage, UpgradeabilityProxy {
  /**
  * @dev Event to show ownership has been transferred
  * @param previousOwner representing the address of the previous owner
  * @param newOwner representing the address of the new owner
  */
  event ProxyOwnershipTransferred(address previousOwner, address newOwner);

  /**
  * @dev the constructor sets the original owner of the contract to the sender account.
  */
  constructor() public {
    setUpgradeabilityOwner(msg.sender);
  }

  /**
  * @dev Throws if called by any account other than the owner.
  */
  modifier onlyProxyOwner() {
    require(msg.sender == proxyOwner());
    _;
  }

  /**
   * @dev Tells the address of the proxy owner
   * @return the address of the proxy owner
   */
  function proxyOwner() public view returns (address) {
    return upgradeabilityOwner();
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferProxyOwnership(address newOwner) public onlyProxyOwner {
    require(newOwner != address(0));
    emit ProxyOwnershipTransferred(proxyOwner(), newOwner);
    setUpgradeabilityOwner(newOwner);
  }

  /**
   * @dev Allows the upgradeability owner to upgrade the current version of the proxy.
   * @param version representing the version name of the new implementation to be set.
   * @param implementation representing the address of the new implementation to be set.
   */
  function upgradeTo(string version, address implementation) public onlyProxyOwner {
    _upgradeTo(version, implementation);
  }

  /**
   * @dev Allows the upgradeability owner to upgrade the current version of the proxy and call the new implementation
   * to initialize whatever is needed through a low level call.
   * @param version representing the version name of the new implementation to be set.
   * @param implementation representing the address of the new implementation to be set.
   * @param data represents the msg.data to bet sent in the low level call. This parameter may include the function
   * signature of the implementation to be called with the needed payload
   */
  function upgradeToAndCall(string version, address implementation, bytes data) payable public onlyProxyOwner {
    upgradeTo(version, implementation);
    require(address(this).call.value(msg.value)(data));
  }
}

// File: contracts/eternal_storage/EternalStorageProxy.sol

/**
 * @title EternalStorageProxy
 * @dev This proxy holds the storage of the token contract and delegates every call to the current implementation set.
 * Besides, it allows to upgrade the token&#39;s behaviour towards further implementations, and provides basic
 * authorization control functionalities
 */
contract EternalStorageProxy is EternalStorage, OwnedUpgradeabilityProxy {}

// File: contracts/DetailedToken.sol

contract DetailedToken{
	string public name;
	string public symbol;
	uint8 public decimals;
}

// File: contracts/Ownable.sol

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

// File: contracts/IcoTokenUpgradeability.sol

//import "./MintableToken.sol";



contract IcoTokenUpgradeability is EternalStorageProxy,DetailedToken{
	    /*define SafeMath library for uint256*/

    constructor(string _name,string _symbol,uint8 _decimals)
			public{
				name=_name;
				symbol=_symbol;
				decimals=_decimals;
			}
}