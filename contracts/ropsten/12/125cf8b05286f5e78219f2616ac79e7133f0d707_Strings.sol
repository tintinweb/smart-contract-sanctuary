/**
 *Submitted for verification at Etherscan.io on 2021-09-30
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

library Strings {
    function isEqual(string memory a, string memory b) public pure returns(bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }

    function isNotEqual(string memory a, string memory b) public pure returns(bool) {
        return !isEqual(a, b);
    }
}

contract NameStore {
    string private name;

    event NameChanged(string newName, string oldName);

    function readName() external view returns (string memory) {
        return name;
    }

    function setName(string memory _name) external {
        require(Strings.isNotEqual(_name, ''), 'Name cannot be empty');
        require(Strings.isNotEqual(_name, name), 'Input is the same as stored value');

        string memory oldName = name;
        name = _name;

        emit NameChanged(name, oldName);
    }
}