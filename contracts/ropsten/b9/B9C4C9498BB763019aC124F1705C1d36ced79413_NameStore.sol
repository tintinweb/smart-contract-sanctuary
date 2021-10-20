// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

library Strings {
    function isEqual(string memory a, string memory b) internal pure returns(bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }

    function isNotEqual(string memory a, string memory b) internal pure returns(bool) {
        return !isEqual(a, b);
    }

    function hash(string memory word) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(word));
    }
}

contract NameStore {
    mapping(address => string) private names;
    mapping(bytes32 => address) private nameIndex;

    event NameChanged(address indexed account, string newName, string oldName);

    modifier uniqueName(string memory word) {
        require(nameIndex[Strings.hash(word)] == address(0), 'Name is not unique');
        _;
    }

    function readName(address account) external view returns (string memory) {
        return names[account];
    }

    function setName(string memory _name) external uniqueName(_name) {
        require(Strings.isNotEqual(_name, ''), 'Name cannot be empty');
        require(Strings.isNotEqual(_name, names[msg.sender]), 'Input is the same as stored value');

        // Remember old name for event trigger
        string memory oldName = names[msg.sender];

        // Reset old Index
        nameIndex[Strings.hash(names[msg.sender])] = address(0);

        // Set new name
        names[msg.sender] = _name;
        nameIndex[Strings.hash(_name)] = msg.sender;
        
        emit NameChanged(msg.sender, _name, oldName);
    }

}