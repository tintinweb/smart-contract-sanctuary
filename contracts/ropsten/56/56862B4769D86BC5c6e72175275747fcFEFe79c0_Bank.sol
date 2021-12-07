/**
 *Submitted for verification at Etherscan.io on 2021-12-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;


/// @title Bank
/// @author nemild, kor, tot

/* 'contract' has similarities to 'class' in other languages (class variables,
inheritance, etc.) */
contract Bank { // CamelCase
    // Declare state variables outside function, persist through life of contract

    // dictionary that maps addresses to balances
    mapping (address => uint256) private balances;
    
    // Users in system
    address[] accounts;
    
    // Interest rate
    uint256 rate = 3;

    // Owner of the system
    address public owner;
    // 'public' makes externally readable (not writeable) by users or contracts

    // Events - publicize actions to external listeners
    event DepositMade(address indexed accountAddress, uint amount);
    event WithdrawMade(address indexed accountAddress, uint amount);
    
    event SystemDepositMade(address indexed admin, uint amount);
    event SystemWithdrawMade(address indexed admin, uint amount);

    // Constructor, can receive one or many variables here; only one allowed
    constructor() public {
        // msg provides details about the message that's sent to the contract
        // msg.sender is contract caller (address of contract creator)
        owner = msg.sender;
    }

    /// @notice Deposit ether into bank
    /// @return The balance of the user after the deposit is made
    function deposit() public payable returns (uint256) {
        // Record account in array for looping
        if (0 == balances[msg.sender]) {
            accounts.push(msg.sender);
        }
        
        balances[msg.sender] = balances[msg.sender] + msg.value;
        // no "this." or "self." required with state variable
        // all values set to data type's initial value by default

        // Broadcast deposit event
        emit DepositMade(msg.sender, msg.value); // fire event

        return balances[msg.sender];
    }

    /// @notice Withdraw ether from bank
    /// @dev This does not return any excess ether sent to it
    /// @param withdrawAmount amount you want to withdraw
    /// @return remainingBal The balance remaining for the user
    function withdraw(uint withdrawAmount) public returns (uint256 remainingBal) {
        require(balances[msg.sender] >= withdrawAmount, "Balance is not enough");
        balances[msg.sender] = balances[msg.sender] - withdrawAmount;

        // Revert on failed
        msg.sender.transfer(withdrawAmount);
        
        // Broadcast withdraw event
        emit WithdrawMade(msg.sender, withdrawAmount);
        
        return balances[msg.sender];
    }

    /// @notice Get balance
    /// @return The balance of the user
    // 'constant' prevents function from editing state variables;
    // allows function to run locally/off blockchain
    function balance() public view returns (uint256) {
        return balances[msg.sender];
    }
    
    /// @notice Calculate Interests given user
    /// @dev Internal use only
    /// @param user user address in the system
    /// @param _rate interest rate
    /// @return Interest earned
    function calculateInterest(address user, uint256 _rate) private view returns(uint256) {
        uint256 interest = balances[user] * _rate / 100;
        return interest;
    }
    
    /// @notice Calculate Interests of all users combined
    /// @dev Public, anyone can lookup
    /// @return Interest earned of all users
    function totalInterestPerYear() external view returns(uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            uint256 interest = calculateInterest(account, rate);
            total = total + interest;
        }
        
        return total;
    }
    
    /// @notice Give dividends to all users, caller must provide enough fund
    /// @dev Only owner can use
    function payDividendsPerYear() payable public {
        require(owner == msg.sender, "You are not authorized");
        uint256 totalInterest = 0;
        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            uint256 interest = calculateInterest(account, rate);
            balances[account] = balances[account] + interest;
            totalInterest = totalInterest + interest;
        }
        require(msg.value == totalInterest, "Not enough interest to pay!!");
    }
    
    /// @notice Bank system balance
    /// @return Balances of all users combined
    function systemBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    /// @notice Deposit ether into bank
    /// @return The balance of the user after the deposit is made
    function systemDeposit() public payable returns (uint256) {
        require(owner == msg.sender, "You are not authorized");

        // Broadcast deposit event
        emit SystemDepositMade(msg.sender, msg.value); // fire event

        return systemBalance();
    }
    
    /// @notice Withdraw ether from the system
    /// @param withdrawAmount amount you want to withdraw
    /// @return remainingBal The balance remaining for the system
    function systemWithdraw(uint withdrawAmount) public returns (uint256 remainingBal) {
        require(owner == msg.sender, "You are not authorized");
        require(systemBalance() >= withdrawAmount, "System balance is not enough");

        // Revert on failed
        msg.sender.transfer(withdrawAmount);
        
        // Broadcast system withdraw event
        emit SystemWithdrawMade(msg.sender, withdrawAmount);
        
        return systemBalance();
    }
    
    // ERC20
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    string public name = "USD";
    string public symbol = "USD";
    uint public decimals = 18;
    
    function totalSupply() external view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            total = total + balances[account];
        }
        
        return total;
    }
    
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
    
    function transfer(address recipient, uint256 amount) external returns (bool) {
        require(balances[msg.sender] >= amount, "Balance is not enough");
        balances[msg.sender] = balances[msg.sender] - amount;
        balances[recipient] = balances[recipient] + amount;
        
        // Broadcast withdraw event
        emit Transfer(msg.sender, recipient, amount);
        
        return true;
    }
}