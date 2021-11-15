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

