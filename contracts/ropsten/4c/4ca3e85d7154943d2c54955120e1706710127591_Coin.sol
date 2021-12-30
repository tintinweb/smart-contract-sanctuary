/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity  >=0.7.0 <0.9.0;

contract Coin {

    address public minter;

    mapping (address => uint) public balances;

    // 会在 send 
    event Send(address from, address to, uint amount);

    // 只有创建时运行
    constructor() {
        minter = msg.sender;
    }


    function mint(address receiver, uint amount) public {
        require(msg.sender == minter);
        require(amount < 1e60);

        balances[receiver] += amount;
    }

    function send(address receiver, uint amount) public {

        require(amount <= balances[msg.sender], "Insufficient balance!");

        balances[msg.sender] -= amount;
        balances[receiver] += amount;

        emit Send(msg.sender, receiver, amount);

    }

}