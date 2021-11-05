/*
██████╗░██████╗░██╗███╗░░░███╗███████╗██████╗░░█████╗░░█████╗░
██╔══██╗██╔══██╗██║████╗░████║██╔════╝██╔══██╗██╔══██╗██╔══██╗
██████╔╝██████╔╝██║██╔████╔██║█████╗░░██║░░██║███████║██║░░██║
██╔═══╝░██╔══██╗██║██║╚██╔╝██║██╔══╝░░██║░░██║██╔══██║██║░░██║
██║░░░░░██║░░██║██║██║░╚═╝░██║███████╗██████╔╝██║░░██║╚█████╔╝
╚═╝░░░░░╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝╚══════╝╚═════╝░╚═╝░░╚═╝░╚════╝░
*/

// SPDX-License-Identifier: GPL-3.0-or-later
// Signer contract. Enables signing transaction before sending it to Gnosis Safe.
// Copyright (C) 2021 PrimeDao

// solium-disable linebreak-style
pragma solidity 0.8.9;

import "./interface/Safe.sol";
import "@gnosis.pm/safe-contracts/contracts/interfaces/ISignatureValidator.sol";

/**
 * @title PrimeDAO Signer Contract
 * @dev   Enables signing approved function signature transaction before sending it to Gnosis Safe.
 */
contract SignerV2 is ISignatureValidator {
    bytes32 private constant DOMAIN_SEPARATOR_TYPEHASH =
        0x7a9f5b2bf4dbb53eb85e012c6094a3d71d76e5bfe821f44ab63ed59311264e35;
    bytes32 private constant MSG_TYPEHASH =
        0xa1a7ad659422d5fc08fdc481fd7d8af8daf7993bc4e833452b0268ceaab66e5d; // mapping for msg typehash

    mapping(bytes32 => bytes32) public approvedSignatures;

    /* solium-disable */
    address public safe;
    mapping(address => mapping(bytes4 => bool)) public allowedTransactions;
    /* solium-enable */

    event SignatureCreated(bytes signature, bytes32 indexed hash);

    modifier onlySafe() {
        require(msg.sender == safe, "Signer: only safe functionality");
        _;
    }

    /**
     * @dev                       Signer Constructor
     * @param _safe               Gnosis Safe address.
     * @param _contracts          array of contract addresses
     * @param _functionSignatures array of function signatures
     */
    constructor(
        address _safe,
        address[] memory _contracts,
        bytes4[] memory _functionSignatures
    ) {
        require(_safe != address(0), "Signer: Safe address zero");
        safe = _safe;
        for (uint256 i; i < _contracts.length; i++) {
            require(
                _contracts[i] != address(0),
                "Signer: contract address zero"
            );
            require(
                _functionSignatures[i] != bytes4(0),
                "Signer: function signature zero"
            );
            allowedTransactions[_contracts[i]][_functionSignatures[i]] = true;
        }
    }

    /**
     * @dev                   Signature generator
     * @param _to             receiver address.
     * @param _value          value in wei.
     * @param _data           encoded transaction data.
     * @param _operation      type of operation call.
     * @param _safeTxGas      safe transaction gas for gnosis safe.
     * @param _baseGas        base gas for gnosis safe.
     * @param _gasPrice       gas price for gnosis safe transaction.
     * @param _gasToken       token which gas needs to paid for gnosis safe transaction.
     * @param _refundReceiver address account to receive refund for remaining gas.
     * @param _nonce          gnosis safe contract nonce.
     */
    function generateSignature(
        address _to,
        uint256 _value,
        bytes calldata _data,
        Enum.Operation _operation,
        uint256 _safeTxGas,
        uint256 _baseGas,
        uint256 _gasPrice,
        address _gasToken,
        address _refundReceiver,
        uint256 _nonce
    ) external returns (bytes memory signature, bytes32 hash) {
        // check if transaction parameters are correct
        require(
            allowedTransactions[_to][_getFunctionHashFromData(_data)],
            "Signer: invalid function"
        );
        require(
            _value == 0 &&
                _refundReceiver == address(0) &&
                _operation == Enum.Operation.Call,
            "Signer: invalid arguments"
        );

        // get contractTransactionHash from gnosis safe
        hash = Safe(safe).getTransactionHash(
            _to,
            0,
            _data,
            _operation,
            _safeTxGas,
            _baseGas,
            _gasPrice,
            _gasToken,
            _refundReceiver,
            _nonce
        );

        bytes memory paddedAddress = bytes.concat(
            bytes12(0),
            bytes20(address(this))
        );
        bytes memory messageHash = _encodeMessageHash(hash);
        // check if transaction is not signed before
        // solhint-disable-next-line reason-string
        require(
            approvedSignatures[hash] != keccak256(messageHash),
            "Signer: transaction already signed"
        );

        // generate signature and add it to approvedSignatures mapping
        signature = bytes.concat(
            paddedAddress,
            bytes32(uint256(65)),
            bytes1(0),
            bytes32(uint256(messageHash.length)),
            messageHash
        );
        approvedSignatures[hash] = keccak256(messageHash);
        emit SignatureCreated(signature, hash);
    }

    /**
     * @dev                Validate signature using EIP1271
     * @param _data        Encoded transaction hash supplied to verify signature.
     * @param _signature   Signature that needs to be verified.
     */
    function isValidSignature(bytes memory _data, bytes memory _signature)
        public
        view
        override
        returns (bytes4)
    {
        if (_data.length == 32) {
            bytes32 hash;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                hash := mload(add(_data, 32))
            }
            if (approvedSignatures[hash] == keccak256(_signature)) {
                return EIP1271_MAGIC_VALUE;
            }
        } else {
            if (approvedSignatures[keccak256(_data)] == keccak256(_signature)) {
                return EIP1271_MAGIC_VALUE;
            }
        }
        return "0x";
    }

    /**
     * @dev               Get the byte hash of function call i.e. first four bytes of data
     * @param data        encoded transaction data.
     */
    function _getFunctionHashFromData(bytes memory data)
        private
        pure
        returns (bytes4 functionHash)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            functionHash := mload(add(data, 32))
        }
    }

    /**
     * @dev                encode message with contants
     * @param message      the message that needs to be encoded
     */
    function _encodeMessageHash(bytes32 message)
        private
        pure
        returns (bytes memory)
    {
        bytes32 safeMessageHash = keccak256(abi.encode(MSG_TYPEHASH, message));
        return
            abi.encodePacked(
                bytes1(0x19),
                bytes1(0x23),
                keccak256(
                    abi.encode(DOMAIN_SEPARATOR_TYPEHASH, safeMessageHash)
                )
            );
    }

    /**
     * @dev                set new safe
     * @param _safe        safe address
     */
    function setSafe(address _safe) public onlySafe {
        require(_safe != address(0), "Signer: Safe zero address");
        safe = _safe;
    }

    /**
     * @dev                      add new contracts and functions
     * @param _contract          contract address
     * @param _functionSignature function signature for the contract
     */
    function approveNewTransaction(address _contract, bytes4 _functionSignature)
        external
        onlySafe
    {
        require(_contract != address(0), "Signer: contract address zero");
        require(
            _functionSignature != bytes4(0),
            "Signer: function signature zero"
        );
        allowedTransactions[_contract][_functionSignature] = true;
    }

    /**
     * @dev                      add new contracts and functions
     * @param _contract           contract address
     * @param _functionSignature function signature for the contract
     */
    function removeAllowedTransaction(
        address _contract,
        bytes4 _functionSignature
    ) external onlySafe {
        // solhint-disable-next-line reason-string
        require(
            allowedTransactions[_contract][_functionSignature] == true,
            "Signer: only approved transactions can be removed"
        );
        allowedTransactions[_contract][_functionSignature] = false;
    }
}

