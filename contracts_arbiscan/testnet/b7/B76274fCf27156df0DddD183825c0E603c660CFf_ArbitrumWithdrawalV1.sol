// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./interfaces/arbitrum/ArbSys.sol";

/**
 * @title Allows for a L2->L1 withdrawal that records an event for BBB nodes to listen to.
 * @author Theo Ilie
 */
contract ArbitrumWithdrawalV1 {
    ArbSys constant private ARB_SYS = ArbSys(0x0000000000000000000000000000000000000064);
    uint constant public MIN_WEI_TO_WITHDRAW = 1000000000000;

    /**
     * @param sender The sender who is withdrawing from Arbitrum
     * @param destination The destination that the sender is withdrawing to. This should be a BBB pool
     * @param amount The wei-denominated amount withdrawn
     */
    event WithdrawInitiated(address indexed sender, address indexed destination, uint amount, uint indexed withdrawalId);

    /// Withdraw to `destination` on Ethereum.
    function withdraw(address destination) external payable returns (uint withdrawalId_) {
        require (msg.value > MIN_WEI_TO_WITHDRAW, "Withdraw amount too low");

        withdrawalId_ = ARB_SYS.withdrawEth(destination);
        emit WithdrawInitiated(msg.sender, destination, msg.value, withdrawalId_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
* @title Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064. Exposes a variety of system-level functionality.
 */
interface ArbSys {
    /**
    * @notice Get internal version number identifying an ArbOS build
    * @return version number as int
     */
    function arbOSVersion() external pure returns (uint);

    /**
    * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
    * @return block number as int
     */ 
    function arbBlockNumber() external view returns (uint);

    /** 
    * @notice Send given amount of Eth to dest from sender.
    * This is a convenience function, which is equivalent to calling sendTxToL1 with empty calldataForL1.
    * @param destination recipient address on L1
    * @return unique identifier for this L2-to-L1 transaction.
    */
    function withdrawEth(address destination) external payable returns(uint);

    /** 
    * @notice Send a transaction to L1
    * @param destination recipient address on L1 
    * @param calldataForL1 (optional) calldata for L1 contract call
    * @return a unique identifier for this L2-to-L1 transaction.
    */
    function sendTxToL1(address destination, bytes calldata calldataForL1) external payable returns(uint);


    /** 
    * @notice get the number of transactions issued by the given external account or the account sequence number of the given contract
    * @param account target account
    * @return the number of transactions issued by the given external account or the account sequence number of the given contract
    */
    function getTransactionCount(address account) external view returns(uint256);

    /**  
    * @notice get the value of target L2 storage slot 
    * This function is only callable from address 0 to prevent contracts from being able to call it
    * @param account target account
    * @param index target index of storage slot 
    * @return stotage value for the given account at the given index
    */
    function getStorageAt(address account, uint256 index) external view returns (uint256);

    /**
    * @notice check if current call is coming from l1
    * @return true if the caller of this was called directly from L1
    */
    function isTopLevelCall() external view returns (bool);

    event EthWithdrawal(address indexed destAddr, uint amount);

    event L2ToL1Transaction(address caller, address indexed destination, uint indexed uniqueId,
                            uint indexed batchNumber, uint indexInBatch,
                            uint arbBlockNum, uint ethBlockNum, uint timestamp,
                            uint callvalue, bytes data);
}