/**
 *Submitted for verification at BscScan.com on 2021-11-10
*/

pragma solidity 0.5.13;

contract X3plan {

    mapping(address => uint) public balances;

    event Deposit(address sender, uint amount);
    event Withdrawal(address receiver, uint amount);
    event Transfer(address sender, address receiver, uint amount);

    function deposit() public payable {
        emit Deposit(msg.sender, msg.value);
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint amount) public {
        require(balances[msg.sender] >= amount, "Insufficient funds");
        emit Withdrawal(msg.sender, amount);
        balances[msg.sender] -= amount;
    }

    function transfer(address receiver, uint amount) public {
        require(balances[msg.sender] >= amount, "Insufficient funds");
        emit Transfer(msg.sender, receiver, amount);
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
    }

}