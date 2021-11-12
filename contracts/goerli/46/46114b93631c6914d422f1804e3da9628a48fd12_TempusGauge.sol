/**
 *Submitted for verification at Etherscan.io on 2021-11-12
*/

pragma solidity ^0.8.0; 

interface TempusVault {

// Function: depositAndFix(address tempusAMM, uint256 tokenAmount, bool isBackingToken, uint256 minTYSRate) 
function depositAndFix(address tempusAMM, uint256 tokenAmount, bool isBackingToken, uint256 minTYSRate) external;
function approve(address spender, uint256 tokens) external;
function completeExitAndRedeem(address tempusAMM, uint256 maxLeftoverShares, bool toBackingToken) external;

}

contract TempusGauge {
    
event checklog(address _checkadd, uint256 _tamount, bool _backing, uint _mintys);
    
address private vault = 0xd4330638b87f97Ec1605D7EC7d67EA1de5Dd7aaA;
address private tempusAMM = 0xD7E0287c555568416956435B0C8777AD376f8040;

function depositFunds(address _address, uint256 _tokenAmount, bool _isbackingtoken, uint256 _minTYSRate) public {
TempusVault(vault).depositAndFix(_address, _tokenAmount, _isbackingtoken, _minTYSRate);
emit checklog(_address, _tokenAmount, _isbackingtoken, _minTYSRate);
    
}
}