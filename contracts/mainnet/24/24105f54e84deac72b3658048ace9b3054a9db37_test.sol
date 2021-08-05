/**
 *Submitted for verification at Etherscan.io on 2020-11-29
*/

pragma solidity ^0.7.0;
//SPDX-License-Identifier: UNLICENSED

contract test{
    mapping(address => bool) whitelisted;
    
    function whitelist(address[] memory addresses) external{
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelisted[addresses[i]] = true;
        }
    }
    
    function isWhitelisted(address addr) public view returns(bool){
        return whitelisted[addr];
    }
}