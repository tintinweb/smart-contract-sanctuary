pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.15;
pragma experimental ABIEncoderV2;
import { IncrementalTree } from "./IncrementalTree.sol";
import { Types } from "./libs/Types.sol";
import { Logger } from "./logger.sol";
import { RollupUtils } from "./libs/RollupUtils.sol";
import { MerkleTreeUtils as MTUtils } from "./MerkleTreeUtils.sol";
import { NameRegistry as Registry } from "./NameRegistry.sol";
import { ITokenRegistry } from "./interfaces/ITokenRegistry.sol";
import { IERC20 } from "./interfaces/IERC20.sol";
import { ParamManager } from "./libs/ParamManager.sol";
import { POB } from "./POB.sol";
import { Governance } from "./Governance.sol";
import { Rollup } from "./rollup.sol";

contract DepositManager {
    MTUtils public merkleUtils;
    Registry public nameRegistry;
    bytes32[] public pendingDeposits;
    mapping(uint256 => bytes32) pendingFilledSubtrees;
    uint256 public firstElement = 1;
    uint256 public lastElement = 0;
    bytes32
        public constant ZERO_BYTES32 = 0x0000000000000000000000000D81d9E21BD7C5bB095535624DcB0759E64B3899;
    uint256 public depositSubTreesPackaged = 0;

    function enqueue(bytes32 newDepositSubtree) public {
        lastElement += 1;
        pendingFilledSubtrees[lastElement] = newDepositSubtree;
        depositSubTreesPackaged++;
    }

    function dequeue() public returns (bytes32 depositSubtreeRoot) {
        require(lastElement >= firstElement); // non-empty queue
        depositSubtreeRoot = pendingFilledSubtrees[firstElement];
        delete pendingFilledSubtrees[firstElement];
        firstElement += 1;
        depositSubTreesPackaged--;
    }

    uint256 public queueNumber;
    uint256 public depositSubtreeHeight;
    Governance public governance;
    Logger public logger;
    ITokenRegistry public tokenRegistry;
    IERC20 public tokenContract;
    IncrementalTree public accountsTree;
    modifier onlyCoordinator() {
        POB pobContract = POB(
            nameRegistry.getContractDetails(ParamManager.POB())
        );
        assert(msg.sender == pobContract.getCoordinator());
        _;
    }

    modifier onlyRollup() {
        assert(
            msg.sender ==
                nameRegistry.getContractDetails(ParamManager.ROLLUP_CORE())
        );
        _;
    }

    constructor(address _registryAddr) public {
        nameRegistry = Registry(_registryAddr);
        governance = Governance(
            nameRegistry.getContractDetails(ParamManager.Governance())
        );
        merkleUtils = MTUtils(
            nameRegistry.getContractDetails(ParamManager.MERKLE_UTILS())
        );
        tokenRegistry = ITokenRegistry(
            nameRegistry.getContractDetails(ParamManager.TOKEN_REGISTRY())
        );
        logger = Logger(nameRegistry.getContractDetails(ParamManager.LOGGER()));
        accountsTree = IncrementalTree(
            nameRegistry.getContractDetails(ParamManager.ACCOUNTS_TREE())
        );

        AddCoordinatorLeaves();
    }

    function AddCoordinatorLeaves() internal {
        // first 2 leaves belong to coordinator
        accountsTree.appendLeaf(ZERO_BYTES32);
        accountsTree.appendLeaf(ZERO_BYTES32);
    }

    /**
     * @notice Adds a deposit for the msg.sender to the deposit queue
     * @param _amount Number of tokens that user wants to deposit
     * @param _tokenType Type of token user is depositing
     */
    function deposit(
        uint256 _amount,
        uint256 _tokenType,
        bytes memory _pubkey
    ) public {
        depositFor(msg.sender, _amount, _tokenType, _pubkey);
    }

    /**
     * @notice Adds a deposit for an address to the deposit queue
     * @param _destination Address for which we are depositing
     * @param _amount Number of tokens that user wants to deposit
     * @param _tokenType Type of token user is depositing
     */
    function depositFor(
        address _destination,
        uint256 _amount,
        uint256 _tokenType,
        bytes memory _pubkey
    ) public {
        // check amount is greater than 0
        require(_amount > 0, "token deposit must be greater than 0");

        // ensure public matches the destination address
        require(
            _destination == RollupUtils.calculateAddress(_pubkey),
            "public key and address don't match"
        );

        // check token type exists
        address tokenContractAddress = tokenRegistry.registeredTokens(
            _tokenType
        );
        tokenContract = IERC20(tokenContractAddress);

        // transfer from msg.sender to this contract
        require(
            tokenContract.transferFrom(msg.sender, address(this), _amount),
            "token transfer not approved"
        );

        // returns leaf index upon successfull append
        uint256 accID = accountsTree.appendDataBlock(_pubkey);

        // create a new account
        Types.UserAccount memory newAccount;
        newAccount.balance = _amount;
        newAccount.tokenType = _tokenType;
        newAccount.nonce = 0;
        newAccount.ID = accID;

        // get new account hash
        bytes memory accountBytes = RollupUtils.BytesFromAccount(newAccount);

        // queue the deposit
        pendingDeposits.push(keccak256(accountBytes));

        // emit the event
        logger.logDepositQueued(accID, _pubkey, accountBytes);

        queueNumber++;
        uint256 tmpDepositSubtreeHeight = 0;
        uint256 tmp = queueNumber;
        while (tmp % 2 == 0) {
            bytes32[] memory deposits = new bytes32[](2);
            deposits[0] = pendingDeposits[pendingDeposits.length - 2];
            deposits[1] = pendingDeposits[pendingDeposits.length - 1];

            pendingDeposits[pendingDeposits.length - 2] = merkleUtils.getParent(
                deposits[0],
                deposits[1]
            );

            // remove 1 deposit from the pending deposit queue
            removeDeposit(pendingDeposits.length - 1);
            tmp = tmp / 2;

            // update the temp deposit subtree height
            tmpDepositSubtreeHeight++;

            // thow event for the coordinator
            logger.logDepositLeafMerged(
                deposits[0],
                deposits[1],
                pendingDeposits[0]
            );
        }

        if (tmpDepositSubtreeHeight > depositSubtreeHeight) {
            depositSubtreeHeight = tmpDepositSubtreeHeight;
        }

        if (depositSubtreeHeight == governance.MAX_DEPOSIT_SUBTREE()) {
            // start adding deposits to prepackaged deposit subtree root queue
            enqueue(pendingDeposits[0]);

            // emit an event to signal that a package is ready
            // isnt really important for anyone tho
            logger.logDepositSubTreeReady(pendingDeposits[0]);

            // update the number of items in pendingDeposits
            queueNumber = queueNumber - 2**depositSubtreeHeight;

            // empty the pending deposits queue
            removeDeposit(0);

            // reset deposit subtree height
            depositSubtreeHeight = 0;
        }
    }

    /**
     * @notice Merges the deposit tree with the balance tree by
     *        superimposing the deposit subtree on the balance tree
     * @param _subTreeDepth Deposit tree depth or depth of subtree that is being deposited
     * @param _zero_account_mp Merkle proof proving the node at which we are inserting the deposit subtree consists of all empty leaves
     * @return Updates in-state merkle tree root
     */
    function finaliseDeposits(
        uint256 _subTreeDepth,
        Types.AccountMerkleProof memory _zero_account_mp,
        bytes32 latestBalanceTree
    ) public onlyRollup returns (bytes32) {
        bytes32 emptySubtreeRoot = merkleUtils.getRoot(_subTreeDepth);

        // from mt proof we find the root of the tree
        // we match the root to the balance tree root on-chain
        bool isValid = merkleUtils.verifyLeaf(
            latestBalanceTree,
            emptySubtreeRoot,
            _zero_account_mp.accountIP.pathToAccount,
            _zero_account_mp.siblings
        );

        require(isValid, "proof invalid");

        // just dequeue from the pre package deposit subtrees
        bytes32 depositsSubTreeRoot = dequeue();

        // emit the event
        logger.logDepositFinalised(
            depositsSubTreeRoot,
            _zero_account_mp.accountIP.pathToAccount
        );

        // return the updated merkle tree root
        return (depositsSubTreeRoot);
    }

    /**
     * @notice Removes a deposit from the pendingDeposits queue and shifts the queue
     * @param _index Index of the element to remove
     * @return Remaining elements of the array
     */
    function removeDeposit(uint256 _index) internal {
        require(
            _index < pendingDeposits.length,
            "array index is out of bounds"
        );

        // if we want to nuke the queue
        if (_index == 0) {
            uint256 numberOfDeposits = pendingDeposits.length;
            for (uint256 i = 0; i < numberOfDeposits; i++) {
                delete pendingDeposits[i];
            }
            pendingDeposits.length = 0;
            return;
        }

        if (_index == pendingDeposits.length - 1) {
            delete pendingDeposits[pendingDeposits.length - 1];
            pendingDeposits.length--;
            return;
        }
    }
}

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

