//SPDX-License-Identifier: lgplv3
pragma solidity ^0.8.0;

import "./MultiSigWallet.sol";

/// @title MultiSigWalletWithPermit wallet with permit -
/// @author [email protected]
contract MultiSigWalletWithPermit is MultiSigWallet {
    uint256 constant MAX =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /*
     * Public functions
     */
    /// @dev Contract constructor sets initial owners, required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    constructor(address[] memory _owners, uint256 _required)
        MultiSigWallet(_owners, _required)
    {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("MultiSigWalletWithPermit")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
        PERMIT_TYPEHASH = keccak256(
            "DelegateCall(address delegator,address destination,uint256 value,bytes data,uint256 transactionId)"
        );
    }

    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public PERMIT_TYPEHASH;

    /*
     * delegateCallWithPermit
     */
    /// @dev delegate call
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @param transactionId Transaction ID.
    /// @return newTransactionId Returns transaction ID.
    function delegateCallWithPermits(
        address destination,
        uint256 value,
        bytes memory data,
        uint256 transactionId,
        bytes32[] memory rs,
        bytes32[] memory ss,
        uint8[] memory vs
    ) public returns (uint256[] memory newTransactionId) {
        require(rs.length == ss.length, "invalid signs");
        require(rs.length == vs.length, "invalid signs2");
        newTransactionId = new uint256[](rs.length);
        for (uint8 i = 0; i < rs.length; ++i) {
            newTransactionId[i] = delegateCallWithPermit(
                destination,
                value,
                data,
                transactionId,
                rs[i],
                ss[i],
                vs[i]
            );
        }
    }

    /*
     * delegateCallWithPermit
     */
    /// @dev delegate call
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @param transactionId Transaction ID.
    /// @return newTransactionId Returns transaction ID.
    function delegateCallWithPermit(
        address destination,
        uint256 value,
        bytes memory data,
        uint256 transactionId,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public returns (uint256 newTransactionId) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        msg.sender,
                        destination,
                        value,
                        data,
                        transactionId
                    )
                )
            )
        );

        address owner = ecrecover(digest, v, r, s);
        require(owner != address(0), "0 address");
        require(isOwner[owner]);

        if (destination != address(0)) {
            require(transactionId == MAX, "invalid transactionId");
            newTransactionId = addTransaction(destination, value, data);
            confirmTransactionInner(transactionId, owner);
        } else {
            confirmTransactionInner(transactionId, owner);
            newTransactionId = transactionId;
        }
    }

    function confirmTransactionInner(uint256 transactionId, address owner)
        private
        transactionExists(transactionId)
        notConfirmed(transactionId, owner)
    {
        confirmations[transactionId][owner] = true;
        emit Confirmation(owner, transactionId);
        executeTransactionInner(transactionId);
    }

    function executeTransactionInner(uint256 transactionId)
        private
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            Transaction storage txn = transactions[transactionId];
            txn.executed = true;
            if (
                external_call(
                    txn.destination,
                    txn.value,
                    txn.data.length,
                    txn.data
                )
            ) emit Execution(transactionId);
            else {
                emit ExecutionFailure(transactionId);
                txn.executed = false;
            }
        }
    }
}