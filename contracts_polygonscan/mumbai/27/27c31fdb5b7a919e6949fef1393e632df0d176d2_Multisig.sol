/**
 *Submitted for verification at polygonscan.com on 2021-09-21
*/

pragma solidity 0.8.7;
//SPDX-License-Identifier: MIT

contract Multisig {
    
    address owner;
    address constant sig = 0xA1eb0F1f494854A6087cfb079D9Ca81101273Bbc;
    uint256 request = 0;
    
    event Withdrawal(uint256 amount, bool success);
    
    constructor() {
        owner = msg.sender;
    }
    
    // receive external() payable {}
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlySig {
        require(msg.sender == sig);
        _;
    }
    
    modifier onlyAuth {
        require(msg.sender == sig || msg.sender == owner);
        _;
    }
    
    modifier withdrawalIssued {
        require(request != 0);
        _;
    }
    
    function issueWithdrawal(uint256 _amount) onlyOwner public {
        request += _amount;
    }
    
    function cancelWithdrawal() withdrawalIssued onlyAuth public {
        request = 0;
    }
    
    function deductRequest(uint256 _amount) withdrawalIssued onlyAuth public {
        request -= _amount;
    }
    
    function finalizeWithdrawal() withdrawalIssued onlySig public {
        payable(owner).transfer(request);
        request = 0;
        emit Withdrawal(request, true);
    }
    
    function getRequest() view public returns (uint256) {
        return request;
    }
}