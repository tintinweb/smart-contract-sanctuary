// SPDX-License-Identifier: GPL-3.0

/// @title FOMO Nouns Settlement Contract
/// @author forager

pragma solidity 0.8.9;

import { INounsAuctionHouse } from './interfaces/INounsAuctionHouse.sol';


contract NounSettlement {
  address payable public fomoExecutor;
  address payable public immutable nounsDaoTreasury;
  address public immutable fomoMultisig;
  INounsAuctionHouse public immutable auctionHouse;

  uint256 public maxPriorityFee = 40 * 10**9; // Prevents malicious actor burning all the ETH on gas
  uint256 private immutable OVERHEAD_GAS = 21000; // Handles gas outside gasleft checks, rounded up from ~20,254 in testing


  constructor(address _fomoExecutor, address _nounsDaoTreasury, address _nounsAuctionHouseAddress, address _fomoMultisig) {
    fomoExecutor = payable(_fomoExecutor);
    nounsDaoTreasury = payable(_nounsDaoTreasury);
    fomoMultisig = _fomoMultisig;
    auctionHouse = INounsAuctionHouse(_nounsAuctionHouseAddress);
  }


  /**
    Events for key actions or parameter updates
   */

  /// @notice Contract funds withdrawn to the Nouns Treasury
  event FundsPulled(address _to, uint256 _amount);

  /// @notice FOMO Executor EOA moved to a new address
  event ExecutorChanged(address _newExecutor);

  /// @notice Maximum priority fee for refunds updated
  event MaxPriorityFeeChanged(uint256 _newMaxPriorityFee);


  /**
    Custom modifiers to handle access and refund
   */
  modifier onlyMultisig() {
    require(msg.sender == fomoMultisig, "Only callable by FOMO Multsig");
    _;
  }

  modifier onlyFOMO() {
    require(msg.sender == fomoExecutor, "Only callable by FOMO Nouns executor");
    _;
  }

  modifier refundGas() { // Executor must be EOA
    uint256 startGas = gasleft();
    require(tx.gasprice <= block.basefee + maxPriorityFee, "Gas price above current reasonable limit");
    _;
    uint256 endGas = gasleft();

    uint256 totalGasCost = tx.gasprice * (startGas - endGas + OVERHEAD_GAS);
    fomoExecutor.transfer(totalGasCost);
  }


  /**
    Fund management to allow donations and liquidation
   */

  /// @notice Donate funds to cover auction settlement gas fees
  function donateFunds() external payable { }
  receive() external payable { }
  fallback() external payable { }

  /// @notice Pull all funds from contract into the Nouns DAO Treasury
  function pullFunds() external onlyMultisig {
    uint256 balance = address(this).balance;
    (bool sent, ) = nounsDaoTreasury.call{value: balance}("");
    require(sent, "Funds removal failed.");
    emit FundsPulled(nounsDaoTreasury, balance);
  }


  /**
    Change addresses or limits for the contract execution
   */
  
  /// @notice Change address for the FOMO Executor EOA that can request gas refunds
  function changeExecutorAddress(address _newFomoExecutor) external onlyMultisig {
    fomoExecutor = payable(_newFomoExecutor);
    emit ExecutorChanged(fomoExecutor);
  }

  /// @notice Update the maximum allowed priority fee (in wei) for refunds
  function changeMaxPriorityFee(uint256 _newMaxPriorityFee) external onlyMultisig {
    maxPriorityFee = _newMaxPriorityFee;
    emit MaxPriorityFeeChanged(maxPriorityFee);
  }


  /**
    Settle the Auction & Mint the Desired Nouns
   */

  /// @notice Settle auction ensuring desired hash is used to generate the new Noun
  function settleAuction(bytes32 _desiredHash) public {
    bytes32 lastHash = blockhash(block.number - 1); // Only settle if desired Noun would be minted
    require(lastHash == _desiredHash, "Prior blockhash did not match intended hash");
    
    auctionHouse.settleCurrentAndCreateNewAuction();
  }

  /// @notice Settle auction, as with settleAuction, AND refund gas to caller
  function settleAuctionWithRefund(bytes32 _desiredHash) external refundGas onlyFOMO {
    settleAuction(_desiredHash);
  }
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for Noun Auction Houses

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

interface INounsAuctionHouse {
    struct Auction {
        // ID for the Noun (ERC721 token ID)
        uint256 nounId;
        // The current highest bid amount
        uint256 amount;
        // The time that the auction started
        uint256 startTime;
        // The time that the auction is scheduled to end
        uint256 endTime;
        // The address of the current highest bid
        address payable bidder;
        // Whether or not the auction has been settled
        bool settled;
    }

    event AuctionCreated(uint256 indexed nounId, uint256 startTime, uint256 endTime);

    event AuctionBid(uint256 indexed nounId, address sender, uint256 value, bool extended);

    event AuctionExtended(uint256 indexed nounId, uint256 endTime);

    event AuctionSettled(uint256 indexed nounId, address winner, uint256 amount);

    event AuctionTimeBufferUpdated(uint256 timeBuffer);

    event AuctionReservePriceUpdated(uint256 reservePrice);

    event AuctionMinBidIncrementPercentageUpdated(uint256 minBidIncrementPercentage);

    function settleAuction() external;

    function settleCurrentAndCreateNewAuction() external;

    function createBid(uint256 nounId) external payable;

    function pause() external;

    function unpause() external;

    function setTimeBuffer(uint256 timeBuffer) external;

    function setReservePrice(uint256 reservePrice) external;

    function setMinBidIncrementPercentage(uint8 minBidIncrementPercentage) external;
}