/*

██████╗░██████╗░██╗███╗░░░███╗███████╗██████╗░░█████╗░░█████╗░
██╔══██╗██╔══██╗██║████╗░████║██╔════╝██╔══██╗██╔══██╗██╔══██╗
██████╔╝██████╔╝██║██╔████╔██║█████╗░░██║░░██║███████║██║░░██║
██╔═══╝░██╔══██╗██║██║╚██╔╝██║██╔══╝░░██║░░██║██╔══██║██║░░██║
██║░░░░░██║░░██║██║██║░╚═╝░██║███████╗██████╔╝██║░░██║╚█████╔╝
╚═╝░░░░░╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝╚══════╝╚═════╝░╚═╝░░╚═╝░╚════╝░

*/

// SPDX-License-Identifier: GPL-3.0-or-later

/* solium-disable */
pragma solidity 0.8.9;

contract Enum {
    enum Operation {
        Call,
        DelegateCall
    }
}

interface Safe {
    function getTransactionHash(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    ) external view returns (bytes32);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

contract ISignatureValidatorConstants {
    // bytes4(keccak256("isValidSignature(bytes,bytes)")
    bytes4 internal constant EIP1271_MAGIC_VALUE = 0x20c13b0b;
}

abstract contract ISignatureValidator is ISignatureValidatorConstants {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param _data Arbitrary length data signed on the behalf of address(this)
     * @param _signature Signature byte array associated with _data
     *
     * MUST return the bytes4 magic value 0x20c13b0b when function passes.
     * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
     * MUST allow external calls
     */
    function isValidSignature(bytes memory _data, bytes memory _signature) public view virtual returns (bytes4);
}