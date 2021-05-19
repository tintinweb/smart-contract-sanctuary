/**
 *Submitted for verification at Etherscan.io on 2021-05-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.0;

contract Owned {
    address owner;
    
    constructor() internal {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

contract Mortal is Owned {
    function destoy() public onlyOwner {
        selfdestruct(payable(owner));
    }
}

/**
 * @title Faucet
 */
contract AdvancedFaucet is Mortal {
    event Withdrawal(address indexed to, uint amount);
    event Deposit(address indexed from, uint amount);
    
    // Accept any incoming amount
    receive () external payable {
        emit Deposit(msg.sender, msg.value);
    }
    
    function withdraw(uint withdraw_amount) public {
        // Limit withdraw_amount
        require(
            withdraw_amount <= 0.1 ether, 
            "Only amount below 0.1 ether is allowed"
        );
        
        // Then transfer designated amount to sender of this msg
        msg.sender.transfer(withdraw_amount);
        emit Withdrawal(msg.sender, withdraw_amount);
    }
}