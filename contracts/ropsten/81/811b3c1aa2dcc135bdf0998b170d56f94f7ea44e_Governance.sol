/**
 *Submitted for verification at Etherscan.io on 2021-09-05
*/

// SPDX-License-Identifier: DEFI

pragma solidity 0.7.0; // Solidity compiler version

contract Governance {
    
    uint16 minimumNumberOfVotes;
    uint16 currentVotes = 0;
    bool isValid = true;
 
    constructor(uint16 _minimumNumberOfVotes) {
        minimumNumberOfVotes = _minimumNumberOfVotes;
    }
    
    function voteUp() public returns(bool _success){
        
        // Increment
        currentVotes += 1;
        
        // Check
        if (currentVotes > minimumNumberOfVotes){
            isValid = false;
            currentVotes = 0;
        }
        
        return true;
        
    }
    
    // Just for testing
    function changeIsValid(bool input) public returns(bool _success){
        isValid = input;
        return true;
    }
    
    function getIsValid() public view returns(bool _isValid){
        return isValid;
    }
    
}