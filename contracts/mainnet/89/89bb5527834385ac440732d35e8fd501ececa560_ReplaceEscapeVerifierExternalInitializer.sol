/*
  Copyright 2019-2021 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.11;

import "ExternalInitializer.sol";
import "Identity.sol";
import "IFactRegistry.sol";
import "MainStorage.sol";
import "Common.sol";
import "LibConstants.sol";

/*
  This contract is an external initializing contract that replaces the escape verifier used by
  the main contract.
*/
contract ReplaceEscapeVerifierExternalInitializer is
    ExternalInitializer, MainStorage, LibConstants {
    using Addresses for address;

    /*
      The initiatialize function gets two parameters in the bytes array:
      1. New escape verifier address,
      2. Keccak256 of the expected id of the contract provied in (1).
    */
    function initialize(bytes calldata data) external override {
        require(data.length == 64, "UNEXPECTED_DATA_SIZE");

        // Extract sub-contract address and hash of verifierId.
        (
            address newEscapeVerifierAddress,
            bytes32 escapeVerifierIdHash
        ) = abi.decode(data, (address, bytes32));

        require(newEscapeVerifierAddress.isContract(), "ADDRESS_NOT_CONTRACT");
        bytes32 contractIdHash = keccak256(
            abi.encodePacked(Identity(newEscapeVerifierAddress).identify()));
        require(contractIdHash == escapeVerifierIdHash, "UNEXPECTED_CONTRACT_IDENTIFIER");

        // Replace the escape verifier address in storage.
        escapeVerifier_ = IFactRegistry(newEscapeVerifierAddress);

        emit LogExternalInitialize(data);
    }
}