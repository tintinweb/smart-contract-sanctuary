/**
 *Submitted for verification at polygonscan.com on 2022-01-21
*/

pragma solidity ^0.4.19;

contract Bank22 {

    mapping(address => uint256) public balanceOfNYC;   // balances, indexed by addresses

    function depositNYC(uint256 amount) public payable {
        require(msg.value == amount);
        balanceOfNYC[msg.sender] += amount;     // adjust the account's balance
    }

    function withdrawNYC(uint256 amount) public {
        require(amount <= balanceOfNYC[msg.sender]);
        balanceOfNYC[msg.sender] -= amount;
        msg.sender.transfer(amount);
    }
}