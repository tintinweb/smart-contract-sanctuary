// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract LibEIP712 {
    uint256 public chainId;
    address verifyingContract = address(this);

    // EIP191 header for EIP712 prefix
    //string constant internal EIP191_HEADER = "\x19\x01";

    // EIP712 Domain Name value
    string internal constant EIP712_DOMAIN_NAME = "DeCus";

    // EIP712 Domain Version value
    string internal constant EIP712_DOMAIN_VERSION = "1.0";

    // Hash of the EIP712 Domain Separator Schema
    bytes32 internal constant EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH =
        keccak256(
            abi.encodePacked(
                "EIP712Domain(",
                "string name,",
                "string version,",
                "uint256 chainId,",
                "address verifyingContract",
                ")"
            )
        );

    // Hash of the EIP712 Domain Separator data
    // solhint-disable-next-line var-name-mixedcase
    bytes32 public EIP712_DOMAIN_HASH;

    constructor() public {
        uint256 id;
        assembly {
            id := chainid()
        }
        chainId = id;

        EIP712_DOMAIN_HASH = keccak256(
            abi.encode(
                EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH,
                keccak256(bytes(EIP712_DOMAIN_NAME)),
                keccak256(bytes(EIP712_DOMAIN_VERSION)),
                chainId,
                verifyingContract
            )
        );
    }

    function hashEIP712Message(bytes32 hashStruct) internal view returns (bytes32 result) {
        bytes32 eip712DomainHash = EIP712_DOMAIN_HASH;

        // Assembly for more efficient computing:
        // keccak256(abi.encodePacked(
        //     EIP191_HEADER,
        //     EIP712_DOMAIN_HASH,
        //     hashStruct
        // ));

        assembly {
            // Load free memory pointer
            let memPtr := mload(64)

            mstore(memPtr, 0x1901000000000000000000000000000000000000000000000000000000000000) // EIP191 header
            mstore(add(memPtr, 2), eip712DomainHash) // EIP712 domain hash
            mstore(add(memPtr, 34), hashStruct) // Hash of struct

            // Compute hash
            result := keccak256(memPtr, 66)
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./LibEIP712.sol";

contract LibRequest is LibEIP712 {
    string private constant ORDER_TYPE =
        "MintRequest(address recipient,uint256 nonce,uint256 amount)";
    bytes32 private constant ORDER_TYPEHASH = keccak256(abi.encodePacked(ORDER_TYPE));

    // solhint-disable max-line-length
    struct MintRequest {
        address recipient; // Address that created the request.
        uint256 nonce; // Arbitrary number to facilitate uniqueness of the request's hash.
        uint256 amount;
    }

    function getMintRequestHash(
        address recipient,
        uint256 nonce,
        uint256 amount
    ) internal view returns (bytes32 requestHash) {
        MintRequest memory request =
            MintRequest({recipient: recipient, nonce: nonce, amount: amount});
        requestHash = hashEIP712Message(hashMintRequest(request));
        return requestHash;
    }

    function hashMintRequest(MintRequest memory request) private pure returns (bytes32 result) {
        return
            keccak256(abi.encode(ORDER_TYPEHASH, request.recipient, request.nonce, request.amount));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./LibRequest.sol";

contract SignatureValidator is LibRequest {
    mapping(address => uint256) public lastNonces;

    function recoverSigner(
        bytes32 message,
        uint8 packedV,
        bytes32 r,
        bytes32 s
    ) public pure returns (address) {
        return ecrecover(message, packedV, r, s);
    }

    function batchValidate(
        address recipient,
        uint256 amount,
        address[] calldata keepers,
        uint256[] calldata nonces,
        bytes32[] calldata r,
        bytes32[] calldata s,
        uint256 packedV
    ) external {
        for (uint256 i = 0; i < keepers.length; i++) {
            require(lastNonces[keepers[i]] < nonces[i], "nonce outdated");
            require(
                recoverSigner(
                    getMintRequestHash(recipient, nonces[i], amount),
                    uint8(packedV), // the lowest byte of packedV
                    r[i],
                    s[i]
                ) == keepers[i],
                "invalid signature"
            );
            lastNonces[keepers[i]] = nonces[i];

            packedV >>= 8;
        }
    }
}