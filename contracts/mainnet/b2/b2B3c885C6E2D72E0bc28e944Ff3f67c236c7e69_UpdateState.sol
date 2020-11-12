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
import "VerifyFactChain.sol";
import "IFactRegistry.sol";
import "MFreezable.sol";
import "MOperator.sol";
import "LibConstants.sol";
import "PublicInputOffsets.sol";
import "AllVerifiers.sol";

/**
  The StarkEx contract tracks the state of the off-chain exchange service by storing Merkle roots
  of the vault state (off-chain account state) and the order state (including fully executed and
  partially fulfilled orders).

  The :sol:mod:`Operator` is the only entity entitled to submit state updates for a batch of
  exchange transactions by calling :sol:func:`updateState` and this is only allowed if the contract
  is not in the `frozen` state (see :sol:mod:`FullWithdrawals`). The call includes the `publicInput`
  of a STARK proof, and additional data (`applicationData`) that includes information not attested
  to by the proof.

  The `publicInput` includes the current (initial) and next (final) Merkle roots as mentioned above,
  the heights of the Merkle trees, a list of vault operations and a list of conditional transfers.

  A vault operation can be a ramping operation (deposit/withdrawal) or an indication to clear
  a full withdrawal request. Each vault operation is encoded in 3 words as follows:
  | 1. Word 0: Stark Key of the vault owner (or the requestor Stark Key for false full
  |    withdrawal).
  | 2. Word 1: Asset ID of the vault representing either the currency (for fungible tokens) or
  |    a unique token ID and its on-chain contract association (for non-fungible tokens).
  | 3. Word 2:
  |    a. ID of the vault (off-chain account)
  |    b. Vault balance change in biased representation (excess-2**63).
  |       A negative balance change implies a withdrawal while a positive amount implies a deposit.
  |       A zero balance change may be used for operations implying neither
  |       (e.g. a false full withdrawal request).
  |    c. A bit indicating whether the operation requires clearing a full withdrawal request.

  The above information is used by the exchange contract in order to update the pending accounts
  used for deposits (see :sol:mod:`Deposits`) and withdrawals (see :sol:mod:`Withdrawals`).

  The next section in the publicInput is a list of encoded conditions corresponding to the
  conditional transfers in the batch. A condition is encoded as a hash of the conditional transfer
  `applicationData`, described below, masked to 250 bits.

  The `applicationData` holds the following information:
  | 1. The ID of the current batch for which the operator is submitting the update. 
  | 2. The expected ID of the last batch accepted on chain. This allows the operator submitting
  |    state updates to ensure the same batch order is accepted on-chain as was intended by the
  |    operator in the event that more than one valid update may have been generated based on
  |    different previous batches - an unlikely but possible event.
  | 3. For each conditional transfer in the batch two words are provided:
  |    a. Word 0: The address of a fact registry contract
  |    b. Word 1: A fact to be verified on the above contract attesting that the
  |       condition has been met on-chain.

  The STARK proof attesting to the validity of the state update is submitted separately by the
  exchange service to (one or more) STARK integrity verifier contract(s).
  Likewise, the signatures of committee members attesting to
  the availability of the vault and order data is submitted separately by the exchange service to
  (one or more) availability verifier contract(s) (see :sol:mod:`Committee`).

  The state update is only accepted by the exchange contract if the integrity verifier and
  availability verifier contracts have indeed received such proof of soundness and data
  availability.
*/
contract UpdateState is
    MainStorage,
    LibConstants,
    VerifyFactChain,
    MAcceptModifications,
    MFreezable,
    MOperator,
    PublicInputOffsets
{

    event LogRootUpdate(
        uint256 sequenceNumber,
        uint256 batchId,
        uint256 vaultRoot,
        uint256 orderRoot
    );

    function updateState(
        uint256[] calldata publicInput,
        uint256[] calldata applicationData
    )
        external
        notFrozen()
        onlyOperator()
    {
        require(
            publicInput.length >= PUB_IN_TRANSACTIONS_DATA_OFFSET,
            "publicInput does not contain all required fields.");
        require(
            publicInput[PUB_IN_FINAL_VAULT_ROOT_OFFSET] < K_MODULUS,
            "New vault root >= PRIME.");
        require(
            publicInput[PUB_IN_FINAL_ORDER_ROOT_OFFSET] < K_MODULUS,
            "New order root >= PRIME.");
        require(
            lastBatchId == 0 ||
            applicationData[APP_DATA_PREVIOUS_BATCH_ID_OFFSET] == lastBatchId,
            "WRONG_PREVIOUS_BATCH_ID");

        // Ensure global timestamp has not expired.
        require(
            publicInput[PUB_IN_GLOBAL_EXPIRATION_TIMESTAMP_OFFSET] < 2**EXPIRATION_TIMESTAMP_BITS,
            "Global expiration timestamp is out of range.");

        require( // NOLINT: block-timestamp.
            // solium-disable-next-line security/no-block-members
            publicInput[PUB_IN_GLOBAL_EXPIRATION_TIMESTAMP_OFFSET] > now / 3600,
            "Timestamp of the current block passed the threshold for the transaction batch.");

        bytes32 publicInputFact = keccak256(abi.encodePacked(publicInput));

        verifyFact(
            verifiersChain,
            publicInputFact,
            "NO_STATE_TRANSITION_VERIFIERS",
            "NO_STATE_TRANSITION_PROOF");

        bytes32 availabilityFact = keccak256(
            abi.encodePacked(
            publicInput[PUB_IN_FINAL_VAULT_ROOT_OFFSET],
            publicInput[PUB_IN_VAULT_TREE_HEIGHT_OFFSET],
            publicInput[PUB_IN_FINAL_ORDER_ROOT_OFFSET],
            publicInput[PUB_IN_ORDER_TREE_HEIGHT_OFFSET],
            sequenceNumber + 1));

        verifyFact(
            availabilityVerifiersChain,
            availabilityFact,
            "NO_AVAILABILITY_VERIFIERS",
            "NO_AVAILABILITY_PROOF");

        performUpdateState(publicInput, applicationData);
    }

    function performUpdateState(
        uint256[] memory publicInput,
        uint256[] memory applicationData
    )
        internal
    {
        rootUpdate(
            publicInput[PUB_IN_INITIAL_VAULT_ROOT_OFFSET],
            publicInput[PUB_IN_FINAL_VAULT_ROOT_OFFSET],
            publicInput[PUB_IN_INITIAL_ORDER_ROOT_OFFSET],
            publicInput[PUB_IN_FINAL_ORDER_ROOT_OFFSET],
            publicInput[PUB_IN_VAULT_TREE_HEIGHT_OFFSET],
            publicInput[PUB_IN_ORDER_TREE_HEIGHT_OFFSET],
            applicationData[APP_DATA_BATCH_ID_OFFSET]
        );
        sendModifications(publicInput, applicationData);
    }

    function rootUpdate(
        uint256 oldVaultRoot,
        uint256 newVaultRoot,
        uint256 oldOrderRoot,
        uint256 newOrderRoot,
        uint256 vaultTreeHeightSent,
        uint256 orderTreeHeightSent,
        uint256 batchId
    )
        internal
        notFrozen()
    {
        // Assert that the old state is correct.
        require(oldVaultRoot == vaultRoot, "VAULT_ROOT_INCORRECT");
        require(oldOrderRoot == orderRoot, "ORDER_ROOT_INCORRECT");

        // Assert that heights are correct.
        require(vaultTreeHeight == vaultTreeHeightSent, "VAULT_HEIGHT_INCORRECT");
        require(orderTreeHeight == orderTreeHeightSent, "ORDER_HEIGHT_INCORRECT");

        // Update state.
        vaultRoot = newVaultRoot;
        orderRoot = newOrderRoot;
        sequenceNumber = sequenceNumber + 1;
        lastBatchId = batchId;

        // Log update.
        emit LogRootUpdate(sequenceNumber, batchId, vaultRoot, orderRoot);
    }

    function sendModifications(
        uint256[] memory publicInput,
        uint256[] memory applicationData
    ) private {
        uint256 nModifications = publicInput[PUB_IN_N_MODIFICATIONS_OFFSET];
        uint256 nCondTransfers = publicInput[PUB_IN_N_CONDITIONAL_TRANSFERS_OFFSET];

        // Sanity value that also protects from theoretical overflow in multiplication.
        require(nModifications < 2**64, "Invalid number of modifications.");
        require(nCondTransfers < 2**64, "Invalid number of conditional transfers.");
        require(
            publicInput.length == PUB_IN_TRANSACTIONS_DATA_OFFSET +
                                  PUB_IN_N_WORDS_PER_MODIFICATION * nModifications +
                                  PUB_IN_N_WORDS_PER_CONDITIONAL_TRANSFER * nCondTransfers,
            "publicInput size is inconsistent with expected transactions.");
        require(
            applicationData.length == APP_DATA_TRANSACTIONS_DATA_OFFSET +
                                      APP_DATA_N_WORDS_PER_CONDITIONAL_TRANSFER * nCondTransfers,
            "applicationData size is inconsistent with expected transactions.");

        uint256 offsetPubInput = PUB_IN_TRANSACTIONS_DATA_OFFSET;
        uint256 offsetAppData = APP_DATA_TRANSACTIONS_DATA_OFFSET;

        for (uint256 i = 0; i < nModifications; i++) {
            uint256 starkKey = publicInput[offsetPubInput];
            uint256 assetId = publicInput[offsetPubInput + 1];

            require(starkKey < K_MODULUS, "Stark key >= PRIME");
            require(assetId < K_MODULUS, "Asset id >= PRIME");

            uint256 actionParams = publicInput[offsetPubInput + 2];
            require ((actionParams >> 96) == 0, "Unsupported modification action field.");

            // Extract and unbias the balance_diff.
            int256 balance_diff = int256((actionParams & ((1 << 64) - 1)) - (1 << 63));
            uint256 vaultId = (actionParams >> 64) & ((1 << 31) - 1);

            if (balance_diff > 0) {
                // This is a deposit.
                acceptDeposit(starkKey, vaultId, assetId, uint256(balance_diff));
            } else if (balance_diff < 0) {
                // This is a withdrawal.
                acceptWithdrawal(starkKey, assetId, uint256(-balance_diff));
            }

            if ((actionParams & (1 << 95)) != 0) {
                clearFullWithdrawalRequest(starkKey, vaultId);
            }

            offsetPubInput += PUB_IN_N_WORDS_PER_MODIFICATION;
        }

        // Conditional Transfers appear after all other modifications.
        for (uint256 i = 0; i < nCondTransfers; i++) {
            address factRegistryAddress = address(applicationData[offsetAppData]);
            bytes32 condTransferFact = bytes32(applicationData[offsetAppData + 1]);
            uint256 condition = publicInput[offsetPubInput];

            // The condition is the 250 LS bits of keccak256 of the fact registry & fact.
            require(
                condition ==
                    uint256(keccak256(abi.encodePacked(factRegistryAddress, condTransferFact))) &
                    MASK_250,
                "Condition mismatch.");
            (bool success, bytes memory returndata) = // NOLINT: low-level-calls-loop.
            factRegistryAddress.staticcall(
                abi.encodeWithSignature("isValid(bytes32)",condTransferFact));
            require(success && returndata.length == 32, "BAD_FACT_REGISTRY_CONTRACT");
            require(
                abi.decode(returndata, (bool)),
                "Condition for the conditional transfer was not met.");

            offsetPubInput += PUB_IN_N_WORDS_PER_CONDITIONAL_TRANSFER;
            offsetAppData += APP_DATA_N_WORDS_PER_CONDITIONAL_TRANSFER;
        }
    }
}
