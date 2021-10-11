//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Test {
    mapping(address => bytes32) names;

    event SetName(address account, bytes32 name);

    function setName(bytes32 name) external {
        names[msg.sender] = name;
        emit SetName(msg.sender, name);
    }

    event TestEvent(uint256 indexed a, uint256 indexed b, uint256 indexed c);

    function nameOf(address account) public view returns (bytes32) {
        return names[account];
    }

    function test(uint256 a, uint256 b ) public pure returns (uint256 c) {
        unchecked {
            c = a / b;
        }
        // emit TestEvent(a, b, c);
    }
}