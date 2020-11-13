pragma solidity >=0.6.0 <0.7.0;

import "../utils/MappedSinglyLinkedList.sol";

contract MappedSinglyLinkedListExposed {
  using MappedSinglyLinkedList for MappedSinglyLinkedList.Mapping;

  MappedSinglyLinkedList.Mapping list;

  function initialize() external {
    list.initialize();
  }

  function addressArray() external view returns (address[] memory) {
    return list.addressArray();
  }

  function addAddresses(address[] calldata addresses) external {
    list.addAddresses(addresses);
  }

  function addAddress(address newAddress) external {
    list.addAddress(newAddress);
  }

  function removeAddress(address prevAddress, address addr) external {
    list.removeAddress(prevAddress, addr);
  }

  function contains(address addr) external view returns (bool) {
    return list.contains(addr);
  }

  function clearAll() external {
    list.clearAll();
  }

}