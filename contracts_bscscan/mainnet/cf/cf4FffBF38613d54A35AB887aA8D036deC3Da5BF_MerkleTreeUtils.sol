pragma solidity ^0.5.15;

/*
Governance contract handles all the proof of burn related functionality
*/
contract Governance {
    constructor(uint256 maxDepth, uint256 maxDepositSubTree) public {
        _MAX_DEPTH = maxDepth;
        _MAX_DEPOSIT_SUBTREE = maxDepositSubTree;
    }

    uint256 public _MAX_DEPTH = 4;

    function MAX_DEPTH() public view returns (uint256) {
        return _MAX_DEPTH;
    }

    uint256 public _MAX_DEPOSIT_SUBTREE = 2;

    function MAX_DEPOSIT_SUBTREE() public view returns (uint256) {
        return _MAX_DEPOSIT_SUBTREE;
    }

    // finalisation time is the number of blocks required by a batch to finalise
    // Delay period = 7 days. Block time = 15 seconds
    uint256 public _TIME_TO_FINALISE = 7 days;

    function TIME_TO_FINALISE() public view returns (uint256) {
        return _TIME_TO_FINALISE;
    }

    // min gas required before rollback pauses
    uint256 public _MIN_GAS_LIMIT_LEFT = 100000;

    function MIN_GAS_LIMIT_LEFT() public view returns (uint256) {
        return _MIN_GAS_LIMIT_LEFT;
    }

    uint256 public _MAX_TXS_PER_BATCH = 10;

    function MAX_TXS_PER_BATCH() public view returns (uint256) {
        return _MAX_TXS_PER_BATCH;
    }

    uint256 public _STAKE_AMOUNT = 32 ether;

    function STAKE_AMOUNT() public view returns (uint256) {
        return _STAKE_AMOUNT;
    }
}

pragma solidity ^0.5.15;
pragma experimental ABIEncoderV2;
import { ParamManager } from "./libs/ParamManager.sol";
import { Governance } from "./Governance.sol";
import { NameRegistry as Registry } from "./NameRegistry.sol";

