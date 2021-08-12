// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Context.sol";
import "./Ownable.sol";

import "./ManagerInterface.sol";
import "./HelloNFTInterface.sol";

contract Manager is ManagerInterface, Context, Ownable
{
    HelloNFTInterface public masterContract;
    
    function onlyBanker (address sender) override external view returns (bool) {
        return sender == address(this);
    }
    
    function onlySpawer (address sender) override external view returns (bool) {
        return sender == address(this);
    }
    
    function setMasterContract (address _contract) public {
        masterContract = HelloNFTInterface(_contract);
    }
    
    function sendRewards (address to, uint256 amount) public onlyOwner {
        masterContract.rewards(to, amount);
    }
}