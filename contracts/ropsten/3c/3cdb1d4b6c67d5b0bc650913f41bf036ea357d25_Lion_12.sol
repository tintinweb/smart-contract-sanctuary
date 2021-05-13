/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

//Jinseon Moon
pragma solidity 0.8.0;

contract Lion_12 {
    struct block {
        uint blocknumber;
        bytes32 previous;
        bytes32 merkle_root;
        bytes32 block_hash;
        //uint time;
        
    }
    
    uint mine = 0;
    
    block[] chain;
    
    function get_Genesis() public {
        chain[0].blocknumber = 0;
        chain[0].previous = bytes32(uint(0));
        chain[0].merkle_root = bytes32(uint(0));
        
        chain[0].block_hash = bytes32(keccak256(abi.encodePacked(chain[0].blocknumber, chain[0].previous, chain[0].merkle_root)));
        //chain[0].time = block.timestamp;
        
        mine = 0;
    }
    
    
    function mining() public {
        bool pow;
        bytes32 previous = keccak256(abi.encodePacked(chain[mine].blocknumber, chain[mine].previous, chain[mine].merkle_root));
        if(previous == chain[mine].block_hash) {
            pow = true;
        } else {
            pow = false;
        }
        
        
        if(pow == true){
            chain[mine+1].blocknumber = mine+1;
            chain[mine+1].previous = bytes32(uint(mine+1));
            chain[mine+1].merkle_root = bytes32(uint(mine+1));
        
            chain[mine+1].block_hash = bytes32(keccak256(abi.encodePacked(chain[mine+1].blocknumber, chain[mine+1].previous, chain[mine+1].merkle_root)));
            
            mine ++;
        }
    }
    
    function InfoCurrentChain() public view returns(uint, bytes32 , bytes32 , bytes32){
        return(chain[mine].blocknumber, chain[mine].previous, chain[mine].merkle_root, chain[mine].block_hash);
    } 
}