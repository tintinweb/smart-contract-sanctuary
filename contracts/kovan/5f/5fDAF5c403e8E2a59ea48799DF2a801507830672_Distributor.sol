// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.10;

import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import './interfaces/IDistributor.sol';
import './interfaces/vaults/IVault.sol';

contract Distributor is IDistributor {
    address public override owner;
    bool public override paused;

    mapping(uint256 => bytes) public vaultBytecodes;

    uint256 public override lastDistributionId;
    mapping(uint256 => Distribution) _distributions;

    mapping(uint256 => mapping(uint256 => uint256)) private _claimedBitMap; // distribution id => max (2**256 - 1) * 256

    bool private _unlocked = true;
    modifier lock() {
        require(_unlocked, 'D_LOCK');
        _unlocked = false;
        _;
        _unlocked = true;
    }

    constructor() {
        owner = msg.sender;
        emit OwnerSet(msg.sender);
    }

    function setOwner(address _owner) external override {
        require(msg.sender == owner, 'D_OWNER_ONLY');
        require(_owner != owner, 'D_ALREADY_SET');
        require(_owner != address(0), 'D_ADDRESS_ZERO');
        owner = _owner;

        emit OwnerSet(_owner);
    }

    function setPaused(bool _paused) external override {
        require(msg.sender == owner, 'D_OWNER_ONLY');
        require(paused != _paused, 'D_ALREADY_SET');
        paused = _paused;

        emit PausedSet(_paused);
    }

    function setVaultBytescode(uint256 vaultBytecodeId, bytes calldata bytecode) external {
        require(msg.sender == owner, 'D_OWNER_ONLY');
        require(vaultBytecodeId > 0, 'D_INVALID_VAULT_ID');
        vaultBytecodes[vaultBytecodeId] = bytecode;

        emit VaultBytescodeSet(vaultBytecodeId, bytecode.length);
    }

    function vaultBytescode(uint256 vaultBytecodeId) external view override returns (bytes memory) {
        require(vaultBytecodeId > 0, 'D_INVALID_VAULT_ID');
        return vaultBytecodes[vaultBytecodeId];
    }

    function create(
        uint256 vaultBytecodeId,
        bytes calldata initializeData,
        address admin,
        bytes32 merkleRoot,
        uint256 expirationBlock
    ) external override lock {
        require(!paused, 'D_PAUSED');
        require(admin != address(0), 'D_ADDRESS_ZERO');
        require(merkleRoot != bytes32(0), 'D_INVALID_MERKLE_ROOT');
        require(expirationBlock > block.number, 'D_EXPIRATION_NOT_FUTURE');
        lastDistributionId++;
        uint256 distributionId = lastDistributionId;
        address vault;
        bytes memory bytecode = vaultBytecodes[vaultBytecodeId];
        require(bytecode.length > 0, 'D_INVALID_BYTECODE');
        bytes32 salt = keccak256(abi.encodePacked(vaultBytecodeId, distributionId));
        assembly {
            vault := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IVault(vault).initialize(initializeData);

        _distributions[lastDistributionId] = Distribution(distributionId, admin, vault, merkleRoot, 0, expirationBlock);

        emit Created(distributionId);
        emit AdminSet(distributionId, admin);
    }

    function distribution(uint256 distributionId) external view override returns (Distribution memory) {
        require(distributionId > 0 && distributionId <= lastDistributionId, 'D_INVALID_DISTRIBUTION');
        return _distributions[lastDistributionId];
    }

    function claim(ClaimParams calldata params) external override lock {
        require(!paused, 'D_PAUSED');
        (bool success, bytes memory result) = address(this).call(
            abi.encodeWithSelector(this._claim.selector, params, msg.sender)
        );
        if (!success) {
            assembly {
                result := add(result, 0x04)
            }
            revert(abi.decode(result, (string)));
        }
    }

    function batchClaim(ClaimParams[] calldata params, bool revertOnFailure) external override lock {
        require(!paused, 'D_PAUSED');
        for (uint256 i; i < params.length; i++) {
            (bool success, bytes memory result) = address(this).call(
                abi.encodeWithSelector(this._claim.selector, params[i], msg.sender)
            );
            if (revertOnFailure && !success) {
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }
        }
    }

    function _claim(ClaimParams memory params, address sender) external {
        require(msg.sender == address(this), 'D_INTERNAL_ONLY');
        require(params.distributionId > 0 && params.distributionId <= lastDistributionId, 'D_INVALID_DISTRIBUTION');
        Distribution storage _distribution = _distributions[params.distributionId];
        require(_distribution.stopBlock == 0 || _distribution.stopBlock > block.number, 'D_STOPPED');
        require(!isClaimed(params.distributionId, params.index), 'D_ALREADY_CLAIMED');

        bytes32 node = keccak256(
            abi.encodePacked(params.index, sender, params.claimData, params.messageSignature, params.entropy)
        );
        require(MerkleProof.verify(params.proof, _distribution.merkleRoot, node), 'D_INVALID_PROOF');

        _setClaimed(params.distributionId, params.index);
        IVault(_distribution.vault).claim(params.claimData);

        emit Claimed(params.distributionId, params.index);
    }

    function isClaimed(uint256 distributionId, uint256 index) public view override returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = _claimedBitMap[distributionId][claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 distributionId, uint256 index) internal {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        _claimedBitMap[distributionId][claimedWordIndex] =
            _claimedBitMap[distributionId][claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    function setStop(uint256 distributionId, uint256 stopBlock) external override {
        Distribution storage _distribution = _distributions[distributionId];
        require(msg.sender == _distribution.admin, 'D_ADMIN_ONLY');
        require(_distribution.stopBlock == 0, 'D_STOP_ALREADY_SET');
        require(stopBlock > block.number, 'D_STOP_NOT_FUTURE');
        _distribution.stopBlock = stopBlock;

        emit StopSet(distributionId, stopBlock);
    }

    function withdraw(uint256 distributionId, bytes calldata data) external override lock {
        require(!paused, 'D_PAUSED');
        Distribution storage _distribution = _distributions[distributionId];
        require(msg.sender == _distribution.admin, 'D_ADMIN_ONLY');
        require(_distribution.stopBlock > 0, 'D_STOP_NOT_SET');
        require(_distribution.stopBlock <= block.number, 'D_STOP_NOT_PAST');
        IVault(_distribution.vault).withdraw(data);

        emit Withdrawn(distributionId);
    }

    function setAdmin(uint256 distributionId, address admin) external override {
        Distribution storage _distribution = _distributions[distributionId];
        require(msg.sender == _distribution.admin, 'D_ADMIN_ONLY');
        require(admin != _distribution.admin, 'D_ALREADY_SET');
        require(admin != address(0), 'D_ADDRESS_ZERO');
        _distribution.admin = admin;

        emit AdminSet(distributionId, admin);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.10;

interface IDistributor {
    event OwnerSet(address owner);
    event PausedSet(bool paused);
    event VaultBytescodeSet(uint256 vaultBytecodeId, uint256 size);

    event Created(uint256 indexed distributionId);
    event Claimed(uint256 indexed distributionId, uint256 indexed index);
    event StopSet(uint256 indexed distributionId, uint256 stopBlock);
    event Withdrawn(uint256 indexed distributionId);
    event AdminSet(uint256 indexed distributionId, address admin);

    struct Distribution {
        // TODO: need to pack data
        uint256 id;
        address admin;
        address vault;
        bytes32 merkleRoot;
        uint256 stopBlock;
        uint256 expirationBlock;
    }

    struct ClaimParams {
        uint256 distributionId;
        uint256 index;
        bytes claimData;
        bytes32 messageSignature;
        bytes32 entropy;
        bytes32[] proof;
    }

    function setOwner(address owner) external;

    function owner() external view returns (address);

    function setPaused(bool paused) external;

    function paused() external view returns (bool);

    function setVaultBytescode(uint256 vaultBytecodeId, bytes calldata bytecode) external;

    function vaultBytescode(uint256 vaultBytecodeId) external view returns (bytes memory);

    function create(
        uint256 vaultBytecodeId,
        bytes calldata initializeData,
        address admin,
        bytes32 merkleRoot,
        uint256 expirationBlock
    ) external;

    function lastDistributionId() external view returns (uint256);

    function distribution(uint256 distributionId) external view returns (Distribution memory);

    function claim(ClaimParams calldata params) external;

    function batchClaim(ClaimParams[] calldata params, bool revertOnFailure) external;

    function isClaimed(uint256 distributionId, uint256 index) external view returns (bool);

    function setStop(uint256 distributionId, uint256 stopBlock) external;

    function withdraw(uint256 distributionId, bytes calldata data) external;

    function setAdmin(uint256 distributionId, address admin) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.10;

interface IVault {
    event OwnerSet(address owner);

    function initialize(bytes calldata data) external;

    function setOwner(address owner) external;

    function owner() external view returns (address);

    function claim(bytes calldata data) external;

    function withdraw(bytes calldata data) external;

    // TODO: implement fees (maybe on claim)
}