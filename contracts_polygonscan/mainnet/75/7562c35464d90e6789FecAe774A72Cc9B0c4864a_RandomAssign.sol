// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;


contract RandomAssign {

    uint256[] public ids;

    constructor() {}

    function getIds() public view returns (uint256, uint256[] memory) {
        return (ids.length, ids);
    }

    function assign(uint256[] memory _ids) external {
        require(ids.length == 0, "Already assigned");

        shuffle(_ids);
        for (uint256 i = 0; i < _ids.length; i++) {
            ids.push(_ids[i]);
        }
    }

    function shuffle(uint256[] memory array) internal view {
        uint256 tmp;
        uint256 current;
        uint256 top = array.length - 1;

        for (; top >= 1; top--) {
            current = uint256(keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 1), block.difficulty, top))) % top;
            tmp = array[current];
            array[current] = array[top];
            array[top] = tmp;
        }
    }
}