import { MerkleTreeUtils as MTUtils } from "./MerkleTreeUtils.sol";
import { ParamManager } from "./libs/ParamManager.sol";
import { NameRegistry as Registry } from "./NameRegistry.sol";
import { Governance } from "./Governance.sol";
import { Logger } from "./logger.sol";
import { RollupUtils } from "./libs/RollupUtils.sol";

contract IncrementalTree {
    Registry public nameRegistry;
    MTUtils public merkleUtils;
    Governance public governance;
    MerkleTree public tree;
    Logger public logger;
    // Merkle Tree to store the whole tree
    struct MerkleTree {
        // Root of the tree
        bytes32 root;
        // current height of the tree
        uint256 height;
        // Allows you to compute the path to the element (but it's not the path to
        // the elements). Caching these values is essential to efficient appends.
        bytes32[] filledSubtrees;
    }

    // The number of inserted leaves
    uint256 public nextLeafIndex = 0;

    constructor(address _registryAddr) public {
        nameRegistry = Registry(_registryAddr);
        merkleUtils = MTUtils(
            nameRegistry.getContractDetails(ParamManager.MERKLE_UTILS())
        );
        governance = Governance(
            nameRegistry.getContractDetails(ParamManager.Governance())
        );

        logger = Logger(nameRegistry.getContractDetails(ParamManager.LOGGER()));
        tree.filledSubtrees = new bytes32[](governance.MAX_DEPTH());
        setMerkleRootAndHeight(
            merkleUtils.getZeroRoot(),
            merkleUtils.getMaxTreeDepth()
        );
        bytes32 zero = merkleUtils.getDefaultHashAtLevel(0);
        for (uint8 i = 1; i < governance.MAX_DEPTH(); i++) {
            tree.filledSubtrees[i] = zero;
        }
    }

    function appendDataBlock(bytes memory datablock) public returns (uint256) {
        bytes32 _leaf = keccak256(abi.encode(datablock));
        uint256 accID = appendLeaf(_leaf);
        logger.logNewPubkeyAdded(accID, datablock);
        return accID;
    }

    /**
     * @notice Append leaf will append a leaf to the end of the tree
     * @return The sibling nodes along the way.
     */
    function appendLeaf(bytes32 _leaf) public returns (uint256) {
        uint256 currentIndex = nextLeafIndex;
        uint256 depth = uint256(tree.height);
        require(
            currentIndex < uint256(2)**depth,
            "IncrementalMerkleTree: tree is full"
        );
        bytes32 currentLevelHash = _leaf;
        bytes32 left;
        bytes32 right;
        for (uint8 i = 0; i < tree.height; i++) {
            if (currentIndex % 2 == 0) {
                left = currentLevelHash;
                right = merkleUtils.getRoot(i);
                tree.filledSubtrees[i] = currentLevelHash;
            } else {
                left = tree.filledSubtrees[i];
                right = currentLevelHash;
            }
            currentLevelHash = merkleUtils.getParent(left, right);
            currentIndex >>= 1;
        }
        tree.root = currentLevelHash;
        uint256 n;
        n = nextLeafIndex;
        nextLeafIndex += 1;
        return n;
    }

    /**
     * @notice Set the tree root and height of the stored tree
     * @param _root The merkle root of the tree
     * @param _height The height of the tree
     */
    function setMerkleRootAndHeight(bytes32 _root, uint256 _height) public {
        tree.root = _root;
        tree.height = _height;
    }

    function getTreeRoot() external view returns (bytes32) {
        return tree.root;
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

/*
POB contract handles all the proof of burn related functionality
*/
contract POB {
    address public coordinator;

    constructor() public {
        coordinator = msg.sender;
    }

    function getCoordinator() public view returns (address) {
        return coordinator;
    }
}

pragma solidity ^0.5.15;

// ERC20 token interface
contract IERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool) {}

    function transfer(address recipient, uint256 value) public returns (bool) {}
}

