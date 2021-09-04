/**
 *Submitted for verification at Etherscan.io on 2021-09-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.4.22;

contract owned {
    address owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }
}


contract mortal is owned {
    function destroy() public onlyOwner {
        selfdestruct(owner); // the owner will receive the balance in the contract
    }
}


contract Faucet is mortal {
    // indexed --> allows events to be searched in log analysis UIs
    event Withdrawal(address indexed sender, uint amount);
    event Deposit(address indexed sender, uint amount);
    
    function withdraw(uint withdraw_amount) public {
            require(withdraw_amount <= 0.1 ether,
                    "0.1 eth limit per withdrawal");
            require(address(this).balance >= withdraw_amount,
                    "Not enough funds in contract");
        
        msg.sender.transfer(withdraw_amount);
            emit Withdrawal(msg.sender, withdraw_amount);
    }
    
    function () external payable {
            emit Deposit(msg.sender, msg.value);
    }
}