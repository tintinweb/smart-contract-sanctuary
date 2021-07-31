// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import './9_SimpleERC20.sol';

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */


/// @title SimpleBank
/// @author nemild, kor, tot

/* 'contract' has similarities to 'class' in other languages (class variables,
inheritance, etc.) */
contract SimpleBank is Ownable{ // CamelCase
    using SafeMath for uint256;
    // Declare state variables outside function, persist through life of contract

    // Events - publicize actions to external listeners
    event DepositMade(address accountAddress, uint amount);
    event WithdrawalMade(address accountAddress, uint amount);
    event Bought(uint256 amount);
    event Sold(uint256 amount);
    event Rugpull(uint256 amount);
    event IncreasedYear(uint256 currentYear);

    IERC20 public token;
    
    uint256 public currentYear = 0;

    // dictionary that maps addresses to balances
    mapping (address => uint256) private balances;
    
    // Users in system
    address[] accounts;
    
    // Interest rate
    uint256 public rate = 3;

    // Constructor, can receive one or many variables here; only one allowed
    constructor(address _token) public {
        token = IERC20(_token);
    }

    // "private" means that other contracts can't directly query balances
    // but data is still viewable to other parties on blockchain

    // 'public' makes externally readable (not writeable) by users or contracts

    function deposit(uint256 amount) payable public {
        require(amount > 0, "You need to sell at least some tokens");
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");
        token.transferFrom(msg.sender, address(this), amount);
        
        if (0 == balances[msg.sender]) {
            accounts.push(msg.sender);
        }
        
        balances[msg.sender] = balances[msg.sender].add(amount);
        // msg.sender.transfer(amount);
        emit Sold(amount);
    }

    function withdraw(uint withdrawAmount) payable public {
        uint256 dexBalance = token.balanceOf(address(this));
        require(withdrawAmount > 0, "Your balance is 0");
        require(withdrawAmount <= dexBalance, "Bankrun or rugpull happen");
        require(balances[msg.sender] >= withdrawAmount, "Over withdraw");
        token.transfer(msg.sender, withdrawAmount);
        balances[msg.sender] = balances[msg.sender].sub(withdrawAmount);
        emit WithdrawalMade(msg.sender, withdrawAmount);
    }

    // /// @notice Deposit ether into bank
    // /// @return The balance of the user after the deposit is made
    // function deposit(uint256 depositAmount) public payable returns (uint256) {
    //     require(depositAmount > 0, "Please deposit more than 0");
    //     // Record account in array for looping
    //     if (0 == balances[msg.sender]) {
    //         accounts.push(msg.sender);
    //     }
        
    //     balances[msg.sender] = balances[msg.sender].add(depositAmount);
    //     // no "this." or "self." required with state variable
    //     // all values set to data type's initial value by default

    //     emit DepositMade(msg.sender, balances[msg.sender]); // fire event

    //     return balances[msg.sender];
    // }

    // /// @notice Withdraw ether from bank
    // /// @dev This does not return any excess ether sent to it
    // /// @param withdrawAmount amount you want to withdraw
    // /// @return remainingBal The balance remaining for the user
    // function withdraw(uint withdrawAmount) public returns (uint256 remainingBal) {
    //     require(balances[msg.sender] < withdrawAmount);
    //     balances[msg.sender] = balances[msg.sender].sub(withdrawAmount);

    //     // Revert on failed
    //     msg.sender.transfer(withdrawAmount);
    //     // address(this).transfer(withdrawAmount);
        
    //     return balances[msg.sender];
    // }

    /// @notice Get balance
    /// @return The balance of the user
    // 'constant' prevents function from editing state variables;
    // allows function to run locally/off blockchain
    function balance() public view returns (uint256) {
        return balances[msg.sender];
    }

    // Fallback function - Called if other functions don't match call or
    // sent ether without data
    // Typically, called when invalid data is sent
    // Added so ether sent to this contract is reverted if the contract fails
    // otherwise, the sender's money is transferred to contract
    fallback () external {
        revert(); // throw reverts state to before call
    }
    
    function calculateInterest(address user, uint256 _rate) internal returns(uint256) {
        uint256 interest = balances[user].mul(_rate).div(100);
        token.mint(address(this),interest);
        return interest;
    }

    function emergencyWithdraw() onlyOwner public {
        uint256 dexBalance = token.balanceOf(address(this));
        token.transfer(msg.sender, dexBalance);
        emit Rugpull(dexBalance);
    }

/*
    function increaseYear(uint256 yearToIncrease) payable onlyOwner public {
        // uint256 amountTobuy = msg.value;
        currentYear = currentYear.add(yearToIncrease);
        for(uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            uint256 interest = calculateInterest(account, rate);
            balances[account] = balances[account].add(interest);
        }
        emit IncreasedYear(currentYear);
    }
*/
    function increaseYear() public {
        for(uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            uint256 interest = calculateInterest(account, rate);
            balances[account] = balances[account].add(interest);
        }
    }

    function systemBalance() public view returns(uint256) {
        return address(this).balance;
    }
}
// ** END EXAMPLE **