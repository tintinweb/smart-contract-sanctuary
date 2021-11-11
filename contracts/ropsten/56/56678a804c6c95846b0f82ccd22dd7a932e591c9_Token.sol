/**
 *Submitted for verification at Etherscan.io on 2021-11-11
*/

/**
 *Submitted for verification at Etherscan.io on 2021-11-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.4.22;

contract owned {
    address owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

contract mortal is owned {
    
    function destroy() public onlyOwner{
        selfdestruct(owner);
    }
}

contract Faucet is mortal{
    event Withdrawal(address indexed to, uint amount);
    event Deposit(address indexed from, uint amount);

    function withdraw(uint withdraw_amount) public {
        
        require(withdraw_amount <= 0.1 ether);
        require(this.balance >= withdraw_amount);
        msg.sender.transfer(withdraw_amount);
        emit Withdrawal(msg.sender, withdraw_amount);
    }

    function () public payable{
    emit Deposit(msg.sender, msg.value);
    }
}

contract Token is mortal {

    constructor(address _faucet) {
        if (!(_faucet.call("withdraw", 0.1 ether))){
            revert("Withdrawl from faucet failed");
        }
    }
}