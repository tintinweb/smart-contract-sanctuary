/**
 *Submitted for verification at Etherscan.io on 2021-11-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract TestCheckForKey { 
    
    bool public claimed;
    
    uint256 public constant checkPrice = 0.02 ether;
    uint256 public constant buyoutPrice = 0.00001 ether;
    
    uint256 public claimAttempts;
    
    address public buyoutClaimerAddress;
    
    event BuyoutOccurred(address _who);
    event NftCheck(address _checker, string _message);
    
    function setCliamed(bool _bool) public {
        claimed = _bool;
    }    
    
    function checkForKey() public payable {
        require(!claimed, "NFT has already been claimed!");
        require(msg.value == checkPrice, "Send 0.02 ETH");
        
        // Evens
        if (claimAttempts % 2 == 0) {
            emit NftCheck(msg.sender, "is the key holder!");
            claimAttempts++;
            setCliamed(true);
        } 
        
        emit NftCheck(msg.sender, "was not the key holder");
        claimAttempts++;
        setCliamed(false);
    }
    
    // In testint this, I'll need to manually set claimed back to false
    function buyout() public payable {
        require(!claimed, "NFT has already been claimed!");
        require(msg.value == buyoutPrice, "Send 10 ETH.");
        
        emit BuyoutOccurred(msg.sender);
        buyoutClaimerAddress = msg.sender;
        
        setCliamed(true);
    }
    
    function withdraw() external { 
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Address: unable to send value, recipient may have reverted");       
    }
}