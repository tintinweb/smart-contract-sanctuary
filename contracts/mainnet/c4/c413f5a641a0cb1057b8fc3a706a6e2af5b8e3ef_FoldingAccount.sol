// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import '../modules/FoldingAccount/FoldingAccountStorage.sol';
import './interfaces/IFoldingConnectorProvider.sol';

contract FoldingAccount is FoldingAccountStorage {
    constructor(address foldingRegistry, address nft) public {
        AccountStore storage store = aStore();

        store.foldingRegistry = foldingRegistry;
        store.nft = nft;
    }

    /// @notice Find the connector for `msg.sig` and delegate call it with `msg.data`
    function delegate() private {
        bool firstCall = false; // We need to delete the entryCaller on exit

        AccountStore storage accountStorage = aStore();
        if (accountStorage.entryCaller == address(0)) {
            accountStorage.entryCaller = msg.sender;
            firstCall = true;
        }
        // Check if a connector expects a callback or find connector
        address impl = accountStorage.callbackTarget;
        if (impl != address(0)) {
            require(accountStorage.expectedCallbackSig == msg.sig, 'FA1');
        } else {
            impl = IFoldingConnectorProvider(accountStorage.foldingRegistry).getImplementation(msg.sig);
        }

        /// @dev This assembly code returns directly to caller
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(0, 0, size)
            switch result
            case 0 {
                revert(0, size)
            }
            default {
                /// @dev if this is the first call, set the entryCaller to 0
                if firstCall {
                    sstore(accountStorage_slot, 0)
                }
                return(0, size)
            }
        }
    }

    fallback() external payable {
        if (msg.sig != bytes4(0)) delegate();
    }
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

interface IFoldingConnectorProvider {
    function getImplementation(bytes4 functionSignature) external view returns (address implementation);
}