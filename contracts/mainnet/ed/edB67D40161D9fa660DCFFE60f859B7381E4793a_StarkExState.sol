/*
  Copyright 2019,2020 StarkWare Industries Ltd.

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
pragma solidity ^0.5.2;

import "Freezable.sol";
import "KeyGetters.sol";
import "MainGovernance.sol";
import "Operator.sol";
import "AcceptModifications.sol";
import "Escapes.sol";
import "StateRoot.sol";
import "TokenQuantization.sol";
import "UpdateState.sol";
import "IFactRegistry.sol";
import "SubContractor.sol";

contract StarkExState is
    MainGovernance,
    SubContractor,
    Operator,
    Freezable,
    AcceptModifications,
    TokenQuantization,
    StateRoot,
    Escapes,
    UpdateState,
    KeyGetters
{
    uint256 constant INITIALIZER_SIZE = 224;  // 1 x address + 6 * uint256 = 224 bytes.

    /*
      Initialization flow:
      1. Extract initialization parameters from data.
      2. Call internalInitializer with those parameters.
    */
    function initialize(bytes calldata data) external {

        // This initializer sets roots etc. It must not be applied twice.
        // I.e. it can run only when the state is still empty.
        require(vaultRoot == 0, "STATE_ALREADY_INITIALIZED");
        require(vaultTreeHeight == 0, "STATE_ALREADY_INITIALIZED");
        require(orderRoot == 0, "STATE_ALREADY_INITIALIZED");
        require(orderTreeHeight == 0, "STATE_ALREADY_INITIALIZED");

        require(data.length == INITIALIZER_SIZE, "INCORRECT_INIT_DATA_SIZE_224");
        IFactRegistry escapeVerifier;
        uint256 initialSequenceNumber;
        uint256 initialVaultRoot;
        uint256 initialOrderRoot;
        uint256 initialVaultTreeHeight;
        uint256 initialOrderTreeHeight;
        uint256 onchainDataVersionValue;
        (
            escapeVerifier,
            initialSequenceNumber,
            initialVaultRoot,
            initialOrderRoot,
            initialVaultTreeHeight,
            initialOrderTreeHeight,
            onchainDataVersionValue
        ) = abi.decode(data, (IFactRegistry, uint256, uint256, uint256, uint256, uint256, uint256));

        initGovernance();
        Operator.initialize();
        StateRoot.initialize(
            initialSequenceNumber,
            initialVaultRoot,
            initialOrderRoot,
            initialVaultTreeHeight,
            initialOrderTreeHeight
        );
        Escapes.initialize(escapeVerifier);
        // TODO(zuphit,01/01/2021): add an attributes subcontract and move this there.
        onchainDataVersion = onchainDataVersionValue;
    }

    /*
      The call to initializerSize is done from MainDispatcher using delegatecall,
      thus the existing state is already accessible.
    */
    function initializerSize() external view returns (uint256) {
        return INITIALIZER_SIZE;
    }

    function identify() external pure returns (string memory) {
        return "StarkWare_StarkExState_2020_1";
    }
}