/**
 *Submitted for verification at Etherscan.io on 2021-10-31
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract FluffyRaffle {
    
    uint256[] public results;

    function raffle() public {
        
        uint256 randomResult = 2718995605243167949223118015739551412378506416483025288945453256892201849746;
        uint256 numberOfWinners = 110;
        uint256 currentSupply = 9342;

        for (uint256 i = 0; i < numberOfWinners; i++) {
            uint256 random = uint256(keccak256(abi.encode(i, randomResult))) % currentSupply;
            results.push(random);
        }
    }
    
}