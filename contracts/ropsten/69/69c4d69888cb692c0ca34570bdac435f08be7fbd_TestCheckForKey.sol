/**
 *Submitted for verification at Etherscan.io on 2021-09-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract TestCheckForKey { 
    
    bool public claimed;
    uint256 public constant checkPrice = 0.02 ether;
    uint256 public claimAttempts;
    
    event NftCheck(address _checker, string _message);
    
    function setCliamed(bool _bool) public {
        claimed = _bool;
    }    
    
    function checkForKey() public payable returns (bool) {
        require(!claimed, "NFT has already been claimed!");
        require(msg.value == checkPrice, "Send 0.02 ETH");
        
        // Evens
        if (claimAttempts % 2 == 0) {
            emit NftCheck(msg.sender, "is the key holder!");
            claimAttempts++;
            return true;
        } 
        
        emit NftCheck(msg.sender, "was not the key holder");
        claimAttempts++;
        return false;
    }
}