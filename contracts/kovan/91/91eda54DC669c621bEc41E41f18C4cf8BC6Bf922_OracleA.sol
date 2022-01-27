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

contract OracleA is OracleInterface {
    event NotifyContractOfBlock(
        uint16 chainId,
        address contractAddress,
        uint256 blockConfirmations
    );

    function notifyContractOfBlock(
        uint16 chainId,
        address contractAddress,
        uint256 blockConfirmations
    ) external override {
        emit NotifyContractOfBlock(chainId, contractAddress, blockConfirmations);
    }
}