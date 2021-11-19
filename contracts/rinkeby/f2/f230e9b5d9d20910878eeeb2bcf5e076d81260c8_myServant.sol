/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

 interface faucetInterface {
  function getTokens() external view;
}


contract myServant {
    address faucetAddress;
    address homeContractAddress;
    address deployer = msg.sender;
    
    function setFaucetAddress(address _faucetAddress) external {
        faucetAddress = _faucetAddress;
    }
    
    function sethomeContractAddress(address _homeContractAddress) external {
        homeContractAddress = _homeContractAddress;
    }
    
    function getTokensFromFaucet() external payable{
       faucetInterface faucet = faucetInterface(faucetAddress);
        return faucet.getTokens();
    }
}