pragma solidity ^0.5.15;
pragma experimental ABIEncoderV2;

import { Types } from "../libs/Types.sol";

interface IFraudProof {
    function processTx(
        bytes32 _balanceRoot,
        bytes32 _accountsRoot,
        Types.Transaction calldata _tx,
        Types.PDAMerkleProof calldata _from_pda_proof,
        Types.AccountProofs calldata accountProofs
    )
        external
        view
        returns (
            bytes32,
            bytes memory,
            bytes memory,
            Types.ErrorCode,
            bool
        );

    function processBatch(
        bytes32 initialStateRoot,
        bytes32 accountsRoot,
        Types.Transaction[] calldata _txs,
        Types.BatchValidationProofs calldata batchProofs,
        bytes32 expectedTxRoot
    )
        external
        view
        returns (
            bytes32,
            bytes32,
            bool
        );

    function ApplyTx(
        Types.AccountMerkleProof calldata _merkle_proof,
        Types.Transaction calldata transaction
    ) external view returns (bytes memory, bytes32 newRoot);
}

pragma solidity ^0.5.15;

// token registry contract interface
contract ITokenRegistry {
    uint256 public numTokens;
    mapping(address => bool) public pendingRegistrations;
    mapping(uint256 => address) public registeredTokens;

    function requestTokenRegistration(address tokenContract) public {}

    function finaliseTokenRegistration(address tokenContract) public {}
}

pragma solidity ^0.5.15;

