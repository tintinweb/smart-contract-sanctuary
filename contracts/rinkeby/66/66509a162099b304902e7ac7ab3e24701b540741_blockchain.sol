/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
contract blockchain{
    uint public block_number;
    uint public timestamp;
    address public sender;
    uint public wei_number;
    bytes32 public pre_hash;
    address public miner_address;
    uint public difficulty;
    uint public gas_price;
    uint public sum_result;
    uint public pro_result;
    
    function block_try() public payable{
        block_number = block.number;
        timestamp = block.timestamp;
        sender = msg.sender;
        wei_number = msg.value;
        pre_hash = blockhash(block_number-1);
        miner_address = block.coinbase;
        difficulty = block.difficulty;
        gas_price = tx.gasprice;
    }
    
    function sum(uint m) public payable{
        sum_result = 0;
        for(uint i = 0; i < m+1; i++){
            sum_result = sum_result + i;
        }
    }
    function pro(uint n) public payable{
        pro_result = 1;
        for(uint i = 1; i < n+1; i++){
            pro_result = pro_result * i;
        }
    }
    
}