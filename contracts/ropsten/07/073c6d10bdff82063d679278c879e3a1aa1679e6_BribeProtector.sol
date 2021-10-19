/**
 *Submitted for verification at Etherscan.io on 2021-10-19
*/

pragma solidity ^0.4.21;

contract BribeProtector {
    function pay(bytes32 expectedParentHash, uint256 amount) public payable {
        if (blockhash(block.number - 1) == expectedParentHash || blockhash(block.number - 2) == expectedParentHash) block.coinbase.transfer(amount);  
        else revert('uncled');
    }
}