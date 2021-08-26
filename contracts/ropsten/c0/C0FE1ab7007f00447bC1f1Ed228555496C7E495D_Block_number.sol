/**
 *Submitted for verification at Etherscan.io on 2021-08-25
*/

pragma solidity ^0.4.0;
contract Block_number {


    function getBlockNumber() constant returns (uint256) {
        return block.number;
    }
    
}