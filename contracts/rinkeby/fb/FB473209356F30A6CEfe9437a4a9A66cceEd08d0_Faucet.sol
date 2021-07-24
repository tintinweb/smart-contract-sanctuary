/**
 *Submitted for verification at Etherscan.io on 2021-07-24
*/

// SPDX-License-Identifier: GPL -3.0
pragma solidity 0.8.6;


contract Faucet {
    // Accept any incoming amount
    address private owner;
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
    }
    receive() external payable {}

    // Give out ether to anyone who asks
    function withdraw(uint withdraw_amount) public isOwner{
        payable(msg.sender).transfer(withdraw_amount);
    }
    function balance()external view returns(uint256){
        return payable(address(this)).balance;
    }

    function balancemsgsender()external view returns(uint256){
        return payable(msg.sender).balance;
    }
}