// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
// solhint-disable var-name-mixedcase
pragma solidity ^0.8.4;

import "./SnarkConstants.sol";
import "./ErrorMsgs.sol";
import "./interfaces/IMintable.sol";
import "./interfaces/IRootsHistory.sol";
import "./eip712/Eip712Verifier.sol";
import "./proofVerifier/PubInputsHasher.sol";
import "./proofVerifier/ProofVerifier.sol";
import "./utils/DefaultOwnable.sol";
import "./utils/Utils.sol";

contract PreZkpMinter is
    DefaultOwnable,
    Eip712Verifier,
    PubInputsHasher,
    ProofVerifier,
    Utils
{
    enum State {
        notStarted,
        ongoing,
        finalized
    }

    event MinterState(State);
    event EndTimeUpdated(uint256 newMintingEnd);
    event Token(address preZkpAddress);
    event Minted(address to, uint256 amount);

    // EIP-712 stuff
    string public constant NAME = "PreZKP minter";
    // keccak256("Mint(address to,bytes32 nullifier,bytes32 root,uint32 treeId,bytes proof,uint256 deadline)"
    bytes32 private immutable _MINT_TYPEHASH =
        0xc9225a77dac2082adbcbee036bfee0139d97340cad7cfd8b61fa0c304ef44aa1;

    uint256 internal constant _ONE_TOKEN = 1e18;

    address public immutable DEFAULT_OWNER;

    address public immutable REGISTER;

    /// @notice Current state of minting campaign
    State public state;

    /// @notice Time when minting ends
    uint32 public mintingEnd;

    /// @notice Address of PreZkpToken contract
    address public preZkp;

    /// @dev mapping from nullifier to block number (when the former was seen)
    mapping(bytes32 => uint256) public isSeenNullifier;

    constructor(
        address defaultOwner,
        address verifier,
        address register,
        uint32 _mintingEnd
    ) Eip712Verifier(NAME, "1") ProofVerifier(verifier) {
        require(address(defaultOwner) != address(0), ERR_ZERO_OWNER);
        require(address(register) != address(0), ERR_ZERO_REGISTER);
        require(uint256(_mintingEnd) > timeNow(), ERR_MINT_ENDED);

        DEFAULT_OWNER = defaultOwner;
        REGISTER = register;
        mintingEnd = uint32(_mintingEnd);
    }

    function openMinting() external onlyOwner {
        require(
            state == State.notStarted && address(preZkp) != address(0),
            ERR_FAILED_MINT_START
        );
        _revertIfEnded();
        state = State.ongoing;
        emit MinterState(State.ongoing);
    }

    function setPreZkp(address _preZkp) external onlyOwner {
        require(
            preZkp == address(0) && address(_preZkp) != address(0),
            ERR_FAILED_PREZKP
        );
        preZkp = _preZkp;
        emit Token(_preZkp);
    }

    function updateMintingEnd(uint32 _mintingEnd) external onlyOwner {
        require(uint256(_mintingEnd) > timeNow(), ERR_FAILED_MINT_END);
        mintingEnd = _mintingEnd;
        emit EndTimeUpdated(uint256(_mintingEnd));
    }

    function mint(
        address to,
        bytes32 nullifier,
        bytes32 root,
        uint32 treeId,
        bytes calldata proof,
        uint256 deadline,
        bytes memory signature
    ) external {
        _revertIfEnded();
        _revertIfNotOpen();
        _revertIfExpired(deadline);

        // ensure nullifier not seen before
        require(isSeenNullifier[nullifier] == 0, ERR_SEEN_NULLIFIER);
        // register nullifier
        isSeenNullifier[nullifier] = block.number;

        // verify EIP-712 signature
        {
            bytes memory message = abi.encode(
                _MINT_TYPEHASH,
                to,
                nullifier,
                root,
                treeId,
                keccak256(proof),
                deadline
            );
            require(verifySignature(to, message, signature), ERR_INVALID_SIGN);
        }

        // check if the root is known
        require(
            IRootsHistory(REGISTER).isKnownRoot(treeId, root),
            ERR_UNKNOWN_ROOT
        );

        // compute public inputs hash
        uint256 pubInputsHash = hashPubInputs(to, treeId, nullifier, root);

        // verify zk-proof
        require(verifyProof(proof, pubInputsHash), ERR_INVALID_PROOF);

        // mint the token
        emit Minted(to, _ONE_TOKEN);
        IMintable(preZkp).mint(to, _ONE_TOKEN);
    }

    function _revertIfExpired(uint256 deadline) private view {
        require(deadline > timeNow(), ERR_EXPIRED_SIGN);
    }

    function _revertIfEnded() private view {
        require(timeNow() < uint256(mintingEnd), ERR_MINT_ENDED);
    }

    function _revertIfNotOpen() private view {
        require(state == State.ongoing, ERR_MINT_NOT_STARTED);
    }

    function _defaultOwner() internal view virtual override returns (address) {
        return DEFAULT_OWNER;
    }
}

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
// solhint-disable var-name-mixedcase
pragma solidity ^0.8.4;

