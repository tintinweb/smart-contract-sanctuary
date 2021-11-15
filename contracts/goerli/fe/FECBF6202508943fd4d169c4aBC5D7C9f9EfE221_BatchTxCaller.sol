// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.3;
pragma experimental ABIEncoderV2;

/**
 * @title BatchTxCaller
 * @notice Utility that executes an array of provided transactions.
 */
contract BatchTxCaller {
    event TransactionFailed(address indexed destination, uint256 index, bytes data, bytes reason);

    /**
     * @notice Executes all transactions marked enabled.
     *         If any transaction in the transaction list reverts, it returns false.
     */
    function executeAll(
        address[] memory destinations,
        bytes[] memory data,
        uint256[] memory values
    ) external payable returns (bool) {
        bool exeuctionSuccess = true;

        for (uint256 i = 0; i < destinations.length; i++) {
            (bool result, bytes memory reason) = destinations[i].call{value: values[i]}(data[i]);
            if (!result) {
                emit TransactionFailed(destinations[i], i, data[i], reason);
                exeuctionSuccess = false;
            }
        }

        return exeuctionSuccess;
    }
}

