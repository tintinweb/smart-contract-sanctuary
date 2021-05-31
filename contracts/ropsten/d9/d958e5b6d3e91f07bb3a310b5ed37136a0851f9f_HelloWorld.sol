/**
 *Submitted for verification at Etherscan.io on 2021-05-31
*/

pragma solidity ^0.4.0;

contract HelloWorld{

    uint balance;

    function update(uint amount) returns (address, uint){

        balance += amount;

        return (msg.sender, balance);

    }

}