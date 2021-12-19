/**
 *Submitted for verification at polygonscan.com on 2021-12-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

// Description:
// This is a naive implementation (and just a stupid idea altogether) of a shared wallet where users can:
// 1. Deposit funds in the contract and have their balances tracked.
// 2. A user should not be able to withdraw from their wallet until at least 2 blocks have passed since the wallet
// was initially created (not yet implemented).
// 3. Withdraw funds up to the amount that they have deposited.
// 4. The owner of the contract should also have the ability to emergency withdraw all of the funds.

// There are a number of bugs and security vulnerabilities.


// TODO:
// 1. Please remedy as many bugs/exploits as you can.

// 2. Implement the 2 block withdrawal time limit outlined in #2 above ^.

// 3. Deploy the contract to the Polygon Mumbai Testnet and send your recruiter the contract address.

contract SharedWallet {

    address public _owner;
    uint public totalFunds = 0 ether;
    mapping(address => uint) public _walletBalances;

    modifier isOwner() {
        require(msg.sender == _owner);
        _;
    }

    constructor () public payable {
        _owner = msg.sender;
    }

    fallback () external payable {
        _walletBalances[msg.sender] += msg.value;
    }

    function withdraw(uint amount) public {
        msg.sender.transfer(amount);
        _walletBalances[msg.sender] -= amount;
    }

    function emergencyWithdrawAllFunds (uint amount) isOwner public {
        require(tx.origin == _owner);
        msg.sender.transfer(amount);
    }

    function deposit() external payable {}

    function balanceOf() external view returns(uint) {
     //   totalFunds = address(this).balance;
        return address(this).balance;
    }

}//end SharedWallet