contract MerkleTreeUtils {
    // The default hashes
    bytes32[] public defaultHashes;
    uint256 public MAX_DEPTH;
    Governance public governance;

    /**
     * @notice Initialize a new MerkleTree contract, computing the default hashes for the merkle tree (MT)
     */
    constructor(address _registryAddr) public {
        Registry nameRegistry = Registry(_registryAddr);
        governance = Governance(
            nameRegistry.getContractDetails(ParamManager.Governance())
        );
        MAX_DEPTH = governance.MAX_DEPTH();
        defaultHashes = new bytes32[](MAX_DEPTH);
        // Calculate & set the default hashes
        setDefaultHashes(MAX_DEPTH);
    }

    /* Methods */

    /**
     * @notice Set default hashes
     */
    function setDefaultHashes(uint256 depth) internal {
        // Set the initial default hash.
        defaultHashes[0] = keccak256(abi.encode(0));
        for (uint256 i = 1; i < depth; i++) {
            defaultHashes[i] = keccak256(
                abi.encode(defaultHashes[i - 1], defaultHashes[i - 1])
            );
        }
    }

    function getZeroRoot() public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    defaultHashes[MAX_DEPTH - 1],
                    defaultHashes[MAX_DEPTH - 1]
                )
            );
    }

    function getMaxTreeDepth() public view returns (uint256) {
        return MAX_DEPTH;
    }

    function getRoot(uint256 index) public view returns (bytes32) {
        return defaultHashes[index];
    }

    function getDefaultHashAtLevel(uint256 index)
        public
        view
        returns (bytes32)
    {
        return defaultHashes[index];
    }

    function keecakHash(bytes memory data) public pure returns (bytes32) {
        return keccak256(data);
    }

    /**
     * @notice Get the merkle root computed from some set of data blocks.
     * @param _dataBlocks The data being used to generate the tree.
     * @return the merkle tree root
     * NOTE: This is a stateless operation
     */
    function getMerkleRoot(bytes[] calldata _dataBlocks)
        external
        view
        returns (bytes32)
    {
        uint256 nextLevelLength = _dataBlocks.length;
        uint256 currentLevel = 0;
        bytes32[] memory nodes = new bytes32[](nextLevelLength + 1); // Add one in case we have an odd number of leaves
        // Generate the leaves
        for (uint256 i = 0; i < _dataBlocks.length; i++) {
            nodes[i] = keccak256(_dataBlocks[i]);
        }
        if (_dataBlocks.length == 1) {
            return nodes[0];
        }
        // Add a defaultNode if we've got an odd number of leaves
        if (nextLevelLength % 2 == 1) {
            nodes[nextLevelLength] = defaultHashes[currentLevel];
            nextLevelLength += 1;
        }

        // Now generate each level
        while (nextLevelLength > 1) {
            currentLevel += 1;
            // Calculate the nodes for the currentLevel
            for (uint256 i = 0; i < nextLevelLength / 2; i++) {
                nodes[i] = getParent(nodes[i * 2], nodes[i * 2 + 1]);
            }
            nextLevelLength = nextLevelLength / 2;
            // Check if we will need to add an extra node
            if (nextLevelLength % 2 == 1 && nextLevelLength != 1) {
                nodes[nextLevelLength] = defaultHashes[currentLevel];
                nextLevelLength += 1;
            }
        }
        // Alright! We should be left with a single node! Return it...
        return nodes[0];
    }

    /**
     * @notice Get the merkle root computed from some set of data blocks.
     * @param nodes The data being used to generate the tree.
     * @return the merkle tree root
     * NOTE: This is a stateless operation
     */
    function getMerkleRootFromLeaves(bytes32[] memory nodes)
        public
        view
        returns (bytes32)
    {
        uint256 nextLevelLength = nodes.length;
        uint256 currentLevel = 0;
        if (nodes.length == 1) {
            return nodes[0];
        }

        // Add a defaultNode if we've got an odd number of leaves
        if (nextLevelLength % 2 == 1) {
            nodes[nextLevelLength] = defaultHashes[currentLevel];
            nextLevelLength += 1;
        }

        // Now generate each level
        while (nextLevelLength > 1) {
            currentLevel += 1;

            // Calculate the nodes for the currentLevel
            for (uint256 i = 0; i < nextLevelLength / 2; i++) {
                nodes[i] = getParent(nodes[i * 2], nodes[i * 2 + 1]);
            }

            nextLevelLength = nextLevelLength / 2;
            // Check if we will need to add an extra node
            if (nextLevelLength % 2 == 1 && nextLevelLength != 1) {
                nodes[nextLevelLength] = defaultHashes[currentLevel];
                nextLevelLength += 1;
            }
        }

        // Alright! We should be left with a single node! Return it...
        return nodes[0];
    }

    /**
     * @notice Calculate root from an inclusion proof.
     * @param _dataBlock The data block we're calculating root for.
     * @param _path The path from the leaf to the root.
     * @param _siblings The sibling nodes along the way.
     * @return The next level of the tree
     * NOTE: This is a stateless operation
     */
    function computeInclusionProofRoot(
        bytes memory _dataBlock,
        uint256 _path,
        bytes32[] memory _siblings
    ) public pure returns (bytes32) {
        // First compute the leaf node
        bytes32 computedNode = keccak256(_dataBlock);

        for (uint256 i = 0; i < _siblings.length; i++) {
            bytes32 sibling = _siblings[i];
            uint8 isComputedRightSibling = getNthBitFromRight(_path, i);
            if (isComputedRightSibling == 0) {
                computedNode = getParent(computedNode, sibling);
            } else {
                computedNode = getParent(sibling, computedNode);
            }
        }
        // Check if the computed node (_root) is equal to the provided root
        return computedNode;
    }

    /**
     * @notice Calculate root from an inclusion proof.
     * @param _leaf The data block we're calculating root for.
     * @param _path The path from the leaf to the root.
     * @param _siblings The sibling nodes along the way.
     * @return The next level of the tree
     * NOTE: This is a stateless operation
     */
    function computeInclusionProofRootWithLeaf(
        bytes32 _leaf,
        uint256 _path,
        bytes32[] memory _siblings
    ) public pure returns (bytes32) {
        // First compute the leaf node
        bytes32 computedNode = _leaf;
        for (uint256 i = 0; i < _siblings.length; i++) {
            bytes32 sibling = _siblings[i];
            uint8 isComputedRightSibling = getNthBitFromRight(_path, i);
            if (isComputedRightSibling == 0) {
                computedNode = getParent(computedNode, sibling);
            } else {
                computedNode = getParent(sibling, computedNode);
            }
        }
        // Check if the computed node (_root) is equal to the provided root
        return computedNode;
    }

    /**
     * @notice Verify an inclusion proof.
     * @param _root The root of the tree we are verifying inclusion for.
     * @param _dataBlock The data block we're verifying inclusion for.
     * @param _path The path from the leaf to the root.
     * @param _siblings The sibling nodes along the way.
     * @return The next level of the tree
     * NOTE: This is a stateless operation
     */
    function verify(
        bytes32 _root,
        bytes memory _dataBlock,
        uint256 _path,
        bytes32[] memory _siblings
    ) public pure returns (bool) {
        // First compute the leaf node
        bytes32 calculatedRoot = computeInclusionProofRoot(
            _dataBlock,
            _path,
            _siblings
        );
        return calculatedRoot == _root;
    }

    /**
     * @notice Verify an inclusion proof.
     * @param _root The root of the tree we are verifying inclusion for.
     * @param _leaf The data block we're verifying inclusion for.
     * @param _path The path from the leaf to the root.
     * @param _siblings The sibling nodes along the way.
     * @return The next level of the tree
     * NOTE: This is a stateless operation
     */
    function verifyLeaf(
        bytes32 _root,
        bytes32 _leaf,
        uint256 _path,
        bytes32[] memory _siblings
    ) public pure returns (bool) {
        bytes32 calculatedRoot = computeInclusionProofRootWithLeaf(
            _leaf,
            _path,
            _siblings
        );
        return calculatedRoot == _root;
    }

    /**
     * @notice Update a leaf using siblings and root
     *         This is a stateless operation
     * @param _leaf The leaf we're updating.
     * @param _path The path from the leaf to the root / the index of the leaf.
     * @param _siblings The sibling nodes along the way.
     * @return Updated root
     */
    function updateLeafWithSiblings(
        bytes32 _leaf,
        uint256 _path,
        bytes32[] memory _siblings
    ) public pure returns (bytes32) {
        bytes32 computedNode = _leaf;
        for (uint256 i = 0; i < _siblings.length; i++) {
            bytes32 parent;
            bytes32 sibling = _siblings[i];
            uint8 isComputedRightSibling = getNthBitFromRight(_path, i);
            if (isComputedRightSibling == 0) {
                parent = getParent(computedNode, sibling);
            } else {
                parent = getParent(sibling, computedNode);
            }
            computedNode = parent;
        }
        return computedNode;
    }

    /**
     * @notice Get the parent of two children nodes in the tree
     * @param _left The left child
     * @param _right The right child
     * @return The parent node
     */
    function getParent(bytes32 _left, bytes32 _right)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(_left, _right));
    }

    /**
     * @notice get the n'th bit in a uint.
     *         For instance, if exampleUint=binary(11), getNth(exampleUint, 0) == 1, getNth(2, 1) == 1
     * @param _intVal The uint we are extracting a bit out of
     * @param _index The index of the bit we want to extract
     * @return The bit (1 or 0) in a uint8
     */
    function getNthBitFromRight(uint256 _intVal, uint256 _index)
        public
        pure
        returns (uint8)
    {
        return uint8((_intVal >> _index) & 1);
    }

    /**
     * @notice Get the right sibling key. Note that these keys overwrite the first bit of the hash
               to signify if it is on the right side of the parent or on the left
     * @param _parent The parent node
     * @return the key for the left sibling (0 as the first bit)
     */
    function getLeftSiblingKey(bytes32 _parent) public pure returns (bytes32) {
        return
            _parent &
            0x0111111111111111111111111111111111111111111111111111111111111111;
    }

    /**
     * @notice Get the right sibling key. Note that these keys overwrite the first bit of the hash
               to signify if it is on the right side of the parent or on the left
     * @param _parent The parent node
     * @return the key for the right sibling (1 as the first bit)
     */
    function getRightSiblingKey(bytes32 _parent) public pure returns (bytes32) {
        return
            _parent |
            0x1000000000000000000000000000000000000000000000000000000000000000;
    }

    function pathToIndex(uint256 path, uint256 height)
        public
        pure
        returns (uint256)
    {
        uint256 result = 0;
        for (uint256 i = 0; i < height; i++) {
            uint8 temp = getNthBitFromRight(path, i);
            // UNSAFE FIX THIS
            result = result + (temp * (2**i));
        }
        return result;
    }
}

