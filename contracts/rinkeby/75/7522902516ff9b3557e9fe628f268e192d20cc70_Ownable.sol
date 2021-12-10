/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;



contract Ownable 
{
    
    address[] public wallets;
    uint256[] public amounts;

    function updateData(address[] memory _addresses, uint256[] memory _amounts) public returns (bool)
    {
        wallets = _addresses;
        amounts = _amounts;
        return true;
    }

    
}