/**
 *Submitted for verification at Etherscan.io on 2021-07-13
*/

// File: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/Receipts.sol

pragma solidity 0.6.12;

contract Receipts {
    struct Receipt {
        address asset;// ERC20 Token Address
        address owner;// Sender
        string targetAddress;// User address in aelf
        uint256 amount;// Locking amount
    }

    uint256 public receiptCount = 0;
    Receipt[] public receipts;
    uint256 public totalAmountInReceipts = 0;
}

// File: @openzeppelin/contracts/math/SafeMath.sol


pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: contracts/merkle.sol

pragma solidity 0.6.12;

contract MerkleTreeGenerator is Ownable {

    using SafeMath for uint256;

    uint256 constant pathMaximalLength = 10;
    uint256 constant public MerkleTreeMaximalLeafCount = 1 << pathMaximalLength;
    uint256 constant TreeMaximalSize = MerkleTreeMaximalLeafCount * 2;
    uint256 public merkleTreeCount = 0;
    uint256 public receiptCountInTree = 0;

    mapping(uint256 => ReceiptCollection) receiptCollections;

    Receipts receiptProvider;
    address public receiptProviderAddress;

    struct MerkleTree {
        bytes32 root;
        uint256 leaf_count;
        uint256 first_receipt_id;
        uint256 size;
    }

    struct ReceiptCollection {
        uint256 first_receipt_id;
        uint256 receipt_count;
        uint256 tree_size;
    }

    constructor (Receipts _lock) public {
        receiptProviderAddress = address(_lock);
        receiptProvider = _lock;
    }

    //fetch receipts
    function _receiptsToLeaves(uint256 _start, uint256 _leafCount) private view returns (bytes32[] memory){
        bytes32[] memory leaves = new bytes32[](_leafCount);

        for (uint256 i = _start; i < _start + _leafCount; i++) {
            (
            ,
            ,
            string memory targetAddress,
            uint256 amount
            ) = receiptProvider.receipts(i);

            bytes32 amountHash = sha256(abi.encodePacked(amount));
            bytes32 targetAddressHash = sha256(abi.encodePacked(targetAddress));
            bytes32 receiptIdHash = sha256(abi.encodePacked(i));

            leaves[i - _start] = (sha256(abi.encode(amountHash, targetAddressHash, receiptIdHash)));
        }

        return leaves;
    }

    function recordReceipts() external onlyOwner {
        uint256 receiptCount = receiptProvider.receiptCount().sub(receiptCountInTree);
        require(receiptCount > 0, "[MERKLE]No receipts.");
        uint256 leafCount = receiptCount < MerkleTreeMaximalLeafCount ? receiptCount : MerkleTreeMaximalLeafCount;
        ReceiptCollection memory receiptCollection = ReceiptCollection(receiptCountInTree, leafCount, TreeMaximalSize);
        receiptCollections[merkleTreeCount] = receiptCollection;
        receiptCountInTree = receiptCountInTree.add(leafCount);
        merkleTreeCount = merkleTreeCount.add(1);
    }

    function getMerkleTree(uint256 _treeIndex) public view returns (bytes32, uint256, uint256, uint256, bytes32[] memory){
        require(_treeIndex < merkleTreeCount);
        ReceiptCollection memory receiptCollection = receiptCollections[_treeIndex];
        MerkleTree memory merkleTree;
        bytes32[] memory treeNodes;
        (merkleTree, treeNodes) = _generateMerkleTree(receiptCollection.first_receipt_id, receiptCollection.receipt_count,receiptCollection.tree_size);
        return (merkleTree.root, merkleTree.first_receipt_id, merkleTree.leaf_count, merkleTree.size, treeNodes);
    }

    //get users merkle tree path
    function generateMerklePath(uint256 _receiptId) public view returns (uint256, uint256, bytes32[] memory, bool[] memory) {
        require(_receiptId < receiptCountInTree);

        uint256 treeIndex = merkleTreeCount - 1;
        for (; treeIndex >= 0; treeIndex--) {
            if (_receiptId >= receiptCollections[treeIndex].first_receipt_id)
                break;
        }

        ReceiptCollection memory receiptCollection = receiptCollections[treeIndex];
        MerkleTree memory merkleTree;
        (merkleTree,) = _generateMerkleTree(receiptCollection.first_receipt_id, receiptCollection.receipt_count, receiptCollection.tree_size);
        uint256 index = _receiptId - merkleTree.first_receipt_id;

        uint256 pathLength;
        bytes32[pathMaximalLength] memory path;
        bool[pathMaximalLength] memory isLeftNeighbors;
        (pathLength, path, isLeftNeighbors) = _generatePath(merkleTree, index, receiptCollection.tree_size);

        bytes32[] memory neighbors = new bytes32[](pathLength);
        bool[] memory positions = new bool[](pathLength);

        for (uint256 i = 0; i < pathLength; i++) {
            neighbors[i] = path[i];
            positions[i] = isLeftNeighbors[i];
        }
        return (treeIndex, pathLength, neighbors, positions);
    }

    function _generateMerkleTree(uint256 _firstReceiptId, uint256 _leafCount, uint256 treeMaximalSize) private view returns (MerkleTree memory, bytes32[] memory) {
        bytes32[] memory leafNodes = _receiptsToLeaves(_firstReceiptId, _leafCount);
        bytes32[] memory allNodes;
        uint256 nodeCount;

        (allNodes, nodeCount) = _leavesToTree(leafNodes, treeMaximalSize);
        MerkleTree memory merkleTree = MerkleTree(allNodes[nodeCount - 1], _leafCount, _firstReceiptId, nodeCount);

        bytes32[] memory treeNodes = new bytes32[](nodeCount);
        for (uint256 t = 0; t < nodeCount; t++) {
            treeNodes[t] = allNodes[t];
        }
        return (merkleTree, treeNodes);
    }

    function _generatePath(MerkleTree memory _merkleTree, uint256 _index, uint256 treeMaximalSize) private view returns (uint256, bytes32[pathMaximalLength] memory, bool[pathMaximalLength] memory){

        bytes32[] memory leaves = _receiptsToLeaves(_merkleTree.first_receipt_id, _merkleTree.leaf_count);
        bytes32[] memory allNodes;
        uint256 nodeCount;

        (allNodes, nodeCount) = _leavesToTree(leaves, treeMaximalSize);
        require(nodeCount == _merkleTree.size);

        bytes32[] memory nodes = new bytes32[](_merkleTree.size);
        for (uint256 t = 0; t < _merkleTree.size; t++) {
            nodes[t] = allNodes[t];
        }

        return _generatePath(nodes, _merkleTree.leaf_count, _index);
    }

    function _generatePath(bytes32[] memory _nodes, uint256 _leafCount, uint256 _index) private pure returns (uint256, bytes32[pathMaximalLength] memory, bool[pathMaximalLength] memory){
        bytes32[pathMaximalLength] memory neighbors;
        bool[pathMaximalLength] memory isLeftNeighbors;
        uint256 indexOfFirstNodeInRow = 0;
        uint256 nodeCountInRow = _leafCount;
        bytes32 neighbor;
        bool isLeftNeighbor;
        uint256 shift;
        uint256 i = 0;

        while (_index < _nodes.length.sub(1)) {

            if (_index.mod(2) == 0)
            {
                // add right neighbor node
                neighbor = _nodes[_index.add(1)];
                isLeftNeighbor = false;
            }
            else
            {
                // add left neighbor node
                neighbor = _nodes[_index.sub(1)];
                isLeftNeighbor = true;
            }

            neighbors[i] = neighbor;
            isLeftNeighbors[i] = isLeftNeighbor;
            i = i.add(1);

            nodeCountInRow = nodeCountInRow.mod(2) == 0 ? nodeCountInRow : nodeCountInRow.add(1);
            shift = _index.sub(indexOfFirstNodeInRow).div(2);
            indexOfFirstNodeInRow = indexOfFirstNodeInRow.add(nodeCountInRow);
            _index = indexOfFirstNodeInRow.add(shift);
            nodeCountInRow =nodeCountInRow.div(2);
        }

        return (i, neighbors, isLeftNeighbors);
    }

    function _leavesToTree(bytes32[] memory _leaves, uint256 maximalTreeSize) private pure returns (bytes32[] memory, uint256){
        uint256 leafCount = _leaves.length;
        bytes32 left;
        bytes32 right;

        uint256 newAdded = 0;
        uint256 i = 0;

        bytes32[] memory nodes = new bytes32[](maximalTreeSize);

        for (uint256 t = 0; t < leafCount; t++)
        {
            nodes[t] = _leaves[t];
        }

        uint256 nodeCount = leafCount;
        if (_leaves.length.mod(2) == 1) {
            nodes[leafCount] = (_leaves[leafCount.sub(1)]);
            nodeCount = nodeCount.add(1);
        }

        // uint256 nodeToAdd = nodes.length / 2;
        uint256 nodeToAdd = nodeCount.div(2);

        while (i < nodeCount.sub(1)) {

            left = nodes[i];
            i = i.add(1);

            right = nodes[i];
            i = i.add(1);

            nodes[nodeCount] = sha256(abi.encode(left, right));
            nodeCount = nodeCount.add(1);

            if (++newAdded != nodeToAdd)
                continue;

            if (nodeToAdd.mod(2) == 1 && nodeToAdd != 1)
            {
                nodeToAdd = nodeToAdd.add(1);
                nodes[nodeCount] = nodes[nodeCount.sub(1)];
                nodeCount = nodeCount.add(1);
            }

            nodeToAdd = nodeToAdd.div(2);
            newAdded = 0;
        }

        return (nodes, nodeCount);
    }
}