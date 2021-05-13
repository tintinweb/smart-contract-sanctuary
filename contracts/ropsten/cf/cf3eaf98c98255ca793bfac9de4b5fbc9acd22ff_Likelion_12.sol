/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

//young do jang
pragma solidity 0.8.0;

contract Likelion_12 {
    struct block {
        uint _blocknumber ;
        bytes32 _blockhash ;
        bytes32 _previousblockhash ;
        string _contents;
    }
    block [] Block;
    bytes32 hash;
    bytes32 previoushash;
    uint i=0;
    
    function GenesisBlock() public {
            Block[0]._blocknumber = 1;
            hash = sha256(abi.encodePacked(Block[0]._blocknumber));
            Block[0]._blockhash = hash;
            Block[0]._previousblockhash = 0;
            Block[0]._contents ="GenesisBlock";
    }
    
    function Newblock(string memory _contents) public {
            i++;
        
            Block[i]._blocknumber = i+1;
            hash = sha256(abi.encodePacked(Block[i]._blocknumber));
            Block[i]._blockhash = hash;
            Block[i]._previousblockhash = Block[i-1]._blockhash;
            Block[i]._contents;
    }
       
    function Check(uint i) public returns(uint, bytes32, bytes32, string memory) {
        return(Block[i]._blocknumber, Block[i]._blockhash, Block[i]._previousblockhash, Block[i]._contents);
    }    
        
}