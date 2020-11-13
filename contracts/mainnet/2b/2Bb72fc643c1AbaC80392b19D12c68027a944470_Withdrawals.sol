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

import "MAcceptModifications.sol";
import "MTokenQuantization.sol";
import "MTokenAssetData.sol";
import "MFreezable.sol";
import "MOperator.sol";
import "MKeyGetters.sol";
import "MTokens.sol";
import "MainStorage.sol";

/**
  For a user to perform a withdrawal operation from the Stark Exchange during normal operation
  two calls are required:

  1. A call to an offchain exchange API, requesting a withdrawal from a user account (vault).
  2. A call to the on-chain :sol:func:`withdraw` function to perform the actual withdrawal of funds transferring them to the users Eth or ERC20 account (depending on the token type).

  For simplicity, hereafter it is assumed that all tokens are ERC20 tokens but the text below
  applies to Eth in the same manner.

  In the first call mentioned above, anyone can call the API to request the withdrawal of an
  amount from a given vault. Following the request, the exchange may include the withdrawal in a
  STARK proof. The submission of a proof then results in the addition of the amount(s) withdrawn to
  an on-chain pending withdrawals account under the stark key of the vault owner and the appropriate
  asset ID. At the same time, this also implies that this amount is deducted from the off-chain
  vault.

  Once the amount to be withdrawn has been transfered to the on-chain pending withdrawals account,
  the user may perform the second call mentioned above to complete the transfer of funds from the
  Stark Exchange contract to the appropriate ERC20 account. Only a user holding the Eth key
  corresponding to the Stark Key of a pending withdrawals account may perform this operation.

  It is possible that for multiple withdrawal calls to the API, a single withdrawal call to the
  contract may retrieve all funds, as long as they are all for the same asset ID.

  The result of the operation, assuming all requirements are met, is that an amount of ERC20 tokens
  in the pending withdrawal account times the quantization factor is transferred to the ERC20
  account of the user.

  A withdrawal request cannot be cancelled. Once funds reach the pending withdrawals account
  on-chain, they cannot be moved back into an off-chain vault before completion of the withdrawal
  to the ERC20 account of the user.

  In the event that the exchange reaches a frozen state the user may perform a withdrawal operation
  via an alternative flow, known as the "Escape" flow. In this flow, the API call above is replaced
  with an :sol:func:`escape` call to the on-chain contract (see :sol:mod:`Escapes`) proving the
  ownership of off-chain funds. If such proof is accepted, the user may proceed as above with
  the :sol:func:`withdraw` call to the contract to complete the operation.
*/
contract Withdrawals is MainStorage, MAcceptModifications, MTokenQuantization, MTokenAssetData,
                        MFreezable, MOperator, MKeyGetters, MTokens  {
    event LogWithdrawalPerformed(
        uint256 starkKey,
        uint256 assetType,
        uint256 nonQuantizedAmount,
        uint256 quantizedAmount,
        address recipient
    );

    event LogNftWithdrawalPerformed(
        uint256 starkKey,
        uint256 assetType,
        uint256 tokenId,
        uint256 assetId,
        address recipient
    );

    event LogMintWithdrawalPerformed(
        uint256 starkKey,
        uint256 tokenId,
        uint256 nonQuantizedAmount,
        uint256 quantizedAmount,
        uint256 assetId
    );

    function getWithdrawalBalance(
        uint256 starkKey,
        uint256 assetId
    )
        external
        view
        returns (uint256 balance)
    {
        uint256 presumedAssetType = assetId;
        balance = fromQuantized(presumedAssetType, pendingWithdrawals[starkKey][assetId]);
    }

    /*
      Allows a user to withdraw accepted funds to a recipient's account.
      This function can be called normally while frozen.
    */
    function withdrawTo(uint256 starkKey, uint256 assetType, address payable recipient)
        public
        isSenderStarkKey(starkKey)
    // No notFrozen modifier: This function can always be used, even when frozen.
    {
        require(!isMintableAssetType(assetType), "MINTABLE_ASSET_TYPE");
        uint256 assetId = assetType;
        // Fetch and clear quantized amount.
        uint256 quantizedAmount = pendingWithdrawals[starkKey][assetId];
        pendingWithdrawals[starkKey][assetId] = 0;

        // Transfer funds.
        transferOut(recipient, assetType, quantizedAmount);
        emit LogWithdrawalPerformed(
            starkKey,
            assetType,
            fromQuantized(assetType, quantizedAmount),
            quantizedAmount,
            recipient
        );
    }

    /*
      Allows a user to withdraw accepted funds to its own account.
      This function can be called normally while frozen.
    */
    function withdraw(uint256 starkKey, uint256 assetType)
        external
    // No notFrozen modifier: This function can always be used, even when frozen.
    {
        withdrawTo(starkKey, assetType, msg.sender);
    }

    /*
      Allows a user to withdraw an accepted NFT to a recipient's account.
      This function can be called normally while frozen.
    */
    function withdrawNftTo(
        uint256 starkKey,
        uint256 assetType,
        uint256 tokenId,
        address recipient
    )
        public
        isSenderStarkKey(starkKey)
    // No notFrozen modifier: This function can always be used, even when frozen.
    {
        // Calculate assetId.
        uint256 assetId = calculateNftAssetId(assetType, tokenId);
        require(!isMintableAssetType(assetType), "MINTABLE_ASSET_TYPE");
        if (pendingWithdrawals[starkKey][assetId] > 0) {
            require(pendingWithdrawals[starkKey][assetId] == 1, "ILLEGAL_NFT_BALANCE");
            pendingWithdrawals[starkKey][assetId] = 0;

            // Transfer funds.
            transferOutNft(recipient, assetType, tokenId);
            emit LogNftWithdrawalPerformed(starkKey, assetType, tokenId, assetId, recipient);
        }
    }

    /*
      Allows a user to withdraw an accepted NFT to its own account.
      This function can be called normally while frozen.
    */
    function withdrawNft(
        uint256 starkKey,
        uint256 assetType,
        uint256 tokenId
    )
        external
    // No notFrozen modifier: This function can always be used, even when frozen.
    {
        withdrawNftTo(starkKey, assetType, tokenId, msg.sender);
    }

    function withdrawAndMint(
        uint256 starkKey,
        uint256 assetType,
        bytes calldata mintingBlob
    ) external isSenderStarkKey(starkKey) {
        require(registeredAssetType[assetType], "INVALID_ASSET_TYPE");
        require(isMintableAssetType(assetType), "NON_MINTABLE_ASSET_TYPE");
        uint256 assetId = calculateMintableAssetId(assetType, mintingBlob);
        if (pendingWithdrawals[starkKey][assetId] > 0) {
            uint256 quantizedAmount = pendingWithdrawals[starkKey][assetId];
            pendingWithdrawals[starkKey][assetId] = 0;
            // Transfer funds.
            transferOutMint(assetType, quantizedAmount, mintingBlob);
            emit LogMintWithdrawalPerformed(
                starkKey, assetType, fromQuantized(assetType, quantizedAmount), quantizedAmount,
                assetId);
        }
    }
}
