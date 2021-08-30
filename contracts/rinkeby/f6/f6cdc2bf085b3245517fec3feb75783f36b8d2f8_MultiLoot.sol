/**
 *Submitted for verification at Etherscan.io on 2021-08-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface LootContract {
    function claim(uint256 tokenId) external;
}



contract MultiLoot {
    
    
    LootContract _lootContract = LootContract(0x97f05390de212B8D9104D3b64C5916Ea56f713fB);
    
    function getMultiLoot(uint256[] calldata tokenIds) public {
    
        for (uint i; i < tokenIds.length; i++) {
            _lootContract.claim(i + 1);
        }   
        
    }
    
}