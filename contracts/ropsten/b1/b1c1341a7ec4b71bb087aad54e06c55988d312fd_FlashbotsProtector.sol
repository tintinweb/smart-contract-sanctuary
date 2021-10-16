/**
 *Submitted for verification at Etherscan.io on 2021-10-16
*/

pragma solidity ^0.4.21;

contract FlashbotsProtector {
    function check(bytes32 expectedParentHash) public {
        require(blockhash(block.number - 1) == expectedParentHash, "block was uncled");
    }
}