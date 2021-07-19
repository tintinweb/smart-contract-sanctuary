/**
 *Submitted for verification at BscScan.com on 2021-07-19
*/

pragma solidity ^0.8.6;
//SPDX-License-Identifier: UNLICENSED

/// @notice ERC20 token contract interface
interface IERC20 {
    function transfer(address user, uint256 amount) external returns (bool);
}

contract TimelockDeposits {
  /// @notice Owner address
  address payable public owner;
  /// @notice Minimum number of blocks between queuing tx and executing it
  uint256 public delay;

  /// @notice Struct to store details of timelock transactions
  struct timelockTransaction {
    address token;
    uint256 value;
    uint256 block;
    bool isExecuted;
    uint256 id;
  }
  /// @notice Array of all timelock transactions
  timelockTransaction[] public transactions;
  
  /// @notice Event emitted when new transaction is queued
  event AddTransaction(address indexed token, uint256 value, uint256 block, uint256 indexed ID);
  /// @notice Event emitted when new transaction is executed
  event ExecuteTransaction(address indexed token, uint256 value, uint256 block, uint256 indexed ID);

  /// @notice Modifier to make a function callable only by the owner.
  modifier onlyOwner {
    require(msg.sender == owner, 'Only owner');
    _;
  }

  /**
   * @notice Construct a new TimelockDeposits contract
   * @param _owner The address with owner rights
   * @param _delay The minimum delay in blocks
   */
  constructor(address payable _owner, uint256 _delay) {
    owner = _owner;
    delay = _delay;
  }

  /**
   * @notice Request native token (ETH, BNB...) withdraw
   * @param _value Value in wei (10^-18)
   */
  function requestWithdraw(uint256 _value) external onlyOwner {
    transactions.push(
        timelockTransaction(address(0), _value, block.number, false, transactions.length)
    );
    emit AddTransaction(address(0), _value, block.number, transactions.length - 1);
  }

  /**
   * @notice Request ERC20 token withdraw
   * @param _token Address of the ERC20 token contract
   * @param _value Value in wei (10^-18)
   */
  function requestWithdrawToken(address _token, uint _value) external onlyOwner {
    transactions.push(
        timelockTransaction(_token, _value, block.number, false, transactions.length)
    );
    emit AddTransaction(_token, _value, block.number, transactions.length - 1);
  }

  /**
   * @notice Execute queued transaction after delay has passed
   * @param _ID Uint256 ID of queued transaction, ID is position  in transactions array
   */
  function executeWithdrawal(uint256 _ID) external onlyOwner {
    require(!transactions[_ID].isExecuted, 'Already executed');
    require(block.number - transactions[_ID].block > delay, 'Delay not satisfied');

    // If token address is 0x0, transfer native tokens
    if (transactions[_ID].token == address(0)) owner.transfer(transactions[_ID].value);
    // Otherwise, transfer ERC20 tokens
    else IERC20(transactions[_ID].token).transfer(owner, transactions[_ID].value);
    
    transactions[_ID].isExecuted = true;

    emit ExecuteTransaction(transactions[_ID].token, transactions[_ID].value, block.number, transactions[_ID].id);
  }

  /// @notice Fallback functions to receive native tokens
  receive() external payable { } 
  fallback() external payable { }
}