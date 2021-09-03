/**
 *Submitted for verification at Etherscan.io on 2021-09-03
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
    address public USDC;
    uint256 public USDC_flux;
    address owner;
    
    modifier onlyOwner(){
        require(msg.sender == owner, "onlyOwner");
        _;
    }
    
    constructor(address usdc){
        owner = msg.sender;
        USDC = usdc;
        USDC_flux = 1000*10**18;
        
    }
    
    function setUSDC(address addr) external onlyOwner{
        USDC = addr;
    }
    
   
    
    function getUSDC() external{
        Token(USDC).transfer(msg.sender, USDC_flux);
    }
    
    
}