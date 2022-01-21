// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/IterableMapping.sol";

enum ContractType {
    Square,
    Cube,
    Teseract
}

contract NODERewardManagement {
    using IterableMapping for IterableMapping.Map;

    // -------------- Constants --------------
    uint256 public constant UNIX_YEAR = 31536000;

    // -------------- Node Structs --------------
    struct NodeEntity {
        string name;
        uint256 creationTime;
        uint256 lastUpdateTime;
        uint256 unclaimedReward;
        ContractType cType;
    }

    // -------------- Contract Storage --------------
    IterableMapping.Map private nodeOwners;
    mapping(address => NodeEntity[]) private _nodesOfUser;

    mapping(ContractType => uint256) public nodePrice;
    mapping(ContractType => uint256) public rewardAPYPerNode;
    mapping(ContractType => uint256) public newRewardAPYPerNode;
    uint256 public claimTime;

    address public admin0XB;
    address public token;

    bool public autoDistribute = true;
    bool public distribution = false;

    uint256 public totalNodesCreated = 0;

    // -------------- Constructor --------------
    constructor(
        uint256 _nodePriceSquare,
        uint256 _nodePriceCube,
        uint256 _nodePriceTeseract,
        uint256 _rewardAPYPerNodeSquare,
        uint256 _rewardAPYPerNodeCube,
        uint256 _rewardAPYPerNodeTeseract,
        uint256 _claimTime
    ) {
        nodePrice[ContractType.Square] = _nodePriceSquare;
        nodePrice[ContractType.Cube] = _nodePriceCube;
        nodePrice[ContractType.Teseract] = _nodePriceTeseract;
        rewardAPYPerNode[ContractType.Square] = _rewardAPYPerNodeSquare;
        rewardAPYPerNode[ContractType.Cube] = _rewardAPYPerNodeCube;
        rewardAPYPerNode[ContractType.Teseract] = _rewardAPYPerNodeTeseract;
        newRewardAPYPerNode[ContractType.Square] = _rewardAPYPerNodeSquare;
        newRewardAPYPerNode[ContractType.Cube] = _rewardAPYPerNodeCube;
        newRewardAPYPerNode[ContractType.Teseract] = _rewardAPYPerNodeTeseract;
        claimTime = _claimTime;
        admin0XB = msg.sender;
    }

    // -------------- Modifier (filter) --------------
    modifier onlySentry() {
        require(msg.sender == token || msg.sender == admin0XB, "Access Denied!");
        _;
    }

    // -------------- External WRITE functions --------------
    function setToken(address token_) external onlySentry {
        token = token_;
    }

    function createNode(
        address account,
        string memory nodeName,
        ContractType _cType
    ) external onlySentry {
        _nodesOfUser[account];

        _nodesOfUser[account].push(
            NodeEntity({
                name: nodeName,
                creationTime: block.timestamp,
                lastUpdateTime: block.timestamp,
                unclaimedReward: 0,
                cType: _cType
            })
        );
        nodeOwners.set(account, _nodesOfUser[account].length);
        totalNodesCreated++;
    }

    function _cashoutNodeReward(address account, uint256 _nodeIndex) external onlySentry returns (uint256) {
        NodeEntity[] storage nodes = _nodesOfUser[account];
        require(_nodeIndex >= 0 && _nodeIndex < nodes.length, "NODE: Index Error");
        NodeEntity storage node = nodes[_nodeIndex];
        uint256 rewardNode = nodeTotalReward(account, _nodeIndex);
        node.unclaimedReward = 0;
        node.lastUpdateTime = block.timestamp;
        return rewardNode;
    }

    function _cashoutAllNodesReward(address account) external onlySentry returns (uint256) {
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        require(nodesCount > 0, "CASHOUT ERROR: You don't have nodes to cash-out");
        NodeEntity storage _node;
        uint256 rewardsTotal = 0;
        for (uint256 i = 0; i < nodesCount; i++) {
            _node = nodes[i];
            rewardsTotal += nodeTotalReward(account, i);
            _node.unclaimedReward = 0;
            _node.lastUpdateTime = block.timestamp;
        }
        return rewardsTotal;
    }

    function _changeNodePrice(ContractType _cType, uint256 newNodePrice) external onlySentry {
        nodePrice[_cType] = newNodePrice;
    }

    function _changeRewardAPYPerNode(ContractType _cType, uint256 newPrice) external onlySentry {
        newRewardAPYPerNode[_cType] = newPrice;
    }

    function _changeClaimTime(uint256 newTime) external onlySentry {
        claimTime = newTime;
    }

    function _changeAutoDistribute(bool newMode) external onlySentry {
        autoDistribute = newMode;
    }

    function _confirmRewardUpdates() external onlySentry returns (string memory) {
        require(
            rewardAPYPerNode[ContractType.Square] != newRewardAPYPerNode[ContractType.Square] ||
                rewardAPYPerNode[ContractType.Cube] != newRewardAPYPerNode[ContractType.Cube] ||
                rewardAPYPerNode[ContractType.Teseract] != newRewardAPYPerNode[ContractType.Teseract],
            "CONFIRM RW: No changes made"
        );

        // TODO: resolve gas problem when scaling up;
        for (uint256 i = 0; i < nodeOwners.size(); i++) {
            address account = nodeOwners.getKeyAtIndex(i);

            NodeEntity[] storage nodes = _nodesOfUser[account];
            uint256 nodesCount = nodes.length;
            for (uint256 j = 0; j < nodesCount; j++) {
                NodeEntity storage node = nodes[j];
                uint256 reward = nodeTotalReward(account, j);
                node.lastUpdateTime = block.timestamp;

                node.unclaimedReward += reward;
            }
        }
        string memory result = "CHANGES MADE: |";
        if (rewardAPYPerNode[ContractType.Square] != newRewardAPYPerNode[ContractType.Square]) {
            rewardAPYPerNode[ContractType.Square] = newRewardAPYPerNode[ContractType.Square];
            result = string(
                abi.encodePacked(
                    "rewardAPYPerNode[Square] <= ",
                    uint2str(newRewardAPYPerNode[ContractType.Square]),
                    "|"
                )
            );
        }
        if (rewardAPYPerNode[ContractType.Cube] != newRewardAPYPerNode[ContractType.Cube]) {
            rewardAPYPerNode[ContractType.Cube] = newRewardAPYPerNode[ContractType.Cube];
            result = string(
                abi.encodePacked("rewardAPYPerNode[Cube] <= ", uint2str(newRewardAPYPerNode[ContractType.Cube]), "|")
            );
        }
        if (rewardAPYPerNode[ContractType.Teseract] != newRewardAPYPerNode[ContractType.Teseract]) {
            rewardAPYPerNode[ContractType.Teseract] = newRewardAPYPerNode[ContractType.Teseract];
            result = string(
                abi.encodePacked(
                    "rewardAPYPerNode[Teseract] <= ",
                    uint2str(newRewardAPYPerNode[ContractType.Teseract]),
                    "|"
                )
            );
        }
        return result;
    }

    // -------------- External READ functions --------------
    function _isNodeOwner(address account) external view returns (bool) {
        return isNodeOwner(account);
    }

    function _getRewardAmountOf(address account) external view returns (uint256) {
        require(isNodeOwner(account), "GET REWARD OF: NO NODE OWNER");
        uint256 nodesCount;
        uint256 rewardCount = 0;

        NodeEntity[] storage nodes = _nodesOfUser[account];
        nodesCount = nodes.length;

        for (uint256 i = 0; i < nodesCount; i++) {
            rewardCount += nodeTotalReward(account, i);
        }

        return rewardCount;
    }

    function _getRewardAmountOf(address account, uint256 _nodeIndex) external view returns (uint256) {
        require(isNodeOwner(account), "GET REWARD OF: NO NODE OWNER");
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 numberOfNodes = nodes.length;
        require(_nodeIndex >= 0 && _nodeIndex < numberOfNodes, "NODE: Node index is improper");
        NodeEntity storage node = nodes[_nodeIndex];
        uint256 rewardNode = node.unclaimedReward;
        return rewardNode;
    }

    function _getNodesNames(address account) external view returns (string memory) {
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

    function _getNodesCreationTime(address account) external view returns (string memory) {
        require(isNodeOwner(account), "GET CREATIME: NO NODE OWNER");
        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        string memory _creationTimes = uint2str(nodes[0].creationTime);
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];

            _creationTimes = string(abi.encodePacked(_creationTimes, separator, uint2str(_node.creationTime)));
        }
        return _creationTimes;
    }

    function _getNodesRewardAvailable(address account) external view returns (string memory) {
        require(isNodeOwner(account), "GET REWARD: NO NODE OWNER");
        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        string memory _rewardsAvailable = uint2str(nodes[0].unclaimedReward);
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];

            _rewardsAvailable = string(abi.encodePacked(_rewardsAvailable, separator, uint2str(_node.unclaimedReward)));
        }
        return _rewardsAvailable;
    }

    function _getNodeslastUpdateTime(address account) external view returns (string memory) {
        require(isNodeOwner(account), "LAST CLAIM TIME: NO NODE OWNER");
        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        string memory _lastUpdateTimes = uint2str(nodes[0].lastUpdateTime);
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];

            _lastUpdateTimes = string(abi.encodePacked(_lastUpdateTimes, separator, uint2str(_node.lastUpdateTime)));
        }
        return _lastUpdateTimes;
    }

    function _getNodeNumberOf(address account) public view returns (uint256) {
        return nodeOwners.get(account);
    }

    // -------------- Private/Internal Helpers --------------
    function nodeTotalReward(address account, uint256 index) private view returns (uint256) {
        NodeEntity[] memory nodes = _nodesOfUser[account];
        NodeEntity memory node = nodes[index];
        return nodeRewardSinceLastUpdate(account, index) + node.unclaimedReward;
    }

    function nodeRewardSinceLastUpdate(address account, uint256 index) private view returns (uint256) {
        NodeEntity[] memory nodes = _nodesOfUser[account];
        NodeEntity memory node = nodes[index];

        uint256 delta = block.timestamp - node.lastUpdateTime;
        uint256 rewardAPY = rewardAPYPerNode[node.cType];
        uint256 result = (rewardAPY / UNIX_YEAR) * delta;
        return result;
    }

    function claimable(NodeEntity memory node) private view returns (bool) {
        return node.lastUpdateTime + claimTime <= block.timestamp;
    }

    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
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

    function isNodeOwner(address account) private view returns (bool) {
        return nodeOwners.get(account) > 0;
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

    function get(Map storage map, address key) internal view returns (uint256) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key) internal view returns (int256) {
        if (!map.inserted[key]) {
            return -1;
        }
        return int256(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint256 index) internal view returns (address) {
        return map.keys[index];
    }

    function size(Map storage map) internal view returns (uint256) {
        return map.keys.length;
    }

    function set(
        Map storage map,
        address key,
        uint256 val
    ) internal {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) internal {
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