library ECVerify {
    function ecrecovery(bytes32 hash, bytes memory sig)
        public
        pure
        returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (sig.length != 65) {
            return address(0x0);
        }

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := and(mload(add(sig, 65)), 255)
        }

        // https://github.com/ethereum/go-ethereum/issues/2053
        if (v < 27) {
            v += 27;
        }

        if (v != 27 && v != 28) {
            return address(0x0);
        }

        // get address out of hash and signature
        address result = ecrecover(hash, v, r, s);

        // ecrecover returns zero on error
        require(result != address(0x0));

        return result;
    }

    function ecrecovery(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (address) {
        // get address out of hash and signature
        address result = ecrecover(hash, v, r, s);

        // ecrecover returns zero on error
        require(result != address(0x0));

        return result;
    }

    function ecverify(
        bytes32 hash,
        bytes memory sig,
        address signer
    ) public pure returns (bool) {
        return signer == ecrecovery(hash, sig);
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

pragma solidity ^0.5.15;
pragma experimental ABIEncoderV2;

import { Types } from "./Types.sol";

library RollupUtils {
    // ---------- Account Related Utils -------------------
    function PDALeafToHash(Types.PDALeaf memory _PDA_Leaf)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(_PDA_Leaf.pubkey));
    }

    // returns a new User Account with updated balance
    function UpdateBalanceInAccount(
        Types.UserAccount memory original_account,
        uint256 new_balance
    ) public pure returns (Types.UserAccount memory updated_account) {
        original_account.balance = new_balance;
        return original_account;
    }

    function BalanceFromAccount(Types.UserAccount memory account)
        public
        pure
        returns (uint256)
    {
        return account.balance;
    }

    // AccountFromBytes decodes the bytes to account
    function AccountFromBytes(bytes memory accountBytes)
        public
        pure
        returns (
            uint256 ID,
            uint256 balance,
            uint256 nonce,
            uint256 tokenType
        )
    {
        return abi.decode(accountBytes, (uint256, uint256, uint256, uint256));
    }

    //
    // BytesFromAccount and BytesFromAccountDeconstructed do the same thing i.e encode account to bytes
    //
    function BytesFromAccount(Types.UserAccount memory account)
        public
        pure
        returns (bytes memory)
    {
        bytes memory data = abi.encodePacked(
            account.ID,
            account.balance,
            account.nonce,
            account.tokenType
        );

        return data;
    }

    function BytesFromAccountDeconstructed(
        uint256 ID,
        uint256 balance,
        uint256 nonce,
        uint256 tokenType
    ) public pure returns (bytes memory) {
        return abi.encodePacked(ID, balance, nonce, tokenType);
    }

    //
    // HashFromAccount and getAccountHash do the same thing i.e hash account
    //
    function getAccountHash(
        uint256 id,
        uint256 balance,
        uint256 nonce,
        uint256 tokenType
    ) public pure returns (bytes32) {
        return
            keccak256(
                BytesFromAccountDeconstructed(id, balance, nonce, tokenType)
            );
    }

    function HashFromAccount(Types.UserAccount memory account)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                BytesFromAccountDeconstructed(
                    account.ID,
                    account.balance,
                    account.nonce,
                    account.tokenType
                )
            );
    }

    // ---------- Tx Related Utils -------------------
    function CompressTx(Types.Transaction memory _tx)
        public
        pure
        returns (bytes memory)
    {
        return
            abi.encode(_tx.fromIndex, _tx.toIndex, _tx.amount, _tx.signature);
    }

    function DecompressTx(bytes memory txBytes)
        public
        pure
        returns (
            uint256 from,
            uint256 to,
            uint256 nonce,
            bytes memory sig
        )
    {
        return abi.decode(txBytes, (uint256, uint256, uint256, bytes));
    }

    function CompressTxWithMessage(bytes memory message, bytes memory sig)
        public
        pure
        returns (bytes memory)
    {
        Types.Transaction memory _tx = TxFromBytes(message);
        return abi.encode(_tx.fromIndex, _tx.toIndex, _tx.amount, sig);
    }

    // Decoding transaction from bytes
    function TxFromBytesDeconstructed(bytes memory txBytes)
        public
        pure
        returns (
            uint256 from,
            uint256 to,
            uint256 tokenType,
            uint256 nonce,
            uint256 txType,
            uint256 amount
        )
    {
        return
            abi.decode(
                txBytes,
                (uint256, uint256, uint256, uint256, uint256, uint256)
            );
    }

    function TxFromBytes(bytes memory txBytes)
        public
        pure
        returns (Types.Transaction memory)
    {
        Types.Transaction memory transaction;
        (
            transaction.fromIndex,
            transaction.toIndex,
            transaction.tokenType,
            transaction.nonce,
            transaction.txType,
            transaction.amount
        ) = abi.decode(
            txBytes,
            (uint256, uint256, uint256, uint256, uint256, uint256)
        );
        return transaction;
    }

    //
    // BytesFromTx and BytesFromTxDeconstructed do the same thing i.e encode transaction to bytes
    //
    function BytesFromTx(Types.Transaction memory _tx)
        public
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                _tx.fromIndex,
                _tx.toIndex,
                _tx.tokenType,
                _tx.nonce,
                _tx.txType,
                _tx.amount
            );
    }

    function BytesFromTxDeconstructed(
        uint256 from,
        uint256 to,
        uint256 tokenType,
        uint256 nonce,
        uint256 txType,
        uint256 amount
    ) public pure returns (bytes memory) {
        return abi.encodePacked(from, to, tokenType, nonce, txType, amount);
    }

    //
    // HashFromTx and getTxSignBytes do the same thing i.e get the tx data to be signed
    //
    function HashFromTx(Types.Transaction memory _tx)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                BytesFromTxDeconstructed(
                    _tx.fromIndex,
                    _tx.toIndex,
                    _tx.tokenType,
                    _tx.nonce,
                    _tx.txType,
                    _tx.amount
                )
            );
    }

    function getTxSignBytes(
        uint256 fromIndex,
        uint256 toIndex,
        uint256 tokenType,
        uint256 txType,
        uint256 nonce,
        uint256 amount
    ) public pure returns (bytes32) {
        return
            keccak256(
                BytesFromTxDeconstructed(
                    fromIndex,
                    toIndex,
                    tokenType,
                    nonce,
                    txType,
                    amount
                )
            );
    }

    /**
     * @notice Calculates the address from the pubkey
     * @param pub is the pubkey
     * @return Returns the address that has been calculated from the pubkey
     */
    function calculateAddress(bytes memory pub)
        public
        pure
        returns (address addr)
    {
        bytes32 hash = keccak256(pub);
        assembly {
            mstore(0, hash)
            addr := mload(0)
        }
    }

    function GetGenesisLeaves() public view returns (bytes32[2] memory leaves) {
        Types.UserAccount memory account1 = Types.UserAccount({
            ID: 0,
            tokenType: 0,
            balance: 0,
            nonce: 0
        });
        Types.UserAccount memory account2 = Types.UserAccount({
            ID: 1,
            tokenType: 0,
            balance: 0,
            nonce: 0
        });
        leaves[0] = HashFromAccount(account1);
        leaves[1] = HashFromAccount(account2);
    }

    function GetGenesisDataBlocks()
        public
        view
        returns (bytes[2] memory dataBlocks)
    {
        Types.UserAccount memory account1 = Types.UserAccount({
            ID: 0,
            tokenType: 0,
            balance: 0,
            nonce: 0
        });
        Types.UserAccount memory account2 = Types.UserAccount({
            ID: 1,
            tokenType: 0,
            balance: 0,
            nonce: 0
        });
        dataBlocks[0] = BytesFromAccount(account1);
        dataBlocks[1] = BytesFromAccount(account2);
    }
}

