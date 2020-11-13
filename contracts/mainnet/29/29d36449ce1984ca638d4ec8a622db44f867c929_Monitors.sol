// SPDX-License-Identifier: AGPL-3.0-only

/*
    Monitors.sol - SKALE Manager
    Copyright (C) 2018-Present SKALE Labs
    @author Artem Payvin

    SKALE Manager is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

import "./SafeCast.sol";

import "./ConstantsHolder.sol";
import "./Nodes.sol";

contract Monitors is Permissions {

    using StringUtils for string;
    using SafeCast for uint;

    struct Verdict {
        uint toNodeIndex;
        uint32 downtime;
        uint32 latency;
    }

    struct CheckedNode {
        uint nodeIndex;
        uint time;
    }

    struct CheckedNodeWithIp {
        uint nodeIndex;
        uint time;
        bytes4 ip;
    }

    mapping (bytes32 => CheckedNode[]) public checkedNodes;
    mapping (bytes32 => uint[][]) public verdicts;

    mapping (bytes32 => uint[]) public groupsForMonitors;

    mapping (bytes32 => uint) public lastVerdictBlocks;
    mapping (bytes32 => uint) public lastBountyBlocks;


    event MonitorCreated(
        uint nodeIndex,
        bytes32 monitorIndex,
        uint numberOfMonitors,
        uint[] nodesInGroup,
        uint time,
        uint gasSpend
    );

    event VerdictWasSent(
        uint indexed fromMonitorIndex,
        uint indexed toNodeIndex,
        uint32 downtime,
        uint32 latency,
        bool status,
        uint previousBlockEvent,
        uint time,
        uint gasSpend
    );

    event MetricsWereCalculated(
        uint forNodeIndex,
        uint32 averageDowntime,
        uint32 averageLatency,
        uint time,
        uint gasSpend
    );

    event PeriodsWereSet(
        uint rewardPeriod,
        uint deltaPeriod,
        uint time,
        uint gasSpend
    );


    event MonitorRotated(
        bytes32 monitorIndex,
        uint newNode
    );

    /**
     * addMonitor - setup monitors of node
     */
    function addMonitor(uint nodeIndex) external allow("SkaleManager") {
        ConstantsHolder constantsHolder = ConstantsHolder(contractManager.getContract("ConstantsHolder"));
        bytes32 monitorIndex = keccak256(abi.encodePacked(nodeIndex));
        _generateGroup(monitorIndex, nodeIndex, constantsHolder.NUMBER_OF_MONITORS());
        CheckedNode memory checkedNode = _getCheckedNodeData(nodeIndex);
        for (uint i = 0; i < groupsForMonitors[monitorIndex].length; i++) {
            bytes32 index = keccak256(abi.encodePacked(groupsForMonitors[monitorIndex][i]));
            addCheckedNode(index, checkedNode);
        }

        emit MonitorCreated(
            nodeIndex,
            monitorIndex,
            groupsForMonitors[monitorIndex].length,
            groupsForMonitors[monitorIndex],
            block.timestamp,
            gasleft()
        );
    }

    function deleteMonitor(uint nodeIndex) external allow("SkaleManager") {
        bytes32 monitorIndex = keccak256(abi.encodePacked(nodeIndex));
        while (verdicts[keccak256(abi.encodePacked(nodeIndex))].length > 0) {
            verdicts[keccak256(abi.encodePacked(nodeIndex))].pop();
        }
        uint[] memory nodesInGroup = groupsForMonitors[monitorIndex];
        uint index;
        bytes32 monitoringIndex;
        for (uint i = 0; i < nodesInGroup.length; i++) {
            monitoringIndex = keccak256(abi.encodePacked(nodesInGroup[i]));
            (index, ) = _find(monitoringIndex, nodeIndex);
            if (index < checkedNodes[monitoringIndex].length) {
                if (index != checkedNodes[monitoringIndex].length.sub(1)) {
                    checkedNodes[monitoringIndex][index] =
                        checkedNodes[monitoringIndex][checkedNodes[monitoringIndex].length.sub(1)];
                }
                checkedNodes[monitoringIndex].pop();
            }
        }
        delete groupsForMonitors[monitorIndex];
    }

    function removeCheckedNodes(uint nodeIndex) external allow("SkaleManager") {
        bytes32 monitorIndex = keccak256(abi.encodePacked(nodeIndex));
        delete checkedNodes[monitorIndex];
    }

    function sendVerdict(uint fromMonitorIndex, Verdict calldata verdict) external allow("SkaleManager") {
        uint index;
        uint time;
        bytes32 monitorIndex = keccak256(abi.encodePacked(fromMonitorIndex));
        (index, time) = _find(monitorIndex, verdict.toNodeIndex);
        require(time > 0, "Checked Node does not exist in MonitorsArray");
        if (time <= block.timestamp) {
            if (index != checkedNodes[monitorIndex].length.sub(1)) {
                checkedNodes[monitorIndex][index] = 
                    checkedNodes[monitorIndex][checkedNodes[monitorIndex].length.sub(1)];
            }
            delete checkedNodes[monitorIndex][checkedNodes[monitorIndex].length.sub(1)];
            checkedNodes[monitorIndex].pop();
            ConstantsHolder constantsHolder = ConstantsHolder(contractManager.getContract("ConstantsHolder"));
            bool receiveVerdict = time.add(constantsHolder.deltaPeriod()) > block.timestamp;
            if (receiveVerdict) {
                verdicts[keccak256(abi.encodePacked(verdict.toNodeIndex))].push(
                    [uint(verdict.downtime), uint(verdict.latency)]
                );
            }
            _emitVerdictsEvent(fromMonitorIndex, verdict, receiveVerdict);
        }
    }

    function calculateMetrics(uint nodeIndex)
        external
        allow("SkaleManager")
        returns (uint averageDowntime, uint averageLatency)
    {
        bytes32 monitorIndex = keccak256(abi.encodePacked(nodeIndex));
        uint lengthOfArray = getLengthOfMetrics(monitorIndex);
        uint[] memory downtimeArray = new uint[](lengthOfArray);
        uint[] memory latencyArray = new uint[](lengthOfArray);
        for (uint i = 0; i < lengthOfArray; i++) {
            downtimeArray[i] = verdicts[monitorIndex][i][0];
            latencyArray[i] = verdicts[monitorIndex][i][1];
        }
        if (lengthOfArray > 0) {
            averageDowntime = _median(downtimeArray);
            averageLatency = _median(latencyArray);
        }
        delete verdicts[monitorIndex];
    }

    function setLastBountyBlock(uint nodeIndex) external allow("SkaleManager") {
        lastBountyBlocks[keccak256(abi.encodePacked(nodeIndex))] = block.number;
    }

    function getCheckedArray(bytes32 monitorIndex)
        external
        view
        returns (CheckedNodeWithIp[] memory checkedNodesWithIp)
    {
        Nodes nodes = Nodes(contractManager.getContract("Nodes"));
        checkedNodesWithIp = new CheckedNodeWithIp[](checkedNodes[monitorIndex].length);
        for (uint i = 0; i < checkedNodes[monitorIndex].length; ++i) {
            checkedNodesWithIp[i].nodeIndex = checkedNodes[monitorIndex][i].nodeIndex;
            checkedNodesWithIp[i].time = checkedNodes[monitorIndex][i].time;
            checkedNodesWithIp[i].ip = nodes.getNodeIP(checkedNodes[monitorIndex][i].nodeIndex);
        }
    }

    function getLastBountyBlock(uint nodeIndex) external view returns (uint) {
        return lastBountyBlocks[keccak256(abi.encodePacked(nodeIndex))];
    }

    function getNodesInGroup(bytes32 monitorIndex) external view returns (uint[] memory) {
        return groupsForMonitors[monitorIndex];
    }

    function getNumberOfNodesInGroup(bytes32 monitorIndex) external view returns (uint) {
        return groupsForMonitors[monitorIndex].length;
    }

    function initialize(address newContractsAddress) public override initializer {
        Permissions.initialize(newContractsAddress);
    }

    /**
     *  Add checked node or update existing one if it is already exits
     */
    function addCheckedNode(bytes32 monitorIndex, CheckedNode memory checkedNode) public allow("SkaleManager") {
        for (uint i = 0; i < checkedNodes[monitorIndex].length; ++i) {
            if (checkedNodes[monitorIndex][i].nodeIndex == checkedNode.nodeIndex) {
                checkedNodes[monitorIndex][i] = checkedNode;
                return;
            }
        }
        checkedNodes[monitorIndex].push(checkedNode);
    }

    function getLastReceivedVerdictBlock(uint nodeIndex) public view returns (uint) {
        return lastVerdictBlocks[keccak256(abi.encodePacked(nodeIndex))];
    }

    function getLengthOfMetrics(bytes32 monitorIndex) public view returns (uint) {
        return verdicts[monitorIndex].length;
    }

    function _generateGroup(bytes32 monitorIndex, uint nodeIndex, uint numberOfNodes)
        private
    {
        Nodes nodes = Nodes(contractManager.getContract("Nodes"));
        uint[] memory activeNodes = nodes.getActiveNodeIds();
        uint numberOfNodesInGroup;
        uint availableAmount = activeNodes.length.sub((nodes.isNodeActive(nodeIndex)) ? 1 : 0);
        if (numberOfNodes > availableAmount) {
            numberOfNodesInGroup = availableAmount;
        } else {
            numberOfNodesInGroup = numberOfNodes;
        }
        uint ignoringTail = 0;
        uint random = uint(keccak256(abi.encodePacked(uint(blockhash(block.number.sub(1))), monitorIndex)));
        for (uint i = 0; i < numberOfNodesInGroup; ++i) {
            uint index = random % (activeNodes.length.sub(ignoringTail));
            if (activeNodes[index] == nodeIndex) {
                _swap(activeNodes, index, activeNodes.length.sub(ignoringTail).sub(1));
                ++ignoringTail;
                index = random % (activeNodes.length.sub(ignoringTail));
            }
            groupsForMonitors[monitorIndex].push(activeNodes[index]);
            _swap(activeNodes, index, activeNodes.length.sub(ignoringTail).sub(1));
            ++ignoringTail;
        }
    }

    function _median(uint[] memory values) private pure returns (uint) {
        if (values.length < 1) {
            revert("Can't calculate _median of empty array");
        }
        _quickSort(values, 0, values.length.sub(1));
        return values[values.length.div(2)];
    }

    function _swap(uint[] memory array, uint index1, uint index2) private pure {
        uint buffer = array[index1];
        array[index1] = array[index2];
        array[index2] = buffer;
    }

    function _find(bytes32 monitorIndex, uint nodeIndex) private view returns (uint index, uint time) {
        index = checkedNodes[monitorIndex].length;
        time = 0;
        for (uint i = 0; i < checkedNodes[monitorIndex].length; i++) {
            uint checkedNodeNodeIndex;
            uint checkedNodeTime;
            checkedNodeNodeIndex = checkedNodes[monitorIndex][i].nodeIndex;
            checkedNodeTime = checkedNodes[monitorIndex][i].time;
            if (checkedNodeNodeIndex == nodeIndex && (time == 0 || checkedNodeTime < time))
            {
                index = i;
                time = checkedNodeTime;
            }
        }
    }

    function _quickSort(uint[] memory array, uint left, uint right) private pure {
        uint leftIndex = left;
        uint rightIndex = right;
        uint middle = array[right.add(left).div(2)];
        while (leftIndex <= rightIndex) {
            while (array[leftIndex] < middle) {
                leftIndex++;
                }
            while (middle < array[rightIndex]) {
                rightIndex--;
                }
            if (leftIndex <= rightIndex) {
                (array[leftIndex], array[rightIndex]) = (array[rightIndex], array[leftIndex]);
                leftIndex++;
                rightIndex = (rightIndex > 0 ? rightIndex.sub(1) : 0);
            }
        }
        if (left < rightIndex)
            _quickSort(array, left, rightIndex);
        if (leftIndex < right)
            _quickSort(array, leftIndex, right);
    }

    function _getCheckedNodeData(uint nodeIndex) private view returns (CheckedNode memory checkedNode) {
        ConstantsHolder constantsHolder = ConstantsHolder(contractManager.getContract("ConstantsHolder"));
        Nodes nodes = Nodes(contractManager.getContract("Nodes"));

        checkedNode.nodeIndex = nodeIndex;
        checkedNode.time = nodes.getNodeNextRewardDate(nodeIndex).sub(constantsHolder.deltaPeriod());
    }

    function _emitVerdictsEvent(
        uint fromMonitorIndex,
        Verdict memory verdict,
        bool receiveVerdict
    )
        private
    {
        uint previousBlockEvent = getLastReceivedVerdictBlock(verdict.toNodeIndex);
        lastVerdictBlocks[keccak256(abi.encodePacked(verdict.toNodeIndex))] = block.number;

        emit VerdictWasSent(
                fromMonitorIndex,
                verdict.toNodeIndex,
                verdict.downtime,
                verdict.latency,
                receiveVerdict,
                previousBlockEvent,
                block.timestamp,
                gasleft()
            );
    }
}
