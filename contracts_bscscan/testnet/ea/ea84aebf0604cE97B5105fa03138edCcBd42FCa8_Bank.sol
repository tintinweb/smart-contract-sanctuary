/**
 *Submitted for verification at BscScan.com on 2021-07-12
*/

pragma solidity ^0.8.0;

interface ERC20 {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

contract Bank {
    address payable private owner;

    event LogDeposit(uint amount, address indexed sender);
    event LogWithdrawal(uint amount, address indexed recipient);

    constructor() {
        owner = payable(msg.sender);
    }
    
    receive() external payable {
        require(msg.value > 0, "no value");
        emit LogDeposit(msg.value, msg.sender);
    }

    function deposit() public payable {
        require(msg.value > 0, "no value");
        emit LogDeposit(msg.value, msg.sender);
    }

    function withdraw(uint amount, address payable recipient) public {
        require(msg.sender == owner, "owner only");
        require(address(this).balance >= amount, "not enough funds");
        emit LogWithdrawal(amount, recipient);
        recipient.transfer(amount);
    }

    function withdrawToken(address token, uint amount, address payable recipient) public {
        require(msg.sender == owner, "owner only");
        ERC20(token).transfer(recipient, amount);
    }
}