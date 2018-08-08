pragma solidity ^0.4.18;


/**
 * @title Proxy
 * @dev Gives the possibility to delegate any call to a foreign implementation.
 */
contract Proxy {
  function implementation() public view returns (address);

  /**
  * @dev Fallback function allowing to perform a delegatecall to the given implementation.
  * This function will return whatever the implementation call returns
  */
  function () payable public {
    address impl = implementation();
    require(impl != address(0));
    bytes memory data = msg.data;

    assembly {
      let result := delegatecall(gas, impl, add(data, 0x20), mload(data), 0, 0)
      let size := returndatasize

      let ptr := mload(0x40)
      returndatacopy(ptr, 0, size)

      switch result
      case 0 { revert(ptr, size) }
      default { return(ptr, size) }
    }
  }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address[] public owners;

  event OwnerAdded(address indexed authorizer, address indexed newOwner, uint256 index);

  event OwnerRemoved(address indexed authorizer, address indexed oldOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owners.push(msg.sender);
    OwnerAdded(0x0, msg.sender, 0);
  }

  /**
   * @dev Throws if called by any account other than one owner.
   */
  modifier onlyOwner() {
    bool isOwner = false;

    for (uint256 i = 0; i < owners.length; i++) {
      if (msg.sender == owners[i]) {
        isOwner = true;
        break;
      }
    }

    require(isOwner);
    _;
  }

  /**
   * @dev Allows one of the current owners to add a new owner
   * @param newOwner The address give ownership to.
   */
  function addOwner(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    uint256 i = owners.push(newOwner) - 1;
    OwnerAdded(msg.sender, newOwner, i);
  }

  /**
   * @dev Allows one of the owners to remove other owner
   */
  function removeOwner(uint256 index) onlyOwner public {
    address owner = owners[index];
    owners[index] = owners[owners.length - 1];
    delete owners[owners.length - 1];
    OwnerRemoved(msg.sender, owner);
  }

  function ownersCount() constant public returns (uint256) {
    return owners.length;
  }
}


contract UpgradableStorage is Ownable {

  // Address of the current implementation
  address internal _implementation;

  event NewImplementation(address implementation);

  /**
  * @dev Tells the address of the current implementation
  * @return address of the current implementation
  */
  function implementation() public view returns (address) {
    return _implementation;
  }
}


/**
 * @title Upgradable
 * @dev This contract represents an upgradable contract
 */
contract Upgradable is UpgradableStorage {
  function initialize() public payable { }
}


contract KnowledgeProxy is Proxy, UpgradableStorage {
  /**
  * @dev Upgrades the implementation to the requested version
  */
  function upgradeTo(address imp) onlyOwner public payable {
    _implementation = imp;
    Upgradable(this).initialize.value(msg.value)();

    NewImplementation(imp);
  }
}