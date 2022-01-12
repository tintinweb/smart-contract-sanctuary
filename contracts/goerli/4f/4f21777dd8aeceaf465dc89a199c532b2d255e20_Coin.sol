/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
contract Coin{

    address public minter;
    mapping (address => uint) public balance;
    event Sent(address from, address to, uint amount);

    constructor(){
        minter = msg.sender;
    }

    function mint(address receiver, uint amount) public {
        require(msg.sender == minter);
        balance[receiver] +=amount;
    }

    error InsufficientBalance(uint requested, uint available);

    function send(address receiver, uint amount) public{
        if(amount > balance[msg.sender])
            revert InsufficientBalance({
                requested: amount,
                available: balance[msg.sender]
            });
        balance[msg.sender] -=amount;
        balance[receiver] += amount;
        emit Sent(msg.sender,receiver,amount);


    }


}