pragma solidity ^0.5.15;

/**
 * @title DataTypes
 */
library Types {
    // We define Usage for a batch or for a tx
    // to check if the usage of a batch and all txs in it are the same
    enum Usage {
        Genesis, // The Genesis type is only applicable to batch but not tx
        Transfer,
        Deposit
    }
    // PDALeaf represents the leaf in
    // Pubkey DataAvailability Tree
    struct PDALeaf {
        bytes pubkey;
    }

    // Batch represents the batch submitted periodically to the ethereum chain
    struct Batch {
        bytes32 stateRoot;
        bytes32 accountRoot;
        bytes32 depositTree;
        address committer;
        bytes32 txRoot;
        uint256 stakeCommitted;
        uint256 finalisesOn;
        uint256 timestamp;
        Usage batchType;
    }

    // Transaction represents how each transaction looks like for
    // this rollup chain
    struct Transaction {
        uint256 fromIndex;
        uint256 toIndex;
        uint256 tokenType;
        uint256 nonce;
        uint256 txType;
        uint256 amount;
        bytes signature;
    }

    // AccountInclusionProof consists of the following fields
    // 1. Path to the account leaf from root in the balances tree
    // 2. Actual data stored in the leaf
    struct AccountInclusionProof {
        uint256 pathToAccount;
        UserAccount account;
    }

    struct TranasctionInclusionProof {
        uint256 pathToTx;
        Transaction data;
    }

    struct PDAInclusionProof {
        uint256 pathToPubkey;
        PDALeaf pubkey_leaf;
    }

    // UserAccount contains the actual data stored in the leaf of balance tree
    struct UserAccount {
        // ID is the path to the pubkey in the PDA tree
        uint256 ID;
        uint256 tokenType;
        uint256 balance;
        uint256 nonce;
    }

    struct AccountMerkleProof {
        AccountInclusionProof accountIP;
        bytes32[] siblings;
    }

    struct AccountProofs {
        AccountMerkleProof from;
        AccountMerkleProof to;
    }

    struct BatchValidationProofs {
        AccountProofs[] accountProofs;
        PDAMerkleProof[] pdaProof;
    }

    struct TransactionMerkleProof {
        TranasctionInclusionProof _tx;
        bytes32[] siblings;
    }

    struct PDAMerkleProof {
        PDAInclusionProof _pda;
        bytes32[] siblings;
    }

    enum ErrorCode {
        NoError,
        InvalidTokenAddress,
        InvalidTokenAmount,
        NotEnoughTokenBalance,
        BadFromTokenType,
        BadToTokenType
    }
}

pragma solidity ^0.5.15;

import { Types } from "./libs/Types.sol";

contract Logger {
    /*********************
     * Rollup Contract *
     ********************/
    event NewBatch(
        address committer,
        bytes32 txroot,
        bytes32 updatedRoot,
        uint256 index,
        Types.Usage batchType
    );

    function logNewBatch(
        address committer,
        bytes32 txroot,
        bytes32 updatedRoot,
        uint256 index,
        Types.Usage batchType
    ) public {
        emit NewBatch(committer, txroot, updatedRoot, index, batchType);
    }

    event StakeWithdraw(address committed, uint256 amount, uint256 batch_id);

    function logStakeWithdraw(
        address committed,
        uint256 amount,
        uint256 batch_id
    ) public {
        emit StakeWithdraw(committed, amount, batch_id);
    }

    event BatchRollback(
        uint256 batch_id,
        address committer,
        bytes32 stateRoot,
        bytes32 txRoot,
        uint256 stakeSlashed
    );

    function logBatchRollback(
        uint256 batch_id,
        address committer,
        bytes32 stateRoot,
        bytes32 txRoot,
        uint256 stakeSlashed
    ) public {
        emit BatchRollback(
            batch_id,
            committer,
            stateRoot,
            txRoot,
            stakeSlashed
        );
    }

    event RollbackFinalisation(uint256 totalBatchesSlashed);

    function logRollbackFinalisation(uint256 totalBatchesSlashed) public {
        emit RollbackFinalisation(totalBatchesSlashed);
    }

    event RegisteredToken(uint256 tokenType, address tokenContract);

    function logRegisteredToken(uint256 tokenType, address tokenContract)
        public
    {
        emit RegisteredToken(tokenType, tokenContract);
    }

    event RegistrationRequest(address tokenContract);

    function logRegistrationRequest(address tokenContract) public {
        emit RegistrationRequest(tokenContract);
    }

    event NewPubkeyAdded(uint256 AccountID, bytes pubkey);

    function logNewPubkeyAdded(uint256 accountID, bytes memory pubkey) public {
        emit NewPubkeyAdded(accountID, pubkey);
    }

    event DepositQueued(uint256 AccountID, bytes pubkey, bytes data);

    function logDepositQueued(
        uint256 accountID,
        bytes memory pubkey,
        bytes memory data
    ) public {
        emit DepositQueued(accountID, pubkey, data);
    }

    event DepositLeafMerged(bytes32 left, bytes32 right, bytes32 newRoot);

    function logDepositLeafMerged(
        bytes32 left,
        bytes32 right,
        bytes32 newRoot
    ) public {
        emit DepositLeafMerged(left, right, newRoot);
    }

    event DepositSubTreeReady(bytes32 root);

    function logDepositSubTreeReady(bytes32 root) public {
        emit DepositSubTreeReady(root);
    }

    event DepositsFinalised(bytes32 depositSubTreeRoot, uint256 pathToSubTree);

    function logDepositFinalised(
        bytes32 depositSubTreeRoot,
        uint256 pathToSubTree
    ) public {
        emit DepositsFinalised(depositSubTreeRoot, pathToSubTree);
    }
}

