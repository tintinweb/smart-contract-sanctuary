// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.6.0 <=0.8.7;
pragma experimental ABIEncoderV2;

import "./Postchain.sol";

contract ChrL2 {
    using Postchain for bytes32;
    using MerkleProof for bytes32[];

    mapping(ERC20 => uint256) public _balances;
    mapping (bytes32 => Withdraw) public _withdraw;
    address[] public directoryNodes;
    address[] public appNodes;

    // Each postchain event will be used to claim only one time.
    mapping (bytes32 => bool) private _events;

    struct Withdraw {
        ERC20 token;
        address beneficiary;
        uint256 amount;
        uint256 block_number;
        bool isWithdraw;
    }

    event Deposited(address indexed owner, ERC20 indexed token, uint256 value);
    event WithdrawRequest(address indexed beneficiary, ERC20 indexed token, uint256 value);
    event Withdrawal(address indexed beneficiary, ERC20 indexed token, uint256 value);

    constructor(address[] memory _directoryNodes, address[] memory _appNodes) {
        directoryNodes = _directoryNodes;
        appNodes = _appNodes;
    }

    function updateDirectoryNodes(bytes32 hash, bytes[] memory sigs, address[] memory _directoryNodes) public returns (bool) {
        if (!hash.isValidNodes(_directoryNodes)) revert("ChrL2: invalid directory node");
        if (!hash.isValidSignatures(sigs, directoryNodes)) revert("ChrL2: not enough require signature");
        for (uint i = 0; i < directoryNodes.length; i++) {
            directoryNodes.pop();
        }
        directoryNodes = _directoryNodes;
        return true;
    }

    function updateAppNodes(bytes32 hash, bytes[] memory sigs, address[] memory _appNodes) public returns (bool) {
        if (!hash.isValidNodes(_appNodes)) revert("ChrL2: invalid app node");
        if (!hash.isValidSignatures(sigs, directoryNodes)) revert("ChrL2: not enough require signature");
        for (uint i = 0; i < appNodes.length; i++) {
            appNodes.pop();
        }
        appNodes = _appNodes;
        return true;
    }

    function deposit(ERC20 token, uint256 amount) public returns (bool) {
        token.transferFrom(msg.sender, address(this), amount);
        _balances[token] += amount;
        emit Deposited(msg.sender, token, amount);
        return true;
    }

    function withdraw_request(
        bytes memory _event,
        // Data.EventProof memory eventProof,
        bytes memory eventProof,
        bytes memory blockHeader,
        bytes[] memory sigs,
        bytes memory el2Leaf,
        // Data.EL2ProofData memory el2Proof
        bytes memory el2Proof
    ) public {
        Data.EventProof memory eventProofData = abi.decode(eventProof, (Data.EventProof));
        {
            require(_events[eventProofData.leaf] == false, "ChrL2: event hash was already used");
            (bytes32 blockRid, bytes32 eventRoot, ) = Postchain.verifyBlockHeader(blockHeader, el2Leaf, el2Proof);
            if (!Postchain.isValidSignatures(blockRid, sigs, appNodes)) revert("ChrL2: block signature is invalid");
            if (!MerkleProof.verify(eventProofData.merkleProofs, eventProofData.leaf, eventProofData.position, eventRoot)) revert("ChrL2: invalid merkle proof");
        }
        _events[eventProofData.leaf] = _updateWithdraw(eventProofData.leaf, _event); // mark the event hash was already used.
    }

    function _updateWithdraw(bytes32 hash, bytes memory _event) internal returns (bool) {
        Withdraw storage wd = _withdraw[hash];
        {
            (ERC20 token, address beneficiary, uint256 amount) = hash.verifyEvent(_event);
            require(amount > 0 && amount <= _balances[token], "ChrL2: invalid amount to make request withdraw");
            wd.token = token;
            wd.beneficiary = beneficiary;
            wd.amount += amount;
            wd.block_number = block.number + 50;
            wd.isWithdraw = false;
            _withdraw[hash] = wd;
            emit WithdrawRequest(beneficiary, token, amount);
        }
        return true;
    }

    function withdraw(bytes32 _hash, address payable beneficiary) public {
        Withdraw storage wd = _withdraw[_hash];
        require(wd.beneficiary == beneficiary, "ChrL2: no fund for the beneficiary");
        require(wd.block_number <= block.number, "ChrL2: not mature enough to withdraw the fund");
        require(wd.isWithdraw == false, "ChrL2: fund was already claimed");
        require(wd.amount > 0 && wd.amount <= _balances[wd.token], "ChrL2: not enough amount to withdraw");
        wd.isWithdraw = true;
        uint value = wd.amount;
        wd.amount = 0;
        _balances[wd.token] -= value;
        wd.token.transfer(beneficiary, value);
        emit Withdrawal(beneficiary, wd.token, value);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.6.0 <=0.8.7;
pragma experimental ABIEncoderV2;

import "./utils/cryptography/Hash.sol";
import "./utils/cryptography/ECDSA.sol";
import "./utils/cryptography/MerkleProof.sol";
import "./token/ERC20.sol";
import "./Data.sol";

library Postchain {
    using EC for bytes32;
    using MerkleProof for bytes32[];

    struct Event {
        uint256 serialNumber;
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
        bytes32 dependenciesHashedLeaf;
        bytes32 extraDataHashedLeaf;
    }

    function isValidNodes(bytes32 hash, address[] memory nodes) public pure returns (bool) {
        uint len = _upperPowerOfTwo(nodes.length);
        bytes32[] memory _nodes = new bytes32[](len);
        for (uint i = 0; i < nodes.length; i++) {
            _nodes[i] = keccak256(abi.encodePacked(nodes[i]));
        }
        for (uint i = nodes.length; i < len; i++) {
            _nodes[i] = 0x0;
        }
        return _nodes.root() == hash;
    }

    function isValidSignatures(bytes32 hash, bytes[] memory signatures, address[] memory signers) public pure returns (bool) {
        uint _actualSignature = 0;
        uint _requiredSignature = _calculateBFTRequiredNum(signers.length);
        for (uint i = 0; i < signatures.length; i++) {
            for (uint k = 0; k < signers.length; k++) {
                if (_isValidSignature(hash, signatures[i], signers[k])) {
                    _actualSignature++;
                    break;
                }
            }
        }
        return (_actualSignature >= _requiredSignature);
    }

    function verifyEvent(bytes32 _hash, bytes memory _event) public pure returns (ERC20, address, uint256) {
        Event memory evt = abi.decode(_event, (Event));
        bytes32 hash = keccak256(_event);
        if (hash != _hash) {
            revert('Postchain: invalid event');
        }
        return (evt.token, evt.beneficiary, evt.amount);
    }

    function verifyBlockHeader(
        bytes memory blockHeader,
        bytes memory el2Leaf,
        // Data.EL2ProofData memory proof
        bytes memory proof
    ) public pure returns (bytes32, bytes32, bytes32) {

        bytes32 blockRid = _decodeBlockHeader(blockHeader);
        Data.EL2ProofData memory proofData = abi.decode(proof, (Data.EL2ProofData));
        if (!proofData.extraMerkleProofs.verifySHA256(proofData.leaf, proofData.el2Position, proofData.extraRoot)) {
            revert("Postchain: invalid el2 extra data");
        }
        return (blockRid, _bytesToBytes32(el2Leaf, 0), _bytesToBytes32(el2Leaf, 32));
    }

    function _decodeBlockHeader(
        bytes memory blockHeader
    ) internal pure returns (bytes32) {
        BlockHeaderData memory header = abi.decode(blockHeader, (BlockHeaderData));

        bytes32 node12 = sha256(abi.encodePacked(
                uint8(0x00),
                Hash.hashGtvBytes32Leaf(header.blockchainRid),
                Hash.hashGtvBytes32Leaf(header.previousBlockRid)
            ));

        bytes32 node34 = sha256(abi.encodePacked(
                uint8(0x00),
                header.merkleRootHashHashedLeaf,
                Hash.hashGtvIntegerLeaf(header.timestamp)
            ));

        bytes32 node56 = sha256(abi.encodePacked(
                uint8(0x00),
                Hash.hashGtvIntegerLeaf(header.height),
                header.dependenciesHashedLeaf
            ));

        bytes32 node1234 = sha256(abi.encodePacked(
                uint8(0x00),
                node12,
                node34
            ));

        bytes32 node5678 = sha256(abi.encodePacked(
                uint8(0x00),
                node56,
                header.extraDataHashedLeaf
            ));

        bytes32 blockRid = sha256(abi.encodePacked(
                uint8(0x7), // Gtv merkle tree Array Root Node prefix
                node1234,
                node5678
            ));

        if (blockRid != header.blockRid) revert("Postchain: invalid block header");
        return blockRid;
    }

    function _calculateBFTRequiredNum(uint total) internal pure returns (uint) {
        if (total == 0) return 0;
        return (total - (total - 1) / 3);
    }

    function _isValidSignature(bytes32 hash, bytes memory signature, address signer) internal pure returns (bool) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedProof = keccak256(abi.encodePacked(prefix, hash));
        return (prefixedProof.recover(signature) == signer || hash.recover(signature) == signer);
    }

   function _upperPowerOfTwo(uint x) internal pure returns (uint) {
        uint p = 1;
        while (p < x) p <<= 1;
        return p;
    }

    function _bytesToBytes32(bytes memory b, uint offset) internal pure returns (bytes32) {
        bytes32 out;

        for (uint i = 0; i < 32; i++) {
            out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.6.0 <=0.8.7;

library Hash {

    function hash(bytes32 left, bytes32 right) public pure returns (bytes32) {
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
            b[nbytes - i] = bytes1(v);
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
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.6.0 <=0.8.7;

library EC {
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

        return _ecrecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function _ecrecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
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
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.6.0 <=0.8.7;

import "./Hash.sol";

library MerkleProof {
    /**
     * @dev verify merkle proof using keccak256
     */
    function verify(bytes32[] calldata proofs, bytes32 leaf, uint position, bytes32 rootHash) public pure returns (bool) {
        bytes32 r = leaf;
        for (uint i = 0; i < proofs.length; i++) {
            uint b = position & (1 << i);
            if (b == 0) {
                r = Hash.hash(r, proofs[i]);
            } else {
                r = Hash.hash(proofs[i], r);
            }
        }
        return (r == rootHash);
    }

    /**
     * @dev verify merkle proof using sha256
     */
    function verifySHA256(bytes32[] calldata proofs, bytes32 leaf, uint position, bytes32 rootHash) public pure returns (bool) {
        bytes32 r = leaf;
        for (uint i = 0; i < proofs.length; i++) {
            uint b = position & (1 << i);
            if (b == 0) {
                r = sha256(abi.encodePacked(r, proofs[i]));
            } else {
                r = sha256(abi.encodePacked(proofs[i], r));
            }
        }
        return (r == rootHash);
    }
    
    function root(bytes32[] memory nodes) public pure returns (bytes32) {
        if (nodes.length == 1) return nodes[0];
        uint len = nodes.length/2;
        bytes32[] memory _nodes = new bytes32[](len);
        for (uint i = 0; i < len; i++) {
            _nodes[i] = Hash.hash(nodes[i*2], nodes[i*2+1]);
        }
        return root(_nodes);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.6.0 <=0.8.7;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface ERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view returns (uint8);
    
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.6.0 <=0.8.7;
pragma experimental ABIEncoderV2;

library Data {
    struct EL2ProofData {
        bytes32 leaf;
        uint el2Position;
        bytes32 extraRoot;
        bytes32[] extraMerkleProofs;
    }

    struct EventProof {
        bytes32 leaf;
        uint position;
        bytes32[] merkleProofs;
    }
}