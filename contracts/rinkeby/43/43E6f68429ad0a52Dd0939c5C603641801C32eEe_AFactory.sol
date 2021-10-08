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

    function createObject(address owner) public {
        owners[owner].push(address(new A(owner)));
    }

}