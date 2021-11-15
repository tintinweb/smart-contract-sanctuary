// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Test{

    mapping(address => uint) balances;

    function deposit() public payable{
        balances[msg.sender] = msg.value;
    }

    function withdraw(uint value) public{
        require(balances[msg.sender] >= value, "The Balances is not enough");
        (msg.sender).transfer(value);
        balances[msg.sender] -= value;
    }
}

