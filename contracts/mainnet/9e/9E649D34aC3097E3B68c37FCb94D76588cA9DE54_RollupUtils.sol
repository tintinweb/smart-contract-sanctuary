pragma solidity ^0.5.15;
pragma experimental ABIEncoderV2;

import { Types } from "./Types.sol";

library RollupUtils {
    // ---------- Account Related Utils -------------------
    function PDALeafToHash(Types.PDALeaf memory _PDA_Leaf)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(_PDA_Leaf.pubkey));
    }

    // returns a new User Account with updated balance
    function UpdateBalanceInAccount(
        Types.UserAccount memory original_account,
        uint256 new_balance
    ) public pure returns (Types.UserAccount memory updated_account) {
        original_account.balance = new_balance;
        return original_account;
    }

    function BalanceFromAccount(Types.UserAccount memory account)
        public
        pure
        returns (uint256)
    {
        return account.balance;
    }

    // AccountFromBytes decodes the bytes to account
    function AccountFromBytes(bytes memory accountBytes)
        public
        pure
        returns (
            uint256 ID,
            uint256 balance,
            uint256 nonce,
            uint256 tokenType
        )
    {
        return abi.decode(accountBytes, (uint256, uint256, uint256, uint256));
    }

    //
    // BytesFromAccount and BytesFromAccountDeconstructed do the same thing i.e encode account to bytes
    //
    function BytesFromAccount(Types.UserAccount memory account)
        public
        pure
        returns (bytes memory)
    {
        bytes memory data = abi.encodePacked(
            account.ID,
            account.balance,
            account.nonce,
            account.tokenType
        );

        return data;
    }

    function BytesFromAccountDeconstructed(
        uint256 ID,
        uint256 balance,
        uint256 nonce,
        uint256 tokenType
    ) public pure returns (bytes memory) {
        return abi.encodePacked(ID, balance, nonce, tokenType);
    }

    //
    // HashFromAccount and getAccountHash do the same thing i.e hash account
    //
    function getAccountHash(
        uint256 id,
        uint256 balance,
        uint256 nonce,
        uint256 tokenType
    ) public pure returns (bytes32) {
        return
            keccak256(
                BytesFromAccountDeconstructed(id, balance, nonce, tokenType)
            );
    }

    function HashFromAccount(Types.UserAccount memory account)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                BytesFromAccountDeconstructed(
                    account.ID,
                    account.balance,
                    account.nonce,
                    account.tokenType
                )
            );
    }

    // ---------- Tx Related Utils -------------------
    function CompressTx(Types.Transaction memory _tx)
        public
        pure
        returns (bytes memory)
    {
        return
            abi.encode(_tx.fromIndex, _tx.toIndex, _tx.amount, _tx.signature);
    }

    function DecompressTx(bytes memory txBytes)
        public
        pure
        returns (
            uint256 from,
            uint256 to,
            uint256 nonce,
            bytes memory sig
        )
    {
        return abi.decode(txBytes, (uint256, uint256, uint256, bytes));
    }

    function CompressTxWithMessage(bytes memory message, bytes memory sig)
        public
        pure
        returns (bytes memory)
    {
        Types.Transaction memory _tx = TxFromBytes(message);
        return abi.encode(_tx.fromIndex, _tx.toIndex, _tx.amount, sig);
    }

    // Decoding transaction from bytes
    function TxFromBytesDeconstructed(bytes memory txBytes)
        public
        pure
        returns (
            uint256 from,
            uint256 to,
            uint256 tokenType,
            uint256 nonce,
            uint256 txType,
            uint256 amount
        )
    {
        return
            abi.decode(
                txBytes,
                (uint256, uint256, uint256, uint256, uint256, uint256)
            );
    }

    function TxFromBytes(bytes memory txBytes)
        public
        pure
        returns (Types.Transaction memory)
    {
        Types.Transaction memory transaction;
        (
            transaction.fromIndex,
            transaction.toIndex,
            transaction.tokenType,
            transaction.nonce,
            transaction.txType,
            transaction.amount
        ) = abi.decode(
            txBytes,
            (uint256, uint256, uint256, uint256, uint256, uint256)
        );
        return transaction;
    }

    //
    // BytesFromTx and BytesFromTxDeconstructed do the same thing i.e encode transaction to bytes
    //
    function BytesFromTx(Types.Transaction memory _tx)
        public
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                _tx.fromIndex,
                _tx.toIndex,
                _tx.tokenType,
                _tx.nonce,
                _tx.txType,
                _tx.amount
            );
    }

    function BytesFromTxDeconstructed(
        uint256 from,
        uint256 to,
        uint256 tokenType,
        uint256 nonce,
        uint256 txType,
        uint256 amount
    ) public pure returns (bytes memory) {
        return abi.encodePacked(from, to, tokenType, nonce, txType, amount);
    }

    //
    // HashFromTx and getTxSignBytes do the same thing i.e get the tx data to be signed
    //
    function HashFromTx(Types.Transaction memory _tx)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                BytesFromTxDeconstructed(
                    _tx.fromIndex,
                    _tx.toIndex,
                    _tx.tokenType,
                    _tx.nonce,
                    _tx.txType,
                    _tx.amount
                )
            );
    }

    function getTxSignBytes(
        uint256 fromIndex,
        uint256 toIndex,
        uint256 tokenType,
        uint256 txType,
        uint256 nonce,
        uint256 amount
    ) public pure returns (bytes32) {
        return
            keccak256(
                BytesFromTxDeconstructed(
                    fromIndex,
                    toIndex,
                    tokenType,
                    nonce,
                    txType,
                    amount
                )
            );
    }

    /**
     * @notice Calculates the address from the pubkey
     * @param pub is the pubkey
     * @return Returns the address that has been calculated from the pubkey
     */
    function calculateAddress(bytes memory pub)
        public
        pure
        returns (address addr)
    {
        bytes32 hash = keccak256(pub);
        assembly {
            mstore(0, hash)
            addr := mload(0)
        }
    }

    function GetGenesisLeaves() public view returns (bytes32[2] memory leaves) {
        Types.UserAccount memory account1 = Types.UserAccount({
            ID: 0,
            tokenType: 0,
            balance: 0,
            nonce: 0
        });
        Types.UserAccount memory account2 = Types.UserAccount({
            ID: 1,
            tokenType: 0,
            balance: 0,
            nonce: 0
        });
        leaves[0] = HashFromAccount(account1);
        leaves[1] = HashFromAccount(account2);
    }

    function GetGenesisDataBlocks()
        public
        view
        returns (bytes[2] memory dataBlocks)
    {
        Types.UserAccount memory account1 = Types.UserAccount({
            ID: 0,
            tokenType: 0,
            balance: 0,
            nonce: 0
        });
        Types.UserAccount memory account2 = Types.UserAccount({
            ID: 1,
            tokenType: 0,
            balance: 0,
            nonce: 0
        });
        dataBlocks[0] = BytesFromAccount(account1);
        dataBlocks[1] = BytesFromAccount(account2);
    }
}

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

