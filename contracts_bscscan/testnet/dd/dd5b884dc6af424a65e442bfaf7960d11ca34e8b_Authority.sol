/**
 *Submitted for verification at BscScan.com on 2021-10-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Authority {
    address public owner;
    mapping (address => bool) public admin;
    
    modifier onlyOnwer(){
        require(msg.sender == owner, "access denied");
        _;
    }
    
    modifier onlyAdmin() {
        require(admin[msg.sender] || msg.sender == owner, "access denied");
        _;
    }
    
    function changeOwner(address newOwner) public onlyOnwer {
        owner = newOwner;
    }
    
    function setAdmin(address user, bool b) public onlyOnwer {
        admin[user] = b;
    }    
}