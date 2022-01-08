// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./OldNODERewardManagement.sol";

contract NODERewardManagement {
    using SafeMath for uint256;
    using IterableMapping for IterableMapping.Map;
    bytes tempNum;
    uint256[] numbers;

    modifier onlyManager() {
        require(_managers[msg.sender] == true, "Only managers can call this function");
        _;
    }

    struct NewNodeEntity {
        uint256 id;
        uint256 creationTime;
        uint256 lastClaimTime;
        uint256 rewardNotClaimed;
    }
    
    IterableMapping.Map private nodeOwners;
    mapping(address => NewNodeEntity[]) private _nodesOfUser;
    mapping(address => bool) public _managers;

    uint256 public nodePrice;
    uint256 public rewardsPerMinute;
    uint256 public claimInterval;

    uint256 public lastIndexProcessed = 0;

    uint256 public totalNodesCreated = 0;
    uint256 public totalRewardStaked = 0;

    event NodeCreated(address indexed from, uint256 id, uint256 index, uint256 totalNodesCreated);


    constructor(
        uint256 _nodePrice,
        uint256 _rewardsPerMinute,
        uint256 _claimInterval
    ) {
        _managers[msg.sender] = true;
        nodePrice = _nodePrice;
        rewardsPerMinute = _rewardsPerMinute;
        claimInterval = _claimInterval;
    }

    function addManager(address manager) external onlyManager {
        _managers[manager] = true;
    }

    function createNode(address account, string memory nodeName, uint256 expireTime) external onlyManager {
        uint256 realExpireTime = 0;
        if (expireTime > 0) {
            realExpireTime = block.timestamp + expireTime;
        }
        _nodesOfUser[account].push(
            NewNodeEntity({
        id : totalNodesCreated + 1,
        creationTime : block.timestamp,
        lastClaimTime : block.timestamp,
        rewardNotClaimed : 0
        })
        );
        totalNodesCreated++;
        emit NodeCreated(account, totalNodesCreated, _nodesOfUser[account].length, totalNodesCreated);
    }

    function createNodes(address account, uint256 numberOfNodes) external onlyManager {
        require(
            numberOfNodes > 0,
            "createNodes ERROR numberOfNodes cant be zero"
        );

        for (uint256 i = 0; i < numberOfNodes; i++) {
            _nodesOfUser[account].push(
                NewNodeEntity({
            id : totalNodesCreated + 1,
            creationTime : block.timestamp + i,
            lastClaimTime : block.timestamp + i,
            rewardNotClaimed : 0
            })
            );

            nodeOwners.set(account, _nodesOfUser[account].length);
            totalNodesCreated++;
            //emit NodeCreated(account, totalNodesCreated, _nodesOfUser[account].length, totalNodesCreated);
        }
        // emit NodeCreated(account, totalNodesCreated, _nodesOfUser[account].length, totalNodesCreated);
    }

    function burn(address account, uint256 index) external onlyManager {

        uint256 numberOfNodes = _nodesOfUser[account].length;
        require(
            numberOfNodes > 0,
            "CASHOUT ERROR: You don't have nodes"
        );

        require(index < numberOfNodes);
        nodeOwners.remove(nodeOwners.getKeyAtIndex(index));
    }

    function getNodeInfo(
        address account,
        uint256 id
    ) public view returns (NewNodeEntity memory) {

        NewNodeEntity[] storage nodes = _nodesOfUser[account];
        require(
            nodes.length > 0,
            "CASHOUT ERROR: You don't have nodes"
        );

        bool found = false;
        int256 index = binary_search(nodes, 0, nodes.length, id);
        uint256 validIndex;
        if (index >= 0) {
            found = true;
            validIndex = uint256(index);
        }
        require(found, "NODE SEARCH: No NODE Found with this blocktime");
        return nodes[validIndex];
    }

    function _getNodeWithCreatime(
        NewNodeEntity[] storage nodes,
        uint256 id
    ) private view returns (NewNodeEntity storage) {
        uint256 numberOfNodes = nodes.length;
        require(
            numberOfNodes > 0,
            "CASHOUT ERROR: You don't have nodes to cash-out"
        );
        bool found = false;
        int256 index = binary_search(nodes, 0, numberOfNodes, id);
        uint256 validIndex;
        if (index >= 0) {
            found = true;
            validIndex = uint256(index);
        }
        require(found, "NODE SEARCH: No NODE Found with this blocktime");
        return nodes[validIndex];
    }

    function binary_search(
        NewNodeEntity[] memory arr,
        uint256 low,
        uint256 high,
        uint256 x
    ) private view returns (int256) {
        if (high >= low) {
            uint256 mid = (high + low).div(2);
            if (arr[mid].id == x) {
                return int256(mid);
            } else if (arr[mid].id > x) {
                return binary_search(arr, low, mid - 1, x);
            } else {
                return binary_search(arr, mid + 1, high, x);
            }
        } else {
            return - 1;
        }
    }

    function addRewardsToNode(address wallet, uint256 nodeIndex, uint256 amount)
    external onlyManager
    {
        require(nodeIndex > 0, "NODE: addRewardsToNode amount must be higher than zero");
        _nodesOfUser[wallet][nodeIndex].rewardNotClaimed += amount;
    }

    function updateNotClaimedRewards()
    internal onlyManager
    {
        for (uint256 i = 0; i < totalNodesCreated; i++) {
            address wallet = nodeOwners.getKeyAtIndex(i);
            for (uint256 j = 0; j < _nodesOfUser[wallet].length; j++) {
                _nodesOfUser[wallet][j].rewardNotClaimed += claimableAmount(_nodesOfUser[wallet][j].lastClaimTime);
                _nodesOfUser[wallet][j].lastClaimTime = block.timestamp;
            }
        }
    }

    function _cashoutNodeReward(address account, uint256 id)
    external onlyManager
    returns (uint256)
    {
        require(id > 0, "NODE: CREATIME must be higher than zero");
        NewNodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 numberOfNodes = nodes.length;
        require(
            numberOfNodes > 0,
            "CASHOUT ERROR: You don't have nodes to cash-out"
        );
        NewNodeEntity storage node = _getNodeWithCreatime(nodes, id);
        uint256 rewardNode = claimableAmount(node.lastClaimTime) + node.rewardNotClaimed;

        node.rewardNotClaimed = 0;
        return rewardNode;
    }

    function _cashoutAllNodesReward(address account)
    external onlyManager
    returns (uint256)
    {
        NewNodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        require(nodesCount > 0, "NODE: CREATIME must be higher than zero");
        NewNodeEntity storage _node;
        uint256 rewardsTotal = 0;
        for (uint256 i = 0; i < nodesCount; i++) {
            _node = nodes[i];
            rewardsTotal += claimableAmount(_node.lastClaimTime) + _node.rewardNotClaimed;

            _node.rewardNotClaimed = 0;
        }
        return rewardsTotal;
    }

    function claimable(NewNodeEntity memory node) private view returns (bool) {
        return node.lastClaimTime + claimInterval <= block.timestamp;
    }

    function _getRewardAmountOf(address account)
    external
    view
    returns (uint256)
    {
        require(isNodeOwner(account), "GET REWARD OF: NO NODE OWNER");
        uint256 nodesCount;
        uint256 rewardCount = 0;

        NewNodeEntity[] storage nodes = _nodesOfUser[account];
        nodesCount = nodes.length;

        for (uint256 i = 0; i < nodesCount; i++) {
            rewardCount += claimableAmount(nodes[i].lastClaimTime) + nodes[i].rewardNotClaimed;
        }

        return rewardCount;
    }

    function _getRewardAmountOf(address account, uint256 id)
    external
    view
    returns (uint256)
    {
        require(isNodeOwner(account), "GET REWARD OF: NO NODE OWNER");
        require(id > 0, "NODE: CREATIME must be higher than zero");

        NewNodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 numberOfNodes = nodes.length;

        require(
            numberOfNodes > 0,
            "CASHOUT ERROR: You don't have nodes to cash-out"
        );

        NewNodeEntity storage node = _getNodeWithCreatime(nodes, id);
        return claimableAmount(node.lastClaimTime) + node.rewardNotClaimed;
    }

    function claimableAmount(uint256 nodeLastClaimTime) private view returns (uint256 availableRewards) {
        uint256 currentTime = block.timestamp;
        uint256 intervalsPassed = (currentTime).sub(nodeLastClaimTime).div(claimInterval);
        return intervalsPassed.mul(rewardsPerMinute);
    }

    function _getNodesIds(address account)
    external
    view
    returns (string memory)
    {
        require(isNodeOwner(account), "GET IDS NO NODE OWNER");
        NewNodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NewNodeEntity memory _node;
        string memory ids = uint2str(nodes[0].id);
        string memory separator = "#";
        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];
            ids = string(abi.encodePacked(ids, separator, uint2str(_node.id)));
        }
        return ids;
    }

    function _getNodesCreationTime(address account)
    external
    view
    returns (string memory)
    {
        require(isNodeOwner(account), "GET CREATIME: NO NODE OWNER");
        NewNodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NewNodeEntity memory _node;
        string memory _creationIds = uint2str(nodes[0].id);
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];

            _creationIds = string(
                abi.encodePacked(
                    _creationIds,
                    separator,
                    uint2str(_node.creationTime)
                )
            );
        }
        return _creationIds;
    }

    function _getNodesRewardAvailable(address account)
    external
    view
    returns (string memory)
    {
        require(isNodeOwner(account), "GET REWARD: NO NODE OWNER");
        NewNodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NewNodeEntity memory _node;
        string memory _rewardsAvailable = uint2str(claimableAmount(_node.lastClaimTime) + _node.rewardNotClaimed);
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];

            _rewardsAvailable = string(
                abi.encodePacked(
                    _rewardsAvailable,
                    separator,
                    uint2str(claimableAmount(_node.lastClaimTime) + _node.rewardNotClaimed)
                )
            );
        }
        return _rewardsAvailable;
    }

    function _getNodesExpireTime(address account)
    external
    view
    returns (string memory)
    {
        return "";
    }

    function _migrateNodes(address oldNodeRewardsContractAddress, address[] memory oldNodeRewardsContractUsers, uint256 amount)
    external
    {
        require(oldNodeRewardsContractAddress != address(0), "oldNodeRewardsContractAddress CANT BE ZERO");
        require(oldNodeRewardsContractAddress != address(this), "oldNodeRewardsContract CANT BE SAME ADDRESS");
        require(oldNodeRewardsContractUsers.length > 0, "rewardTokenUsers CANT BE ZERO");

        // Instance old rewards contract for get their nodes
        OldNODERewardManagement oldNodeRewardManagement = OldNODERewardManagement(oldNodeRewardsContractAddress);

        // 1. Loop all users from old node rewards contract
        for (uint256 x = 0; x < oldNodeRewardsContractUsers.length; x++) {

            address user = oldNodeRewardsContractUsers[x];

            OldNODERewardManagement.NodeEntity[] memory nodes = oldNodeRewardManagement.getNodes(user);

            // 3. If users has nodes (nodesCreationTime should be bigger than zero)
            if (nodes.length > 0) {

                // 4. Get all nodes from user
                for (uint256 i = 0; i < nodes.length; i++) {

                    // 5. Get last claim date from users old nodes
                    uint256 lastClaimDate = nodes[i].lastClaimTime;

                    // 6. Calc how much he should can claim from each old node
                    uint256 notClaimedAmount = claimableAmount(lastClaimDate);

                    // 7. Set node creation date before last claim date
                    uint256 creationDate = nodes[i].creationTime;

                    // 8. Create same node number on new contract
                    _nodesOfUser[user].push(
                        NewNodeEntity({
                            id : totalNodesCreated + 1,
                            creationTime : creationDate,
                            lastClaimTime : block.timestamp,
                            rewardNotClaimed : notClaimedAmount
                            })
                    );

                    nodeOwners.set(user, _nodesOfUser[user].length);
                    totalNodesCreated++;
                    _nodesOfUser[user][i].rewardNotClaimed += amount;
                    emit NodeCreated(user, totalNodesCreated, _nodesOfUser[user].length, totalNodesCreated);
                }
            }
        }
    }


    /*
    for (uint256 i = 0; i < totalNodesCreated; i++) {
        address wallet = nodeOwners.getKeyAtIndex(i);
        for (uint256 j = 0; j < _nodesOfUser[wallet].length; j++) {
            _nodesOfUser[wallet][j].rewardNotClaimed += claimableAmount(_nodesOfUser[wallet][j]);
            _nodesOfUser[wallet][j].lastClaimTime = block.timestamp;
        }
    }
*/

    function _getNodesLastClaimTime(address account)
    external
    view
    returns (string memory)
    {
        require(isNodeOwner(account), "LAST CLAIME TIME: NO NODE OWNER");
        NewNodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NewNodeEntity memory _node;
        string memory _lastClaimTimes = uint2str(nodes[0].lastClaimTime);
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];

            _lastClaimTimes = string(
                abi.encodePacked(
                    _lastClaimTimes,
                    separator,
                    uint2str(_node.lastClaimTime)
                )
            );
        }
        return _lastClaimTimes;
    }

    function uint2str(uint256 _i)
    internal
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

    function _changeNodePrice(uint256 newNodePrice) external onlyManager {
        nodePrice = newNodePrice;
    }

    function _changeRewardsPerMinute(uint256 newPrice) external onlyManager {
        rewardsPerMinute = newPrice;
        updateNotClaimedRewards();
    }

    function _changeClaimInterval(uint256 newTime) external onlyManager {
        claimInterval = newTime;
    }

    function _getNodeNumberOf(address account) public view returns (uint256) {
        return nodeOwners.get(account);
    }

    function isNodeOwner(address account) private view returns (bool) {
        return nodeOwners.get(account) > 0;
    }

    function _isNodeOwner(address account) external view returns (bool) {
        return isNodeOwner(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

library SafeMath {
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is TKNaper than requiring 'a' not being zero, but the
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
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
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
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
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
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
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
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./SafeMath.sol";

contract OldNODERewardManagement {
    using SafeMath for uint256;

    struct NodeEntity {
        uint256 creationTime;
        uint256 lastClaimTime;
        uint256 dividendsPaid;
        uint256 expireTime;
    }

    mapping(address => NodeEntity[]) private _nodesOfUser;
    mapping(address => bool) public _managers;

    uint256 public nodePrice;

    uint256 public rewardsPerMinute;

    bool public distribution = false;

    uint256 public totalNodesCreated = 0;
    uint256 public totalRewardStaked = 0;

    uint256 public claimInterval = 60;

    uint256 public stakeNodeStartAmount = 0 * 10 ** 18;
    uint256 public nodeStartAmount = 1 * 10 ** 18;

    event NodeCreated(address indexed from, string name, uint256 index, uint256 totalNodesCreated);

    constructor(
        uint256 _nodePrice,
        uint256 _rewardsPerMinute
    ) {
        _managers[msg.sender] = true;
        nodePrice = _nodePrice;
        rewardsPerMinute = _rewardsPerMinute;
    }

    modifier onlyManager() {
        require(_managers[msg.sender] == true, "Only managers can call this function");
        _;
    }

    function addManager(address manager) external onlyManager {
        _managers[manager] = true;
    }

    function createNode(address account, string memory name, uint256 expireTime) external onlyManager {
        uint256 realExpireTime = 0;
        if (expireTime > 0) {
            realExpireTime = block.timestamp + expireTime;
        }
        _nodesOfUser[account].push(
            NodeEntity({
        creationTime : block.timestamp,
        lastClaimTime : block.timestamp,
        dividendsPaid : 0,
        expireTime : realExpireTime
        })
        );
        totalNodesCreated++;
        emit NodeCreated(account, name, _nodesOfUser[account].length, totalNodesCreated);
    }

    function dividendsOwing(NodeEntity memory node) private view returns (uint256 availableRewards) {
        uint256 currentTime = block.timestamp;
        if (currentTime > node.expireTime && node.expireTime > 0) {
            currentTime = node.expireTime;
        }
        uint256 minutesPassed = (currentTime).sub(node.creationTime).div(claimInterval);
        return minutesPassed.mul(rewardsPerMinute).add(node.expireTime > 0 ? stakeNodeStartAmount : nodeStartAmount).sub(node.dividendsPaid);
    }

    function _checkExpired(NodeEntity memory node) private view returns (bool isExpired) {
        return (node.expireTime > 0 && node.expireTime <= block.timestamp);
    }

    function _getNodeByIndex(
        NodeEntity[] storage nodes,
        uint256 index
    ) private view returns (NodeEntity storage) {
        uint256 numberOfNodes = nodes.length;
        require(
            numberOfNodes > 0,
            "CASHOUT ERROR: You don't have nodes to cash-out"
        );
        require(index < numberOfNodes, "CASHOUT ERROR: Invalid node");
        return nodes[index];
    }

    function _cashoutNodeReward(address account, uint256 index)
    external
    onlyManager
    returns (uint256)
    {
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 numberOfNodes = nodes.length;
        require(
            numberOfNodes > 0,
            "CASHOUT ERROR: You don't have nodes to cash-out"
        );
        NodeEntity storage node = _getNodeByIndex(nodes, index);
        uint256 rewardNode = dividendsOwing(node);
        node.dividendsPaid += rewardNode;
        return rewardNode;
    }

    function _cashoutAllNodesReward(address account)
    external
    onlyManager
    returns (uint256)
    {
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        require(nodesCount > 0, "NODE: NO NODE OWNER");
        NodeEntity storage _node;
        uint256 rewardsTotal = 0;
        for (uint256 i = 0; i < nodesCount; i++) {
            _node = nodes[i];
            uint256 rewardNode = dividendsOwing(_node);
            rewardsTotal += rewardNode;
            _node.lastClaimTime = block.timestamp;
            _node.dividendsPaid += rewardNode;
        }
        return rewardsTotal;
    }

    function getPendingCashoutAllNodesReward(address account)
    external
    view
    returns (uint256)
    {
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        require(nodesCount > 0, "NODE: NO NODE OWNER");

        uint256 rewardsTotal = 0;
        for (uint256 i = 0; i < nodesCount; i++) {
            uint256 rewardNode = dividendsOwing(nodes[i]);
            rewardsTotal += rewardNode;
        }
        return rewardsTotal;
    }

    function _getRewardAmountOf(address account)
    external
    view
    returns (uint256)
    {
        require(isNodeOwner(account), "GET REWARD OF: NO NODE OWNER");
        uint256 nodesCount;
        uint256 rewardCount = 0;

        NodeEntity[] storage nodes = _nodesOfUser[account];
        nodesCount = nodes.length;

        NodeEntity storage _node;
        for (uint256 i = 0; i < nodesCount; i++) {
            _node = nodes[i];
            rewardCount += dividendsOwing(_node);
        }

        return rewardCount;
    }

    function _getRewardAmountOf(address account, uint256 index)
    external
    view
    returns (uint256)
    {
        require(isNodeOwner(account), "GET REWARD OF: NO NODE OWNER");
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 numberOfNodes = nodes.length;
        require(
            numberOfNodes > 0,
            "CASHOUT ERROR: You don't have nodes to cash-out"
        );
        NodeEntity storage node = _getNodeByIndex(nodes, index);
        uint256 rewardNode = dividendsOwing(node);
        return rewardNode;
    }

    function _getNodeRewardAmountOf(address account, uint256 index)
    external
    view
    returns (uint256)
    {
        NodeEntity memory node = _getNodeByIndex(_nodesOfUser[account], index);
        return dividendsOwing(node);
    }


    function _getNodesExpireTime(address account)
    external
    view
    returns (string memory)
    {
        require(isNodeOwner(account), "GET CREATIME: NO NODE OWNER");
        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        string memory _expireTimes = uint2str(nodes[0].expireTime);
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];
            _expireTimes = string(
                abi.encodePacked(
                    _expireTimes,
                    separator,
                    uint2str(_node.expireTime)
                )
            );
        }
        return _expireTimes;
    }


    function _getNodesCreationTime(address account)
    external
    view
    returns (string memory)
    {
        require(isNodeOwner(account), "GET CREATIME: NO NODE OWNER");
        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        string memory _creationTimes = uint2str(nodes[0].creationTime);
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];

            _creationTimes = string(
                abi.encodePacked(
                    _creationTimes,
                    separator,
                    uint2str(_node.creationTime)
                )
            );
        }
        return _creationTimes;
    }

    function _getNodesRewardAvailable(address account)
    external
    view
    returns (string memory)
    {
        require(isNodeOwner(account), "GET REWARD: NO NODE OWNER");
        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        string memory _rewardsAvailable = uint2str(dividendsOwing(nodes[0]));
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];

            _rewardsAvailable = string(
                abi.encodePacked(
                    _rewardsAvailable,
                    separator,
                    uint2str(dividendsOwing(_node))
                )
            );
        }
        return _rewardsAvailable;
    }

    function _getNodesLastClaimTime(address account)
    external
    view
    returns (string memory)
    {
        require(isNodeOwner(account), "LAST CLAIME TIME: NO NODE OWNER");
        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        string memory _lastClaimTimes = uint2str(nodes[0].lastClaimTime);
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];

            _lastClaimTimes = string(
                abi.encodePacked(
                    _lastClaimTimes,
                    separator,
                    uint2str(_node.lastClaimTime)
                )
            );
        }
        return _lastClaimTimes;
    }

    function getNodes(address user) external view returns (NodeEntity[] memory nodes) {
        return _nodesOfUser[user];
    }

    function uint2str(uint256 _i)
    internal
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

    function _changeStakeNodeStartAmount(uint256 newStartAmount) external onlyManager {
        stakeNodeStartAmount = newStartAmount;
    }

    function _changeNodeStartAmount(uint256 newStartAmount) external onlyManager {
        nodeStartAmount = newStartAmount;
    }

    function _changeNodePrice(uint256 newNodePrice) external onlyManager {
        nodePrice = newNodePrice;
    }

    function _changeRewardsPerMinute(uint256 newPrice) external onlyManager {
        rewardsPerMinute = newPrice;
    }

    function _changeClaimInterval(uint256 newInterval) external onlyManager {
        claimInterval = newInterval;
    }

    function _getNodeNumberOf(address account) public view returns (uint256) {
        return _nodesOfUser[account].length;
    }

    function isNodeOwner(address account) private view returns (bool) {
        return _nodesOfUser[account].length > 0;
    }

    function _isNodeOwner(address account) external view returns (bool) {
        return isNodeOwner(account);
    }
}