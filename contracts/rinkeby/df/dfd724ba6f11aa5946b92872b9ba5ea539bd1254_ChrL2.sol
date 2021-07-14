// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;
import "./ERC20.sol";

contract ChrL2 {

    bytes32 constant L2_EVENT_KEY = 0x1F1831C339CD7E1195B64253AF6691E58A43D402BE48D0834BBD1869A9C9C935;

    bytes32 constant L2_STATE_KEY = 0x04A48CDA5CE81FF2A97A9E2C0F521C2853258D6DDBA62190D3F0A2523B09C4B0;

    mapping (address => mapping(ERC20 => uint256)) private _balances;
    mapping (ERC20 => Withdraw) public _withdraw;

    struct Event {
        ERC20 token;
        address beneficiary;
        uint256 amount;
    }

    struct BlockHeaderData {
        bytes32 blockchainRid;
        bytes32 blockRid;
        bytes32 previousBlockRid;
        bytes32 merkleRootHashHashedLeaf;
        uint timestamp;
        uint height;
        bytes32 dependeciesHashedLeaf;
        bytes32 l2RootEvent;
        bytes32 l2RootState;
    }

    struct Withdraw {
        address beneficiary;
        uint256 amount;
        uint256 block_number;
        bool isWithdraw;
    }

    event Deposited(address indexed owner, ERC20 indexed token, uint256 value);
    event WithdrawRequest(address indexed beneficiary, ERC20 indexed token, uint256 value);
    event Withdrawal(address indexed beneficiary, ERC20 indexed token, uint256 value);

    function deposit(ERC20 token, uint256 amount) public returns (bool) {
        token.transferFrom(msg.sender, address(this), amount);
        _balances[msg.sender][token] += amount;
        emit Deposited(msg.sender, token, amount);
        return true;
    }

    function withdraw_request(bytes calldata _event, bytes32 _hash,
        bytes calldata blockHeader,
        bytes[] calldata sigs, address[] calldata signers,
        bytes32[] calldata merkleProofs, uint position) public {

        _verify(_hash, blockHeader, sigs, signers, merkleProofs, position);
        (ERC20 token, address beneficiary, uint256 amount) = verifyEventHash(_event, _hash);
        Withdraw storage wd = _withdraw[token];
        wd.beneficiary = beneficiary;
        wd.amount += amount;
        wd.block_number = block.number + 50;
        wd.isWithdraw = false;
        _withdraw[token] = wd;
        emit WithdrawRequest(beneficiary, token, amount);
    }

    function _verify(bytes32 _hash,
        bytes calldata blockHeader,
        bytes[] calldata sigs, address[] calldata signers,
        bytes32[] calldata merkleProofs, uint position) internal pure {

        (bytes32 blockRid, bytes32 eventRoot, ) = verifyBlockHeader(blockHeader);
        if (!verifyBlockSig(blockRid, sigs, signers)) revert("block signature is invalid");
        if (!verifyMerkleProof(merkleProofs, _hash, position, eventRoot)) revert("invalid event merkle proof");
    }

    function withdraw(ERC20 token, address payable beneficiary) public returns (bool) {
        Withdraw storage wd = _withdraw[token];
        if (!wd.isWithdraw && wd.amount > 0 && block.number >= wd.block_number) {
            wd.isWithdraw = true;
            uint value = wd.amount;
            wd.amount = 0;
            token.transfer(beneficiary, value);
            emit Withdrawal(beneficiary, token, value);
            return true;
        }
        return false;
    }

    function hashGtvIntegerLeaf(uint value) public pure returns (bytes32) {
        uint8 nbytes = 1;
        uint remainingValue = value >> 8; // minimal length is 1 so we skip the first byte
        while (remainingValue > 0) {
            nbytes += 1;
            remainingValue = remainingValue >> 8;
        }
        bytes memory b = new bytes(nbytes);
        remainingValue = value;
        for (uint8 i = 1; i <= nbytes; i++) {
            uint8 v = uint8(remainingValue & 0xFF);
            b[nbytes - i] = byte(v);
            remainingValue = remainingValue >> 8;
        }

        return sha256(abi.encodePacked(
                uint8(0x1),  // Gtv merkle tree leaf prefix
                uint8(0xA3), // GtvInteger tag: CONTEXT_CLASS, CONSTRUCTED, 3
                uint8(nbytes + 2),
                uint8(0x2), // DER integer tag
                nbytes,
                b
            ));
    }

    function hashGtvBytes32Leaf(bytes32 value) public pure returns (bytes32) {
        return sha256(abi.encodePacked(
                uint8(0x1),  // Gtv merkle tree leaf prefix
                uint8(0xA1), // // Gtv ByteArray tag: CONTEXT_CLASS, CONSTRUCTED, 1
                uint8(32 + 2),
                uint8(0x4), // DER ByteArray tag
                uint8(32),
                value
            ));
    }

    function hashGtvBytes64Leaf(bytes calldata value) public pure returns (bytes32) {
        return sha256(abi.encodePacked(
                uint8(0x1),  // Gtv merkle tree leaf prefix
                uint8(0xA1), // // Gtv ByteArray tag: CONTEXT_CLASS, CONSTRUCTED, 1
                uint8(64 + 2),
                uint8(0x4), // DER ByteArray tag
                uint8(64),
                value
            ));
    }

    function verifyBlockHeader(bytes calldata blockHeader) public pure returns (bytes32, bytes32, bytes32) {

        BlockHeaderData memory header = abi.decode(blockHeader, (BlockHeaderData));

        bytes32 node12 = sha256(abi.encodePacked(
                uint8(0x00),
                hashGtvBytes32Leaf(header.blockchainRid),
                hashGtvBytes32Leaf(header.previousBlockRid)
            ));

        bytes32 node34 = sha256(abi.encodePacked(
                uint8(0x00),
                header.merkleRootHashHashedLeaf,
                hashGtvIntegerLeaf(header.timestamp)
            ));

        bytes32 node56 = sha256(abi.encodePacked(
                uint8(0x00),
                hashGtvIntegerLeaf(header.height),
                header.dependeciesHashedLeaf
            ));

        bytes32 l2event = sha256(abi.encodePacked(
                uint8(0x00),
                L2_EVENT_KEY,
                hashGtvBytes32Leaf(header.l2RootEvent)
            ));

        bytes32 l2state = sha256(abi.encodePacked(
                uint8(0x00),
                L2_STATE_KEY,
                hashGtvBytes32Leaf(header.l2RootState)
            ));

        bytes32 node78 = sha256(abi.encodePacked(
                uint8(0x8), // Gtv merkle tree dict prefix
                l2event,
                l2state
            ));

        bytes32 node1234 = sha256(abi.encodePacked(
                uint8(0x00),
                node12,
                node34
            ));

        bytes32 node5678 = sha256(abi.encodePacked(
                uint8(0x00),
                node56,
                node78
            ));

        bytes32 blockRid = sha256(abi.encodePacked(
                uint8(0x7), // Gtv merkle tree Array Root Node prefix
                node1234,
                node5678
            ));

        if (blockRid != header.blockRid) revert("invalid block header");
        return (blockRid, header.l2RootEvent, header.l2RootState);
    }

    function verifyBlockSig(bytes32 message, bytes[] calldata sigs, address[] calldata signers) public pure returns (bool) {

        if (sigs.length != signers.length) {
            return false;
        }
        for (uint i = 0; i < sigs.length; i++) {
            // Check the signature (r, s, v) length
            if (sigs[i].length != 65) {
                return false;
            }

            if (recover(message, sigs[i]) != signers[i]) {
                return false;
            }
        }

        return true;
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) public pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) public pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        // require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    function verifyEventHash(bytes calldata _event, bytes32 _hash) public pure returns (ERC20, address, uint256) {
        Event memory evt = abi.decode(_event, (Event));
        bytes32 hash = keccak256(_event);
        if (hash != _hash) {
            revert('invalid event');
        }
        return (evt.token, evt.beneficiary, evt.amount);
    }

    /**
     * @dev verify merkle proof
     */
    function verifyMerkleProof(bytes32[] calldata proofs, bytes32 leaf, uint position, bytes32 root) public pure returns (bool) {
        bytes32 r = leaf;
        for (uint i = 0; i < proofs.length; i++) {
            uint b = position & (1 << i);
            if (b == 0) {
                r = sha3Hash(r, proofs[i]);
            } else {
                r = sha3Hash(proofs[i], r);
            }
        }
        return (r == root);
    }

    function sha3Hash(bytes32 left, bytes32 right) public pure returns (bytes32) {
        if (left == 0x0 && right == 0x0) {
            return 0x0;
        } else if (left == 0x0) {
            return keccak256(abi.encodePacked(right));
        } else if (right == 0x0) {
            return keccak256(abi.encodePacked(left));
        } else {
            return keccak256(abi.encodePacked(left, right));
        }
    }
}