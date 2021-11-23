/*
 * Copyright (c) 2021 Haddo, Inc.

 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:

 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * Authors: [email protected]
 */
// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

contract AtomicExecutor {

    constructor() public {}

    event ExecutionSuccess();
    event ExecutionFailure(uint transactionId);

    // Executable transaction definition
    struct Transaction {
        address destination;
        uint value;
        bytes data;
    }

    // Entrypoint for executing multiple transactions atomically.
    // If execution of any of the transaction fails, the rest of
    // the transactions are not executed.
    function executeTransactions(Transaction[] calldata transactions) public {
        for (uint i = 0; i < transactions.length; i++) {
            if (!executeTransactionImpl(transactions[i].destination, transactions[i].value,
                                       transactions[i].data.length, transactions[i].data)) {
                emit ExecutionFailure(i);
                return;
            }
        }

        // If we have successfully managed to execute all of the transactions
        // then emit success event.
        emit ExecutionSuccess();
    }

    // This call has been separated into its own function in order to take advantage
    // of the Solidity's code generator to produce a loop that copies tx.data into memory.
    function executeTransactionImpl(address destination, uint value, uint dataLength, bytes memory data) internal returns (bool) {
        bool result;
        assembly {
            let x := mload(0x40)   // "Allocate" memory for output (0x40 is where "free memory" pointer is stored by convention)
            let d := add(data, 32) // First 32 bytes are the padded length of data, so exclude that
            result := call(
                sub(gas(), 34710), // 34710 is the value that solidity is currently emitting
                                   // It includes callGas (700) + callVeryLow (3, to pay for SUB) + callValueTransferGas (9000) +
                                   // callNewAccountGas (25000, in case the destination address does not exist and needs creating)
                destination,
                value,
                d,
                dataLength,        // Size of the input (in bytes) - this is what fixes the padding problem
                x,
                0                  // Output is ignored, therefore the output size is zero
            )
        }
        return result;
    }

}