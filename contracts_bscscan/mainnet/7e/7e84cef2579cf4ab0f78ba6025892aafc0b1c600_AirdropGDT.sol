/**
 *Submitted for verification at BscScan.com on 2021-08-31
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.7.6;

interface IGorillaDiamond {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function approve(address spender, uint256 amount) external returns (bool);
}

contract AirdropGDT {

    IGorillaDiamond gorillaDiamondInstance = IGorillaDiamond(0xb7F2bca9b034f8cc143339Dd12bb31D3D50Cf27a);
    
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
    
    function destroy() external onlyOwner {
        address payable receiver = msg.sender;
        selfdestruct(receiver);
    }

    
    // contract variables and functions for loading then transferring from array separately
    address[] public accounts;
   
    function pushToArray(address receiver) external onlyAdmin returns(bool) {
        accounts.push(receiver);
        return true;
    }
    
    function popFromArray() external onlyAdmin returns(bool) {
        accounts.pop();
        return true;
    }

    function clearArray() external onlyAdmin returns(bool) {
        for(uint8 j = 0; j < accounts.length; j) {
            accounts.pop();
        }
        return true;
    }

    function setSingleAddressSmall(uint arrayPosition, address address1) external onlyAdmin returns(bool) {
        accounts[arrayPosition] = address1;
        return true;
    }

    function getArray() external view returns(address[] memory) {
        return accounts;
    }
    
    function setArray(address[] calldata _addresses) external onlyAdmin {
        accounts = _addresses;
    }
    
    function transferArray(uint amount) public onlyAdmin returns(bool) {
        for (uint8 i = 0; i < accounts.length; i++) {
            require(gorillaDiamondInstance.transfer(accounts[i], amount), 'transferFrom failed');
        }
        return true;
    }

    
    // contract function for loading then transferring from array together
    function transferToAll(address[] calldata _addresses, uint amount) external onlyAdmin returns(bool) {
        
        for (uint8 i = 0; i < _addresses.length; i++) {
            require(gorillaDiamondInstance.transfer(_addresses[i], amount), 'transferFrom failed');
        }
        return true;
    }

    
    receive() payable external {}

}