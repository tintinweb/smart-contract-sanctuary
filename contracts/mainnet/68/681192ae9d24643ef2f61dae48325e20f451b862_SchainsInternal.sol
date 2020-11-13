// SPDX-License-Identifier: AGPL-3.0-only

/*
    SchainsInternal.sol - SKALE Manager
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

import "./ConstantsHolder.sol";
import "./Nodes.sol";
import "./ISkaleDKG.sol";

/**
 * @title SchainsInternal - contract contains all functionality logic to manage Schains
 */
contract SchainsInternal is Permissions {

    struct Schain {
        string name;
        address owner;
        uint indexInOwnerList;
        uint8 partOfNode;
        uint lifetime;
        uint startDate;
        uint startBlock;
        uint deposit;
        uint64 index;
    }


    // mapping which contain all schains
    mapping (bytes32 => Schain) public schains;

    mapping (bytes32 => bool) public isSchainActive;

    mapping (bytes32 => uint[]) public schainsGroups;

    mapping (bytes32 => mapping (uint => bool)) private _exceptionsForGroups;
    // mapping shows schains by owner's address
    mapping (address => bytes32[]) public schainIndexes;
    // mapping shows schains which Node composed in
    mapping (uint => bytes32[]) public schainsForNodes;

    mapping (uint => uint[]) public holesForNodes;

    mapping (bytes32 => uint[]) public holesForSchains;


    // array which contain all schains
    bytes32[] public schainsAtSystem;

    uint64 public numberOfSchains;
    // total resources that schains occupied
    uint public sumOfSchainsResources;

    mapping (bytes32 => bool) public usedSchainNames;

    /**
     * @dev initializeSchain - initializes Schain
     * function could be run only by executor
     * @param name - SChain name
     * @param from - Schain owner
     * @param lifetime - initial lifetime of Schain
     * @param deposit - given amount of SKL
     */
    function initializeSchain(
        string calldata name,
        address from,
        uint lifetime,
        uint deposit) external allow("Schains")
    {
        bytes32 schainId = keccak256(abi.encodePacked(name));
        schains[schainId].name = name;
        schains[schainId].owner = from;
        schains[schainId].startDate = block.timestamp;
        schains[schainId].startBlock = block.number;
        schains[schainId].lifetime = lifetime;
        schains[schainId].deposit = deposit;
        schains[schainId].index = numberOfSchains;
        isSchainActive[schainId] = true;
        numberOfSchains++;
        schainsAtSystem.push(schainId);
        usedSchainNames[schainId] = true;
    }

    function createGroupForSchain(
        bytes32 schainId,
        uint numberOfNodes,
        uint8 partOfNode
    )
        external
        allow("Schains")
        returns (uint[] memory)
    {
        ConstantsHolder constantsHolder = ConstantsHolder(contractManager.getContract("ConstantsHolder"));
        schains[schainId].partOfNode = partOfNode;
        if (partOfNode > 0) {
            sumOfSchainsResources = sumOfSchainsResources.add(
                numberOfNodes.mul(constantsHolder.TOTAL_SPACE_ON_NODE()).div(partOfNode)
            );
        }
        return _generateGroup(schainId, numberOfNodes);
    }

    /**
     * @dev setSchainIndex - adds Schain's hash to owner
     * function could be run only by executor
     * @param schainId - hash by Schain name
     * @param from - Schain owner
     */
    function setSchainIndex(bytes32 schainId, address from) external allow("Schains") {
        schains[schainId].indexInOwnerList = schainIndexes[from].length;
        schainIndexes[from].push(schainId);
    }

    /**
     * @dev changeLifetime - changes Lifetime for Schain
     * function could be run only by executor
     * @param schainId - hash by Schain name
     * @param lifetime - time which would be added to lifetime of Schain
     * @param deposit - amount of SKL which payed for this time
     */
    function changeLifetime(bytes32 schainId, uint lifetime, uint deposit) external allow("Schains") {
        schains[schainId].deposit = schains[schainId].deposit.add(deposit);
        schains[schainId].lifetime = schains[schainId].lifetime.add(lifetime);
    }

    /**
     * @dev removeSchain - removes Schain from the system
     * function could be run only by executor
     * @param schainId - hash by Schain name
     * @param from - owner of Schain
     */
    function removeSchain(bytes32 schainId, address from) external allow("Schains") {
        isSchainActive[schainId] = false;
        uint length = schainIndexes[from].length;
        uint index = schains[schainId].indexInOwnerList;
        if (index != length.sub(1)) {
            bytes32 lastSchainId = schainIndexes[from][length.sub(1)];
            schains[lastSchainId].indexInOwnerList = index;
            schainIndexes[from][index] = lastSchainId;
        }
        schainIndexes[from].pop();

        // TODO:
        // optimize
        for (uint i = 0; i + 1 < schainsAtSystem.length; i++) {
            if (schainsAtSystem[i] == schainId) {
                schainsAtSystem[i] = schainsAtSystem[schainsAtSystem.length.sub(1)];
                break;
            }
        }
        schainsAtSystem.pop();

        delete schains[schainId];
        numberOfSchains--;
    }

    function removeNodeFromSchain(
        uint nodeIndex,
        bytes32 schainHash
    )
        external
        allowThree("NodeRotation", "SkaleDKG", "Schains")
    {
        uint indexOfNode = _findNode(schainHash, nodeIndex);
        uint indexOfLastNode = schainsGroups[schainHash].length.sub(1);

        if (indexOfNode == indexOfLastNode) {
            schainsGroups[schainHash].pop();
        } else {
            delete schainsGroups[schainHash][indexOfNode];
            if (holesForSchains[schainHash].length > 0 && holesForSchains[schainHash][0] > indexOfNode) {
                uint hole = holesForSchains[schainHash][0];
                holesForSchains[schainHash][0] = indexOfNode;
                holesForSchains[schainHash].push(hole);
            } else {
                holesForSchains[schainHash].push(indexOfNode);
            }
        }

        uint schainId = findSchainAtSchainsForNode(nodeIndex, schainHash);
        removeSchainForNode(nodeIndex, schainId);
    }

    function removeNodeFromExceptions(bytes32 schainHash, uint nodeIndex) external allow("Schains") {
        _exceptionsForGroups[schainHash][nodeIndex] = false;
    }

    /**
     * @dev deleteGroup - delete Group from Data contract
     * function could be run only by executor
     * @param schainId - Groups identifier
     */
    function deleteGroup(bytes32 schainId) external allow("Schains") {
        // delete channel
        ISkaleDKG skaleDKG = ISkaleDKG(contractManager.getContract("SkaleDKG"));

        delete schainsGroups[schainId];
        if (skaleDKG.isChannelOpened(schainId)) {
            skaleDKG.deleteChannel(schainId);
        }
    }

    /**
     * @dev setException - sets a Node like exception
     * function could be run only by executor
     * @param schainId - Groups identifier
     * @param nodeIndex - index of Node which would be notes like exception
     */
    function setException(bytes32 schainId, uint nodeIndex) external allowTwo("Schains", "NodeRotation") {
        _exceptionsForGroups[schainId][nodeIndex] = true;
    }

    /**
     * @dev setNodeInGroup - adds Node to Group
     * function could be run only by executor
     * @param schainId - Groups
     * @param nodeIndex - index of Node which would be added to the Group
     */
    function setNodeInGroup(bytes32 schainId, uint nodeIndex) external allowTwo("Schains", "NodeRotation") {
        if (holesForSchains[schainId].length == 0) {
            schainsGroups[schainId].push(nodeIndex);
        } else {
            schainsGroups[schainId][holesForSchains[schainId][0]] = nodeIndex;
            uint min = uint(-1);
            uint index = 0;
            for (uint i = 1; i < holesForSchains[schainId].length; i++) {
                if (min > holesForSchains[schainId][i]) {
                    min = holesForSchains[schainId][i];
                    index = i;
                }
            }
            if (min == uint(-1)) {
                delete holesForSchains[schainId];
            } else {
                holesForSchains[schainId][0] = min;
                holesForSchains[schainId][index] =
                    holesForSchains[schainId][holesForSchains[schainId].length - 1];
                holesForSchains[schainId].pop();
            }
        }
    }

    function removeHolesForSchain(bytes32 schainHash) external allow("Schains") {
        delete holesForSchains[schainHash];
    }

    /**
     * @dev getSchains - gets all Schains at the system
     * @return array of hashes by Schain names
     */
    function getSchains() external view returns (bytes32[] memory) {
        return schainsAtSystem;
    }

    /**
     * @dev getSchainsPartOfNode - gets occupied space for given Schain
     * @param schainId - hash by Schain name
     * @return occupied space
     */
    function getSchainsPartOfNode(bytes32 schainId) external view returns (uint8) {
        return schains[schainId].partOfNode;
    }

    /**
     * @dev getSchainListSize - gets number of created Schains at the system by owner
     * @param from - owner of Schain
     * return number of Schains
     */
    function getSchainListSize(address from) external view returns (uint) {
        return schainIndexes[from].length;
    }

    /**
     * @dev getSchainIdsByAddress - gets array of hashes by Schain names which owned by `from`
     * @param from - owner of some Schains
     * @return array of hashes by Schain names
     */
    function getSchainIdsByAddress(address from) external view returns (bytes32[] memory) {
        return schainIndexes[from];
    }

    /**
     * @dev getSchainIdsForNode - returns array of hashes by Schain names,
     * which given Node composed
     * @param nodeIndex - index of Node
     * @return array of hashes by Schain names
     */
    function getSchainIdsForNode(uint nodeIndex) external view returns (bytes32[] memory) {
        return schainsForNodes[nodeIndex];
    }

    function getSchainOwner(bytes32 schainId) external view returns (address) {
        return schains[schainId].owner;
    }

    /**
     * @dev isSchainNameAvailable - checks is given name available
     * Need to delete - copy of web3.utils.soliditySha3
     * @param name - possible new name of Schain
     * @return if available - true, else - false
     */
    function isSchainNameAvailable(string calldata name) external view returns (bool) {
        bytes32 schainId = keccak256(abi.encodePacked(name));
        return schains[schainId].owner == address(0) && !usedSchainNames[schainId];
    }

    /**
     * @dev isTimeExpired - checks is Schain lifetime expired
     * @param schainId - hash by Schain name
     * @return if expired - true, else - false
     */
    function isTimeExpired(bytes32 schainId) external view returns (bool) {
        return uint(schains[schainId].startDate).add(schains[schainId].lifetime) < block.timestamp;
    }

    /**
     * @dev isOwnerAddress - checks is `from` - owner of `schainId` Schain
     * @param from - owner of Schain
     * @param schainId - hash by Schain name
     * @return if owner - true, else - false
     */
    function isOwnerAddress(address from, bytes32 schainId) external view returns (bool) {
        return schains[schainId].owner == from;
    }

    function isSchainExist(bytes32 schainId) external view returns (bool) {
        return keccak256(abi.encodePacked(schains[schainId].name)) != keccak256(abi.encodePacked(""));
    }

    function getSchainName(bytes32 schainId) external view returns (string memory) {
        return schains[schainId].name;
    }

    function getActiveSchain(uint nodeIndex) external view returns (bytes32) {
        for (uint i = schainsForNodes[nodeIndex].length; i > 0; i--) {
            if (schainsForNodes[nodeIndex][i - 1] != bytes32(0)) {
                return schainsForNodes[nodeIndex][i - 1];
            }
        }
        return bytes32(0);
    }

    function getActiveSchains(uint nodeIndex) external view returns (bytes32[] memory activeSchains) {
        uint activeAmount = 0;
        for (uint i = 0; i < schainsForNodes[nodeIndex].length; i++) {
            if (schainsForNodes[nodeIndex][i] != bytes32(0)) {
                activeAmount++;
            }
        }

        uint cursor = 0;
        activeSchains = new bytes32[](activeAmount);
        for (uint i = schainsForNodes[nodeIndex].length; i > 0; i--) {
            if (schainsForNodes[nodeIndex][i - 1] != bytes32(0)) {
                activeSchains[cursor++] = schainsForNodes[nodeIndex][i - 1];
            }
        }
    }

    /**
     * @dev getNumberOfNodesInGroup - shows number of Nodes in Group
     * @param schainId - Groups identifier
     * @return number of Nodes in Group
     */
    function getNumberOfNodesInGroup(bytes32 schainId) external view returns (uint) {
        return schainsGroups[schainId].length;
    }

    /**
     * @dev getNodesInGroup - shows Nodes in Group
     * @param schainId - Groups identifier
     * @return array of indexes of Nodes in Group
     */
    function getNodesInGroup(bytes32 schainId) external view returns (uint[] memory) {
        return schainsGroups[schainId];
    }

    /**
     * @dev getNodeIndexInGroup - looks for Node in Group
     * @param schainId - Groups identifier
     * @param nodeId - Nodes identifier
     * @return index of Node in Group
     */
    function getNodeIndexInGroup(bytes32 schainId, uint nodeId) external view returns (uint) {
        for (uint index = 0; index < schainsGroups[schainId].length; index++) {
            if (schainsGroups[schainId][index] == nodeId) {
                return index;
            }
        }
        return schainsGroups[schainId].length;
    }

    function isAnyFreeNode(bytes32 schainId) external view returns (bool) {
        Nodes nodes = Nodes(contractManager.getContract("Nodes"));
        uint8 space = schains[schainId].partOfNode;
        uint[] memory nodesWithFreeSpace = nodes.getNodesWithFreeSpace(space);
        for (uint i = 0; i < nodesWithFreeSpace.length; i++) {
            if (_isCorrespond(schainId, nodesWithFreeSpace[i])) {
                return true;
            }
        }
        return false;
    }

    function checkException(bytes32 schainId, uint nodeIndex) external view returns (bool) {
        return _exceptionsForGroups[schainId][nodeIndex];
    }

    function checkHoleForSchain(bytes32 schainHash, uint indexOfNode) external view returns (bool) {
        for (uint i = 0; i < holesForSchains[schainHash].length; i++) {
            if (holesForSchains[schainHash][i] == indexOfNode) {
                return true;
            }
        }
        return false;
    }

    function initialize(address newContractsAddress) public override initializer {
        Permissions.initialize(newContractsAddress);

        numberOfSchains = 0;
        sumOfSchainsResources = 0;
    }

    /**
     * @dev addSchainForNode - adds Schain hash to Node
     * function could be run only by executor
     * @param nodeIndex - index of Node
     * @param schainId - hash by Schain name
     */
    function addSchainForNode(uint nodeIndex, bytes32 schainId) public allowTwo("Schains", "NodeRotation") {
        if (holesForNodes[nodeIndex].length == 0) {
            schainsForNodes[nodeIndex].push(schainId);
        } else {
            schainsForNodes[nodeIndex][holesForNodes[nodeIndex][0]] = schainId;
            uint min = uint(-1);
            uint index = 0;
            for (uint i = 1; i < holesForNodes[nodeIndex].length; i++) {
                if (min > holesForNodes[nodeIndex][i]) {
                    min = holesForNodes[nodeIndex][i];
                    index = i;
                }
            }
            if (min == uint(-1)) {
                delete holesForNodes[nodeIndex];
            } else {
                holesForNodes[nodeIndex][0] = min;
                holesForNodes[nodeIndex][index] = holesForNodes[nodeIndex][holesForNodes[nodeIndex].length - 1];
                holesForNodes[nodeIndex].pop();
            }
        }
    }

    /**
     * @dev removesSchainForNode - clean given Node of Schain
     * function could be run only by executor
     * @param nodeIndex - index of Node
     * @param schainIndex - index of Schain in schainsForNodes array by this Node
     */
    function removeSchainForNode(uint nodeIndex, uint schainIndex)
        public
        allowThree("NodeRotation", "SkaleDKG", "Schains")
    {
        uint length = schainsForNodes[nodeIndex].length;
        if (schainIndex == length.sub(1)) {
            schainsForNodes[nodeIndex].pop();
        } else {
            schainsForNodes[nodeIndex][schainIndex] = bytes32(0);
            if (holesForNodes[nodeIndex].length > 0 && holesForNodes[nodeIndex][0] > schainIndex) {
                uint hole = holesForNodes[nodeIndex][0];
                holesForNodes[nodeIndex][0] = schainIndex;
                holesForNodes[nodeIndex].push(hole);
            } else {
                holesForNodes[nodeIndex].push(schainIndex);
            }
        }
    }

    /**
     * @dev getLengthOfSchainsForNode - returns number of Schains which contain given Node
     * @param nodeIndex - index of Node
     * @return number of Schains
     */
    function getLengthOfSchainsForNode(uint nodeIndex) public view returns (uint) {
        return schainsForNodes[nodeIndex].length;
    }

    /**
     * @dev findSchainAtSchainsForNode - finds index of Schain at schainsForNode array
     * @param nodeIndex - index of Node at common array of Nodes
     * @param schainId - hash of name of Schain
     * @return index of Schain at schainsForNode array
     */
    function findSchainAtSchainsForNode(uint nodeIndex, bytes32 schainId) public view returns (uint) {
        uint length = getLengthOfSchainsForNode(nodeIndex);
        for (uint i = 0; i < length; i++) {
            if (schainsForNodes[nodeIndex][i] == schainId) {
                return i;
            }
        }
        return length;
    }

    function isEnoughNodes(bytes32 schainId) public view returns (uint[] memory result) {
        Nodes nodes = Nodes(contractManager.getContract("Nodes"));
        uint8 space = schains[schainId].partOfNode;
        uint[] memory nodesWithFreeSpace = nodes.getNodesWithFreeSpace(space);
        uint counter = 0;
        for (uint i = 0; i < nodesWithFreeSpace.length; i++) {
            if (!_isCorrespond(schainId, nodesWithFreeSpace[i])) {
                counter++;
            }
        }
        if (counter < nodesWithFreeSpace.length) {
            result = new uint[](nodesWithFreeSpace.length.sub(counter));
            counter = 0;
            for (uint i = 0; i < nodesWithFreeSpace.length; i++) {
                if (_isCorrespond(schainId, nodesWithFreeSpace[i])) {
                    result[counter] = nodesWithFreeSpace[i];
                    counter++;
                }
            }
        }
    }

    /**
     * @dev _generateGroup - generates Group for Schain
     * @param schainId - index of Group
     */
    function _generateGroup(bytes32 schainId, uint numberOfNodes) private returns (uint[] memory nodesInGroup) {
        Nodes nodes = Nodes(contractManager.getContract("Nodes"));
        uint8 space = schains[schainId].partOfNode;
        nodesInGroup = new uint[](numberOfNodes);

        uint[] memory possibleNodes = isEnoughNodes(schainId);
        require(possibleNodes.length >= nodesInGroup.length, "Not enough nodes to create Schain");
        uint ignoringTail = 0;
        uint random = uint(keccak256(abi.encodePacked(uint(blockhash(block.number.sub(1))), schainId)));
        for (uint i = 0; i < nodesInGroup.length; ++i) {
            uint index = random % (possibleNodes.length.sub(ignoringTail));
            uint node = possibleNodes[index];
            nodesInGroup[i] = node;
            _swap(possibleNodes, index, possibleNodes.length.sub(ignoringTail).sub(1));
            ++ignoringTail;

            _exceptionsForGroups[schainId][node] = true;
            addSchainForNode(node, schainId);
            require(nodes.removeSpaceFromNode(node, space), "Could not remove space from Node");
        }

        // set generated group
        schainsGroups[schainId] = nodesInGroup;
    }

    function _isCorrespond(bytes32 schainId, uint nodeIndex) private view returns (bool) {
        Nodes nodes = Nodes(contractManager.getContract("Nodes"));
        return !_exceptionsForGroups[schainId][nodeIndex] && nodes.isNodeActive(nodeIndex);
    }

    function _swap(uint[] memory array, uint index1, uint index2) private pure {
        uint buffer = array[index1];
        array[index1] = array[index2];
        array[index2] = buffer;
    }

    /**
     * @dev findNode - find local index of Node in Schain
     * @param schainId - Groups identifier
     * @param nodeIndex - global index of Node
     * @return local index of Node in Schain
     */
    function _findNode(bytes32 schainId, uint nodeIndex) private view returns (uint) {
        uint[] memory nodesInGroup = schainsGroups[schainId];
        uint index;
        for (index = 0; index < nodesInGroup.length; index++) {
            if (nodesInGroup[index] == nodeIndex) {
                return index;
            }
        }
        return index;
    }

}
