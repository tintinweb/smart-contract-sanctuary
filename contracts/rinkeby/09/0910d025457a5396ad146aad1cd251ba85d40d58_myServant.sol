/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

 interface faucetInterface {
  function getTokens() external view;
}


contract myServant {
    address public faucetAddress;
    address public homeContractAddress;
    address deployer = msg.sender;
    
    function setFaucetAddress(address _faucetAddress) public {
        faucetAddress = _faucetAddress;
    }
    
    function sethomeContractAddress(address _homeContractAddress) public {
        homeContractAddress = _homeContractAddress;
    }
    
    function getTokensFromFaucet() public payable{
       faucetInterface faucet = faucetInterface(faucetAddress);
        return faucet.getTokens();
    }
}