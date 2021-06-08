/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

contract CRCManager {
  // struct MiningTransaction {
  //   string memberId;
  //   string transactionType;
  //   uint amount;
  //   uint completedAt; 
  // }

  struct TradingTransaction {
    address clientWallet;
    // address adminWallet;
    uint amount;
    uint rate;
    string memberId;
    // string transactionId;
    // uint createdAt;
    // uint boughtAt;
  }

  // MiningTransaction[] public miningTransactions;
  string[] public miningTransactionsRaw;
  TradingTransaction[] public tradingTransactions;
  address public owner;

  modifier restricted() {
    require(msg.sender == owner);
    _;
  }

  constructor() public {
    owner = msg.sender;
  }

  /**
    Mining transactions functions
  */
  // function saveMiningTransactions(MiningTransaction[] memory transactions) public restricted {
  //   for(uint i=0; i<transactions.length; i++){
  //     miningTransactions.push(transactions[i]);
  //   }
  // }

  // function getMiningTransactionsCount() public view returns (uint) {
  //   return miningTransactions.length;
  // }

  // function getMiningTransactions() public view returns(MiningTransaction[] memory){
  //   return miningTransactions;
  // }

  function saveMiningTransactionRaw(string memory transaction) public restricted {
    miningTransactionsRaw.push(transaction);
  }

  function getMiningTransactionsRawCount() public view returns (uint) {
    return miningTransactionsRaw.length;
  }

  function getMiningTransactionsRaw() public view returns(string[] memory){
    return miningTransactionsRaw;
  }

  /**
    Trading transactions
  */
  function saveTradingTransaction(TradingTransaction memory transaction) public restricted {
    tradingTransactions.push(transaction);
  }

  function getTradingTransactionsCount() public view returns (uint) {
    return tradingTransactions.length;
  }

  function getTradingTransactions() public view returns(TradingTransaction[] memory){
    return tradingTransactions;
  }

  // function saveMiningTransaction(string memory memberId, string memory transactionType, uint amount,  uint256 completedAt) public restricted {
  //   MiningTransaction memory newMiningTransaction = MiningTransaction({
  //     memberId: memberId,
  //     amount: amount,
  //     transactionType: transactionType,
  //     completedAt: completedAt
  //   });

  //   miningTransactions.push(newMiningTransaction);
  // }
}