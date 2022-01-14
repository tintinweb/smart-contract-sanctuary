//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract dENS {
  address public owner = msg.sender;

  modifier isOwner() {
    require(msg.sender == owner, "Only Owner can send transaction!");
    _;
  }

  struct nameToAddress {
    string name;
    address ethAddress;
  }

  struct addressToName {
    address ethAddress;
    string name;
  }

  nameToAddress[] nametoethaddress;
  addressToName[] addresstotame;

  mapping(string => address) public nameToAddressMapping;
  mapping(address => string) public addressToNameMapping;

  function registerName(string memory _name, address _address) public isOwner {
    nametoethaddress.push(nameToAddress({ name: _name, ethAddress: _address }));
    addresstotame.push(addressToName({ ethAddress: _address, name: _name }));
    nameToAddressMapping[_name] = _address;
    addressToNameMapping[_address] = _name;
  }

  function transferOwnership(address _newOwner) public isOwner {
    owner = _newOwner;
  }
}