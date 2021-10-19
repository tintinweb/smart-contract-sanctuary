/**
 *Submitted for verification at Etherscan.io on 2021-10-19
*/

pragma solidity ^0.4.21;

contract BribeProtector {
    function pay(bytes32 expectedParentHash) public payable {
        if (blockhash(block.number - 1) == expectedParentHash || blockhash(block.number - 2) == expectedParentHash) block.coinbase.transfer(msg.value);  
        else revert('uncled');
    }
}