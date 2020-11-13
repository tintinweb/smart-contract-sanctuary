// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import { TransactionData, Action, AbsoluteTokenAmount, Fee, TokenAmount } from "../shared/Structs.sol";


contract SignatureVerifier {

    mapping (address => uint256) internal nonce_;

    bytes32 internal immutable domainSeparator_;

    bytes32 internal constant DOMAIN_SEPARATOR_TYPEHASH = keccak256(
        abi.encodePacked(
            "EIP712Domain(",
            "string name,",
            "address verifyingContract",
            ")"
        )
    );
    bytes32 internal constant TX_DATA_TYPEHASH = keccak256(
        abi.encodePacked(
            TX_DATA_ENCODED_TYPE,
            ABSOLUTE_TOKEN_AMOUNT_ENCODED_TYPE,
            ACTION_ENCODED_TYPE,
            FEE_ENCODED_TYPE,
            TOKEN_AMOUNT_ENCODED_TYPE
        )
    );
    bytes32 internal constant ABSOLUTE_TOKEN_AMOUNT_TYPEHASH =
        keccak256(ABSOLUTE_TOKEN_AMOUNT_ENCODED_TYPE);
    bytes32 internal constant ACTION_TYPEHASH = keccak256(
        abi.encodePacked(
            ACTION_ENCODED_TYPE,
            TOKEN_AMOUNT_ENCODED_TYPE
        )
    );
    bytes32 internal constant FEE_TYPEHASH = keccak256(FEE_ENCODED_TYPE);
    bytes32 internal constant TOKEN_AMOUNT_TYPEHASH = keccak256(TOKEN_AMOUNT_ENCODED_TYPE);

    bytes internal constant TX_DATA_ENCODED_TYPE = abi.encodePacked(
        "TransactionData(",
        "Action[] actions,",
        "TokenAmount[] inputs,",
        "Fee fee,",
        "AbsoluteTokenAmount[] requiredOutputs,",
        "uint256 nonce",
        ")"
    );
    bytes internal constant ABSOLUTE_TOKEN_AMOUNT_ENCODED_TYPE = abi.encodePacked(
        "AbsoluteTokenAmount(",
        "address token,",
        "uint256 amount",
        ")"
    );
    bytes internal constant ACTION_ENCODED_TYPE = abi.encodePacked(
        "Action(",
        "bytes32 protocolAdapterName,",
        "uint8 actionType,",
        "TokenAmount[] tokenAmounts,",
        "bytes data",
        ")"
    );
    bytes internal constant FEE_ENCODED_TYPE = abi.encodePacked(
        "Fee(",
        "uint256 share,",
        "address beneficiary",
        ")"
    );
    bytes internal constant TOKEN_AMOUNT_ENCODED_TYPE = abi.encodePacked(
        "TokenAmount(",
        "address token,",
        "uint256 amount,",
        "uint8 amountType",
        ")"
    );

    constructor(string memory name) public {
        domainSeparator_ = keccak256(
            abi.encode(
                DOMAIN_SEPARATOR_TYPEHASH,
                keccak256(abi.encodePacked(name)),
                address(this)
            )
        );
    }

    /**
     * @return Address of the Core contract used.
     */
    function nonce(
        address account
    )
        external
        view
        returns (uint256)
    {
        return nonce_[account];
    }

    function updateNonce(
        address account
    )
        internal
    {
        nonce_[account]++;
    }

    function getAccountFromSignature(
        TransactionData memory data,
        bytes memory signature
    )
        public
        view
        returns (address payable)
    {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(signature);

        bytes32 hashedData = keccak256(
            abi.encodePacked(
                bytes1(0x19),
                bytes1(0x01),
                domainSeparator_,
                hash(data)
            )
        );

        address signer = ecrecover(hashedData, v, r, s);

        require(signer != address(0), "SV: bad signature");
        require(nonce_[signer] == data.nonce, "SV: bad nonce");

        return payable(signer);
    }

    /// @return Hash to be signed by tokens supplier.
    function hash(
        TransactionData memory data
    )
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                TX_DATA_TYPEHASH,
                hash(data.actions),
                hash(data.inputs),
                hash(data.fee),
                hash(data.requiredOutputs),
                data.nonce
            )
        );
    }

    function hash(
        Action[] memory actions
    )
        internal
        pure
        returns (bytes32)
    {
        bytes memory actionsData = new bytes(0);

        uint256 length = actions.length;
        for (uint256 i = 0; i < length; i++) {
            actionsData = abi.encodePacked(
                actionsData,
                keccak256(
                    abi.encode(
                        ACTION_TYPEHASH,
                        actions[i].protocolAdapterName,
                        actions[i].actionType,
                        hash(actions[i].tokenAmounts),
                        keccak256(actions[i].data)
                    )
                )
            );
        }

        return keccak256(actionsData);
    }

    function hash(
        TokenAmount[] memory tokenAmounts
    )
        internal
        pure
        returns (bytes32)
    {
        bytes memory tokenAmountsData = new bytes(0);

        uint256 length = tokenAmounts.length;
        for (uint256 i = 0; i < length; i++) {
            tokenAmountsData = abi.encodePacked(
                tokenAmountsData,
                keccak256(
                    abi.encode(
                        TOKEN_AMOUNT_TYPEHASH,
                        tokenAmounts[i].token,
                        tokenAmounts[i].amount,
                        tokenAmounts[i].amountType
                    )
                )
            );
        }

        return keccak256(tokenAmountsData);
    }

    function hash(
        Fee memory fee
    )
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                FEE_TYPEHASH,
                fee.share,
                fee.beneficiary
            )
        );
    }

    function hash(
        AbsoluteTokenAmount[] memory absoluteTokenAmounts
    )
        internal
        pure
        returns (bytes32)
    {
        bytes memory absoluteTokenAmountsData = new bytes(0);

        uint256 length = absoluteTokenAmounts.length;
        for (uint256 i = 0; i < length; i++) {
            absoluteTokenAmountsData = abi.encodePacked(
                absoluteTokenAmountsData,
                keccak256(
                    abi.encode(
                        ABSOLUTE_TOKEN_AMOUNT_TYPEHASH,
                        absoluteTokenAmounts[i].token,
                        absoluteTokenAmounts[i].amount
                    )
                )
            );
        }

        return keccak256(absoluteTokenAmountsData);
    }

    function splitSignature(
        bytes memory signature
    )
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        require(signature.length == 65, "SV: bad signature");

        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(signature, 32))
            // second 32 bytes.
            s := mload(add(signature, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(signature, 96)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        // Reference: github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/cryptography/ECDSA.sol
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert("SV: bad 's'");
        }

        if (v != 27 && v != 28) {
            revert("SV: bad 'v'");
        }

        return (v, r, s);
    }
}
