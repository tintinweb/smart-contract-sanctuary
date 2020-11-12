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

import "LibConstants.sol";
import "MAcceptModifications.sol";
import "MTokenQuantization.sol";
import "MainStorage.sol";

/*
  Interface containing actions a verifier can invoke on the state.
  The contract containing the state should implement these and verify correctness.
*/
contract AcceptModifications is
    MainStorage,
    LibConstants,
    MAcceptModifications,
    MTokenQuantization
{
    event LogWithdrawalAllowed(
        uint256 starkKey,
        uint256 assetType,
        uint256 nonQuantizedAmount,
        uint256 quantizedAmount
    );

    event LogNftWithdrawalAllowed(uint256 starkKey, uint256 assetId);

    event LogMintableWithdrawalAllowed(
        uint256 starkKey,
        uint256 assetId,
        uint256 quantizedAmount
    );

    /*
      Transfers funds from the on-chain deposit area to the off-chain area.
      Implemented in the Deposits contracts.
    */
    function acceptDeposit(
        uint256 starkKey,
        uint256 vaultId,
        uint256 assetId,
        uint256 quantizedAmount
    ) internal {
        // Fetch deposit.
        require(
            pendingDeposits[starkKey][assetId][vaultId] >= quantizedAmount,
            "DEPOSIT_INSUFFICIENT"
        );

        // Subtract accepted quantized amount.
        pendingDeposits[starkKey][assetId][vaultId] -= quantizedAmount;
    }

    /*
      Transfers funds from the off-chain area to the on-chain withdrawal area.
    */
    function allowWithdrawal(
        uint256 starkKey,
        uint256 assetId,
        uint256 quantizedAmount
    )
        internal
    {
        // Fetch withdrawal.
        uint256 withdrawal = pendingWithdrawals[starkKey][assetId];

        // Add accepted quantized amount.
        withdrawal += quantizedAmount;
        require(withdrawal >= quantizedAmount, "WITHDRAWAL_OVERFLOW");

        // Store withdrawal.
        pendingWithdrawals[starkKey][assetId] = withdrawal;

        // Log event.
        uint256 presumedAssetType = assetId;
        if (registeredAssetType[presumedAssetType]) {
            emit LogWithdrawalAllowed(
                starkKey,
                presumedAssetType,
                fromQuantized(presumedAssetType, quantizedAmount),
                quantizedAmount
            );
        } else if(assetId == ((assetId & MASK_240) | MINTABLE_ASSET_ID_FLAG)) {
            emit LogMintableWithdrawalAllowed(
                starkKey,
                assetId,
                quantizedAmount
            );
        }
        else {
            // In ERC721 case, assetId is not the assetType.
            require(withdrawal <= 1, "INVALID_NFT_AMOUNT");
            emit LogNftWithdrawalAllowed(starkKey, assetId);
        }
    }


    // Verifier authorizes withdrawal.
    function acceptWithdrawal(
        uint256 starkKey,
        uint256 assetId,
        uint256 quantizedAmount
    ) internal {
        allowWithdrawal(starkKey, assetId, quantizedAmount);
    }

    /*
      Implemented in the FullWithdrawal contracts.
    */
    function clearFullWithdrawalRequest(
        uint256 starkKey,
        uint256 vaultId
    )
        internal
    {
        // Reset escape request.
        fullWithdrawalRequests[starkKey][vaultId] = 0;  // NOLINT: reentrancy-benign.
    }
}
