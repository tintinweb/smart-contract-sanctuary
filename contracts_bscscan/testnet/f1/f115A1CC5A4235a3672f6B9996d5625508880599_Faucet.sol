/**
 *Submitted for verification at BscScan.com on 2021-09-16
*/

/**
 *Submitted for verification at Etherscan.io on 2021-08-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface Token {
    function transfer(address, uint256) external returns(bool);
    function balanceOf(address account) external view returns (uint256);
}

contract Faucet {
    address public GTA;
    uint256 public GTA_flux;
    address owner;
    
    modifier onlyOwner(){
        require(msg.sender == owner, "onlyOwner");
        _;
    }
    
    constructor(address usdc){
        owner = msg.sender;
        GTA = usdc;
        GTA_flux = 100*10**18;
        
    }
    
    function setUSDC(address addr) external onlyOwner{
        GTA = addr;
    }
    
   
    
    function getGTA() external{
        Token(GTA).transfer(msg.sender, GTA_flux);
    }
    
    
}