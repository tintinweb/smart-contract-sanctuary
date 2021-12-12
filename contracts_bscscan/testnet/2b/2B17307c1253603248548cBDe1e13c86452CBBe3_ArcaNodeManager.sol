// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IterableMapping.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IArcaNodeManager.sol";


// TODO: This contract is a simple refactorizer of the NODERewardManagement contract, bugs in the NODERewardManagement contract are not fixed.
contract ArcaNodeManager is Ownable, IArcaNodeManager {
    using SafeMath for uint;
    using IterableMapping for IterableMapping.Map;

    struct NodeEntity {
        string name;
        uint creationTime;
        uint lastClaimTime;
        uint rewardAvailable;
    }

    IterableMapping.Map private nodeOwners;
    mapping(address => NodeEntity[]) private _nodesOfUser;

    uint public nodePrice;
    uint public rewardPerNode;
    uint public claimTime;

    bool public autoDistri = true;
    bool public distribution = false;

    uint public gasForDistribution = 300000;
    uint public lastDistributionCount = 0;
    uint public lastIndexProcessed = 0;

    uint public totalNodesCreated = 0;
    uint public totalRewardStaked = 0;


    constructor(uint _nodePrice, uint _rewardPerNode, uint _claimTime) {
        nodePrice = _nodePrice;
        rewardPerNode = _rewardPerNode;
        claimTime = _claimTime;
    }

    function distributeRewards() public returns (uint, uint, uint) {
        distribution = true;
        uint numberOfnodeOwners = nodeOwners.keys.length;
        require(numberOfnodeOwners > 0, "DISTRI REWARDS: NO NODE OWNERS");
        if (numberOfnodeOwners == 0) {
            return (0, 0, lastIndexProcessed);
        }

        uint gasUsed = 0;
        uint gasLeft = gasleft();
        uint newGasLeft;
        uint localLastIndex = lastIndexProcessed;
        uint iterations = 0;
        uint newClaimTime = block.timestamp;
        uint nodesCount;
        uint claims = 0;
        NodeEntity[] memory nodes;
        NodeEntity memory _node;

        while (gasUsed < gasForDistribution && iterations < numberOfnodeOwners) {
            localLastIndex++;
            if (localLastIndex >= nodeOwners.keys.length) {
                localLastIndex = 0;
            }
            nodes = _nodesOfUser[nodeOwners.keys[localLastIndex]];
            nodesCount = nodes.length;
            for (uint256 i = 0; i < nodesCount; i++) {
                _node = nodes[i];
                if (_claimable(_node)) {
                    _node.rewardAvailable += rewardPerNode;
                    _node.lastClaimTime = newClaimTime;
                    totalRewardStaked += rewardPerNode;
                    claims++;
                }
            }
            iterations++;

            newGasLeft = gasleft();

            if (gasLeft > newGasLeft) {
                gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            }

            gasLeft = newGasLeft;
        }
        lastIndexProcessed = localLastIndex;
        distribution = false;
        return (iterations, claims, lastIndexProcessed);
    }

    function createNode(address account, string memory nodeName) external override {
        require(_isNameAvailable(account, nodeName), "CREATE NODE: Name not available");
        NodeEntity memory node =  NodeEntity(
            {
                name: nodeName,
                creationTime: block.timestamp,
                lastClaimTime: block.timestamp,
                rewardAvailable: rewardPerNode
            }
        );
        _nodesOfUser[account].push(node);
        nodeOwners.set(account, _nodesOfUser[account].length);
        totalNodesCreated++;
        if (autoDistri && !distribution) {
            distributeRewards();
        }
    }

    function _isNameAvailable(address account, string memory nodeName) private view returns (bool) {
        NodeEntity[] storage nodes = _nodesOfUser[account];
        for (uint256 i = 0; i < nodes.length; i++) {
            if (keccak256(bytes(nodes[i].name)) == keccak256(bytes(nodeName))) {
                return false;
            }
        }
        return true;
    }

    // TODO Not use for instance
    function _burn(uint index) private {
        require(index < nodeOwners.size());
        nodeOwners.remove(nodeOwners.getKeyAtIndex(index));
    }
    // TODO: ? not code, fix it
    function _addReward(address account, uint amount) external {
        // TODO: add last reward node ?
    }

    function _getNodeWithCreatime(NodeEntity[] storage nodes, uint creationTime) private view returns (NodeEntity storage) {
        uint256 numberOfNodes = nodes.length;
        require(numberOfNodes > 0, "CASHOUT ERROR: You don't have nodes to cash-out");
        bool found = false;
        int index = _binarySearch(nodes, 0, numberOfNodes, creationTime);
        uint validIndex;
        if (index >= 0) {
            found = true;
            validIndex = uint(index);
        }
        require(found, "NODE SEARCH: No NODE Found with this blocktime");
        return nodes[validIndex];
    }

    function _binarySearch(NodeEntity[] memory arr, uint low, uint high, uint x) private view returns (int) {
        if (high >= low) {
            uint mid = (high + low).div(2);
            if (arr[mid].creationTime == x) {
                return int(mid);
            } else if (arr[mid].creationTime > x) {
                return _binarySearch(arr, low, mid - 1, x);
            } else {
                return _binarySearch(arr, mid + 1, high, x);
            }
        } else {
            return -1;
        }
    }

    function cashoutNodeReward(address account, uint creationTime) external override returns (uint) {
        require(creationTime > 0, "NODE: CREATIME must be higher than zero");
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint numberOfNodes = nodes.length;
        require(numberOfNodes > 0, "CASHOUT ERROR: You don't have nodes to cash-out");
        NodeEntity storage node = _getNodeWithCreatime(nodes, creationTime);
        uint256 rewardNode = node.rewardAvailable;
        node.rewardAvailable = 0;
        return rewardNode;
    }

    function cashoutAllNodesReward(address account) external override returns (uint){
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint nodesCount = nodes.length;
        require(nodesCount > 0, "NODE: CREATIME must be higher than zero");
        NodeEntity storage _node;
        uint rewardsTotal = 0;
        for (uint i = 0; i < nodesCount; i++) {
            _node = nodes[i];
            rewardsTotal += _node.rewardAvailable;
            _node.rewardAvailable = 0;
        }
        return rewardsTotal;
    }

    function _claimable(NodeEntity memory node) private view returns (bool) {
        return node.lastClaimTime + claimTime <= block.timestamp;
    }

    function getRewardAmountOf(address account) external override view returns (uint){
        require(isNodeOwner(account), "GET REWARD OF: NO NODE OWNER");
        uint nodesCount;
        uint rewardCount = 0;

        NodeEntity[] storage nodes = _nodesOfUser[account];
        nodesCount = nodes.length;

        for (uint256 i = 0; i < nodesCount; i++) {
            rewardCount += nodes[i].rewardAvailable;
        }

        return rewardCount;
    }

    function getRewardAmountOf(address account, uint creationTime) external override view returns (uint){
        require(isNodeOwner(account), "GET REWARD OF: NO NODE OWNER");
        require(creationTime > 0, "NODE: CREATIME must be higher than zero");
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint numberOfNodes = nodes.length;
        require(numberOfNodes > 0, "CASHOUT ERROR: You don't have nodes to cash-out");
        NodeEntity storage node = _getNodeWithCreatime(nodes, creationTime);
        uint rewardNode = node.rewardAvailable;
        return rewardNode;
    }

    function getNodeRewardAmountOf(address account, uint creationTime) external view returns (uint){
        return _getNodeWithCreatime(_nodesOfUser[account], creationTime).rewardAvailable;
    }

    function getNodesNames(address account) external view returns (string memory){
        require(isNodeOwner(account), "GET NAMES: NO NODE OWNER");
        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        string memory names = nodes[0].name;
        string memory separator = "#";
        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];
            names = string(abi.encodePacked(names, separator, _node.name));
        }
        return names;
    }
    // Todo refactor same fn getNodesNames /!\
    function getNodesCreationTime(address account) external view returns (string memory){
        require(isNodeOwner(account), "GET CREATIME: NO NODE OWNER");
        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        string memory creationTimes = Strings.toString(nodes[0].creationTime);
        string memory separator = "#";

        for (uint i = 1; i < nodesCount; i++) {
            _node = nodes[i];
            creationTimes = string(
                abi.encodePacked(creationTimes, separator, Strings.toString(_node.creationTime))
            );
        }
        return creationTimes;
    }
    // Todo refactor same fn getNodesCreationTime /!\
    function getNodesRewardAvailable(address account) external view returns (string memory){
        require(isNodeOwner(account), "GET REWARD: NO NODE OWNER");
        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        string memory _rewardsAvailable = Strings.toString(nodes[0].rewardAvailable);
        string memory separator = "#";

        for (uint i = 1; i < nodesCount; i++) {
            _node = nodes[i];
            _rewardsAvailable = string(
                abi.encodePacked(_rewardsAvailable, separator, Strings.toString(_node.rewardAvailable))
            );
        }
        return _rewardsAvailable;
    }

    function getNodesLastClaimTime(address account) external view returns (string memory) {
        require(isNodeOwner(account), "LAST CLAIME TIME: NO NODE OWNER");
        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        string memory _lastClaimTimes = Strings.toString(nodes[0].lastClaimTime);
        string memory separator = "#";

        for (uint i = 1; i < nodesCount; i++) {
            _node = nodes[i];
            _lastClaimTimes = string(
                abi.encodePacked(_lastClaimTimes, separator, Strings.toString(_node.lastClaimTime))
            );
        }
        return _lastClaimTimes;
    }

    function setNodePrice(uint price) external onlyOwner {
        nodePrice = price;
    }

    function setRewardPerNode(uint price) external onlyOwner {
        rewardPerNode = price;
    }

    function setClaimTime(uint time) external onlyOwner {
        claimTime = time;
    }

    function setAutoDistri(bool distri) external onlyOwner {
        autoDistri = distri;
    }

    function setGasDistri(uint gasDistri) external onlyOwner {
        gasForDistribution = gasDistri;
    }

    function getNodeNumberOf(address account) external view returns (uint) {
        return nodeOwners.get(account);
    }

    function isNodeOwner(address account) public view returns (bool) {
        return nodeOwners.get(account) > 0;
    }

    function getNodePrice() external override view returns(uint) {
        return nodePrice;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint256) values;
        mapping(address => uint256) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint256) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key)
    public
    view
    returns (int256)
    {
        if (!map.inserted[key]) {
            return - 1;
        }
        return int256(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint256 index)
    public
    view
    returns (address)
    {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint256) {
        return map.keys.length;
    }

    function set(
        Map storage map,
        address key,
        uint256 val
    ) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IArcaNodeManager {
    function getNodePrice() external returns(uint);
    function createNode(address account, string memory nodeName) external;
    function getRewardAmountOf(address account) external returns (uint);
    function getRewardAmountOf(address account, uint creationTime) external returns (uint);
    function cashoutNodeReward(address account, uint creationTime) external returns (uint);
    function cashoutAllNodesReward(address account) external returns (uint);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}