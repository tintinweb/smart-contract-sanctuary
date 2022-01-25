/**
 *Submitted for verification at Etherscan.io on 2022-01-24
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract PiggyBank{
    event Deposite(uint amount);
    event Withdraw(uint amount);

    address public owner = msg.sender;

    receive() external payable{
        emit Deposite(msg.value);
    }

    function withdraw() external{
        require(msg.sender == owner, "not owner");
        emit Withdraw(address(this).balance);
        selfdestruct(payable(msg.sender));
    }

    function getba() public view returns(uint){
        return address(this).balance;
    }
}