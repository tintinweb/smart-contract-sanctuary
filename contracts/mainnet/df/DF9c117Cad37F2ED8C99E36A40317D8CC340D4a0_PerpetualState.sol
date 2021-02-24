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
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.11;

import "PerpetualEscapes.sol";
import "UpdatePerpetualState.sol";
import "Configuration.sol";
import "Freezable.sol";
import "KeyGetters.sol";
import "MainGovernance.sol";
import "Operator.sol";
import "AcceptModifications.sol";
import "ForcedTradeActionState.sol";
import "ForcedWithdrawalActionState.sol";
import "StateRoot.sol";
import "TokenQuantization.sol";
import "IFactRegistry.sol";
import "SubContractor.sol";

contract PerpetualState is
    MainGovernance,
    SubContractor,
    Configuration,
    Operator,
    Freezable,
    AcceptModifications,
    TokenQuantization,
    ForcedTradeActionState,
    ForcedWithdrawalActionState,
    StateRoot,
    PerpetualEscapes,
    UpdatePerpetualState,
    KeyGetters
{
    // Empty state is 8 words (256 bytes) To pass as uint[] we need also head & len fields (64).
    uint256 constant INITIALIZER_SIZE = 384; // Padded address(32), uint(32), Empty state(256+64).

    /*
      Initialization flow:
      1. Extract initialization parameters from data.
      2. Call internalInitializer with those parameters.
    */
    function initialize(bytes calldata data) external override {
        // This initializer sets roots etc. It must not be applied twice.
        // I.e. it can run only when the state is still empty.
        require(sharedStateHash == bytes32(0x0), "STATE_ALREADY_INITIALIZED");
        require(configurationHash[GLOBAL_CONFIG_KEY] == bytes32(0x0), "STATE_ALREADY_INITIALIZED");

        require(data.length == INITIALIZER_SIZE, "INCORRECT_INIT_DATA_SIZE_384");

        (
            IFactRegistry escapeVerifier,
            uint256 initialSequenceNumber,
            uint256[] memory initialState
        ) = abi.decode(
            data,
            (IFactRegistry, uint256, uint256[])
        );

        initGovernance();
        Configuration.initialize(PERPETUAL_CONFIGURATION_DELAY);
        Operator.initialize();
        StateRoot.initialize(
            initialSequenceNumber,
            initialState[0],
            initialState[2],
            initialState[1],
            initialState[3]
        );
        sharedStateHash = keccak256(abi.encodePacked(initialState));
        PerpetualEscapes.initialize(escapeVerifier);
    }

    /*
      The call to initializerSize is done from MainDispatcherBase using delegatecall,
      thus the existing state is already accessible.
    */
    function initializerSize() external view override returns (uint256) {
        return INITIALIZER_SIZE;
    }

    function identify() external pure override returns (string memory) {
        return "StarkWare_PerpetualState_2020_1";
    }
}