//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IterableMapping.sol";

contract ServiceV1 {
  event Claimed(address indexed miner, uint256 reward);
  event Paid(address indexed entity, uint128 nodeId, uint256 upToBlockNumber);

  using IterableMapping for IterableMapping.Map;

  struct NodeEntity {
      string name;
      uint256 creationBlockNumber;
      uint256 lastClaimBlockNumber;
      uint256 lastPaidBlockNumber;
  }
  
  mapping(address => NodeEntity[]) public _nodesOfUser; // TODO change to private
  mapping(address => bool) public _isBlacklisted;

  IterableMapping.Map private nodeOwners;

  IERC20 public nodeifyToken;
  address public admin = 0xE5CaB58b538CC570388bF8550B5Ecb71A824EFB4;
  address public feeCollectorAddress = 0x0788a572c51802eEF7d198afaD100627B59e9DEC;
  uint128 public maxNodesPerAddress = 100;
  uint256 public nodePrice = 100000000000000000000;
  uint256 public totalNodesCreated;
  uint128 public rewardPerBlock = 10000000000000;
  uint128 public maxPaymentPeriods = 3;
  uint256 public startingReward = 0;
  uint256 public rewardBalance;
  uint256 public gracePeriodInBlocks = 70000;
  uint256 public recurringPaymentCycleInBlocks = 210000;

  constructor(address _nodeifyTokenAddress) {
    nodeifyToken = IERC20(_nodeifyTokenAddress);
  }

    function createNodeWithTokens(string memory name) public payable {
        require(
            bytes(name).length > 3 && bytes(name).length < 32,
            "Name Size Invalid"
        );
        address sender = msg.sender;
        require(
            sender != address(0),
            "Creation from the zero address"
        );
        require(!_isBlacklisted[sender], "Blacklisted address");
        require(
            nodeifyToken.balanceOf(sender) >= nodePrice,
            "Balance too low for creation"
        );

        nodeifyToken.transferFrom(sender, address(this), nodePrice);
        createNode(sender, name);
    }

  function claimAll(uint256 blockNumber) public payable {
    uint256 value = msg.value;
    for (uint16 i = 0; i <= _nodesOfUser[msg.sender].length; i++) {
      uint256 reward = getRewardByBlock(msg.sender, i, blockNumber);
      uint256 fee = (reward * 3) / 50;
      require(value >= fee, "invalid fee");
      if (reward > 0) {
        this.claim(msg.sender, i, blockNumber);
      }
      value = value - fee;
    }
  }

  modifier onlyOwner {
    require(msg.sender == admin, "Not Owner");
    _;
  }

  modifier nonNillValue(uint256 _amount) {
    require(_amount > 0, "Not Nill Value");
    _;
  }

  function deposit(uint256 amount) public onlyOwner nonNillValue(amount) {
    nodeifyToken.transferFrom(msg.sender, address(this), amount);
    rewardBalance = rewardBalance + amount;
  }

  function withdraw(address destination, uint256 amount) public onlyOwner nonNillValue(amount) {
    require(rewardBalance >= amount, "not enough");
    rewardBalance = rewardBalance - amount;
    nodeifyToken.transfer(destination, amount);
  }

  function claim(address entity, uint128 nodeId, uint256 blockNumber) public payable returns (bool) {
    address sender = msg.sender;
    uint256 blockLastClaimedOn = _nodesOfUser[entity][nodeId].lastClaimBlockNumber;
    // uint256 blockLastPaidOn = _nodesOfUser[entity][nodeId].lastPaidBlockNumber;

    // TODO add more checks here
    require(blockNumber <= block.number, "invalid block");
    require(blockNumber > blockLastClaimedOn, "too soon");

    uint256 reward = getRewardByBlock(sender, nodeId, blockNumber);
    require(reward > 0, "no reward");

    uint256 fee = reward * 3 / 50;
    require(msg.value >= fee, "invalid fee");

    _nodesOfUser[entity][nodeId].lastClaimBlockNumber = blockNumber;

    rewardBalance = rewardBalance - reward;
    payable(feeCollectorAddress).transfer(msg.value);
    nodeifyToken.transfer(sender, reward);

    emit Claimed(sender, reward);

    return true;
  }

  function canBePaid(address entity, uint128 nodeId) public view returns (bool) {
    return !hasNodeExpired(entity, nodeId) && !hasMaxPayments(entity, nodeId);
  }

  function doesNodeExist(address entity, uint128 nodeId) public view returns (bool) {
    return _nodesOfUser[entity][nodeId].lastPaidBlockNumber > 0;
  }

  function hasNodeExpired(address entity, uint128 nodeId) public view returns (bool) {
    uint256 blockLastPaidOn = _nodesOfUser[entity][nodeId].lastPaidBlockNumber;
    if (doesNodeExist(entity, nodeId) == false) return true;

    return block.number > blockLastPaidOn + recurringPaymentCycleInBlocks + gracePeriodInBlocks;
  }

  function hasMaxPayments(address entity, uint128 nodeId) public view returns (bool) {
    uint256 blockLastPaidOn = _nodesOfUser[entity][nodeId].lastPaidBlockNumber;
    uint256 limit = block.number + recurringPaymentCycleInBlocks * maxPaymentPeriods;

    return blockLastPaidOn + recurringPaymentCycleInBlocks >= limit;
  }

  function payAll(uint256 nodeCount) public payable {
    require(nodeCount > 0, "invalid value");
    require(msg.value == 2929616229135700 * nodeCount, "invalid fee");

    for (uint16 nodeId = 0; nodeId <= _nodesOfUser[msg.sender].length; nodeId++) {
      if (!canBePaid(msg.sender, nodeId)) {
        continue;
      }

      payFee(nodeId);
      nodeCount = nodeCount - 1;
    }

    require(nodeCount == 0, "invalid count");
  }

  function payFee(uint128 nodeId) public payable {
    address sender = msg.sender;

    require(doesNodeExist(sender, nodeId), "doesnt exist");
    require(hasNodeExpired(sender, nodeId) == false, "too late");
    require(hasMaxPayments(sender, nodeId) == false, "too soon");
    
    
    _nodesOfUser[sender][nodeId].lastPaidBlockNumber = block.number;
    payable(feeCollectorAddress).transfer(msg.value);

    emit Paid(sender, nodeId, _nodesOfUser[sender][nodeId].lastPaidBlockNumber + recurringPaymentCycleInBlocks);
  }

    function createNode(address account, string memory nodeName) internal {
        require(
            isNameAvailable(account, nodeName),
            "CREATE NODE: Name not available"
        );
        _nodesOfUser[account].push(
            NodeEntity({
                name: nodeName,
                creationBlockNumber: block.number,
                lastClaimBlockNumber: block.number,
                lastPaidBlockNumber: block.number
            })
        );
        nodeOwners.set(account, _nodesOfUser[account].length);
        totalNodesCreated++;
    }

    function isNameAvailable(address account, string memory nodeName)
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

  function getReward(address entity, uint128 nodeId) public view returns (uint256) {
    return getRewardByBlock(entity, nodeId, block.number);
  }

  function getRewardAll(address entity, uint256 blockNumber) public view returns (uint256) {
    uint256 rewardsAll;

    for (uint128 i = 0; i <= _nodesOfUser[entity].length; i++) {
      rewardsAll = rewardsAll + getRewardByBlock(entity, i, blockNumber > 0 ? blockNumber : block.number);
    }

    return rewardsAll;
  }

  function getRewardByBlock(address entity, uint128 nodeId, uint256 blockNumber) public view returns (uint256) {
    uint256 blockLastClaimedOn = _nodesOfUser[entity][nodeId].lastClaimBlockNumber;
    // TODO add many checks here to ensure the reward is correct
    if (hasNodeExpired(entity, nodeId)) return 0;
    if (blockNumber > block.number) return 0;
    if (blockLastClaimedOn == 0) return 0;
    if (blockNumber < blockLastClaimedOn) return 0;

    uint256 reward = (blockNumber - blockLastClaimedOn) * rewardPerBlock;
    return reward;
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

//SPDX-License-Identifier: Unlicense
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
            return -1;
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