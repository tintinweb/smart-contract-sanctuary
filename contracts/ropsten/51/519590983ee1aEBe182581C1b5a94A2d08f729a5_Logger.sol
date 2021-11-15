pragma solidity ^0.5.15;

/**
 * @title DataTypes
 */
library Types {
    // We define Usage for a batch or for a tx
    // to check if the usage of a batch and all txs in it are the same
    enum Usage {
        Genesis, // The Genesis type is only applicable to batch but not tx
        Transfer,
        Deposit
    }
    // PDALeaf represents the leaf in
    // Pubkey DataAvailability Tree
    struct PDALeaf {
        bytes pubkey;
    }

    // Batch represents the batch submitted periodically to the ethereum chain
    struct Batch {
        bytes32 stateRoot;
        bytes32 accountRoot;
        bytes32 depositTree;
        address committer;
        bytes32 txRoot;
        uint256 stakeCommitted;
        uint256 finalisesOn;
        uint256 timestamp;
        Usage batchType;
    }

    // Transaction represents how each transaction looks like for
    // this rollup chain
    struct Transaction {
        uint256 fromIndex;
        uint256 toIndex;
        uint256 tokenType;
        uint256 nonce;
        uint256 txType;
        uint256 amount;
        bytes signature;
    }

    // AccountInclusionProof consists of the following fields
    // 1. Path to the account leaf from root in the balances tree
    // 2. Actual data stored in the leaf
    struct AccountInclusionProof {
        uint256 pathToAccount;
        UserAccount account;
    }

    struct TranasctionInclusionProof {
        uint256 pathToTx;
        Transaction data;
    }

    struct PDAInclusionProof {
        uint256 pathToPubkey;
        PDALeaf pubkey_leaf;
    }

    // UserAccount contains the actual data stored in the leaf of balance tree
    struct UserAccount {
        // ID is the path to the pubkey in the PDA tree
        uint256 ID;
        uint256 tokenType;
        uint256 balance;
        uint256 nonce;
    }

    struct AccountMerkleProof {
        AccountInclusionProof accountIP;
        bytes32[] siblings;
    }

    struct AccountProofs {
        AccountMerkleProof from;
        AccountMerkleProof to;
    }

    struct BatchValidationProofs {
        AccountProofs[] accountProofs;
        PDAMerkleProof[] pdaProof;
    }

    struct TransactionMerkleProof {
        TranasctionInclusionProof _tx;
        bytes32[] siblings;
    }

    struct PDAMerkleProof {
        PDAInclusionProof _pda;
        bytes32[] siblings;
    }

    enum ErrorCode {
        NoError,
        InvalidTokenAddress,
        InvalidTokenAmount,
        NotEnoughTokenBalance,
        BadFromTokenType,
        BadToTokenType
    }
}

pragma solidity ^0.5.15;

import { Types } from "./libs/Types.sol";

contract Logger {
    /*********************
     * Rollup Contract *
     ********************/
    event NewBatch(
        address committer,
        bytes32 txroot,
        bytes32 updatedRoot,
        uint256 index,
        Types.Usage batchType
    );

    function logNewBatch(
        address committer,
        bytes32 txroot,
        bytes32 updatedRoot,
        uint256 index,
        Types.Usage batchType
    ) public {
        emit NewBatch(committer, txroot, updatedRoot, index, batchType);
    }

    event StakeWithdraw(address committed, uint256 amount, uint256 batch_id);

    function logStakeWithdraw(
        address committed,
        uint256 amount,
        uint256 batch_id
    ) public {
        emit StakeWithdraw(committed, amount, batch_id);
    }

    event BatchRollback(
        uint256 batch_id,
        address committer,
        bytes32 stateRoot,
        bytes32 txRoot,
        uint256 stakeSlashed
    );

    function logBatchRollback(
        uint256 batch_id,
        address committer,
        bytes32 stateRoot,
        bytes32 txRoot,
        uint256 stakeSlashed
    ) public {
        emit BatchRollback(
            batch_id,
            committer,
            stateRoot,
            txRoot,
            stakeSlashed
        );
    }

    event RollbackFinalisation(uint256 totalBatchesSlashed);

    function logRollbackFinalisation(uint256 totalBatchesSlashed) public {
        emit RollbackFinalisation(totalBatchesSlashed);
    }

    event RegisteredToken(uint256 tokenType, address tokenContract);

    function logRegisteredToken(uint256 tokenType, address tokenContract)
        public
    {
        emit RegisteredToken(tokenType, tokenContract);
    }

    event RegistrationRequest(address tokenContract);

    function logRegistrationRequest(address tokenContract) public {
        emit RegistrationRequest(tokenContract);
    }

    event NewPubkeyAdded(uint256 AccountID, bytes pubkey);

    function logNewPubkeyAdded(uint256 accountID, bytes memory pubkey) public {
        emit NewPubkeyAdded(accountID, pubkey);
    }

    event DepositQueued(uint256 AccountID, bytes pubkey, bytes data);

    function logDepositQueued(
        uint256 accountID,
        bytes memory pubkey,
        bytes memory data
    ) public {
        emit DepositQueued(accountID, pubkey, data);
    }

    event DepositLeafMerged(bytes32 left, bytes32 right, bytes32 newRoot);

    function logDepositLeafMerged(
        bytes32 left,
        bytes32 right,
        bytes32 newRoot
    ) public {
        emit DepositLeafMerged(left, right, newRoot);
    }

    event DepositSubTreeReady(bytes32 root);

    function logDepositSubTreeReady(bytes32 root) public {
        emit DepositSubTreeReady(root);
    }

    event DepositsFinalised(bytes32 depositSubTreeRoot, uint256 pathToSubTree);

    function logDepositFinalised(
        bytes32 depositSubTreeRoot,
        uint256 pathToSubTree
    ) public {
        emit DepositsFinalised(depositSubTreeRoot, pathToSubTree);
    }
}

