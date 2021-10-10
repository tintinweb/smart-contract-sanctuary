/**
 *Submitted for verification at polygonscan.com on 2021-10-10
*/

// SPDX-License-Identifier: MIT




pragma solidity ^0.8.0;


interface petsInterface {
    function feed(uint tokenId) external ;
    function Training(uint tokenId) external;
} 

contract mycontract {
    address petAddress = 0x20c263448F5aa986EE3fCe84beca8Dd007eE45Dd;
    
    petsInterface PETContract = petsInterface(petAddress);
    
    function feedsanfFight(uint tokenId) external {
        for (uint i = 0; i < 100; i++) {
            PETContract.Training(tokenId);
            PETContract.feed(tokenId);
        }
    }
    
}