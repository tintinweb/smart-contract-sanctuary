// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract A {
    address owner;

    constructor(address _owner) {
      owner = _owner;
    }
    function getContractAddress() public pure returns(string memory) {
        return "This is the name";
    }
}

contract AFactory {
    mapping (address => address[]) public owners;
    event DeployMinter(address owner, string name, string symbol);


    function createObject(address owner, string memory name, string memory symbol) public {
        owners[owner].push(address(new A(owner)));
        emit DeployMinter(owner, name, symbol);
    }

    function getAddresses(address owner) public view returns (address[] memory) {
        return owners[owner];
    }
}