/**
 *Submitted for verification at BscScan.com on 2021-07-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract MyContract {

    uint256 number;

  
    function store(uint256 num) public isOwner{
        number = num;
    }

    
    function retrieve() public view returns (uint256){
        return number;
    }
    
    
        address private owner;
    
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    

    modifier isOwner() {
        
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        emit OwnerSet(address(0), owner);
    }

   
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

   
    function getOwner() external view returns (address) {
        return owner;
    }
    
    
    
    
    
}