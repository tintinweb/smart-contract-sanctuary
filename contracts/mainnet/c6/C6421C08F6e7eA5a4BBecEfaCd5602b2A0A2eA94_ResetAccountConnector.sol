// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import './interfaces/IResetAccountConnector.sol';
import '../modules/FoldingAccount/FoldingAccountStorage.sol';
import '../modules/StopLoss/StopLossStorage.sol';

contract ResetAccountConnector is IResetAccountConnector, FoldingAccountStorage, StopLossStorage {
    function resetAccount(
        address oldOwner,
        address newOwner,
        uint256
    ) external override onlyNFTContract {
        emit OwnerChanged(aStore().owner, newOwner);
        aStore().owner = newOwner;
        if (oldOwner != address(0)) {
            StopLossStore storage store = stopLossStore();
            store.unwindFactor = 0;
            store.slippageIncentive = 0;
            store.collateralUsageLimit = 0;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IResetAccountConnector {
    event OwnerChanged(address oldOwner, address newOwner);

    function resetAccount(
        address oldOwner,
        address newOwner,
        uint256 accountId
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract FoldingAccountStorage {
    bytes32 constant ACCOUNT_STORAGE_POSITION = keccak256('folding.account.storage');

    /**
     * entryCaller:         address of the caller of the account, during a transaction
     *
     * callbackTarget:      address of logic to be run when expecting a callback
     *
     * expectedCallbackSig: signature of function to be run when expecting a callback
     *
     * foldingRegistry      address of factory creating FoldingAccount
     *
     * nft:                 address of the nft contract.
     *
     * owner:               address of the owner of this FoldingAccount.
     */
    struct AccountStore {
        address entryCaller;
        address callbackTarget;
        bytes4 expectedCallbackSig;
        address foldingRegistry;
        address nft;
        address owner;
    }

    modifier onlyAccountOwner() {
        AccountStore storage s = aStore();
        require(s.entryCaller == s.owner, 'FA2');
        _;
    }

    modifier onlyNFTContract() {
        AccountStore storage s = aStore();
        require(s.entryCaller == s.nft, 'FA3');
        _;
    }

    modifier onlyAccountOwnerOrRegistry() {
        AccountStore storage s = aStore();
        require(s.entryCaller == s.owner || s.entryCaller == s.foldingRegistry, 'FA4');
        _;
    }

    function aStore() internal pure returns (AccountStore storage s) {
        bytes32 position = ACCOUNT_STORAGE_POSITION;
        assembly {
            s_slot := position
        }
    }

    function accountOwner() internal view returns (address) {
        return aStore().owner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

contract StopLossStorage {
    bytes32 constant STOP_LOSS_LIMIT_STORAGE_POSITION = keccak256('folding.storage.stopLoss');

    /**
     * collateralUsageLimit:    when the position collateral usage surpasses this threshold,
     *                          anyone will be able to trigger the stop loss
     *
     * slippageIncentive:       when the bot repays the debt, it will be able to take
     *                          an amount of supply token equivalent to the repaid debt plus
     *                          this incentive specified in percentage.
     *                          It has to be carefully configured with unwind factor
     *
     * unwindFactor:            percentage of debt that can be repaid when the position is
     *                          eligible for stop loss
     */
    struct StopLossStore {
        uint256 collateralUsageLimit; // ranges from 0 to 1e18
        uint256 slippageIncentive; // ranges from 0 to 1e18
        uint256 unwindFactor; // ranges from 0 to 1e18
    }

    function stopLossStore() internal pure returns (StopLossStore storage s) {
        bytes32 position = STOP_LOSS_LIMIT_STORAGE_POSITION;
        assembly {
            s_slot := position
        }
    }
}