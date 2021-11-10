/**
 *Submitted for verification at Etherscan.io on 2021-11-10
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract NamePlate{
    address public owner;
    string public ownerName;
    uint public bidAmount = 1000000000;
    
    constructor(){
        owner = msg.sender;
        ownerName = "Mathew";
    }
    
    event NewOwner(address owner, string name);
    
    modifier higherBid{
        require(msg.value <= bidAmount, "bidAmount greater than the amount sent");
        _;
    }
    
    function bid(string memory _name) external payable higherBid{
        owner = msg.sender;
        bidAmount = msg.value;
        ownerName = _name;
        emit NewOwner(owner, ownerName);
    }
}