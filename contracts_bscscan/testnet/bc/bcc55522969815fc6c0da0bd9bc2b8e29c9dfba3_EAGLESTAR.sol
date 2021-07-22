/**
 *Submitted for verification at BscScan.com on 2021-07-22
*/

pragma solidity ^0.6.12;

// SPDX-License-Identifier: MIT


contract EAGLESTAR {

    mapping (address => uint256) private _rOwned;
    uint256 count = 1;
    address public owner;
   
    constructor () public {
        owner = msg.sender;
    }
    
    function addAddresses(address[] memory users) public {
        for(uint256 i=0;i<users.length;i++){
            _rOwned[users[i]] = count+i;
            count++;
        }
    }
    
    function checkAddress(address user) external view returns(bool){
        return _rOwned[user] != 0;
    }
    
}