/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

pragma solidity >=0.5.16 <0.6.9;
contract betminer {
    function checklasttwentyblock() view public returns(uint256, uint256) {
    
        if(uint256(blockhash(block.number-1)) % 34344 == 1){
            uint256 crew = uint256(blockhash(block.number-1)) % 34344;
            return (crew, block.number-1);
        }else if(uint256(blockhash(block.number-2)) % 34344 == 1){
            uint256 crew = uint256(blockhash(block.number-2)) % 34344;
            return (crew, block.number-2);
        } else if(uint256(blockhash(block.number-3)) % 34344 == 1){
            uint256 crew = uint256(blockhash(block.number-3)) % 34344;
            return (crew, block.number-3);
        }else if(uint256(blockhash(block.number-4)) % 34344 == 1){
            uint256 crew = uint256(blockhash(block.number-4)) % 34344;
            return (crew, block.number-4);
        }else if(uint256(blockhash(block.number-5)) % 34344 == 1){
            uint256 crew = uint256(blockhash(block.number-5)) % 34344;
            return (crew, block.number-5);
        } else if(uint256(blockhash(block.number-6)) % 34344 == 1){
            uint256 crew = uint256(blockhash(block.number-6)) % 34344;
            return (crew, block.number-6);
        } else if(uint256(blockhash(block.number-7)) % 34344 == 1){
            uint256 crew = uint256(blockhash(block.number-7)) % 34344;
            return (crew, block.number-7);
        } else if(uint256(blockhash(block.number-8)) % 34344 == 1){
            uint256 crew = uint256(blockhash(block.number-8)) % 34344;
            return (crew, block.number-8);
        } else if(uint256(blockhash(block.number-9)) % 34344 == 1){
            uint256 crew = uint256(blockhash(block.number-9)) % 34344;
            return (crew, block.number-9);
        } else if(uint256(blockhash(block.number-10)) % 34344 == 1){
            uint256 crew = uint256(blockhash(block.number-10)) % 34344;
            return (crew, block.number-10);
        } else if(uint256(blockhash(block.number-11)) % 34344 == 1){
            uint256 crew = uint256(blockhash(block.number-11)) % 34344;
            return (crew, block.number-11);
        } else if(uint256(blockhash(block.number-12)) % 34344 == 1){
            uint256 crew = uint256(blockhash(block.number-12)) % 34344;
            return (crew, block.number-12);
        } else if(uint256(blockhash(block.number-13)) % 34344 == 1){
            uint256 crew = uint256(blockhash(block.number-13)) % 34344;
            return (crew, block.number-13);
        } else if(uint256(blockhash(block.number-14)) % 34344 == 1){
            uint256 crew = uint256(blockhash(block.number-14)) % 34344;
            return (crew, block.number-14);
        } else if(uint256(blockhash(block.number-15)) % 34344 == 1){
            uint256 crew = uint256(blockhash(block.number-15)) % 34344;
            return (crew, block.number-15);
        }
        else 
        {
            uint256 crew = uint256(blockhash(block.number-1)) % 34344;
            return (crew, block.number-1);
        }
    }
}