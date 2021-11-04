// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract MockOrc {

    mapping(uint256 => address) public ownerOf;

    function setOwner(uint256 id, address own) external {
        ownerOf[id] = own;
    }

    function activities(uint256 id) external view returns (address owner, uint88 timestamp, uint8 action) {
        return (ownerOf[id], 0, 0);
    }
}