/**
 *Submitted for verification at BscScan.com on 2021-12-15
*/

pragma solidity ^0.8.0;

contract Random{

    uint nonce = 0;
    function getRandomNumber() external returns (uint) {
        nonce += 1;
        return uint(keccak256(abi.encodePacked(nonce, msg.sender, blockhash(block.number - 1))));
    }
}