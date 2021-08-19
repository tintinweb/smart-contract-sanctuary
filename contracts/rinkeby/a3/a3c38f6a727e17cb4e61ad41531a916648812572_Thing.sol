/**
 *Submitted for verification at Etherscan.io on 2021-08-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Thing {

  string public name;
  uint public value;

  event ThingEvent(address sender, string name, uint value);

  constructor() {
    name = "master"; // force default deployment to be init'd
  }

  function init(string memory _name, uint _value) public {
    require(bytes(name).length == 0); // ensure not init'd already.
    require(bytes(_name).length > 0);

    name = _name;
    value = _value;
  }

  function doit() public {
    emit ThingEvent(address(this), name, value);
  }

  function epicfail() public returns (string memory){
    value++;
    require(false, "Hello world!");
    return "Goodbye sweet world!";
  }

  function increment() public {
    value++;
  }
}

contract CloneFactory {

  function createClone(address target) internal returns (address result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      result := create(0, clone, 0x37)
    }
  }

  function isClone(address target, address query) internal view returns (bool result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
      mstore(add(clone, 0xa), targetBytes)
      mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

      let other := add(clone, 0x40)
      extcodecopy(query, other, 0, 0x2d)
      result := and(
        eq(mload(clone), mload(other)),
        eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
      )
    }
  }
}

contract ThingFactory is CloneFactory {

  address public libraryAddress;

  event ThingCreated(address newThingAddress, address libraryAddress);

  constructor (address _libraryAddress) {
    libraryAddress = _libraryAddress;
  }

  function onlyCreate() public {
    createClone(libraryAddress);
  }

  function createThing(string memory _name, uint _value) public {
    address clone = createClone(libraryAddress);
    Thing(clone).init(_name, _value);
    emit ThingCreated(clone, libraryAddress);
  }

  function isThing(address thing) public view returns (bool) {
    return isClone(libraryAddress, thing);
  }

  function incrementThings(address[] memory things) public returns (bool) {
    for(uint i = 0; i < things.length; i++) {
      require(isThing(things[i]), "Must all be things");
      Thing(things[i]).increment();
    }
    return true;
  }
}