pragma solidity ^0.5.15;

contract NameRegistry {
    struct ContractDetails {
        // registered contract address
        address contractAddress;
    }
    event RegisteredNewContract(bytes32 name, address contractAddr);
    mapping(bytes32 => ContractDetails) registry;

    function registerName(bytes32 name, address addr) external returns (bool) {
        ContractDetails memory info = registry[name];
        // create info if it doesn't exist in the registry
        if (info.contractAddress == address(0)) {
            info.contractAddress = addr;
            registry[name] = info;
            // added to registry
            return true;
        } else {
            // already was registered
            return false;
        }
    }

    function getContractDetails(bytes32 name) external view returns (address) {
        return (registry[name].contractAddress);
    }

    function updateContractDetails(bytes32 name, address addr) external {
        // TODO not sure if we should do this
        // If we do we need a plan on how to remove this
    }
}

pragma solidity ^0.5.15;

library ParamManager {
    function DEPOSIT_MANAGER() public pure returns (bytes32) {
        return keccak256("deposit_manager");
    }

    function WITHDRAW_MANAGER() public pure returns (bytes32) {
        return keccak256("withdraw_manager");
    }

    function TOKEN() public pure returns (bytes32) {
        return keccak256("token");
    }

    function POB() public pure returns (bytes32) {
        return keccak256("pob");
    }

    function Governance() public pure returns (bytes32) {
        return keccak256("governance");
    }

    function ROLLUP_CORE() public pure returns (bytes32) {
        return keccak256("rollup_core");
    }

    function ACCOUNTS_TREE() public pure returns (bytes32) {
        return keccak256("accounts_tree");
    }

    function LOGGER() public pure returns (bytes32) {
        return keccak256("logger");
    }

    function MERKLE_UTILS() public pure returns (bytes32) {
        return keccak256("merkle_lib");
    }

    function PARAM_MANAGER() public pure returns (bytes32) {
        return keccak256("param_manager");
    }

    function TOKEN_REGISTRY() public pure returns (bytes32) {
        return keccak256("token_registry");
    }

    function FRAUD_PROOF() public pure returns (bytes32) {
        return keccak256("fraud_proof");
    }

    bytes32 public constant _CHAIN_ID = keccak256("opru-123");

    function CHAIN_ID() public pure returns (bytes32) {
        return _CHAIN_ID;
    }
}

