/**
 *Submitted for verification at Etherscan.io on 2021-08-25
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract RandomNumber {

    event RandomNumberSet(address sender, uint256 seed, uint256 number);

    function getRandomNumberWithOutSeed(uint256 max) public view returns (uint256){
        return calcRandomNumber(max, 0);
    }

    function getRandomNumberWithSeed(uint256 max, uint256 seed) public view returns (uint256){
        return calcRandomNumber(max, seed);
    }

    function getSetRandomNumberWithOutSeed(uint256 max) public returns (uint256){
        uint256 randomNumber = calcRandomNumber(max, 0);

        emit RandomNumberSet(msg.sender, 0, randomNumber);

        return randomNumber;
    }

    function getSetRandomNumberWithSeed(uint256 max, uint256 seed) public returns (uint256){
        uint256 randomNumber = calcRandomNumber(max, seed);

        emit RandomNumberSet(msg.sender, seed, randomNumber);

        return randomNumber;
    }

    function calcRandomNumber(uint256 max, uint256 seed) private view returns (uint256)
    {
        uint256 randomNumber = uint256(
            keccak256(abi.encodePacked(
                block.timestamp,
                block.difficulty,
                block.coinbase,
                block.gaslimit,
                msg.sender,
                block.number,
                seed
            ))
        );

        return randomNumber % max;
    }
}