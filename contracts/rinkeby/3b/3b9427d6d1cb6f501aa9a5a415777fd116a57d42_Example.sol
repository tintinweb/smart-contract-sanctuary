/**
 *Submitted for verification at Etherscan.io on 2021-11-01
*/

pragma solidity ^0.8.0;



struct IDonor {
    address contractAddress;
    uint256 tokenId;  
}

contract Example {
    // IDonor[] _donors = [];
    // n Pool of m NFTs 
    // Example donor of pool 1 -> donor 3 -> address -> number (position) NFT #TokenId
    mapping(uint256 => IDonor[]) public donors;
    // function isDonorAvailable(uint256 pool, uint256 donor, address contractAddress, uint256 position) public view returns (bool) { 
    //     return donors[pool][donor][contractAddress][position];
    // }
    
    event GENERATED_NUMBER(uint256);
    
    function addDonor(uint256 pool, address contractAddress, uint256 tokenId) public { 
         donors[pool].push(IDonor(contractAddress, tokenId));
    } 
    
     function deleteDonor(uint256 pool, address contractAddress, uint256 tokenId) public { 
         uint256 index;
        for(uint256 i = 0 ; i  < donors[pool].length ; i ++){
         if(donors[pool][i].tokenId == tokenId && donors[pool][i].contractAddress == contractAddress){
             index = i;
             break;
         }   
        }
        
        if(index >= 0){
            delete donors[pool][index];
        }
    }  
    
    function isDonorAvailable(uint256 pool, address contractAddress, uint256 tokenId) public view returns (bool) {
         for(uint256 i = 0 ; i < donors[pool].length; i++){
            if(donors[pool][i].tokenId == tokenId && donors[pool][i].contractAddress == contractAddress){
             return true;
         }   
        }
        return false;
    }
    
     function random(uint256 pool) private view returns (uint) {
        // sha3 and now have been deprecated
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, donors[pool].length)));
        // convert hash to integer
        // players is an array of entrants
        
    }
    
    function generateRandomNumber(uint256 pool) public {
        uint256 generatedNo = random(pool);
        emit GENERATED_NUMBER(generatedNo);
    }
}