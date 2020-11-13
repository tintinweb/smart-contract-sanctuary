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

/*
  Interface containing actions a verifier can invoke on the state.
  The contract containing the state should implement these and verify correctness.
*/
contract MAcceptModifications {

    function acceptDeposit(
        uint256 starkKey,
        uint256 vaultId,
        uint256 assetId,
        uint256 quantizedAmount
    )
        internal;

    function allowWithdrawal(
        uint256 starkKey,
        uint256 assetId,
        uint256 quantizedAmount
    )
        internal;

    function acceptWithdrawal(
        uint256 starkKey,
        uint256 assetId,
        uint256 quantizedAmount
    )
        internal;

    function clearFullWithdrawalRequest(
        uint256 starkKey,
        uint256 vaultId
    )
        internal;
}
