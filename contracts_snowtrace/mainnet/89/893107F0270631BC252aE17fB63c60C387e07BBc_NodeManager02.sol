// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/INodeManager.sol";

pragma solidity ^0.8.4;

contract NodeManager02 is Ownable, Pausable, ReentrancyGuard {
  using SafeMath for uint256;

  struct NodeEntity {
    string name;
    uint256 creationTime;
    uint256 lastClaimTime;
    uint256 lastCompoundTime;
    uint256 amount;
    bool deleted;
  }

  address public token;
  uint256 public rewardPerNode;
  uint256 public minPrice;

  uint256 public totalNodesCreated = 0;
  uint256 public totalStaked = 0;

  uint256[] private _boostMultipliers = [105, 120, 140];
  uint256[] private _boostRequiredDays = [3, 7, 15];
  INodeManager private nodeManager01;

  mapping(address => bool) public isAuthorizedAddress;
  mapping(address => NodeEntity[]) private _nodesOfUser;
  mapping(address => bool) private migratedWallets;

  event NodeIncreased(address indexed account, uint256 indexed amount);
  event NodeRenamed(address indexed account, string newName);
  event NodeCreated(
    address indexed account,
    uint256 indexed amount,
    uint256 indexed blockTime
  );
  event NodeMerged(
    address indexed account,
    uint256 indexed sourceBlockTime,
    uint256 indexed destBlockTime
  );

  modifier onlyAuthorized() {
    require(isAuthorizedAddress[_msgSender()], "UNAUTHORIZED");
    _;
  }

  constructor(
    uint256 _rewardPerNode,
    uint256 _minPrice,
    address _nodeManager01
  ) {
    rewardPerNode = _rewardPerNode;
    minPrice = _minPrice;

    isAuthorizedAddress[_msgSender()] = true;

    nodeManager01 = INodeManager(_nodeManager01);
  }

  // Private methods

  function _isNameAvailable(address account, string memory nodeName)
    private
    view
    returns (bool)
  {
    NodeEntity[] memory nodes = _nodesOfUser[account];
    for (uint256 i = 0; i < nodes.length; i++) {
      if (keccak256(bytes(nodes[i].name)) == keccak256(bytes(nodeName))) {
        return false;
      }
    }
    return true;
  }

  function _getNodeWithCreatime(
    NodeEntity[] storage nodes,
    uint256 _creationTime
  ) private view returns (NodeEntity storage) {
    uint256 numberOfNodes = nodes.length;
    require(
      numberOfNodes > 0,
      "CASHOUT ERROR: You don't have nodes to cash-out"
    );
    bool found = false;
    int256 index = _binarySearch(nodes, 0, numberOfNodes, _creationTime);
    uint256 validIndex;
    if (index >= 0) {
      found = true;
      validIndex = uint256(index);
    }
    require(found, "NODE SEARCH: No NODE Found with this blocktime");
    return nodes[validIndex];
  }

  function _binarySearch(
    NodeEntity[] memory arr,
    uint256 low,
    uint256 high,
    uint256 x
  ) private view returns (int256) {
    if (high >= low) {
      uint256 mid = (high + low).div(2);
      if (arr[mid].creationTime == x) {
        return int256(mid);
      } else if (arr[mid].creationTime > x) {
        return _binarySearch(arr, low, mid - 1, x);
      } else {
        return _binarySearch(arr, mid + 1, high, x);
      }
    } else {
      return -1;
    }
  }

  function _uint2str(uint256 _i)
    private
    pure
    returns (string memory _uintAsString)
  {
    if (_i == 0) {
      return "0";
    }
    uint256 j = _i;
    uint256 len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint256 k = len;
    while (_i != 0) {
      k = k - 1;
      uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      _i /= 10;
    }
    return string(bstr);
  }

  function _calculateNodeRewards(
    uint256 _lastClaimTime,
    uint256 _lastCompoundTime,
    uint256 amount_
  ) public view returns (uint256) {
    uint256 elapsedTime_ = (block.timestamp - _lastCompoundTime);
    uint256 _boostMultiplier = _calculateBoost(_lastClaimTime);
    uint256 rewardPerDay = amount_.mul(rewardPerNode).div(100);
    uint256 elapsedMinutes = elapsedTime_ / 1 minutes;
    uint256 rewardPerMinute = rewardPerDay.mul(10000).div(1440);

    return
      rewardPerMinute.mul(elapsedMinutes).div(10000).mul(_boostMultiplier).div(
        100
      );
  }

  function _calculateBoost(uint256 _lastClaimTime)
    public
    view
    returns (uint256)
  {
    uint256 elapsedTime_ = (block.timestamp - _lastClaimTime);
    uint256 elapsedTimeInDays_ = elapsedTime_ / 1 days;

    if (elapsedTimeInDays_ >= _boostRequiredDays[2]) {
      return _boostMultipliers[2];
    } else if (elapsedTimeInDays_ >= _boostRequiredDays[1]) {
      return _boostMultipliers[1];
    } else if (elapsedTimeInDays_ >= _boostRequiredDays[0]) {
      return _boostMultipliers[0];
    } else {
      return 100;
    }
  }

  // External methods

  function createNode(
    address account,
    string memory nodeName,
    uint256 amount_
  ) external onlyAuthorized whenNotPaused {
    require(_isNameAvailable(account, nodeName), "Name not available");
    NodeEntity[] storage _nodes = _nodesOfUser[account];
    require(_nodes.length <= 100, "Max nodes exceeded");
    _nodes.push(
      NodeEntity({
        name: nodeName,
        creationTime: block.timestamp,
        lastClaimTime: block.timestamp,
        lastCompoundTime: block.timestamp,
        amount: amount_,
        deleted: false
      })
    );

    totalNodesCreated++;
    totalStaked += amount_;

    emit NodeCreated(account, amount_, block.timestamp);
  }

  function cashoutNodeReward(address account, uint256 _creationTime)
    external
    onlyAuthorized
    whenNotPaused
  {
    require(_creationTime > 0, "NODE: CREATIME must be higher than zero");
    NodeEntity[] storage nodes = _nodesOfUser[account];
    require(
      nodes.length > 0,
      "CASHOUT ERROR: You don't have nodes to cash-out"
    );
    NodeEntity storage node = _getNodeWithCreatime(nodes, _creationTime);
    require(!node.deleted, "DELETED");
    node.lastClaimTime = block.timestamp;
    node.lastCompoundTime = block.timestamp;
  }

  function compoundNodeReward(
    address account,
    uint256 _creationTime,
    uint256 rewardAmount_
  ) external onlyAuthorized whenNotPaused {
    require(_creationTime > 0, "NODE: CREATIME must be higher than zero");
    NodeEntity[] storage nodes = _nodesOfUser[account];
    require(
      nodes.length > 0,
      "CASHOUT ERROR: You don't have nodes to cash-out"
    );
    NodeEntity storage node = _getNodeWithCreatime(nodes, _creationTime);
    require(!node.deleted, "DELETED");
    node.amount += rewardAmount_;
    node.lastCompoundTime = block.timestamp;
  }

  function cashoutAllNodesRewards(address account)
    external
    onlyAuthorized
    whenNotPaused
  {
    NodeEntity[] storage nodes = _nodesOfUser[account];
    uint256 nodesCount = nodes.length;
    require(nodesCount > 0, "NODE: CREATIME must be higher than zero");
    NodeEntity storage _node;
    for (uint256 i = 0; i < nodesCount; i++) {
      _node = nodes[i];
      if (!_node.deleted) {
        _node.lastClaimTime = block.timestamp;
        _node.lastCompoundTime = block.timestamp;
      }
    }
  }

  function compoundAllNodesRewards(address account)
    external
    onlyAuthorized
    whenNotPaused
  {
    NodeEntity[] storage nodes = _nodesOfUser[account];
    uint256 nodesCount = nodes.length;
    require(nodesCount > 0, "NODE: CREATIME must be higher than zero");
    NodeEntity storage _node;
    for (uint256 i = 0; i < nodesCount; i++) {
      _node = nodes[i];
      if (!_node.deleted) {
        uint256 rewardAmount = getNodeReward(account, _node.creationTime);
        _node.amount += rewardAmount;
        _node.lastCompoundTime = block.timestamp;
      }
    }
  }

  function renameNode(
    address account,
    string memory _newName,
    uint256 _creationTime
  ) external onlyAuthorized whenNotPaused {
    require(_isNameAvailable(account, _newName), "Name not available");
    require(_creationTime > 0, "NODE: CREATIME must be higher than zero");
    NodeEntity[] storage nodes = _nodesOfUser[account];
    require(
      nodes.length > 0,
      "CASHOUT ERROR: You don't have nodes to cash-out"
    );
    NodeEntity storage node = _getNodeWithCreatime(nodes, _creationTime);
    require(!node.deleted, "DELETED");
    node.name = _newName;
  }

  function mergeNodes(
    address account,
    uint256 _creationTime1,
    uint256 _creationTime2
  ) external onlyAuthorized whenNotPaused {
    require(_creationTime1 > 0 && _creationTime2 > 0, "MERGE:1");
    NodeEntity[] storage nodes = _nodesOfUser[account];
    require(
      nodes.length > 0,
      "CASHOUT ERROR: You don't have nodes to cash-out"
    );
    NodeEntity storage node1 = _getNodeWithCreatime(nodes, _creationTime1);
    NodeEntity storage node2 = _getNodeWithCreatime(nodes, _creationTime2);

    node1.amount += node2.amount;
    node1.lastClaimTime = block.timestamp;
    node1.lastCompoundTime = block.timestamp;

    node2.deleted = true;
    totalNodesCreated--;

    emit NodeMerged(account, _creationTime2, _creationTime1);
  }

  function increaseNodeAmount(
    address account,
    uint256 _creationTime,
    uint256 _amount
  ) external onlyAuthorized whenNotPaused {
    require(_creationTime > 0, "NODE: CREATIME must be higher than zero");
    NodeEntity[] storage nodes = _nodesOfUser[account];
    require(
      nodes.length > 0,
      "CASHOUT ERROR: You don't have nodes to cash-out"
    );
    NodeEntity storage node = _getNodeWithCreatime(nodes, _creationTime);
    require(!node.deleted, "DELETED");
    node.amount += _amount;
    node.lastCompoundTime = block.timestamp;
  }

  function migrateNodes(address account) external whenNotPaused nonReentrant {
    require(!migratedWallets[account], "Already migrated");
    INodeManager.NodeEntity[] memory oldNodes = nodeManager01.getAllNodes(
      account
    );
    require(oldNodes.length > 0, "LENGTH");
    NodeEntity[] storage _nodes = _nodesOfUser[account];
    require(_nodes.length + oldNodes.length <= 100, "Max nodes exceeded");

    for (uint256 index = 0; index < oldNodes.length; index++) {
      _nodes.push(
        NodeEntity({
          name: oldNodes[index].name,
          creationTime: oldNodes[index].creationTime,
          lastClaimTime: oldNodes[index].lastClaimTime,
          lastCompoundTime: oldNodes[index].lastClaimTime,
          amount: oldNodes[index].amount,
          deleted: false
        })
      );

      totalNodesCreated++;
      totalStaked += oldNodes[index].amount;
      migratedWallets[account] = true;

      emit NodeCreated(account, oldNodes[index].amount, block.timestamp);
    }
  }

  // Setters & Getters

  function setToken(address newToken) external onlyOwner {
    token = newToken;
  }

  function setRewardPerNode(uint256 newVal) external onlyOwner {
    rewardPerNode = newVal;
  }

  function setMinPrice(uint256 newVal) external onlyOwner {
    minPrice = newVal;
  }

  function setBoostMultipliers(uint8[] calldata newVal) external onlyOwner {
    require(newVal.length == 3, "Wrong length");
    _boostMultipliers = newVal;
  }

  function setBoostRequiredDays(uint8[] calldata newVal) external onlyOwner {
    require(newVal.length == 3, "Wrong length");
    _boostRequiredDays = newVal;
  }

  function setAuthorized(address account, bool newVal) external onlyOwner {
    isAuthorizedAddress[account] = newVal;
  }

  function getMinPrice() external view returns (uint256) {
    return minPrice;
  }

  function getNodeNumberOf(address account) external view returns (uint256) {
    return _nodesOfUser[account].length;
  }

  function getAllNodes(address account)
    external
    view
    returns (NodeEntity[] memory)
  {
    return _nodesOfUser[account];
  }

  function getAllNodesAmount(address account) external view returns (uint256) {
    NodeEntity[] memory nodes = _nodesOfUser[account];
    uint256 nodesCount = nodes.length;
    require(nodesCount > 0, "NO_NODES");
    uint256 totalAmount_ = 0;
    for (uint256 i = 0; i < nodesCount; i++) {
      if (!nodes[i].deleted) {
        totalAmount_ += nodes[i].amount;
      }
    }

    return totalAmount_;
  }

  function getNodeReward(address account, uint256 _creationTime)
    public
    view
    returns (uint256)
  {
    require(_creationTime > 0, "E:1");
    NodeEntity[] storage nodes = _nodesOfUser[account];
    require(nodes.length > 0, "E:2");
    NodeEntity storage node = _getNodeWithCreatime(nodes, _creationTime);
    require(!node.deleted, "DELETED");
    return
      _calculateNodeRewards(
        node.lastClaimTime,
        node.lastCompoundTime,
        node.amount
      );
  }

  function getAllNodesRewards(address account) external view returns (uint256) {
    NodeEntity[] storage nodes = _nodesOfUser[account];
    uint256 nodesCount = nodes.length;
    require(nodesCount > 0, "E:1");
    NodeEntity storage _node;
    uint256 rewardsTotal = 0;
    for (uint256 i = 0; i < nodesCount; i++) {
      _node = nodes[i];
      if (!_node.deleted) {
        rewardsTotal += _calculateNodeRewards(
          _node.lastClaimTime,
          _node.lastCompoundTime,
          _node.amount
        );
      }
    }
    return rewardsTotal;
  }

  // Firewall methods

  function pause() external onlyAuthorized {
    _pause();
  }

  function unpause() external onlyAuthorized {
    _unpause();
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INodeManager {
  struct NodeEntity {
    string name;
    uint256 creationTime;
    uint256 lastClaimTime;
    uint256 amount;
  }

  function getMinPrice() external view returns (uint256);

  function createNode(
    address account,
    string memory nodeName,
    uint256 amount
  ) external;

  function getNodeReward(address account, uint256 _creationTime)
    external
    view
    returns (uint256);

  function getAllNodesRewards(address account) external view returns (uint256);

  function cashoutNodeReward(address account, uint256 _creationTime) external;

  function cashoutAllNodesRewards(address account) external;

  function compoundNodeReward(
    address account,
    uint256 creationTime,
    uint256 rewardAmount
  ) external;

  function getAllNodes(address account)
    external
    view
    returns (NodeEntity[] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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