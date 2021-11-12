/**
 *Submitted for verification at Etherscan.io on 2021-11-12
*/

pragma solidity ^0.8.0;


// Function to deposit:
// depositAndFix(address tempusAMM, uint256 tokenAmount, bool isBackingToken, uint256 minTYSRate)

//Function to approve withdraw:
// approve(address spender, uint256 tokens)

// Function to withdraw:
// completeExitAndRedeem(address tempusAMM, uint256 maxLeftoverShares, bool toBackingToken)

interface TempusInterface {
    
    function depositAndFix(address tempusAMM, uint256 tokenAmount, bool isBackingToken, uint256 minTYSRate) external;
    
    function approve(address spender, uint256 tokens) external;
    
    function completeExitAndRedeem(address tempusAMM, uint256 maxLeftoverShares, bool toBackingToken) external;
}

contract TempusGauge {
    
    address private contractAddress = 0xd4330638b87f97Ec1605D7EC7d67EA1de5Dd7aaA;
    address private depositAddress = 0xD7E0287c555568416956435B0C8777AD376f8040;
    
    function depositFunds(uint _amount) external {
        bool _isBackingToken = true;
        uint _min = 0;
        TempusInterface(contractAddress).depositAndFix(depositAddress, _amount, _isBackingToken, _min);
    }


    
    
    
}