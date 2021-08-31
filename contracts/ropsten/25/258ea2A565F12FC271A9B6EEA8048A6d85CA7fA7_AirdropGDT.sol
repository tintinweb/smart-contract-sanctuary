/**
 *Submitted for verification at Etherscan.io on 2021-08-31
*/

// Name: GDT Airdrop
// Author: Ben Gehmlich
// Date: August 4, 2021

// This contract code is an original work
// and may not be used, in part or in whole, without the written authorization of the author and of Gorilla Diamond Inc.

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;

interface IGorillaDiamond {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function approve(address spender, uint256 amount) external returns (bool);
}

contract AirdropGDT {

    IGorillaDiamond gorillaDiamondInstance = IGorillaDiamond(0x4835f57826FcFD2b26B399d56fF429fF1739ff5c);
    
    // contract variables and functions for administration
    address public owner;  
    mapping(address => bool) public admins;
     
    modifier onlyOwner {               
        require(msg.sender == owner);   
        _;   
    }

    modifier onlyAdmin() {
        require(admins[msg.sender] == true);
            _;
    }
    
    constructor(){                     
         owner = msg.sender;
         admins[msg.sender] = true;
    }

    function addAdmin(address userAddress) external onlyAdmin {
            admins[userAddress] = true;    
    }
    
    function removeAdmin(address userAddress) external onlyAdmin {
            admins[userAddress] = false;    
    }

    
    // contract variables and functions for loading then transferring from array separately
    address[] public accounts;
   
    function pushToArray(address receiver) external onlyAdmin {
        accounts.push(receiver);
    }
    
    function popFromArray() external onlyAdmin {
        accounts.pop();
    }

    function clearArray() external onlyAdmin {
        for(uint8 j = 0; j < accounts.length; j) {
            accounts.pop();
        }
    }

    function getArray() public view returns(address[] memory) {
        return accounts;
    }
    
    function transferArray(uint amount) external onlyAdmin {
        for (uint8 i = 0; i < accounts.length; i++) {
            require(gorillaDiamondInstance.transfer(accounts[i], amount), 'transferFrom failed');
        }
    }

    
    // contract function for loading then transferring from array together
    function transferToAll(address[] calldata _addresses, uint[] calldata amount) external onlyAdmin {
        
        for (uint8 i = 0; i < _addresses.length; i++) {
            gorillaDiamondInstance.transfer(_addresses[i], amount[i]);
        }
    }

    
    receive() payable external {}

}