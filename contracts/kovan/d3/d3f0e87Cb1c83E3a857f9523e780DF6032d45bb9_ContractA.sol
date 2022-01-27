/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.4;
pragma abicoder v2;


interface OracleInterface {
    function notifyContractOfBlock(
        uint16 chainId,
        address contractAddress,
        uint256 blockConfirmations
    ) external;
}


contract ContractA {
    OracleInterface public oracle;

    constructor(OracleInterface _oracle) {
        oracle = _oracle;
    }

    function requestToOracle(uint16 chainId, address contractAddress, uint256 blockConfirmations) public {
        oracle.notifyContractOfBlock(chainId, contractAddress, blockConfirmations);
    }
}