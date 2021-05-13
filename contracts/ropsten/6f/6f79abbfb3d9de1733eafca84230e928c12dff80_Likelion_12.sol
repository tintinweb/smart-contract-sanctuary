/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

// Sungrae Park

pragma solidity 0.8.0;

contract Likelion_12{
    
    struct Block {
        uint Block_number;
        bytes32 Prev_hash;
        bytes32 Block_hash;
        string _string;
    }
    
    Block[] mini_Blockchain;
    
    function AddBlock(string memory _string) public {
        uint block_number = mini_Blockchain.length;
        bytes32 prev_hash = mini_Blockchain[mini_Blockchain.length-1].Block_hash;
        bytes32 block_hash = keccak256(abi.encodePacked(block_number, prev_hash, _string));
        
        mini_Blockchain.push(Block(block_number, prev_hash, block_hash, _string));
    }
    
    function Create_GenesisBLock(string memory _string) public returns(string memory){
        uint block_number = 0;
        bytes32 prev_hash = 0;
        bytes32 block_hash = keccak256(abi.encodePacked(block_number,prev_hash, _string));
        if(mini_Blockchain.length == 0){
            mini_Blockchain.push(Block(block_number, prev_hash, block_hash, _string));
            
            return "Complete";
            
        }else{
            return "Already genesis block exists";

        }
        
    }
    
    function getBlockInfo(uint a) public view returns(uint, bytes32, bytes32, string memory){
        return (mini_Blockchain[a].Block_number,mini_Blockchain[a].Prev_hash,mini_Blockchain[a].Block_hash,mini_Blockchain[a]._string);
    }
}