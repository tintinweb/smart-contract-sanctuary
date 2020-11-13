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
import "MFreezable.sol";
import "MKeyGetters.sol";
import "MainStorage.sol";

/**
  At any point in time, a user may opt to perform a full withdrawal request for a given off-chain
  vault. Such a request is a different flow than the normal withdrawal flow
  (see :sol:mod:`Withdrawals`) in the following ways:

  1. The user calls a contract function instead of calling an off-chain service API.
  2. Upon the successful fulfillment of the operation, the entire vault balance is withdrawn, and it is effectively evicted (no longer belongs to the user). Hence, a full withdrawal request does not include an amount to withdraw.
  3. Failure of the offchain exchange to service a full withdrawal request within a given timeframe gives the user the option to freeze the exchange disabling the ability to update its state.

  A full withdrawal operation is executed as follows:

  1. The user submits a full withdrawal request by calling :sol:func:`fullWithdrawalRequest` with the vault ID to be withdrawn.
  2. Under normal operation of the exchange service, the exchange submits a STARK proof indicating the fulfillment of the withdrawal from the vault.
  3. If the exchange fails to service the request (does not submit a valid proof as above), upon the expiration of a :sol:cons:`FREEZE_GRACE_PERIOD`, the user is entitled to freeze the contract by calling :sol:func:`freezeRequest` and indicating the vaultId for which the full withdrawal request has not been serviced.
  4. Upon acceptance of the proof above, the contract adds the withdrawn amount to an on-chain pending withdrawals account under the stark key of the vault owner and the appropriate asset ID. At the same time, the full withdrawal request is cleared.
  5. The user may then withdraw this amount from the pending withdrawals account by calling the normal withdraw function (see :sol:mod:`Withdrawals`) to transfer the funds to the users Eth or ERC20 account (depending on the token type).

  If a user requests a full withdrawal for a vault that is not associated with the StarkKey of the
  user, the exchange may prove this and the full withdrawal request is cleared without any effect on
  the vault (and no funds will be released on-chain for withdrawal).

  Full withdrawal requests cannot be cancelled by a user.

  To avoid the potential attack of the exchange by a flood of full withdrawal requests, the rate of
  such requests must be limited. In the currently implementation, this is achieved by making the
  cost of the request exceed 1M gas.

*/
contract FullWithdrawals is MainStorage, LibConstants, MFreezable, MKeyGetters {
    event LogFullWithdrawalRequest(uint256 starkKey, uint256 vaultId);

    function fullWithdrawalRequest(uint256 starkKey, uint256 vaultId) external notFrozen()
        isSenderStarkKey(starkKey) {
        // Verify vault ID in range.
        require(vaultId <= MAX_VAULT_ID, "OUT_OF_RANGE_VAULT_ID");

        // Start timer on escape request.
        // solium-disable-next-line security/no-block-members
        fullWithdrawalRequests[starkKey][vaultId] = now;

        // Log request.
        emit LogFullWithdrawalRequest(starkKey, vaultId);

        // Burn gas to prevent denial of service (too many requests per block).
        for (uint256 i = 0; i < 22231; i++) {}
        // solium-disable-previous-line no-empty-blocks
    }

    function getFullWithdrawalRequest(uint256 starkKey, uint256 vaultId)
        external
        view
        returns (uint256 res)
    {
        // Return request value. Expect zero if the request doesn't exist or has been serviced, and
        // a non-zero value otherwise.
        res = fullWithdrawalRequests[starkKey][vaultId];
    }

    function freezeRequest(uint256 starkKey, uint256 vaultId) external notFrozen() {
        // Verify vaultId in range.
        require(vaultId <= MAX_VAULT_ID, "OUT_OF_RANGE_VAULT_ID");

        // Load request time.
        uint256 requestTime = fullWithdrawalRequests[starkKey][vaultId];
        require(requestTime != 0, "FULL_WITHDRAWAL_UNREQUESTED");

        // Verify timer on escape request.
        uint256 freezeTime = requestTime + FREEZE_GRACE_PERIOD;
        assert(freezeTime >= FREEZE_GRACE_PERIOD);
        // solium-disable-next-line security/no-block-members
        require(now >= freezeTime, "FULL_WITHDRAWAL_PENDING"); // NOLINT: timestamp.

        // The only place this function is called.
        freeze();
    }
}
