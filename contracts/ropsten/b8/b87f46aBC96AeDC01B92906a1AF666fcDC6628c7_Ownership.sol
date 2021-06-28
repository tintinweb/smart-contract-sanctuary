/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.20;

contract Ownership {
    
    address payable contract_owner = payable(msg.sender);
    
    function changeOwner(address payable new_owner) external {
        assert(msg.sender==contract_owner);
        contract_owner = new_owner;
    }
    
    receive() external payable { 
        // used to pay developers, servers, marketing etc
        contract_owner.transfer(msg.value);
    }
    
    fallback() external payable { 
        // used to pay developers, servers, marketing etc
        contract_owner.transfer(msg.value);
    }
}