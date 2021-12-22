/**
 *Submitted for verification at Etherscan.io on 2021-12-22
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract globalVariable {

    function getGasInfo() public view returns (uint, uint){
        return (tx.gasprice, block.gaslimit);
    }

    function getBlockInfo() public view returns (uint, address, uint, uint, uint, uint) {
        return(block.chainid,   //chain's id
                block.coinbase,   //winning miner's address
                block.difficulty, 
                block.gaslimit,
                block.number,     //the position of block in the chain
                block.timestamp
        );
    }

}