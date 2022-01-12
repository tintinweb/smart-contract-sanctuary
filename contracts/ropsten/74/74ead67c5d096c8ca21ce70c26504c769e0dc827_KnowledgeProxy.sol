/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

pragma solidity ^0.4.18;


 
contract Proxy {
  function implementation() public view returns (address);

   
  function () payable public {
    address impl = implementation();
    require(impl != address(0));
    bytes memory data = msg.data;

    assembly {
      let result := delegatecall(gas, impl, add(data, 0x20), mload(data), 0, 0)
      let size := returndatasize

      let ptr := mload(0x40)
      returndatacopy(ptr, 0, size)

    }
  }
}


 
contract Ownable {
  address[] public owners;

  event OwnerAdded(address indexed authorizer, address indexed newOwner, uint256 index);

  event OwnerRemoved(address indexed authorizer, address indexed oldOwner);

   
  function Ownable() public {
    owners.push(msg.sender);
    OwnerAdded(0x0, msg.sender, 0);
  }

   
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

   
  function addOwner(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    uint256 i = owners.push(newOwner) - 1;
    OwnerAdded(msg.sender, newOwner, i);
  }

   
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

   
  address internal _implementation;

  event NewImplementation(address implementation);

   
  function implementation() public view returns (address) {
    return _implementation;
  }
}


 
contract Upgradable is UpgradableStorage {
  function initialize() public payable { }
}


contract KnowledgeProxy is Proxy, UpgradableStorage {
   
  function upgradeTo(address imp) onlyOwner public payable {
    _implementation = imp;
    Upgradable(this).initialize.value(msg.value)();

    NewImplementation(imp);
  }
}