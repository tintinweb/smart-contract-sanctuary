/**
 *Submitted for verification at polygonscan.com on 2021-07-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {
    
    uint256[3] public numbers;
    
    event called(uint256[] indexed numbers);
    
    function placeBet(uint256[] memory _num) public {
        
    }


}