// @dev Order of alt_bn128 and the field prime of Baby Jubjub and Poseidon hash
uint256 constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

// @dev Field prime of alt_bn128
uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.4;

// Shared between contracts
string constant ERR_ZERO_OWNER = "SH:EB"; // zero address of owner provided

// TriadIncrementalMerkleTrees contract
string constant ERR_ZERO_ROOT = "TT:E1"; // merkle tree root can not be zero
string constant ERR_CANT_DEL_ROOT = "TT:E2"; // failed to delete a root from history

// IdentityRegister contract
string constant ERR_DOUBLE_COMMIT = "IdentityReg: already registered";
string constant ERR_EMPTY_TRIADS = "IR:E1"; // input arrays must have at least one TRIAD
string constant ERR_EXPIRED_REG = "IdentityReg: registration closed";
string constant ERR_EXPIRED_REG_END = "IR:E3"; // provided registration end already expired
string constant ERR_FINALIZED_REG = "IdentityReg: already finalized";
string constant ERR_CANT_OPEN = "IR:E4"; // registration already opened or invalid input
string constant ERR_NOT_STARTED_REG = "IdentityReg: not started"; // registration not yet started
string constant ERR_ONGOING_REG = "IdentityReg: not yet finished";
string constant ERR_FAILED_REG_END = "IR:E6"; // invalid registration deadline provided
string constant ERR_TOO_LARGE_COMMITMENTS = "IR:E7"; // commitment exceeds maximum scalar field size
string constant ERR_UNEVEN_TRIAD = "IR:E8"; // input array length must be multiple of TRIAD_SIZE
string constant ERR_UNMATCHED_ARRAYS = "IR:E9"; // input arrays have different length
string constant ERR_ZERO_KYC_ID = "IR:EA"; // kycId can't be zero

// PreZkpMinter contract
string constant ERR_ZERO_REGISTER = "PM:02"; // zero address of register provided
string constant ERR_MINT_ENDED = "PZMinter: minting period ended";
string constant ERR_MINT_NOT_STARTED = "PZMinter: minting not started";
string constant ERR_FAILED_MINT_START = "PM:05"; // invalid openMinting input
string constant ERR_FAILED_PREZKP = "PM:06"; // invalid setPreZkp input
string constant ERR_FAILED_MINT_END = "PM:07"; // invalid updateMintingEnd input
string constant ERR_INVALID_SIGN = "PZMinter: invalid signature";
string constant ERR_EXPIRED_SIGN = "PZMinter: signature expired";
string constant ERR_INVALID_PROOF = "PZMinter: invalid proof";
string constant ERR_SEEN_NULLIFIER = "PZMinter: seen nullifier";
string constant ERR_UNKNOWN_ROOT = "PZMinter: unknown root";

// ProofVerifier contract
string constant ERR_INVALID_PROOF_ELEMENT = "PZMinter: invalid proof (gte Q)";
string constant ERR_INVALID_PROOF_INPUT = "PZMinter: invalid proof (input)";
string constant ERR_INVALID_PROOF_SIZE = "PZMinter: invalid proof (size)";
string constant ERR_INVALID_PUBINPUTS = "PZMinter: invalid pub inputs";
string constant ERR_ZERO_VERIFIER = "PM:01"; // zero address of verifier provided

// PubInputsHasher contract
string constant ERR_LARGE_NULLIFIER = "PZMinter: nullifier gte SnarkField";
string constant ERR_LARGE_ROOT = "PZMinter: root gte SnarkField";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IMintable {
    function mint(address to, uint256 value) external;
}

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.4;

interface IRootsHistory {
    /// @notice Returns `true` if the given root of the given tree is known
    function isKnownRoot(uint256 treeId, bytes32 root)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: OpenZeppelin Community <[email protected]>
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
// solhint-disable var-name-mixedcase
pragma solidity >=0.8.4;

/**
 * @title Eip712Verifier
 * @notice Functions for signatures verification
 */
contract Eip712Verifier {
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    // Source: openzeppelin/contracts/cryptography/draft-EIP712.sol
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(
            typeHash,
            hashedName,
            hashedVersion
        );
        _TYPE_HASH = typeHash;
    }

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    function verifySignature(
        address signatory,
        bytes memory message,
        bytes memory signature
    ) public view returns (bool success) {
        _revertZeroSignatory(signatory);
        bytes32 msgHash = keccak256(message);
        bytes32 typedMsgHash = keccak256(
            abi.encodePacked("\x19\x01", _domainSeparatorV4(), msgHash)
        );
        return signatory == tryRecover(typedMsgHash, signature);
    }

