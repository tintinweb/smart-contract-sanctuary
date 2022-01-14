/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract dENS {
  address public owner = msg.sender;

  modifier isOwner() {
    require(msg.sender == owner);
    _;
  }

  struct nameToETHAddress {
    string name;
    address ethAddress;
  }

  nameToETHAddress[] nametoethaddress;

  mapping(string => address) public nameToAddressMapping;

  function registerName(string memory _name, address _address) public isOwner {
    nametoethaddress.push(
      nameToETHAddress({ name: _name, ethAddress: _address })
    );
    nameToAddressMapping[_name] = _address;
  }

  function transferOwnership(address _newOwner) public isOwner {
    require(_newOwner != address(0));
    owner = _newOwner;
  }
}