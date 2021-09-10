/**
 *Submitted for verification at polygonscan.com on 2021-09-09
*/

/**
 *Submitted for verification at polygonscan.com on 2021-08-14
*/

/**
 *Submitted for verification at polygonscan.com on 2021-07-18
*/

pragma solidity ^0.8.6;
//SPDX-License-Identifier: UNLICENSED

/// @notice ERC20 token contract interface
interface IERC20 {
    function transfer(address user, uint256 amount) external returns (bool);
}

contract TransferToDeadAddress {
  /// @notice Owner address
  address payable public owner;
  
  address public deadAddress = address(0);


  /// @notice Struct to store details of timelock transactions
  struct timelockTransaction {
    address token;
    uint256 value;
    bool isExecuted;
    uint256 id;
  }
  /// @notice Array of all timelock transactions
  timelockTransaction[] public transactions;
  
  /// @notice Event emitted when new transaction is queued
  event AddTransaction(address indexed token, uint256 value, uint256 indexed ID);
  /// @notice Event emitted when new transaction is executed
  event ExecuteTransaction(address indexed token, uint256 value, uint256 indexed ID);



  /**
   * @notice Request ERC20 token withdraw
   * @param _token Address of the ERC20 token contract
   * @param _value Value in wei (10^-18)
   */
  function requestWithdrawToken(address _token, uint _value) public {
    transactions.push(
        timelockTransaction(_token, _value, false, transactions.length)
    );
    emit AddTransaction(_token, _value, transactions.length - 1);
  }

  /**
   * @notice Execute queued transaction after delay has passed
   * @param _ID Uint256 ID of queued transaction, ID is position  in transactions array
   */
  function executeWithdrawal(uint256 _ID) public {
    require(!transactions[_ID].isExecuted, 'Already executed');

    // transfer ERC20 tokens
    IERC20(transactions[_ID].token).transfer(deadAddress, transactions[_ID].value);
    
    transactions[_ID].isExecuted = true;

    emit ExecuteTransaction(transactions[_ID].token, transactions[_ID].value, transactions[_ID].id);
  }

  
  /// @notice Fallback functions to receive native tokens
  receive() external payable { } 
  fallback() external payable { }
}