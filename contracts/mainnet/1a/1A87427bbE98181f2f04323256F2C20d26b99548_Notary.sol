/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

/// Intentionally simple, intentionally cheap contract for public notarization or signature witnessing.
/// https://github.com/afterfund/notary
contract Notary {

    event Signed(
        uint documentType,
        address indexed witness,
        address[] indexed signatories,
        string indexed documentURL,
        string documentHash
    );

    function witness(
        uint documentType,
        address[] calldata signatories,
        string calldata documentURL,
        string calldata documentHash
    ) public {
        emit Signed(documentType, msg.sender, signatories, documentURL, documentHash);
    }
}