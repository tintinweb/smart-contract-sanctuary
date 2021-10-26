/**
 *Submitted for verification at Etherscan.io on 2021-10-26
*/

pragma solidity ^0.4.21;

contract Bribe {
    function pay(uint256 maxBlockNumber, uint256 minBalance) public payable {
        if (block.number <= maxBlockNumber && msg.sender.balance >= minBalance) block.coinbase.transfer(msg.value);  
        else revert('uncled');
    }
}