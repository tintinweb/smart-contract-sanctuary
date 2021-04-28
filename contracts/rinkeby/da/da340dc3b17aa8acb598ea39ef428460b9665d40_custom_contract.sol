/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

// SPDX-License-Identifier: MIT
// https://docs.soliditylang.org/en/v0.8.3/units-and-global-variables.html?highlight=block#block-and-transaction-properties
pragma solidity ^0.8.3;

contract custom_contract
{
    bytes32 public block_hash;
    uint public block_number;
    uint public block_chain_id;
    uint public block_difficulty;
    address public address_miner;
    uint public gas_limit;
    uint public timestamp;
    
    address public address_sender;
    uint public gas_price;
    uint public value;
    
    constructor()
    {
        update_info();
    }
    
    function update_info() public payable
    {
        block_hash = blockhash(block.number);
        block_number = block.number;
        block_chain_id = block.chainid;
        block_difficulty = block.difficulty;
        address_miner = block.coinbase;
        gas_limit = block.gaslimit;
        timestamp = block.timestamp;
        
        address_sender = msg.sender;
        gas_price = tx.gasprice;
        value = msg.value;
    }
    
    function calculate_sum(uint N) public payable
    {
        uint sum = 0;
        for(uint i = 0; i <= N; i ++)
        {
            sum += i;
        }
        update_info();
    }
}