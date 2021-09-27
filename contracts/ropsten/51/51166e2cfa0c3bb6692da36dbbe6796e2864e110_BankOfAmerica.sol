/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title BankOfAmerica
 * @dev No one can hack this
 */
contract BankOfAmerica {
    event Deposit(address who, uint256 amount);
    event Withdrawal(address who, uint256 amount);
    uint balance = 0;
    
    /**
     * Called when no function signature matches
    */
    fallback() external payable {
        _receive();
    }
    
    /**
     * Called when ether is sent to this contract without any
     * transaction data
     */
    receive() external payable {
        _receive();
    }
    
    /**
     * Receive some funds
    */
    function _receive() internal {
        emit Deposit(msg.sender, msg.value);
        balance += msg.value;
    }
    
    /**
     * Withdraw some funds
     */
    function withdraw(uint256 amount) public {
        require(amount <= balance, "Bank doesn't have enough ETH");
        emit Withdrawal(msg.sender, amount);
        payable(msg.sender).transfer(amount);
    }
    
    function getBalance() public view returns (uint) {
        return balance;
    }
}