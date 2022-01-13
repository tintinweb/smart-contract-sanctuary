//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract dENS {
  address owner = 0x20be2A10A85c3567FC853050E079786BF1C363b4;

  struct nameToETHAddress {
    string name;
    address ethAddress;
  }

  nameToETHAddress[] nametoethaddress;

  mapping(string => address) public nameToAddressMapping;

  function registerName(string memory _name, address _address) public {
    require(msg.sender == owner);
    nametoethaddress.push(
      nameToETHAddress({ name: _name, ethAddress: _address })
    );
    nameToAddressMapping[_name] = _address;
  }
}