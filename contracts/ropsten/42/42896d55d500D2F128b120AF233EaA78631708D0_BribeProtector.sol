/**
 *Submitted for verification at Etherscan.io on 2021-10-20
*/

pragma solidity ^0.4.21;

contract BribeProtector {
    function pay(uint256 maxBlockNumber) public payable {
        if (block.number <= maxBlockNumber) block.coinbase.transfer(msg.value);  
        else revert('uncled');
    }
}