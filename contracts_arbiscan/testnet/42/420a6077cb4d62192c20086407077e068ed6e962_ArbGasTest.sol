/**
 *Submitted for verification at arbiscan.io on 2021-12-01
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface ArbGasInfo {
    // return gas prices in wei, assuming the specified aggregator is used
    //        (
    //            per L2 tx,
    //            per L1 calldata unit, (zero byte = 4 units, nonzero byte = 16 units)
    //            per storage allocation,
    //            per ArbGas base,
    //            per ArbGas congestion,
    //            per ArbGas total
    //        )
    function getPricesInWeiWithAggregator(address aggregator) external view returns (uint, uint, uint, uint, uint, uint);

    // return gas prices in wei, as described above, assuming the caller's preferred aggregator is used
    //     if the caller hasn't specified a preferred aggregator, the default aggregator is assumed
    function getPricesInWei() external view returns (uint, uint, uint, uint, uint, uint);

    // return prices in ArbGas (per L2 tx, per L1 calldata unit, per storage allocation),
    //       assuming the specified aggregator is used
    function getPricesInArbGasWithAggregator(address aggregator) external view returns (uint, uint, uint);

    // return gas prices in ArbGas, as described above, assuming the caller's preferred aggregator is used
    //     if the caller hasn't specified a preferred aggregator, the default aggregator is assumed
    function getPricesInArbGas() external view returns (uint, uint, uint);

    // return gas accounting parameters (speedLimitPerSecond, gasPoolMax, maxTxGasLimit)
    function getGasAccountingParams() external view returns (uint, uint, uint);

    // get ArbOS's estimate of the L1 gas price in wei
    function getL1GasPriceEstimate() external view returns(uint);

    // set ArbOS's estimate of the L1 gas price in wei
    // reverts unless called by chain owner or designated gas oracle (if any)
    function setL1GasPriceEstimate(uint priceInWei) external;
}


/**
* @title Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064. Exposes a variety of system-level functionality.
 */
interface ArbSys {
    /**
    * @notice Get internal version number identifying an ArbOS build
    * @return version number as int
     */
    function arbOSVersion() external pure returns (uint);

    function arbChainID() external view returns(uint);

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

    /**
     * @notice check if the caller (of this caller of this) is an aliased L1 contract address
     * @return true iff the caller's address is an alias for an L1 contract address
     */
    function wasMyCallersAddressAliased() external view returns (bool);

    /**
     * @notice return the address of the caller (of this caller of this), without applying L1 contract address aliasing
     * @return address of the caller's caller, without applying L1 contract address aliasing
     */
    function myCallersAddressWithoutAliasing() external view returns (address);

    /**
     * @notice map L1 sender contract address to its L2 alias
     * @param sender sender address
     * @param dest destination address
     * @return aliased sender address
     */
    function mapL1SenderContractAddressToL2Alias(address sender, address dest) external pure returns(address);

    /**
     * @notice get the caller's amount of available storage gas
     * @return amount of storage gas available to the caller
     */
    function getStorageGasAvailable() external returns(uint);

    event L2ToL1Transaction(address caller, address indexed destination, uint indexed uniqueId,
                            uint indexed batchNumber, uint indexInBatch,
                            uint arbBlockNum, uint ethBlockNum, uint timestamp,
                            uint callvalue, bytes data);
}


contract ArbGasTest {

    uint256 previousStorageGas = 0;
    uint256 previousL1Estimate = 0;
    uint256 previousGasCost = 0;
    uint256 previousStorage = 0;
    uint256 fakeNumber = 0;

    event L2GasReport(uint l1Inclusion, uint l1CallData, uint l2Compute, uint l2Storage);

    function saveStorage() public {
        ArbSys arbSys = ArbSys(0x0000000000000000000000000000000000000064);
        previousStorageGas = arbSys.getStorageGasAvailable();
    }

    function saveL1Estimate() public {
        ArbGasInfo gasInfo = ArbGasInfo(0x000000000000000000000000000000000000006C);
        previousL1Estimate = gasInfo.getL1GasPriceEstimate();
    }

    function estimateMyGas() public {
        ArbSys arbSys = ArbSys(0x0000000000000000000000000000000000000064);
        uint initialStorageLeft = arbSys.getStorageGasAvailable();

        ArbGasInfo gasInfo = ArbGasInfo(0x000000000000000000000000000000000000006C);
        (uint perL2, uint perL1CallData, uint perStorageAlloc, , , ) = gasInfo.getPricesInWei();

        uint l2gasStart = gasleft();

        for (uint i = 0; i < 50; i++) {
            fakeNumber = fakeNumber + 1;
        }

        uint l2GasEnd = gasleft();
        uint gasSpent = l2GasEnd - l2gasStart;
        uint l2Compute = gasSpent * tx.gasprice;

        previousStorage = initialStorageLeft - arbSys.getStorageGasAvailable();
        uint l2Storage = (initialStorageLeft - arbSys.getStorageGasAvailable()) * perStorageAlloc;

        previousGasCost = perL2 + perL1CallData + l2Compute + l2Storage;
        emit L2GasReport(perL2, perL1CallData, l2Compute, l2Storage);
    }

}