pragma solidity ^0.5.15;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";
import { IERC20 } from "./interfaces/IERC20.sol";
import { ITokenRegistry } from "./interfaces/ITokenRegistry.sol";
import { IFraudProof } from "./interfaces/IFraudProof.sol";
import { ParamManager } from "./libs/ParamManager.sol";
import { Types } from "./libs/Types.sol";
import { RollupUtils } from "./libs/RollupUtils.sol";
import { ECVerify } from "./libs/ECVerify.sol";
import { IncrementalTree } from "./IncrementalTree.sol";
import { Logger } from "./logger.sol";
import { POB } from "./POB.sol";
import { MerkleTreeUtils as MTUtils } from "./MerkleTreeUtils.sol";
import { NameRegistry as Registry } from "./NameRegistry.sol";
import { Governance } from "./Governance.sol";
import { DepositManager } from "./DepositManager.sol";

contract RollupSetup {
    using SafeMath for uint256;
    using BytesLib for bytes;
    using ECVerify for bytes32;

    /*********************
     * Variable Declarations *
     ********************/

    // External contracts
    DepositManager public depositManager;
    IncrementalTree public accountsTree;
    Logger public logger;
    ITokenRegistry public tokenRegistry;
    Registry public nameRegistry;
    Types.Batch[] public batches;
    MTUtils public merkleUtils;

    IFraudProof public fraudProof;

    bytes32
        public constant ZERO_BYTES32 = 0x0000000000000000000000000000000000000000000000000000000000000000;
    address payable constant BURN_ADDRESS = 0x0000000000000000000000000000000000000000;
    Governance public governance;

    // this variable will be greater than 0 if
    // there is rollback in progress
    // will be reset to 0 once rollback is completed
    uint256 public invalidBatchMarker;

    modifier onlyCoordinator() {
        POB pobContract = POB(
            nameRegistry.getContractDetails(ParamManager.POB())
        );
        assert(msg.sender == pobContract.getCoordinator());
        _;
    }

    modifier isNotRollingBack() {
        assert(invalidBatchMarker == 0);
        _;
    }

    modifier isRollingBack() {
        assert(invalidBatchMarker > 0);
        _;
    }
}

contract RollupHelpers is RollupSetup {
    /**
     * @notice Returns the latest state root
     */
    function getLatestBalanceTreeRoot() public view returns (bytes32) {
        return batches[batches.length - 1].stateRoot;
    }

    /**
     * @notice Returns the total number of batches submitted
     */
    function numOfBatchesSubmitted() public view returns (uint256) {
        return batches.length;
    }

    function addNewBatch(
        bytes32 txRoot,
        bytes32 _updatedRoot,
        Types.Usage batchType
    ) internal {
        Types.Batch memory newBatch = Types.Batch({
            stateRoot: _updatedRoot,
            accountRoot: accountsTree.getTreeRoot(),
            depositTree: ZERO_BYTES32,
            committer: msg.sender,
            txRoot: txRoot,
            stakeCommitted: msg.value,
            finalisesOn: block.number + governance.TIME_TO_FINALISE(),
            timestamp: now,
            batchType: batchType
        });

        batches.push(newBatch);
        logger.logNewBatch(
            newBatch.committer,
            txRoot,
            _updatedRoot,
            batches.length - 1,
            batchType
        );
    }

    function addNewBatchWithDeposit(bytes32 _updatedRoot, bytes32 depositRoot)
        internal
    {
        Types.Batch memory newBatch = Types.Batch({
            stateRoot: _updatedRoot,
            accountRoot: accountsTree.getTreeRoot(),
            depositTree: depositRoot,
            committer: msg.sender,
            txRoot: ZERO_BYTES32,
            stakeCommitted: msg.value,
            finalisesOn: block.number + governance.TIME_TO_FINALISE(),
            timestamp: now,
            batchType: Types.Usage.Deposit
        });

        batches.push(newBatch);
        logger.logNewBatch(
            newBatch.committer,
            ZERO_BYTES32,
            _updatedRoot,
            batches.length - 1,
            Types.Usage.Deposit
        );
    }

    /**
     * @notice Returns the batch
     */
    function getBatch(uint256 _batch_id)
        public
        view
        returns (Types.Batch memory batch)
    {
        require(
            batches.length - 1 >= _batch_id,
            "Batch id greater than total number of batches, invalid batch id"
        );
        batch = batches[_batch_id];
    }

    /**
     * @notice SlashAndRollback slashes all the coordinator's who have built on top of the invalid batch
     * and rewards challengers. Also deletes all the batches after invalid batch
     */
    function SlashAndRollback() public isRollingBack {
        uint256 challengerRewards = 0;
        uint256 burnedAmount = 0;
        uint256 totalSlashings = 0;

        for (uint256 i = batches.length - 1; i >= invalidBatchMarker; i--) {
            // if gas left is low we would like to do all the transfers
            // and persist intermediate states so someone else can send another tx
            // and rollback remaining batches
            if (gasleft() <= governance.MIN_GAS_LIMIT_LEFT()) {
                // exit loop gracefully
                break;
            }

            // load batch
            Types.Batch memory batch = batches[i];

            // calculate challeger's reward
            uint256 _challengerReward = (batch.stakeCommitted.mul(2)).div(3);
            challengerRewards += _challengerReward;
            burnedAmount += batch.stakeCommitted.sub(_challengerReward);

            batches[i].stakeCommitted = 0;

            // delete batch
            delete batches[i];

            // queue deposits again
            depositManager.enqueue(batch.depositTree);

            totalSlashings++;

            logger.logBatchRollback(
                i,
                batch.committer,
                batch.stateRoot,
                batch.txRoot,
                batch.stakeCommitted
            );
            if (i == invalidBatchMarker) {
                // we have completed rollback
                // update the marker
                invalidBatchMarker = 0;
                break;
            }
        }

        // transfer reward to challenger
        (msg.sender).transfer(challengerRewards);

        // burn the remaning amount
        (BURN_ADDRESS).transfer(burnedAmount);

        // resize batches length
        batches.length = batches.length.sub(totalSlashings);

        logger.logRollbackFinalisation(totalSlashings);
    }
}

