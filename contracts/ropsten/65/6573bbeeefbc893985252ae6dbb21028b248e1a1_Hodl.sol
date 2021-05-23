/**
 *Submitted for verification at Etherscan.io on 2021-05-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Hodl{
    
    address payable owner_address;
    string owner;
    uint256 bal;
    uint start;
    
    constructor(string memory name, uint256 value) {
        owner = name;
        owner_address = payable(msg.sender);
        bal = value;
        start = block.timestamp;
    }
    
    function checkTime() public view returns(bool){
        if ((block.timestamp -  start) >= 365*1 days ){
            return true;
        }
        else{
            return false;
        }
    }
    
    function Destroy() external {
        require(owner_address == payable(msg.sender), "You are not the owner");
        require(checkTime(), "Time is not up");
        selfdestruct(owner_address);
    }
}