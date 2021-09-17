/**
 *Submitted for verification at Etherscan.io on 2021-09-17
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;

contract Migrations {
    address public owner;

    // This event indicates the last completed migration, the new contract address, and the ABI
    // for the new contract.
    event DSNPMigration(address contractAddr, string contractName);

    constructor() {
        owner = msg.sender;
    }

    modifier restricted() {
        if (msg.sender == owner) _;
    }

    // This method should be called only after deployment has succeeded.
    function upgraded(address contractAddr, string memory contractName) public restricted {
        emit DSNPMigration(contractAddr, contractName);
    }
}