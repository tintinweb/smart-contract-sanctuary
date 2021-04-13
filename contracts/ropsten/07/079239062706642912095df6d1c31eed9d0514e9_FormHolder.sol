/**
 *Submitted for verification at Etherscan.io on 2021-04-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
//pragma experimental ABIEncoderV2;

contract FormHolder {
    
    struct FormData {
        string userId;
        string idea;
    }

    mapping(uint256 => FormData) public formRepo;

    function setForm(uint256 uuid, string memory userId, string memory idea) public 
    {
        formRepo[uuid].userId = userId;
        formRepo[uuid].idea = idea;
    }

    function getForm(uint256 uuid) public view
        returns (FormData memory usersFormData)
    {
        usersFormData = formRepo[uuid];
    }
}