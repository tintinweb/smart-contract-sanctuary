// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./SafeMath.sol";
import "./IterableMapping.sol";

contract NODERewardManagement {
    using SafeMath for uint256;
    using IterableMapping for IterableMapping.Map;

    modifier onlyManager() {
        require(_managers[msg.sender] == true, "Only managers can call this function");
        _;
    }

    struct NodeEntity {
        uint256 nodeId;
        uint256 creationTime;
        uint256 lastClaimTime;
        uint256 rewardNotClaimed;
    }

    IterableMapping.Map private nodeOwners;
    mapping(address => NodeEntity[]) private _nodesOfUser;
    mapping(address => bool) public _managers;

    uint256 public nodePrice = 0; // 10
    uint256 public rewardsPerMinute = 0; // 1
    uint256 public claimInterval = 0; // 5 min

    uint256 public lastIndexProcessed = 0;
    uint256 public totalNodesCreated = 0;
    uint256 public totalRewardStaked = 0;

    bool public createSingleNodeEnabled = false;
    bool public createMultiNodeEnabled = false;
    bool public cashoutEnabled = false;

    uint256 public gasForDistribution = 30000;

    event NodeCreated(address indexed from, uint256 nodeId, uint256 index, uint256 totalNodesCreated);

    constructor(
    ) {
        _managers[msg.sender] = true;
    }

    function updateManagers(address manager, bool newVal) external onlyManager {
        require(manager != address(0),"new manager is the zero address");
        _managers[manager] = newVal;
    }

    // string memory nodeName, uint256 expireTime ignored, just for match with old contract
    function createNode(address account, string memory nodeName, uint256 expireTime) external onlyManager {

        require(createSingleNodeEnabled,"createSingleNodeEnabled disabled");

        _nodesOfUser[account].push(
            NodeEntity({
        nodeId : totalNodesCreated + 1,
        creationTime : block.timestamp,
        lastClaimTime : block.timestamp,
        rewardNotClaimed : 0
        })
        );

        nodeOwners.set(account, _nodesOfUser[account].length);
        totalNodesCreated++;
        emit NodeCreated(account, totalNodesCreated, _nodesOfUser[account].length, totalNodesCreated);
    }

    function createNodesWithRewardsAndClaimDates(address account, uint256 numberOfNodes, uint256[] memory rewards, uint256[] memory claimsTimes) external onlyManager {

        require(createMultiNodeEnabled,"createcreateMultiNodeEnabledSingleNodeEnabled disabled");
        require(numberOfNodes > 0,"createNodes numberOfNodes cant be zero");
        require(rewards.length > 0 ? rewards.length == numberOfNodes: true,"rewards length not equal numberOfNodes");
        require(claimsTimes.length > 0 ? claimsTimes.length == numberOfNodes: true,"claimsTimes length not equal numberOfNodes");
        require(rewards.length > 0 && claimsTimes.length > 0 ? rewards.length == numberOfNodes && claimsTimes.length == numberOfNodes: true,"rewards and claimsTimes length not equal numberOfNodes");

        for (uint256 i = 0; i < numberOfNodes; i++) {
            _nodesOfUser[account].push(
                NodeEntity({
            nodeId : totalNodesCreated + 1,
            creationTime : block.timestamp + i,
            lastClaimTime : claimsTimes.length > 0 ? claimsTimes[i] : 0,
            rewardNotClaimed : rewards.length > 0 ? rewards[i] : 0
            })
            );

            nodeOwners.set(account, _nodesOfUser[account].length);
            totalNodesCreated++;
            emit NodeCreated(account, totalNodesCreated, _nodesOfUser[account].length, totalNodesCreated);
        }
    }

    function createNodes(address account, uint256 numberOfNodes) external onlyManager {

        require(createMultiNodeEnabled,"createcreateMultiNodeEnabledSingleNodeEnabled disabled");
        require(numberOfNodes > 0,"createNodes numberOfNodes cant be zero");

        for (uint256 i = 0; i < numberOfNodes; i++) {
            _nodesOfUser[account].push(
                NodeEntity({
            nodeId : totalNodesCreated + 1,
            creationTime : block.timestamp + i,
            lastClaimTime : block.timestamp + i,
            rewardNotClaimed : 0
            })
            );

            nodeOwners.set(account, _nodesOfUser[account].length);
            totalNodesCreated++;
            emit NodeCreated(account, totalNodesCreated, _nodesOfUser[account].length, totalNodesCreated);
        }
    }

    function burn(address account, uint256 _creationTime) external onlyManager {
        require(isNodeOwner(account), "GET REWARD OF: NO NODE OWNER");
        require(_creationTime > 0, "NODE: CREATIME must be higher than zero");

        int256 nodeIndex = getNodeIndexByCreationTime(_nodesOfUser[account], _creationTime);

        require(uint256(nodeIndex) < _nodesOfUser[account].length, "NODE: CREATIME must be higher than zero");
        nodeOwners.remove(nodeOwners.getKeyAtIndex(uint256(nodeIndex)));
    }

    function getNodeIndexByCreationTime(
        NodeEntity[] storage nodes,
        uint256 _creationTime
    ) private view returns (int256) {
        bool found = false;
        int256 index = binary_search(nodes, 0, nodes.length, _creationTime);
        int256 validIndex;
        if (index >= 0) {
            found = true;
            validIndex = int256(index);
        }
        return validIndex;
    }

    function getNodeInfo(
        address account,
        uint256 _creationTime
    ) public view returns (NodeEntity memory) {

        require(isNodeOwner(account), "GET REWARD OF: NO NODE OWNER");
        require(_creationTime > 0, "NODE: CREATIME must be higher than zero");

        int256 nodeIndex = getNodeIndexByCreationTime(_nodesOfUser[account], _creationTime);

        require(nodeIndex != -1, "NODE SEARCH: No NODE Found with this blocktime");
        return _nodesOfUser[account][uint256(nodeIndex)];
    }

    function _getNodeWithCreatime(
        NodeEntity[] storage nodes,
        uint256 _creationTime
    ) private view returns (NodeEntity storage) {

        require(_creationTime > 0, "NODE: CREATIME must be higher than zero");
        int256 nodeIndex = getNodeIndexByCreationTime(nodes, _creationTime);

        require(nodeIndex != -1, "NODE SEARCH: No NODE Found with this blocktime");
        return nodes[uint256(nodeIndex)];
    }

    function updateRewardsToNode(address account, uint256 _creationTime, uint256 amount, bool increaseOrDecrease)
    external onlyManager
    {
        require(isNodeOwner(account), "GET REWARD OF: NO NODE OWNER");
        require(_creationTime > 0, "NODE: CREATIME must be higher than zero");
        require(amount > 0, "amount must be higher than zero");

        int256 nodeIndex = getNodeIndexByCreationTime(_nodesOfUser[account], _creationTime);
        require(nodeIndex != -1, "NODE SEARCH: No NODE Found with this blocktime");

        increaseOrDecrease ? _nodesOfUser[account][uint256(nodeIndex)].rewardNotClaimed += amount : _nodesOfUser[account][uint256(nodeIndex)].rewardNotClaimed -= amount;
    }

    function _cashoutNodeReward(address account, uint256 _creationTime)
    external
    returns (uint256)
    {
        require(cashoutEnabled, "cashoutEnabled disabled");
        require(isNodeOwner(account), "GET REWARD OF: NO NODE OWNER");

        NodeEntity storage node = _getNodeWithCreatime(_nodesOfUser[account], _creationTime);
        require(isNodeClaimable(node), "too early to claim from this node");

        int256 nodeIndex = getNodeIndexByCreationTime(_nodesOfUser[account], _creationTime);
        uint256 rewardNode = availableClaimableAmount(node.lastClaimTime) + node.rewardNotClaimed;

        _nodesOfUser[account][uint256(nodeIndex)].rewardNotClaimed = 0;
        _nodesOfUser[account][uint256(nodeIndex)].lastClaimTime = block.timestamp;

        return rewardNode;
    }

    function _cashoutAllNodesReward(address account)
    external onlyManager
    returns (uint256)
    {
        require(isNodeOwner(account), "GET REWARD OF: NO NODE OWNER");
        require(cashoutEnabled, "cashoutEnabled disabled");

        uint256 rewardsTotal = 0;
        for (uint256 i = 0; i < _nodesOfUser[account].length; i++) {
            rewardsTotal += availableClaimableAmount(_nodesOfUser[account][i].lastClaimTime) + _nodesOfUser[account][i].rewardNotClaimed;
            _nodesOfUser[account][i].rewardNotClaimed = 0;
            _nodesOfUser[account][i].lastClaimTime = block.timestamp;
        }
        return rewardsTotal;
    }

    function isNodeClaimable(NodeEntity memory node) private view returns (bool) {
        return node.lastClaimTime + claimInterval <= block.timestamp;
    }

    function _getRewardAmountOf(address account)
    external
    view
    returns (uint256)
    {
        require(isNodeOwner(account), "GET REWARD OF: NO NODE OWNER");

        uint256 rewardCount = 0;

        for (uint256 i = 0; i < _nodesOfUser[account].length; i++) {
            rewardCount += availableClaimableAmount(_nodesOfUser[account][i].lastClaimTime) + _nodesOfUser[account][i].rewardNotClaimed;
        }

        return rewardCount;
    }

    function _getRewardAmountOf(address account, uint256 _creationTime)
    external
    view
    returns (uint256)
    {
        require(isNodeOwner(account), "GET REWARD OF: NO NODE OWNER");
        require(_creationTime > 0, "NODE: CREATIME must be higher than zero");

        NodeEntity storage node = _getNodeWithCreatime(_nodesOfUser[account], _creationTime);
        return availableClaimableAmount(node.lastClaimTime) + node.rewardNotClaimed;
    }

    function _pendingClaimableAmount(uint256 nodeLastClaimTime) private view returns (uint256 availableRewards) {
        uint256 currentTime = block.timestamp;
        uint256 timePassed = (currentTime).sub(nodeLastClaimTime);
        uint256 intervalsPassed = timePassed.div(claimInterval);

        if (intervalsPassed < 1) {
            return timePassed.mul(rewardsPerMinute).div(claimInterval);
        }

        return 0;
    }

    function availableClaimableAmount(uint256 nodeLastClaimTime) private view returns (uint256 availableRewards) {
        uint256 currentTime = block.timestamp;
        uint256 intervalsPassed = (currentTime).sub(nodeLastClaimTime).div(claimInterval);
        return intervalsPassed.mul(rewardsPerMinute);
    }

    function _getNodesPendingClaimableAmount(address account)
    external
    view
    returns (string memory)
    {
        require(isNodeOwner(account), "GET CREATIME: NO NODE OWNER");

        string memory pendingClaimableAmount = uint2str(_pendingClaimableAmount(_nodesOfUser[account][0].lastClaimTime));

        for (uint256 i = 1; i < _nodesOfUser[account].length; i++) {
            pendingClaimableAmount = string(abi.encodePacked(pendingClaimableAmount,"#", uint2str(_pendingClaimableAmount(_nodesOfUser[account][i].lastClaimTime))));
        }

        return pendingClaimableAmount;
    }

    function _getNodesCreationTime(address account)
    external
    view
    returns (string memory)
    {
        require(isNodeOwner(account), "GET CREATIME: NO NODE OWNER");

        string memory _creationTimes = uint2str(_nodesOfUser[account][0].creationTime);

        for (uint256 i = 1; i < _nodesOfUser[account].length; i++) {
            _creationTimes = string(abi.encodePacked(_creationTimes,"#",uint2str(_nodesOfUser[account][i].creationTime)));
        }

        return _creationTimes;
    }

    function _getNodesRewardAvailable(address account)
    external
    view
    returns (string memory)
    {
        require(isNodeOwner(account), "GET REWARD: NO NODE OWNER");

        string memory _rewardsAvailable = uint2str(availableClaimableAmount(_nodesOfUser[account][0].lastClaimTime) + _nodesOfUser[account][0].rewardNotClaimed);

        for (uint256 i = 1; i < _nodesOfUser[account].length; i++) {
            _rewardsAvailable = string(
                abi.encodePacked(
                    _rewardsAvailable,
                    "#",
                    uint2str(availableClaimableAmount(_nodesOfUser[account][i].lastClaimTime) + _nodesOfUser[account][i].rewardNotClaimed)
                )
            );
        }
        return _rewardsAvailable;
    }
    // not used, just for be compatible, with old contract
    function _getNodesExpireTime(address account)
    external
    view
    returns (string memory)
    {
        return "";
    }

    function _getNodesLastClaimTime(address account)
    external
    view
    returns (string memory)
    {

        require(isNodeOwner(account), "GET REWARD: NO NODE OWNER");

        string memory _lastClaimTimes = uint2str(_nodesOfUser[account][0].lastClaimTime);

        for (uint256 i = 1; i < _nodesOfUser[account].length; i++) {
            _lastClaimTimes = string(abi.encodePacked(_lastClaimTimes,"#",uint2str(_nodesOfUser[account][i].lastClaimTime)));
        }
        return _lastClaimTimes;
    }

    function _refreshNodeRewards(uint256 gas) private
    returns (
        uint256,
        uint256,
        uint256
    )
    {
        uint256 numberOfnodeOwners = nodeOwners.keys.length;
        require(numberOfnodeOwners > 0, "DISTRI REWARDS: NO NODE OWNERS");
        if (numberOfnodeOwners == 0) {
            return (0, 0, lastIndexProcessed);
        }

        uint256 iterations = 0;
        uint256 claims = 0;
        uint256 localLastIndex = lastIndexProcessed;

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 newGasLeft;

        while (gasUsed < gas && iterations < numberOfnodeOwners) {

            localLastIndex++;
            if (localLastIndex >= nodeOwners.keys.length) {
                localLastIndex = 0;
            }

            address account = nodeOwners.keys[localLastIndex];
            for (uint256 i = 0; i < _nodesOfUser[account].length; i++) {

                int256 nodeIndex = getNodeIndexByCreationTime(_nodesOfUser[account], _nodesOfUser[account][i].creationTime);
                require(nodeIndex != -1, "NODE SEARCH: No NODE Found with this blocktime");

                uint256 rewardNotClaimed = availableClaimableAmount(_nodesOfUser[account][i].lastClaimTime) + _pendingClaimableAmount(_nodesOfUser[account][i].lastClaimTime);
                _nodesOfUser[account][uint256(nodeIndex)].rewardNotClaimed += rewardNotClaimed;
                _nodesOfUser[account][uint256(nodeIndex)].lastClaimTime = block.timestamp;
                totalRewardStaked += rewardNotClaimed;
                claims++;
            }
            iterations++;

            newGasLeft = gasleft();

            if (gasLeft > newGasLeft) {
                gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            }

            gasLeft = newGasLeft;
        }
        lastIndexProcessed = localLastIndex;
        return (iterations, claims, lastIndexProcessed);
    }

    function _updateRewardsToAllNodes(uint256 gas, uint256 rewardAmount, bool increaseOrDecrease) private
    returns (
        uint256,
        uint256,
        uint256
    )
    {
        uint256 numberOfnodeOwners = nodeOwners.keys.length;
        require(numberOfnodeOwners > 0, "DISTRI REWARDS: NO NODE OWNERS");
        if (numberOfnodeOwners == 0) {
            return (0, 0, lastIndexProcessed);
        }

        uint256 iterations = 0;
        uint256 claims = 0;
        uint256 localLastIndex = lastIndexProcessed;

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 newGasLeft;

        while (gasUsed < gas && iterations < numberOfnodeOwners) {

            localLastIndex++;
            if (localLastIndex >= nodeOwners.keys.length) {
                localLastIndex = 0;
            }

            address account = nodeOwners.keys[localLastIndex];

            for (uint256 i = 0; i < _nodesOfUser[account].length; i++) {

                int256 nodeIndex = getNodeIndexByCreationTime(_nodesOfUser[account], _nodesOfUser[account][i].creationTime);

                increaseOrDecrease ? _nodesOfUser[account][uint256(nodeIndex)].rewardNotClaimed += rewardAmount : _nodesOfUser[account][uint256(nodeIndex)].rewardNotClaimed -= rewardAmount;
                _nodesOfUser[account][uint256(nodeIndex)].lastClaimTime = block.timestamp;
                totalRewardStaked += rewardAmount;
                claims++;
            }
            iterations++;

            newGasLeft = gasleft();

            if (gasLeft > newGasLeft) {
                gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            }

            gasLeft = newGasLeft;
        }
        lastIndexProcessed = localLastIndex;
        return (iterations, claims, lastIndexProcessed);
    }

    function updateRewardsToAllNodes(uint256 gas, uint256 amount, bool increaseOrDecrease) external onlyManager
    returns (
        uint256,
        uint256,
        uint256
    )
    {
        return _updateRewardsToAllNodes(gas, amount, increaseOrDecrease);
    }

    function refreshNodeRewards(uint256 gas) external onlyManager
    returns (
        uint256,
        uint256,
        uint256
    )
    {
        return _refreshNodeRewards(gas);
    }

    function _changeNodePrice(uint256 newNodePrice) external onlyManager {
        nodePrice = newNodePrice;
    }

    function _changeRewardsPerMinute(uint256 newPrice) external onlyManager {
        if (nodeOwners.keys.length > 0) {
            _refreshNodeRewards(gasForDistribution);
        }
        rewardsPerMinute = newPrice;
    }

    function _changeGasDistri(uint256 newGasDistri) external onlyManager {
        gasForDistribution = newGasDistri;
    }

    function _changeClaimInterval(uint256 newTime) external onlyManager {
        if (nodeOwners.keys.length > 0) {
            _refreshNodeRewards(gasForDistribution);
        }
        claimInterval = newTime;
    }

    function _changeCreateSingleNodeEnabled(bool newVal) external onlyManager {
        createSingleNodeEnabled = newVal;
    }

    function _changeCashoutEnabled(bool newVal) external onlyManager {
        cashoutEnabled = newVal;
    }

    function _changeCreateMultiNodeEnabled(bool newVal) external onlyManager {
        createMultiNodeEnabled = newVal;
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

    function binary_search(
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
                return binary_search(arr, low, mid - 1, x);
            } else {
                return binary_search(arr, mid + 1, high, x);
            }
        } else {
            return -1;
        }
    }
}