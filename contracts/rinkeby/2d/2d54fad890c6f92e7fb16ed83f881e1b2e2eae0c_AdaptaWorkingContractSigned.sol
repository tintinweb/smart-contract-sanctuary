/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract AdaptaWorkingContractSigned {

    
    mapping(address => bool) public address_signed_working_contract;

    function sign_contract() public {
        require(address_signed_working_contract[msg.sender] == false, "You already have signed the contract");
        
        address_signed_working_contract[msg.sender] = true;
    }

}