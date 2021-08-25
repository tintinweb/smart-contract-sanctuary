/**
 *Submitted for verification at Etherscan.io on 2021-08-25
*/

pragma solidity 0.5.16;

contract SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Math overflow!");
        return c;
    }
}

contract myFirstContract is SafeMath {
    address admin;
    mapping(address=> uint) public deposits;
    mapping(address=> uint) public withdrawals;
    
    uint public totalDeposits = 0;
    uint public totalWithdrawals = 0;
    
    constructor() public {
        admin = msg.sender;
    }
    
    // Deposit Function
    function deposit() public payable {
        deposits[msg.sender] = add(deposits[msg.sender], msg.value);
        totalDeposits = add(totalDeposits, msg.value);
    }
    
    // Withdraw Function
    function withdraw(uint amount) public {
        require(address(msg.sender).balance >= amount, "Insufficient balance.");
        msg.sender.transfer(amount);
        withdrawals[msg.sender] = add(withdrawals[msg.sender], amount);
        totalWithdrawals = add(totalWithdrawals, amount);
    }
}