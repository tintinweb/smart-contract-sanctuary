// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./IEIP712Verifier.sol";

/**
 * @title EIP712 typed signatures verifier for EAS delegated attestations.
 */
contract EIP712Verifier is IEIP712Verifier {
    string public constant VERSION = "0.6";

    // EIP712 domain separator, making signatures from different domains incompatible.
    bytes32 public immutable DOMAIN_SEPARATOR; // solhint-disable-line var-name-mixedcase

    // The hash of the data type used to relay calls to the attest function. It's the value of
    // keccak256("Attest(address recipient,bytes32 schema,uint256 expirationTime,bytes32 refUUID,bytes data,uint256 nonce)").
    bytes32 public constant ATTEST_TYPEHASH = 0x39c0608dd995a3a25bfecb0fffe6801a81bae611d94438af988caa522d9d1476;

    // The hash of the data type used to relay calls to the revoke function. It's the value of
    // keccak256("Revoke(bytes32 uuid,uint256 nonce)").
    bytes32 public constant REVOKE_TYPEHASH = 0xbae0931f3a99efd1b97c2f5b6b6e79d16418246b5055d64757e16de5ad11a8ab;

    // Replay protection nonces.
    mapping(address => uint256) private _nonces;

    /**
     * @dev Creates a new EIP712Verifier instance.
     */
    constructor() {
        uint256 chainId;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("EAS")),
                keccak256(bytes(VERSION)),
                chainId,
                address(this)
            )
        );
    }

    /**
     * @inheritdoc IEIP712Verifier
     */
    function getNonce(address account) external view override returns (uint256) {
        return _nonces[account];
    }

    /**
     * @inheritdoc IEIP712Verifier
     */
    function attest(
        address recipient,
        bytes32 schema,
        uint256 expirationTime,
        bytes32 refUUID,
        bytes calldata data,
        address attester,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        ATTEST_TYPEHASH,
                        recipient,
                        schema,
                        expirationTime,
                        refUUID,
                        keccak256(data),
                        _nonces[attester]++
                    )
                )
            )
        );

        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == attester, "ERR_INVALID_SIGNATURE");
    }

    /**
     * @inheritdoc IEIP712Verifier
     */
    function revoke(
        bytes32 uuid,
        address attester,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(REVOKE_TYPEHASH, uuid, _nonces[attester]++))
            )
        );

        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == attester, "ERR_INVALID_SIGNATURE");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/**
 * @title EIP712 typed signatures verifier for EAS delegated attestations interface.
 */
interface IEIP712Verifier {
    /**
     * @dev Returns the current nonce per-account.
     *
     * @param account The requested accunt.
     *
     * @return The current nonce.
     */
    function getNonce(address account) external view returns (uint256);

    /**
     * @dev Verifies signed attestation.
     *
     * @param recipient The recipient of the attestation.
     * @param schema The UUID of the AS.
     * @param expirationTime The expiration time of the attestation.
     * @param refUUID An optional related attestation's UUID.
     * @param data Additional custom data.
     * @param attester The attesting account.
     * @param v The recovery ID.
     * @param r The x-coordinate of the nonce R.
     * @param s The signature data.
     */
    function attest(
        address recipient,
        bytes32 schema,
        uint256 expirationTime,
        bytes32 refUUID,
        bytes calldata data,
        address attester,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Verifies signed revocations.
     *
     * @param uuid The UUID of the attestation to revoke.
     * @param attester The attesting account.
     * @param v The recovery ID.
     * @param r The x-coordinate of the nonce R.
     * @param s The signature data.
     */
    function revoke(
        bytes32 uuid,
        address attester,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

{
  "optimizer": {
    "enabled": true,
    "runs": 10000
  },
  "metadata": {
    "bytecodeHash": "none"
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}