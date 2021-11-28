/**
 *Submitted for verification at BscScan.com on 2021-11-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.16;

contract ActivityAccount  {

    address payable public  governance;

    mapping (address => bool) public userPurchaseRecord;

    constructor () public  {
        governance = tx.origin; 
    }


  function setGovernance(address payable _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function purchaseActiveAuthority() public payable returns(bool success) {
        require(msg.value > 0, "! not balance");
        require(msg.value == 100000000000000000 , "must 0.1 BNB"); // 0.1 BNB
        // require(msg.value == 1000000000000000000 , "! not balance");
        governance.transfer(msg.value); 
        userPurchaseRecord[msg.sender] = true; 
        return true;
    }

    function checkUserIsActive(address account) public view returns (bool) {
        return userPurchaseRecord[account];
    }
}