    // Based on openzeppelin/contracts/cryptography/ECDSA.sol
    function tryRecover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        // Get signature params
        bytes32 r;
        bytes32 s;
        uint8 v;
        bytes32 vs;
        if (signature.length == 65) {
            // r,s,v signature (standard)
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (signature.length == 64) {
            // r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098)
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
                s := and(
                    vs,
                    0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
                )
                v := add(shr(255, vs), 27)
            }
        } else {
            revert("ECDSA: invalid signature length");
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            revert("ECDSA: invalid signature 's' value");
        }
        if (v != 27 && v != 28) {
            revert("ECDSA: invalid signature 'v' value");
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            revert("ECDSA: invalid signature");
        }

        return signer;
    }

    // Source: openzeppelin/contracts/cryptography/draft-EIP712.sol
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return
                _buildDomainSeparator(
                    _TYPE_HASH,
                    _HASHED_NAME,
                    _HASHED_VERSION
                );
        }
    }

    // Source: openzeppelin/contracts/cryptography/draft-EIP712.sol
    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    typeHash,
                    nameHash,
                    versionHash,
                    block.chainid,
                    address(this)
                )
            );
    }

    function _revertZeroSignatory(address signatory) private pure {
        require(signatory != address(0), "ECDSA: zero signatory address");
    }
}

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
// solhint-disable var-name-mixedcase
pragma solidity ^0.8.4;

import "../ErrorMsgs.sol";
import "../SnarkConstants.sol";

contract PubInputsHasher {
    // bytes4(keccak256('PreZkp'))
    uint256 public constant EXTERNAL_NULLIFIER = 0x4da08cc7;

    function hashPubInputs(
        address to,
        uint32 treeId,
        bytes32 nullifier,
        bytes32 root
    ) public pure returns (uint256) {
        require(uint256(nullifier) < SNARK_SCALAR_FIELD, ERR_LARGE_NULLIFIER);
        require(uint256(root) < SNARK_SCALAR_FIELD, ERR_LARGE_ROOT);
        // `to` and `treeId` are too small to exceed SNARK_SCALAR_FIELD

        uint256 externalAndTree = (EXTERNAL_NULLIFIER << 32) | uint256(treeId);
        // packedData is too small to exceed SNARK_SCALAR_FIELD
        uint256 packedData = (externalAndTree << 160) | uint256(uint160(to));

        return
            uint256(sha256(abi.encode(packedData, nullifier, root))) %
            SNARK_SCALAR_FIELD;
    }
}

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
// solhint-disable var-name-mixedcase
pragma solidity ^0.8.4;

import "../ErrorMsgs.sol";
import "../SnarkConstants.sol";
import "../interfaces/IVerifier.sol";

contract ProofVerifier {
    address public immutable VERIFIER;

    constructor(address verifier) {
        require(address(verifier) != address(0), ERR_ZERO_VERIFIER);
        VERIFIER = verifier;
    }

    function verifyProof(bytes calldata proof, uint256 pubInputHash)
        public
        view
        returns (bool)
    {
        (
            uint256[2] memory a,
            uint256[2][2] memory b,
            uint256[2] memory c,
            uint256[1] memory input
        ) = unpackSanitizeProof(proof);

        // check public inputs
        require(input[0] == pubInputHash, ERR_INVALID_PUBINPUTS);

        // verify proof with snarkjs verifier
        return IVerifier(VERIFIER).verifyProof(a, b, c, input);
    }

    function unpackSanitizeProof(bytes calldata proof)
        public
        pure
        returns (
            uint256[2] memory a,
            uint256[2][2] memory b,
            uint256[2] memory c,
            uint256[1] memory input
        )
    {
        require(proof.length == 288, ERR_INVALID_PROOF_SIZE);
        uint256[9] memory p = abi.decode(proof, (uint256[9]));

        for (uint8 i = 0; i < 8; i++) {
            require(p[i] < PRIME_Q, ERR_INVALID_PROOF_ELEMENT);
        }
        require(p[8] < SNARK_SCALAR_FIELD, ERR_INVALID_PROOF_INPUT);

        a = [p[0], p[1]];
        b = [[p[2], p[3]], [p[4], p[5]]];
        c = [p[6], p[7]];
        input = [p[8]];
    }
}

// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.4;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * Inspired and borrowed by/from the openzeppelin/contracts` {Ownable}.
 * Unlike openzeppelin` version:
 * - by default, the owner account is the one returned by the {_defaultOwner}
 * function, but not the deployer address;
 * - this contract has no constructor and may run w/o initialization;
 * - the {renounceOwnership} function removed.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 * The child contract must define the {_defaultOwner} function.
 */
abstract contract DefaultOwnable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @dev Returns the current owner address, if it's defined, or the default owner address otherwise.
    function owner() public view virtual returns (address) {
        return _owner == address(0) ? _defaultOwner() : _owner;
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /// @dev Transfers ownership of the contract to the `newOwner`. The owner can only call.
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    function _defaultOwner() internal view virtual returns (address);
}

// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.4;

contract Utils {
    /// @dev Returns the current block timestamp (added to ease testing)
    function timeNow() internal view virtual returns (uint256) {
        return block.timestamp;
    }
}

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.4;

interface IVerifier {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[1] memory input
    ) external view returns (bool);
}