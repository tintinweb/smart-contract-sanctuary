/**
 *Submitted for verification at Etherscan.io on 2021-07-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract MyContract {

    string Text;

  
    function store( string memory _text) public isOwner{
        Text = _text;
    }


    
    function retrieve() public view returns (string memory){
        return Text;
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