// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract A {
    address owner;
    string name;
    string symbol;

    constructor(address _owner, string memory _name, string memory _symbol) {
      owner = _owner;
      name = _name;
      symbol = _symbol;

    }
    function getOwner() public view returns(address) {
        return owner;
    }
}

contract AFactory {
    mapping (address => address[]) owners;
    event DeployMinter(address owner, string name, string symbol);


    function createObject(address owner, string memory name, string memory symbol) public {
        owners[owner].push(address(new A(owner, name, symbol)));
        emit DeployMinter(owner, name, symbol);
    }

    function getAddresses(address owner) public view returns (address[] memory) {
        return owners[owner];
    }
}