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
    address public LUCA;
    uint256 public LUCA_flux;
    address public ZMT;
    uint256 public ZMT_flux;
    address owner;
    
    modifier onlyOwner(){
        require(msg.sender == owner, "onlyOwner");
        _;
    }
    
    constructor(address luca, address zmt){
        owner = msg.sender;
        LUCA = luca;
        ZMT = zmt;
        LUCA_flux = 100*10**18;
        ZMT_flux = 100*10**18;
    }
    
    function setLuca(address addr, uint256 flux) external onlyOwner{
        LUCA = addr;
        LUCA_flux = flux;
    }
    
    function setZMT(address addr, uint256 flux) external onlyOwner{
        ZMT = addr;
        ZMT_flux = flux;
    }
    
    function getLuca() external{
        Token(LUCA).transfer(msg.sender, LUCA_flux);
    }
    
    
    function getZMT() external{
        Token(ZMT).transfer(msg.sender, LUCA_flux);
    }
}