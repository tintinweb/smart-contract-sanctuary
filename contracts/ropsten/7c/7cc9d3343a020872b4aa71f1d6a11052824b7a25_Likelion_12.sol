/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

//JinAe Byeon

pragma solidity 0.8.0;

contract Likelion_12 {
    struct block {
        uint num;
        bytes32 previous_hash;
        string put;
        bytes32 hash;
        
    }
    block[] blocks;
    
    function setBlocks(string memory i) public {
        if (blocks.length == 0){
            blocks.push(block(blocks.length + 1,keccak256(bytes("1")),i,keccak256(bytes(i))));
        }else{
            blocks.push(block(blocks.length + 1,blocks[blocks.length-1].hash,i,keccak256(bytes(i))));
        }
    }
    function show(uint i) public view returns(uint,bytes32,string memory,bytes32){
        return (blocks[i].num,blocks[i].previous_hash,blocks[i].put,blocks[i].hash);
    }
}