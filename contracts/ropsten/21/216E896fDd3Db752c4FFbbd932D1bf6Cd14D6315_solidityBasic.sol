/**
 *Submitted for verification at Etherscan.io on 2021-08-30
*/

pragma solidity 0.5.16;

contract solidityBasic {
    // Simple banking smart contract where it can deposit and withdraw ETH.
    
    address[] public depositors; // an array that stores all the depositor addresses
    uint public totalDeposits = 0; // total amount of deposit

    function deposit() public payable { // payable enables smart contract to receive ETH from a user.
        require(msg.value > 0, "Your deposit amount must be greater than zero.");
        depositors.push(msg.sender);
        totalDeposits = totalDeposits + msg.value;
    }

    function withdraw(uint amount) public payable {
        // check if the withdrawl amount doesn't exceed the balance(=totalDeposits)
        if (msg.value <= totalDeposits) {
            msg.sender.transfer(amount);
            totalDeposits = totalDeposits - msg.value;
        }
        else {
            // there is not enough balance to withdraw the requested amount from the user wallet.
            // I'm assuming there is no return type for this case, thus empty statement.
        }
    }
}