// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

contract Vault {
    mapping (address => uint) private balances;
    mapping (address => bool) public enrolled;
    address public owner = msg.sender;

    event LogEnrolled(address accountAddress);
    event LogDepositMade(address accountAddress, uint amount);
    event LogWithdrawal(address accountAddress, uint withdrawAmount, uint newBalance);

    /// @notice Get balance
    /// @return The balance of the user
    function getBalance() public view returns (uint) {
      return balances[msg.sender];
    }

    /// @notice Enroll a customer with the bank
    /// @return The users enrolled status
    // Emit the appropriate event
    function enroll() public returns (bool){
      enrolled[msg.sender] = true;
      emit LogEnrolled(msg.sender);

      return true;
    }

    /// @notice Deposit ether into bank
    /// @return The balance of the user after the deposit is made
    function deposit() public payable returns (uint) {
      require(enrolled[msg.sender]);
      balances[msg.sender] += msg.value;

      emit LogDepositMade(msg.sender, msg.value);

      return balances[msg.sender];
    }

    /// @notice Withdraw ether from bank
    /// @dev This does not return any excess ether sent to it
    /// @param withdrawAmount amount you want to withdraw
    /// @return The balance remaining for the user
    function withdraw(uint withdrawAmount) public returns (uint) {
      require(balances[msg.sender] >= withdrawAmount);
      balances[msg.sender] -= withdrawAmount;

      payable(msg.sender).transfer(withdrawAmount);
      emit LogWithdrawal(msg.sender, withdrawAmount, balances[msg.sender]);

      return balances[msg.sender];
    }
}

