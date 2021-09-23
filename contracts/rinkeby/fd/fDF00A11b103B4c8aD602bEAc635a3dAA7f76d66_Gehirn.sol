/**
 *Submitted for verification at Etherscan.io on 2021-09-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;



// File: Gehirn.sol

/** 
 * @title Gehirn von Thomas Wenzlaff
 * @dev Mein Smart Contract mit solidity zum Speichern von IQ auf der Blockchain
 */
contract Gehirn {
    
    uint256 iq = 0;
    
    function store(uint256 neuerIQ) payable public {
        iq = neuerIQ;
    } 
    
    function retrieve() public view returns (uint256){
        return iq;
    }
}