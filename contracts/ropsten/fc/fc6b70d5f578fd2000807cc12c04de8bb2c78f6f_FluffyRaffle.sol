/**
 *Submitted for verification at Etherscan.io on 2021-10-31
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract FluffyRaffle {
    
    uint256[] public results;
    string public result;


    function raffle() public {
        
        uint256 randomResult = 20316769326685189292057703141521220704725457566228150735692488265362209334950;
        uint256 numberOfWinners = 110;
        uint256 currentSupply = 9342;

        for (uint256 i = 0; i < numberOfWinners; i++) {
            uint256 random = uint256(keccak256(abi.encode(i, randomResult))) % currentSupply;
            results.push(random);
        }
    }
    
}