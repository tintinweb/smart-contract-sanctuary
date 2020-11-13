// SPDX-License-Identifier: AGPL-3.0-only

/*
    Schains.sol - SKALE Manager
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

import "./Permissions.sol";
import "./SchainsInternal.sol";
import "./ConstantsHolder.sol";
import "./KeyStorage.sol";
import "./SkaleVerifier.sol";
import "./FieldOperations.sol";
import "./NodeRotation.sol";
import "./ISkaleDKG.sol";


/**
 * @title Schains - contract contains all functionality logic to manage Schains
 */
contract Schains is Permissions {
    using StringUtils for string;
    using StringUtils for uint;

    struct SchainParameters {
        uint lifetime;
        uint8 typeOfSchain;
        uint16 nonce;
        string name;
    }

    // informs that Schain is created
    event SchainCreated(
        string name,
        address owner,
        uint partOfNode,
        uint lifetime,
        uint numberOfNodes,
        uint deposit,
        uint16 nonce,
        bytes32 schainId,
        uint time,
        uint gasSpend
    );

    event SchainDeleted(
        address owner,
        string name,
        bytes32 indexed schainId
    );

    event NodeRotated(
        bytes32 schainId,
        uint oldNode,
        uint newNode
    );

    event NodeAdded(
        bytes32 schainId,
        uint newNode
    );

    // informs that Schain based on some Nodes
    event SchainNodes(
        string name,
        bytes32 schainId,
        uint[] nodesInGroup,
        uint time,
        uint gasSpend
    );

    bytes32 public constant SCHAIN_CREATOR_ROLE = keccak256("SCHAIN_CREATOR_ROLE");

    /**
     * @dev addSchain - create Schain in the system
     * function could be run only by executor
     * @param from - owner of Schain
     * @param deposit - received amoung of SKL
     * @param data - Schain's data
     */
    function addSchain(address from, uint deposit, bytes calldata data) external allow("SkaleManager") {
        SchainParameters memory schainParameters = _fallbackSchainParametersDataConverter(data);
        ConstantsHolder constantsHolder = ConstantsHolder(contractManager.getContract("ConstantsHolder"));
        uint schainCreationTimeStamp = constantsHolder.schainCreationTimeStamp();
        uint minSchainLifetime = constantsHolder.minimalSchainLifetime();
        require(now >= schainCreationTimeStamp, "It is not a time for creating Schain");
        require(
            schainParameters.lifetime >= minSchainLifetime,
            "Minimal schain lifetime should be satisfied"
        );
        require(
            getSchainPrice(schainParameters.typeOfSchain, schainParameters.lifetime) <= deposit,
            "Not enough money to create Schain");

        _addSchain(from, deposit, schainParameters);
    }

    function addSchainByFoundation(
        uint lifetime,
        uint8 typeOfSchain,
        uint16 nonce,
        string calldata name
    )
        external
    {
        require(hasRole(SCHAIN_CREATOR_ROLE, msg.sender), "Sender is not authorized to create schian");

        SchainParameters memory schainParameters = SchainParameters({
            lifetime: lifetime,
            typeOfSchain: typeOfSchain,
            nonce: nonce,
            name: name
        });

        _addSchain(msg.sender, 0, schainParameters);
    }

    /**
     * @dev deleteSchain - removes Schain from the system
     * function could be run only by executor
     * @param from - owner of Schain
     * @param name - Schain name
     */
    function deleteSchain(address from, string calldata name) external allow("SkaleManager") {
        NodeRotation nodeRotation = NodeRotation(contractManager.getContract("NodeRotation"));
        SchainsInternal schainsInternal = SchainsInternal(contractManager.getContract("SchainsInternal"));
        bytes32 schainId = keccak256(abi.encodePacked(name));
        require(
            schainsInternal.isOwnerAddress(from, schainId),
            "Message sender is not an owner of Schain"
        );
        address nodesAddress = contractManager.getContract("Nodes");

        // removes Schain from Nodes
        uint[] memory nodesInGroup = schainsInternal.getNodesInGroup(schainId);
        uint8 partOfNode = schainsInternal.getSchainsPartOfNode(schainId);
        for (uint i = 0; i < nodesInGroup.length; i++) {
            uint schainIndex = schainsInternal.findSchainAtSchainsForNode(
                nodesInGroup[i],
                schainId
            );
            if (schainsInternal.checkHoleForSchain(schainId, i)) {
                continue;
            }
            require(
                schainIndex < schainsInternal.getLengthOfSchainsForNode(nodesInGroup[i]),
                "Some Node does not contain given Schain");
            schainsInternal.removeNodeFromSchain(nodesInGroup[i], schainId);
            schainsInternal.removeNodeFromExceptions(schainId, nodesInGroup[i]);
            if (!Nodes(nodesAddress).isNodeLeft(nodesInGroup[i])) {
                this.addSpace(nodesInGroup[i], partOfNode);
            }
        }
        schainsInternal.deleteGroup(schainId);
        schainsInternal.removeSchain(schainId, from);
        schainsInternal.removeHolesForSchain(schainId);
        nodeRotation.removeRotation(schainId);
        emit SchainDeleted(from, name, schainId);
    }

    function deleteSchainByRoot(string calldata name) external allow("SkaleManager") {
        NodeRotation nodeRotation = NodeRotation(contractManager.getContract("NodeRotation"));
        bytes32 schainId = keccak256(abi.encodePacked(name));
        SchainsInternal schainsInternal = SchainsInternal(
            contractManager.getContract("SchainsInternal"));
        require(schainsInternal.isSchainExist(schainId), "Schain does not exist");

        // removes Schain from Nodes
        uint[] memory nodesInGroup = schainsInternal.getNodesInGroup(schainId);
        uint8 partOfNode = schainsInternal.getSchainsPartOfNode(schainId);
        for (uint i = 0; i < nodesInGroup.length; i++) {
            uint schainIndex = schainsInternal.findSchainAtSchainsForNode(
                nodesInGroup[i],
                schainId
            );
            if (schainsInternal.checkHoleForSchain(schainId, i)) {
                continue;
            }
            require(
                schainIndex < schainsInternal.getLengthOfSchainsForNode(nodesInGroup[i]),
                "Some Node does not contain given Schain");
            schainsInternal.removeNodeFromSchain(nodesInGroup[i], schainId);
            schainsInternal.removeNodeFromExceptions(schainId, nodesInGroup[i]);
            this.addSpace(nodesInGroup[i], partOfNode);
        }
        schainsInternal.deleteGroup(schainId);
        address from = schainsInternal.getSchainOwner(schainId);
        schainsInternal.removeSchain(schainId, from);
        schainsInternal.removeHolesForSchain(schainId);
        nodeRotation.removeRotation(schainId);
        emit SchainDeleted(from, name, schainId);
    }

    function restartSchainCreation(string calldata name) external allow("SkaleManager") {
        NodeRotation nodeRotation = NodeRotation(contractManager.getContract("NodeRotation"));
        bytes32 schainId = keccak256(abi.encodePacked(name));
        ISkaleDKG skaleDKG = ISkaleDKG(contractManager.getContract("SkaleDKG"));
        require(!skaleDKG.isLastDKGSuccesful(schainId), "DKG success");
        SchainsInternal schainsInternal = SchainsInternal(
            contractManager.getContract("SchainsInternal"));
        require(schainsInternal.isAnyFreeNode(schainId), "No any free Nodes for rotation");
        uint newNodeIndex = nodeRotation.selectNodeToGroup(schainId);
        skaleDKG.openChannel(schainId);
        emit NodeAdded(schainId, newNodeIndex);
    }

    /**
     * @dev addSpace - return occupied space to Node
     * @param nodeIndex - index of Node at common array of Nodes
     * @param partOfNode - divisor of given type of Schain
     */
    function addSpace(uint nodeIndex, uint8 partOfNode) external allowTwo("Schains", "NodeRotation") {
        Nodes nodes = Nodes(contractManager.getContract("Nodes"));
        nodes.addSpaceToNode(nodeIndex, partOfNode);
    }

    /**
     * @dev verifySignature - verify signature which create Group by Groups BLS master public key     
     * @param signatureA - first part of BLS signature
     * @param signatureB - second part of BLS signature
     * @param hash - hashed message
     * @param counter - smallest sub from square
     * @param hashA - first part of hashed message
     * @param hashB - second part of hashed message
     * @param schainName - name of the Schain
     * @return true - if correct, false - if not
     */
    function verifySchainSignature(
        uint signatureA,
        uint signatureB,
        bytes32 hash,
        uint counter,
        uint hashA,
        uint hashB,
        string calldata schainName
    )
        external
        view
        returns (bool)
    {
        SkaleVerifier skaleVerifier = SkaleVerifier(contractManager.getContract("SkaleVerifier"));

        G2Operations.G2Point memory publicKey = KeyStorage(
            contractManager.getContract("KeyStorage")
        ).getCommonPublicKey(
            keccak256(abi.encodePacked(schainName))
        );
        return skaleVerifier.verify(
            Fp2Operations.Fp2Point({
                a: signatureA,
                b: signatureB
            }),
            hash, counter,
            hashA, hashB,
            publicKey
        );
    }

    function initialize(address newContractsAddress) public override initializer {
        Permissions.initialize(newContractsAddress);
    }

    /**
     * @dev getSchainPrice - returns current price for given Schain
     * @param typeOfSchain - type of Schain
     * @param lifetime - lifetime of Schain
     * @return current price for given Schain
     */
    function getSchainPrice(uint typeOfSchain, uint lifetime) public view returns (uint) {
        ConstantsHolder constantsHolder = ConstantsHolder(contractManager.getContract("ConstantsHolder"));
        uint nodeDeposit = constantsHolder.NODE_DEPOSIT();
        uint numberOfNodes;
        uint8 divisor;
        (numberOfNodes, divisor) = getNodesDataFromTypeOfSchain(typeOfSchain);
        if (divisor == 0) {
            return 1e18;
        } else {
            uint up = nodeDeposit.mul(numberOfNodes.mul(lifetime.mul(2)));
            uint down = uint(
                uint(constantsHolder.SMALL_DIVISOR())
                    .mul(uint(constantsHolder.SECONDS_TO_YEAR()))
                    .div(divisor)
            );
            return up.div(down);
        }
    }

    /**
     * @dev getNodesDataFromTypeOfSchain - returns number if Nodes
     * and part of Node which needed to this Schain
     * @param typeOfSchain - type of Schain
     * @return numberOfNodes - number of Nodes needed to this Schain
     * @return partOfNode - divisor of given type of Schain
     */
    function getNodesDataFromTypeOfSchain(uint typeOfSchain)
        public
        view
        returns (uint numberOfNodes, uint8 partOfNode)
    {
        ConstantsHolder constantsHolder = ConstantsHolder(contractManager.getContract("ConstantsHolder"));
        numberOfNodes = constantsHolder.NUMBER_OF_NODES_FOR_SCHAIN();
        if (typeOfSchain == 1) {
            partOfNode = constantsHolder.SMALL_DIVISOR() / constantsHolder.SMALL_DIVISOR();
        } else if (typeOfSchain == 2) {
            partOfNode = constantsHolder.SMALL_DIVISOR() / constantsHolder.MEDIUM_DIVISOR();
        } else if (typeOfSchain == 3) {
            partOfNode = constantsHolder.SMALL_DIVISOR() / constantsHolder.LARGE_DIVISOR();
        } else if (typeOfSchain == 4) {
            partOfNode = 0;
            numberOfNodes = constantsHolder.NUMBER_OF_NODES_FOR_TEST_SCHAIN();
        } else if (typeOfSchain == 5) {
            partOfNode = constantsHolder.SMALL_DIVISOR() / constantsHolder.MEDIUM_TEST_DIVISOR();
            numberOfNodes = constantsHolder.NUMBER_OF_NODES_FOR_MEDIUM_TEST_SCHAIN();
        } else {
            revert("Bad schain type");
        }
    }

    function _initializeSchainInSchainsInternal(
        string memory name,
        address from,
        uint deposit,
        uint lifetime) private
    {
        address dataAddress = contractManager.getContract("SchainsInternal");
        require(SchainsInternal(dataAddress).isSchainNameAvailable(name), "Schain name is not available");

        // initialize Schain
        SchainsInternal(dataAddress).initializeSchain(
            name,
            from,
            lifetime,
            deposit);
        SchainsInternal(dataAddress).setSchainIndex(keccak256(abi.encodePacked(name)), from);
    }

    /**
     * @dev fallbackSchainParameterDataConverter - converts data from bytes to normal parameters
     * @param data - concatenated parameters
     * @return schainParameters Parsed lifetime, typeOfSchain, nonce and name
     */
    function _fallbackSchainParametersDataConverter(bytes memory data)
        private
        pure
        returns (SchainParameters memory schainParameters)
    {
        (schainParameters.lifetime,
        schainParameters.typeOfSchain,
        schainParameters.nonce,
        schainParameters.name) = abi.decode(data, (uint, uint8, uint16, string));
    }

    /**
     * @dev _createGroupForSchain - creates Group for Schain
     * @param schainName - name of Schain
     * @param schainId - hash by name of Schain
     * @param numberOfNodes - number of Nodes needed for this Schain
     * @param partOfNode - divisor of given type of Schain
     */
    function _createGroupForSchain(
        string memory schainName,
        bytes32 schainId,
        uint numberOfNodes,
        uint8 partOfNode
    )
        private
    {
        SchainsInternal schainsInternal = SchainsInternal(contractManager.getContract("SchainsInternal"));
        uint[] memory nodesInGroup = schainsInternal.createGroupForSchain(schainId, numberOfNodes, partOfNode);
        ISkaleDKG(contractManager.getContract("SkaleDKG")).openChannel(schainId);

        emit SchainNodes(
            schainName,
            schainId,
            nodesInGroup,
            block.timestamp,
            gasleft());
    }

    /**
     * @dev _addSchain - create Schain in the system
     * function could be run only by executor
     * @param from - owner of Schain
     * @param deposit - received amoung of SKL
     * @param schainParameters - Schain's data
     */
    function _addSchain(address from, uint deposit, SchainParameters memory schainParameters) private {
        uint numberOfNodes;
        uint8 partOfNode;

        require(schainParameters.typeOfSchain <= 5, "Invalid type of Schain");

        //initialize Schain
        _initializeSchainInSchainsInternal(
            schainParameters.name,
            from,
            deposit,
            schainParameters.lifetime);

        // create a group for Schain
        (numberOfNodes, partOfNode) = getNodesDataFromTypeOfSchain(schainParameters.typeOfSchain);

        _createGroupForSchain(
            schainParameters.name,
            keccak256(abi.encodePacked(schainParameters.name)),
            numberOfNodes,
            partOfNode
        );

        emit SchainCreated(
            schainParameters.name,
            from,
            partOfNode,
            schainParameters.lifetime,
            numberOfNodes,
            deposit,
            schainParameters.nonce,
            keccak256(abi.encodePacked(schainParameters.name)),
            block.timestamp,
            gasleft());
    }
}