contract Rollup is RollupHelpers {
    /*********************
     * Constructor *
     ********************/
    constructor(address _registryAddr, bytes32 genesisStateRoot) public {
        nameRegistry = Registry(_registryAddr);

        logger = Logger(nameRegistry.getContractDetails(ParamManager.LOGGER()));
        depositManager = DepositManager(
            nameRegistry.getContractDetails(ParamManager.DEPOSIT_MANAGER())
        );

        governance = Governance(
            nameRegistry.getContractDetails(ParamManager.Governance())
        );
        merkleUtils = MTUtils(
            nameRegistry.getContractDetails(ParamManager.MERKLE_UTILS())
        );
        accountsTree = IncrementalTree(
            nameRegistry.getContractDetails(ParamManager.ACCOUNTS_TREE())
        );

        tokenRegistry = ITokenRegistry(
            nameRegistry.getContractDetails(ParamManager.TOKEN_REGISTRY())
        );

        fraudProof = IFraudProof(
            nameRegistry.getContractDetails(ParamManager.FRAUD_PROOF())
        );
        addNewBatch(ZERO_BYTES32, genesisStateRoot, Types.Usage.Genesis);
    }

    /**
     * @notice Submits a new batch to batches
     * @param _txs Compressed transactions .
     * @param _updatedRoot New balance tree root after processing all the transactions
     */
    function submitBatch(
        bytes[] calldata _txs,
        bytes32 _updatedRoot,
        Types.Usage batchType
    ) external payable onlyCoordinator isNotRollingBack {
        require(
            msg.value >= governance.STAKE_AMOUNT(),
            "Not enough stake committed"
        );

        require(
            _txs.length <= governance.MAX_TXS_PER_BATCH(),
            "Batch contains more transations than the limit"
        );
        bytes32 txRoot = merkleUtils.getMerkleRoot(_txs);
        require(
            txRoot != ZERO_BYTES32,
            "Cannot submit a transaction with no transactions"
        );
        addNewBatch(txRoot, _updatedRoot, batchType);
    }

    /**
     * @notice finalise deposits and submit batch
     */
    function finaliseDepositsAndSubmitBatch(
        uint256 _subTreeDepth,
        Types.AccountMerkleProof calldata _zero_account_mp
    ) external payable onlyCoordinator isNotRollingBack {
        bytes32 depositSubTreeRoot = depositManager.finaliseDeposits(
            _subTreeDepth,
            _zero_account_mp,
            getLatestBalanceTreeRoot()
        );
        // require(
        //     msg.value >= governance.STAKE_AMOUNT(),
        //     "Not enough stake committed"
        // );

        bytes32 updatedRoot = merkleUtils.updateLeafWithSiblings(
            depositSubTreeRoot,
            _zero_account_mp.accountIP.pathToAccount,
            _zero_account_mp.siblings
        );

        // add new batch
        addNewBatchWithDeposit(updatedRoot, depositSubTreeRoot);
    }

    /**
     *  disputeBatch processes a transactions and returns the updated balance tree
     *  and the updated leaves.
     * @notice Gives the number of batches submitted on-chain
     * @return Total number of batches submitted onchain
     */
    function disputeBatch(
        uint256 _batch_id,
        Types.Transaction[] memory _txs,
        Types.BatchValidationProofs memory batchProofs
    ) public {
        {
            // load batch
            require(
                batches[_batch_id].stakeCommitted != 0,
                "Batch doesnt exist or is slashed already"
            );

            // check if batch is disputable
            require(
                block.number < batches[_batch_id].finalisesOn,
                "Batch already finalised"
            );

            require(
                (_batch_id < invalidBatchMarker || invalidBatchMarker == 0),
                "Already successfully disputed. Roll back in process"
            );

            require(
                batches[_batch_id].txRoot != ZERO_BYTES32,
                "Cannot dispute blocks with no transaction"
            );
        }

        bytes32 updatedBalanceRoot;
        bool isDisputeValid;
        bytes32 txRoot;
        (updatedBalanceRoot, txRoot, isDisputeValid) = processBatch(
            batches[_batch_id - 1].stateRoot,
            batches[_batch_id - 1].accountRoot,
            _txs,
            batchProofs,
            batches[_batch_id].txRoot
        );

        // dispute is valid, we need to slash and rollback :(
        if (isDisputeValid) {
            // before rolling back mark the batch invalid
            // so we can pause and unpause
            invalidBatchMarker = _batch_id;
            SlashAndRollback();
            return;
        }

        // if new root doesnt match what was submitted by coordinator
        // slash and rollback
        if (updatedBalanceRoot != batches[_batch_id].stateRoot) {
            invalidBatchMarker = _batch_id;
            SlashAndRollback();
            return;
        }
    }

    function ApplyTx(
        Types.AccountMerkleProof memory _merkle_proof,
        bytes memory txBytes
    ) public view returns (bytes memory, bytes32 newRoot) {
        Types.Transaction memory transaction = RollupUtils.TxFromBytes(txBytes);
        return fraudProof.ApplyTx(_merkle_proof, transaction);
    }

    /**
     * @notice processTx processes a transactions and returns the updated balance tree
     *  and the updated leaves
     * conditions in require mean that the dispute be declared invalid
     * if conditons evaluate if the coordinator was at fault
     * @return Total number of batches submitted onchain
     */
    function processTx(
        bytes32 _balanceRoot,
        bytes32 _accountsRoot,
        bytes memory sig,
        bytes memory txBytes,
        Types.PDAMerkleProof memory _from_pda_proof,
        Types.AccountProofs memory accountProofs
    )
        public
        view
        returns (
            bytes32,
            bytes memory,
            bytes memory,
            Types.ErrorCode,
            bool
        )
    {
        Types.Transaction memory _tx = RollupUtils.TxFromBytes(txBytes);
        _tx.signature = sig;
        return
            fraudProof.processTx(
                _balanceRoot,
                _accountsRoot,
                _tx,
                _from_pda_proof,
                accountProofs
            );
    }

    /**
     * @notice processBatch processes a batch and returns the updated balance tree
     *  and the updated leaves
     * conditions in require mean that the dispute be declared invalid
     * if conditons evaluate if the coordinator was at fault
     * @return Total number of batches submitted onchain
     */
    function processBatch(
        bytes32 initialStateRoot,
        bytes32 accountsRoot,
        Types.Transaction[] memory _txs,
        Types.BatchValidationProofs memory batchProofs,
        bytes32 expectedTxRoot
    )
        public
        view
        returns (
            bytes32,
            bytes32,
            bool
        )
    {
        return
            fraudProof.processBatch(
                initialStateRoot,
                accountsRoot,
                _txs,
                batchProofs,
                expectedTxRoot
            );
    }

    /**
     * @notice Withdraw delay allows coordinators to withdraw their stake after the batch has been finalised
     * @param batch_id Batch ID that the coordinator submitted
     */
    function WithdrawStake(uint256 batch_id) public {
        Types.Batch memory committedBatch = batches[batch_id];
        require(
            committedBatch.stakeCommitted != 0,
            "Stake has been already withdrawn!!"
        );
        require(
            msg.sender == committedBatch.committer,
            "You are not the correct committer for this batch"
        );
        require(
            block.number > committedBatch.finalisesOn,
            "This batch is not yet finalised, check back soon!"
        );

        msg.sender.transfer(committedBatch.stakeCommitted);
        logger.logStakeWithdraw(
            msg.sender,
            committedBatch.stakeCommitted,
            batch_id
        );
        committedBatch.stakeCommitted = 0;
    }
}

/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */

pragma solidity ^0.5.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add 
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes_slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes_slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes_slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes_slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes_slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes_slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))
                
                for { 
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint _start,
        uint _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_bytes.length >= (_start + _length));

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint _start) internal  pure returns (address) {
        require(_bytes.length >= (_start + 20));
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint _start) internal  pure returns (uint8) {
        require(_bytes.length >= (_start + 1));
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint _start) internal  pure returns (uint16) {
        require(_bytes.length >= (_start + 2));
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint _start) internal  pure returns (uint32) {
        require(_bytes.length >= (_start + 4));
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint _start) internal  pure returns (uint64) {
        require(_bytes.length >= (_start + 8));
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint _start) internal  pure returns (uint96) {
        require(_bytes.length >= (_start + 12));
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint _start) internal  pure returns (uint128) {
        require(_bytes.length >= (_start + 16));
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint(bytes memory _bytes, uint _start) internal  pure returns (uint256) {
        require(_bytes.length >= (_start + 32));
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint _start) internal  pure returns (bytes32) {
        require(_bytes.length >= (_start + 32));
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes_slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes_slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

