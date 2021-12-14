/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.4.18;

contract Company {
    address owner;
    uint256 public amount;
    string name;
    uint public unLockTime = now + 365 days;

    function Company() payable public {
        owner = msg.sender;
        amount = msg.value;
    }

    modifier onlyOwnweAttime {
        require(msg.sender == owner && unLockTime < now);
        _;
    }
    function send() public onlyOwnweAttime {
        selfdestruct(owner);
    }
        
    function fallback() external payable {
    }
    
    function receive() external payable {
    }

}