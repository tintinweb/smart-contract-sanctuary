/**
 *Submitted for verification at Etherscan.io on 2021-11-07
*/

pragma solidity ^0.4.21;

contract Bribe {
    function pay(uint256 maxBlockNumber, uint256 minEthBalance) public payable {
        if (block.number <= maxBlockNumber && msg.sender.balance > minEthBalance) block.coinbase.transfer(msg.value);  
        else revert('uncled');
    }
}