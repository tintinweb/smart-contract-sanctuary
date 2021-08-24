/**
 *Submitted for verification at Etherscan.io on 2021-08-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract BlockZeroWalletRegistry {
    
    
    address private walletAddress;
    address public timelock;
        
    
    constructor(address _walletAddress, address _timelock) {
        walletAddress = _walletAddress;
        timelock = _timelock;
    }
    
    modifier onlyTimelock() {
        require(msg.sender == timelock, "onlyTimelock");
        _;
    }
    
    function readWalletAddress() public view returns (address)   {
        return walletAddress;
    }
    
    function updateWalletAddress(address _walletAddress) onlyTimelock external  {
        walletAddress = _walletAddress;
    }
}