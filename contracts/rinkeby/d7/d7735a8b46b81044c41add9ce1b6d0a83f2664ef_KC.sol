/**
 *Submitted for verification at Etherscan.io on 2021-09-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract KC {
    
    address public manager;
    string[] public kc;
    
    constructor(){
        manager = msg.sender;
    }
    
    modifier restricted_by_manager(){
        require(msg.sender == manager);
        _;
    }
    
    function addkc(string memory title) public restricted_by_manager{
        kc.push(title);
    }
    
    function getkcCount() public view returns (uint){
        return kc.length;
    }
    
    function getkcByIndex(uint  index) public view returns (string memory){
        return kc[index];
    }
        
}