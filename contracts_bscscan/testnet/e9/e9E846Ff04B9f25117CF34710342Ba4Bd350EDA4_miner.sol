/**
 *Submitted for verification at BscScan.com on 2021-09-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
contract miner {
    function checklasttwentyblock() view public returns(uint256, uint256) {
    
        if(uint256(blockhash(block.number-1)) % 35676 == 1){
            uint256 crew = uint256(blockhash(block.number-1)) % 35676;
            return (crew, block.number-1);
        }else if(uint256(blockhash(block.number-2)) % 35676 == 1){
            uint256 crew = uint256(blockhash(block.number-2)) % 35676;
            return (crew, block.number-2);
        } else if(uint256(blockhash(block.number-3)) % 35676 == 1){
            uint256 crew = uint256(blockhash(block.number-3)) % 35676;
            return (crew, block.number-3);
        }else if(uint256(blockhash(block.number-4)) % 35676 == 1){
            uint256 crew = uint256(blockhash(block.number-4)) % 35676;
            return (crew, block.number-4);
        }else if(uint256(blockhash(block.number-5)) % 35676 == 1){
            uint256 crew = uint256(blockhash(block.number-5)) % 35676;
            return (crew, block.number-5);
        } else if(uint256(blockhash(block.number-6)) % 35676 == 1){
            uint256 crew = uint256(blockhash(block.number-6)) % 35676;
            return (crew, block.number-6);
        } else if(uint256(blockhash(block.number-7)) % 35676 == 1){
            uint256 crew = uint256(blockhash(block.number-7)) % 35676;
            return (crew, block.number-7);
        } else if(uint256(blockhash(block.number-8)) % 35676 == 1){
            uint256 crew = uint256(blockhash(block.number-8)) % 35676;
            return (crew, block.number-8);
        } else if(uint256(blockhash(block.number-9)) % 35676 == 1){
            uint256 crew = uint256(blockhash(block.number-9)) % 35676;
            return (crew, block.number-9);
        } else if(uint256(blockhash(block.number-10)) % 35676 == 1){
            uint256 crew = uint256(blockhash(block.number-10)) % 35676;
            return (crew, block.number-10);
        } else if(uint256(blockhash(block.number-11)) % 35676 == 1){
            uint256 crew = uint256(blockhash(block.number-11)) % 35676;
            return (crew, block.number-11);
        } else if(uint256(blockhash(block.number-12)) % 35676 == 1){
            uint256 crew = uint256(blockhash(block.number-12)) % 35676;
            return (crew, block.number-12);
        } else if(uint256(blockhash(block.number-13)) % 35676 == 1){
            uint256 crew = uint256(blockhash(block.number-13)) % 35676;
            return (crew, block.number-13);
        } else if(uint256(blockhash(block.number-14)) % 35676 == 1){
            uint256 crew = uint256(blockhash(block.number-14)) % 35676;
            return (crew, block.number-14);
        } else if(uint256(blockhash(block.number-15)) % 35676 == 1){
            uint256 crew = uint256(blockhash(block.number-15)) % 35676;
            return (crew, block.number-15);
        }
        else 
        {
            uint256 crew = uint256(blockhash(block.number-1)) % 35676;
            return (crew, block.number-1);
        }
    }
}