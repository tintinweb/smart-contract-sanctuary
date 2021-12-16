// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract MockChest {

    mapping (string => uint256[]) public cardRank;
    mapping (uint256 => bool) public existId;

    constructor() {
        cardRank['A'] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
        cardRank['A+'] = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100];
    }

    function getCard() public returns(uint) {
        uint result;
        uint256[] memory ids = new uint256[](1);
        uint greatness = getRandomNumber(10000);
        // uint percent = greatness / 100;
        if (greatness > 9634) {
            ids[0] = getRandomNumber(cardRank['A'].length - 1);
            result = cardRank['A'][ids[0]];
            delete cardRank['A'][ids[0]];
            return result;
        } else {
            ids[0] = getRandomNumber(cardRank['A+'].length - 1);
            result = cardRank['A+'][ids[0]];
            delete cardRank['A+'][ids[0]];
            return result;
        }
    }
    
    function getRandomNumber(uint mod) public view returns(uint) {
        uint256 rand = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    blockhash(block.number - 1),
                    block.difficulty,
                    msg.sender
                )
            )
        );
        return (rand % mod) + 1;
    }
}