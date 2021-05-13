/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

pragma solidity 0.8.0;


contract Likelion_12 {
    //YunJun Lee
    uint blockNumber = 0;
    bytes32 blockHash ;
    struct block {
     
    uint blockNumber;
    bytes32 blockHash;
    bytes32 preblock;
    string input;
       
    }
    block[] chain;
    
    function makeblock(string memory _input) public {

        //bytes32 _blockHash;
        bytes32 _preblock;
        if (blockNumber==0){
             _preblock = 0;
             blockHash = keccak256(abi.encodePacked(_input, blockNumber,_preblock));
        }else {
            _preblock = blockHash;
            blockHash = keccak256(abi.encodePacked(_input, blockNumber, _preblock)) ;
        }
        
        chain.push(block(blockNumber, blockHash, _preblock,_input))   ;
        blockNumber+=1;
    }
    function getChainLength() public view returns (uint){
        return chain.length;
    }
    

    
    
}