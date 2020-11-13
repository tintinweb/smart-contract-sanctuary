// SPDX-License-Identifier: AGPL-3.0-only

/*
    SkaleDKG.sol - SKALE Manager
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
import "./Punisher.sol";
import "./SlashingTable.sol";
import "./Schains.sol";
import "./SchainsInternal.sol";
import "./FieldOperations.sol";
import "./NodeRotation.sol";
import "./KeyStorage.sol";
import "./ISkaleDKG.sol";
import "./ECDH.sol";
import "./Precompiled.sol";

contract SkaleDKG is Permissions, ISkaleDKG {
    using Fp2Operations for Fp2Operations.Fp2Point;
    using G2Operations for G2Operations.G2Point;

    struct Channel {
        bool active;
        uint n;
        uint startedBlockTimestamp;
        uint startedBlock;
    }

    struct ProcessDKG {
        uint numberOfBroadcasted;
        uint numberOfCompleted;
        bool[] broadcasted;
        bool[] completed;
    }

    struct ComplaintData {
        uint nodeToComplaint;
        uint fromNodeToComplaint;
        uint startComplaintBlockTimestamp;
    }

    struct KeyShare {
        bytes32[2] publicKey;
        bytes32 share;
    }

    uint public constant COMPLAINT_TIMELIMIT = 1800;

    mapping(bytes32 => Channel) public channels;

    mapping(bytes32 => uint) public lastSuccesfulDKG;

    mapping(bytes32 => ProcessDKG) public dkgProcess;

    mapping(bytes32 => ComplaintData) public complaints;

    mapping(bytes32 => uint) public startAlrightTimestamp;

    mapping(bytes32 => mapping(uint => bytes32)) public hashedData;

    event ChannelOpened(bytes32 groupIndex);

    event ChannelClosed(bytes32 groupIndex);

    event BroadcastAndKeyShare(
        bytes32 indexed groupIndex,
        uint indexed fromNode,
        G2Operations.G2Point[] verificationVector,
        KeyShare[] secretKeyContribution
    );

    event AllDataReceived(bytes32 indexed groupIndex, uint nodeIndex);
    event SuccessfulDKG(bytes32 indexed groupIndex);
    event BadGuy(uint nodeIndex);
    event FailedDKG(bytes32 indexed groupIndex);
    event ComplaintSent(bytes32 indexed groupIndex, uint indexed fromNodeIndex, uint indexed toNodeIndex);
    event NewGuy(uint nodeIndex);
    event ComplaintError(string error);

    modifier correctGroup(bytes32 groupIndex) {
        require(channels[groupIndex].active, "Group is not created");
        _;
    }

    modifier correctGroupWithoutRevert(bytes32 groupIndex) {
        if (!channels[groupIndex].active) {
            emit ComplaintError("Group is not created");
        } else {
            _;
        }
    }

    modifier correctNode(bytes32 groupIndex, uint nodeIndex) {
        uint index = _nodeIndexInSchain(groupIndex, nodeIndex);
        require(
            index < channels[groupIndex].n,
            "Node is not in this group");
        _;
    }

    modifier correctNodeWithoutRevert(bytes32 groupIndex, uint nodeIndex) {
        uint index = _nodeIndexInSchain(groupIndex, nodeIndex);
        if (index >= channels[groupIndex].n) {
            emit ComplaintError("Node is not in this group");
        } else {
            _;
        }
    }

    function openChannel(bytes32 groupIndex) external override allowTwo("Schains","NodeRotation") {
        _openChannel(groupIndex);
    }

    function deleteChannel(bytes32 groupIndex) external override allow("SchainsInternal") {
        require(channels[groupIndex].active, "Channel is not created");
        delete channels[groupIndex];
        delete dkgProcess[groupIndex];
        delete complaints[groupIndex];
        KeyStorage(contractManager.getContract("KeyStorage")).deleteKey(groupIndex);
    }

    function broadcast(
        bytes32 groupIndex,
        uint nodeIndex,
        G2Operations.G2Point[] calldata verificationVector,
        KeyShare[] calldata secretKeyContribution
    )
        external
        correctGroup(groupIndex)
    {
        require(_isNodeByMessageSender(nodeIndex, msg.sender), "Node does not exist for message sender");
        uint n = channels[groupIndex].n;
        require(verificationVector.length == getT(n), "Incorrect number of verification vectors");
        require(
            secretKeyContribution.length == n,
            "Incorrect number of secret key shares"
        );
        uint index = _nodeIndexInSchain(groupIndex, nodeIndex);
        require(index < channels[groupIndex].n, "Node is not in this group");
        require(!dkgProcess[groupIndex].broadcasted[index], "This node has already broadcasted");
        dkgProcess[groupIndex].broadcasted[index] = true;
        dkgProcess[groupIndex].numberOfBroadcasted++;
        if (dkgProcess[groupIndex].numberOfBroadcasted == channels[groupIndex].n) {
            startAlrightTimestamp[groupIndex] = now;
        }
        hashedData[groupIndex][index] = _hashData(secretKeyContribution, verificationVector);
        KeyStorage keyStorage = KeyStorage(contractManager.getContract("KeyStorage"));
        keyStorage.adding(groupIndex, verificationVector[0]);
        emit BroadcastAndKeyShare(
            groupIndex,
            nodeIndex,
            verificationVector,
            secretKeyContribution
        );
    }

    function complaint(bytes32 groupIndex, uint fromNodeIndex, uint toNodeIndex)
        external
        correctGroupWithoutRevert(groupIndex)
        correctNode(groupIndex, fromNodeIndex)
        correctNodeWithoutRevert(groupIndex, toNodeIndex)
    {
        require(_isNodeByMessageSender(fromNodeIndex, msg.sender), "Node does not exist for message sender");
        require(isNodeBroadcasted(groupIndex, fromNodeIndex), "Node has not broadcasted");
        bool broadcasted = isNodeBroadcasted(groupIndex, toNodeIndex);
        if (broadcasted) {
            _handleComplaintWhenBroadcasted(groupIndex, fromNodeIndex, toNodeIndex);
            return;
        } else {
            // not broadcasted in 30 min
            if (channels[groupIndex].startedBlockTimestamp.add(COMPLAINT_TIMELIMIT) <= block.timestamp) {
                _finalizeSlashing(groupIndex, toNodeIndex);
                return;
            }
            emit ComplaintError("Complaint sent too early");
            return;
        }
    }

    function response(
        bytes32 groupIndex,
        uint fromNodeIndex,
        uint secretNumber,
        G2Operations.G2Point calldata multipliedShare,
        G2Operations.G2Point[] calldata verificationVector,
        KeyShare[] calldata secretKeyContribution
    )
        external
        correctGroup(groupIndex)
    {
        uint indexOnSchain = _nodeIndexInSchain(groupIndex, fromNodeIndex);
        require(indexOnSchain < channels[groupIndex].n, "Node is not in this group");
        require(complaints[groupIndex].nodeToComplaint == fromNodeIndex, "Not this Node");
        require(_isNodeByMessageSender(fromNodeIndex, msg.sender), "Node does not exist for message sender");
        require(
            hashedData[groupIndex][indexOnSchain] == _hashData(secretKeyContribution, verificationVector),
            "Broadcasted Data is not correct"
        );
        uint index = _nodeIndexInSchain(groupIndex, complaints[groupIndex].fromNodeToComplaint);
        _verifyDataAndSlash(
            groupIndex,
            indexOnSchain,
            secretNumber,
            multipliedShare,
            verificationVector,
            secretKeyContribution[index].share
         );
    }

    function alright(bytes32 groupIndex, uint fromNodeIndex)
        external
        correctGroup(groupIndex)
        correctNode(groupIndex, fromNodeIndex)
    {
        require(_isNodeByMessageSender(fromNodeIndex, msg.sender), "Node does not exist for message sender");
        uint index = _nodeIndexInSchain(groupIndex, fromNodeIndex);
        uint numberOfParticipant = channels[groupIndex].n;
        require(numberOfParticipant == dkgProcess[groupIndex].numberOfBroadcasted, "Still Broadcasting phase");
        require(
            complaints[groupIndex].fromNodeToComplaint != fromNodeIndex ||
            (fromNodeIndex == 0 && complaints[groupIndex].startComplaintBlockTimestamp == 0),
            "Node has already sent complaint"
        );
        require(!dkgProcess[groupIndex].completed[index], "Node is already alright");
        dkgProcess[groupIndex].completed[index] = true;
        dkgProcess[groupIndex].numberOfCompleted++;
        emit AllDataReceived(groupIndex, fromNodeIndex);
        if (dkgProcess[groupIndex].numberOfCompleted == numberOfParticipant) {
            _setSuccesfulDKG(groupIndex);
        }
    }

    function getChannelStartedTime(bytes32 groupIndex) external view returns (uint) {
        return channels[groupIndex].startedBlockTimestamp;
    }

    function getChannelStartedBlock(bytes32 groupIndex) external view returns (uint) {
        return channels[groupIndex].startedBlock;
    }

    function getNumberOfBroadcasted(bytes32 groupIndex) external view returns (uint) {
        return dkgProcess[groupIndex].numberOfBroadcasted;
    }

    function getNumberOfCompleted(bytes32 groupIndex) external view returns (uint) {
        return dkgProcess[groupIndex].numberOfCompleted;
    }

    function getTimeOfLastSuccesfulDKG(bytes32 groupIndex) external view returns (uint) {
        return lastSuccesfulDKG[groupIndex];
    }

    function getComplaintData(bytes32 groupIndex) external view returns (uint, uint) {
        return (complaints[groupIndex].fromNodeToComplaint, complaints[groupIndex].nodeToComplaint);
    }

    function getComplaintStartedTime(bytes32 groupIndex) external view returns (uint) {
        return complaints[groupIndex].startComplaintBlockTimestamp;
    }

    function getAlrightStartedTime(bytes32 groupIndex) external view returns (uint) {
        return startAlrightTimestamp[groupIndex];
    }

    function isChannelOpened(bytes32 groupIndex) external override view returns (bool) {
        return channels[groupIndex].active;
    }

    function isLastDKGSuccesful(bytes32 groupIndex) external override view returns (bool) {
        return channels[groupIndex].startedBlockTimestamp <= lastSuccesfulDKG[groupIndex];
    }

    function isBroadcastPossible(bytes32 groupIndex, uint nodeIndex) external view returns (bool) {
        uint index = _nodeIndexInSchain(groupIndex, nodeIndex);
        return channels[groupIndex].active &&
            index <  channels[groupIndex].n &&
            _isNodeByMessageSender(nodeIndex, msg.sender) &&
            !dkgProcess[groupIndex].broadcasted[index];
    }

    function isComplaintPossible(
        bytes32 groupIndex,
        uint fromNodeIndex,
        uint toNodeIndex
    )
        external
        view
        returns (bool)
    {
        uint indexFrom = _nodeIndexInSchain(groupIndex, fromNodeIndex);
        uint indexTo = _nodeIndexInSchain(groupIndex, toNodeIndex);
        bool complaintSending = (
                complaints[groupIndex].nodeToComplaint == uint(-1) &&
                dkgProcess[groupIndex].broadcasted[indexTo] &&
                !dkgProcess[groupIndex].completed[indexFrom]
            ) ||
            (
                dkgProcess[groupIndex].broadcasted[indexTo] &&
                complaints[groupIndex].startComplaintBlockTimestamp.add(COMPLAINT_TIMELIMIT) <= block.timestamp &&
                complaints[groupIndex].nodeToComplaint == toNodeIndex
            ) ||
            (
                !dkgProcess[groupIndex].broadcasted[indexTo] &&
                complaints[groupIndex].nodeToComplaint == uint(-1) &&
                channels[groupIndex].startedBlockTimestamp.add(COMPLAINT_TIMELIMIT) <= block.timestamp
            ) ||
            (
                complaints[groupIndex].nodeToComplaint == uint(-1) &&
                isEveryoneBroadcasted(groupIndex) &&
                dkgProcess[groupIndex].completed[indexFrom] &&
                !dkgProcess[groupIndex].completed[indexTo] &&
                startAlrightTimestamp[groupIndex].add(COMPLAINT_TIMELIMIT) <= block.timestamp
            );
        return channels[groupIndex].active &&
            indexFrom < channels[groupIndex].n &&
            indexTo < channels[groupIndex].n &&
            dkgProcess[groupIndex].broadcasted[indexFrom] &&
            _isNodeByMessageSender(fromNodeIndex, msg.sender) &&
            complaintSending;
    }

    function isAlrightPossible(bytes32 groupIndex, uint nodeIndex) external view returns (bool) {
        uint index = _nodeIndexInSchain(groupIndex, nodeIndex);
        return channels[groupIndex].active &&
            index < channels[groupIndex].n &&
            _isNodeByMessageSender(nodeIndex, msg.sender) &&
            channels[groupIndex].n == dkgProcess[groupIndex].numberOfBroadcasted &&
            (complaints[groupIndex].fromNodeToComplaint != nodeIndex ||
            (nodeIndex == 0 && complaints[groupIndex].startComplaintBlockTimestamp == 0)) &&
            !dkgProcess[groupIndex].completed[index];
    }

    function isResponsePossible(bytes32 groupIndex, uint nodeIndex) external view returns (bool) {
        uint index = _nodeIndexInSchain(groupIndex, nodeIndex);
        return channels[groupIndex].active &&
            index < channels[groupIndex].n &&
            _isNodeByMessageSender(nodeIndex, msg.sender) &&
            complaints[groupIndex].nodeToComplaint == nodeIndex;
    }

    function initialize(address contractsAddress) public override initializer {
        Permissions.initialize(contractsAddress);
    }

    function isNodeBroadcasted(bytes32 groupIndex, uint nodeIndex) public view returns (bool) {
        uint index = _nodeIndexInSchain(groupIndex, nodeIndex);
        return index < channels[groupIndex].n && dkgProcess[groupIndex].broadcasted[index];
    }

    function isEveryoneBroadcasted(bytes32 groupIndex) public view returns (bool) {
        return channels[groupIndex].n == dkgProcess[groupIndex].numberOfBroadcasted;
    }

    function isAllDataReceived(bytes32 groupIndex, uint nodeIndex) public view returns (bool) {
        uint index = _nodeIndexInSchain(groupIndex, nodeIndex);
        return dkgProcess[groupIndex].completed[index];
    }

    function getT(uint n) public pure returns (uint) {
        return n.mul(2).add(1).div(3);
    }

    function _setSuccesfulDKG(bytes32 groupIndex) internal {
        lastSuccesfulDKG[groupIndex] = now;
        channels[groupIndex].active = false;
        KeyStorage(contractManager.getContract("KeyStorage")).finalizePublicKey(groupIndex);
        emit SuccessfulDKG(groupIndex);
    }

    function _verifyDataAndSlash(
        bytes32 groupIndex,
        uint indexOnSchain,
        uint secretNumber,
        G2Operations.G2Point calldata multipliedShare,
        G2Operations.G2Point[] calldata verificationVector,
        bytes32 share
    )
        internal
    {
        bytes32[2] memory publicKey = Nodes(contractManager.getContract("Nodes")).getNodePublicKey(
            complaints[groupIndex].fromNodeToComplaint
        );
        uint256 pkX = uint(publicKey[0]);

        (pkX, ) = ECDH(contractManager.getContract("ECDH")).deriveKey(secretNumber, pkX, uint(publicKey[1]));
        bytes32 key = bytes32(pkX);

        // Decrypt secret key contribution
        uint secret = Decryption(contractManager.getContract("Decryption")).decrypt(
            share,
            key
        );

        uint badNode = (_checkCorrectMultipliedShare(multipliedShare, indexOnSchain, secret, verificationVector) ?
            complaints[groupIndex].fromNodeToComplaint : complaints[groupIndex].nodeToComplaint);
        _finalizeSlashing(groupIndex, badNode);
    }

    function _checkCorrectMultipliedShare(
        G2Operations.G2Point memory multipliedShare,
        uint indexOnSchain,
        uint secret,
        G2Operations.G2Point[] calldata verificationVector
    )
        private
        view
        returns (bool)
    {
        if (!multipliedShare.isG2()) {
            return false;
        }
        G2Operations.G2Point memory value = G2Operations.getG2Zero();
        G2Operations.G2Point memory tmp = G2Operations.getG2Zero();
        for (uint i = 0; i < verificationVector.length; i++) {
            tmp = verificationVector[i].mulG2(indexOnSchain.add(1) ** i);
            value = tmp.addG2(value);
        }
        tmp = multipliedShare;
        Fp2Operations.Fp2Point memory g1 = G2Operations.getG1();
        Fp2Operations.Fp2Point memory share = Fp2Operations.Fp2Point({
            a: 0,
            b: 0
        });
        (share.a, share.b) = Precompiled.bn256ScalarMul(g1.a, g1.b, secret);
        if (!(share.a == 0 && share.b == 0)) {
            share.b = Fp2Operations.P.sub((share.b % Fp2Operations.P));
        }

        require(G2Operations.isG1(share), "mulShare not in G1");

        G2Operations.G2Point memory g2 = G2Operations.getG2();
        require(G2Operations.isG2(tmp), "tmp not in g2");

        return value.isEqual(multipliedShare) && Precompiled.bn256Pairing(
            share.a, share.b,
            g2.x.b, g2.x.a, g2.y.b, g2.y.a,
            g1.a, g1.b,
            tmp.x.b, tmp.x.a, tmp.y.b, tmp.y.a);
    }

    function _openChannel(bytes32 groupIndex) private {
        SchainsInternal schainsInternal = SchainsInternal(
            contractManager.getContract("SchainsInternal")
        );

        uint len = schainsInternal.getNumberOfNodesInGroup(groupIndex);
        channels[groupIndex].active = true;
        channels[groupIndex].n = len;
        delete dkgProcess[groupIndex].completed;
        delete dkgProcess[groupIndex].broadcasted;
        dkgProcess[groupIndex].broadcasted = new bool[](len);
        dkgProcess[groupIndex].completed = new bool[](len);
        complaints[groupIndex].fromNodeToComplaint = uint(-1);
        complaints[groupIndex].nodeToComplaint = uint(-1);
        delete complaints[groupIndex].startComplaintBlockTimestamp;
        delete dkgProcess[groupIndex].numberOfBroadcasted;
        delete dkgProcess[groupIndex].numberOfCompleted;
        channels[groupIndex].startedBlockTimestamp = now;
        channels[groupIndex].startedBlock = block.number;
        KeyStorage(contractManager.getContract("KeyStorage")).initPublicKeyInProgress(groupIndex);

        emit ChannelOpened(groupIndex);
    }

    function _handleComplaintWhenBroadcasted(bytes32 groupIndex, uint fromNodeIndex, uint toNodeIndex) private {
        // incorrect data or missing alright
        if (complaints[groupIndex].nodeToComplaint == uint(-1)) {
            if (
                isEveryoneBroadcasted(groupIndex) &&
                !isAllDataReceived(groupIndex, toNodeIndex) &&
                startAlrightTimestamp[groupIndex].add(COMPLAINT_TIMELIMIT) <= block.timestamp
            ) {
                // missing alright
                _finalizeSlashing(groupIndex, toNodeIndex);
                return;
            } else if (!isAllDataReceived(groupIndex, fromNodeIndex)) {
                // incorrect data
                complaints[groupIndex].nodeToComplaint = toNodeIndex;
                complaints[groupIndex].fromNodeToComplaint = fromNodeIndex;
                complaints[groupIndex].startComplaintBlockTimestamp = block.timestamp;
                emit ComplaintSent(groupIndex, fromNodeIndex, toNodeIndex);
                return;
            }
            emit ComplaintError("Has already sent alright");
            return;
        } else if (complaints[groupIndex].nodeToComplaint == toNodeIndex) {
            // 30 min after incorrect data complaint
            if (complaints[groupIndex].startComplaintBlockTimestamp.add(COMPLAINT_TIMELIMIT) <= block.timestamp) {
                _finalizeSlashing(groupIndex, complaints[groupIndex].nodeToComplaint);
                return;
            }
            emit ComplaintError("The same complaint rejected");
            return;
        }
        emit ComplaintError("One complaint is already sent");
    }

    function _finalizeSlashing(bytes32 groupIndex, uint badNode) private {
        NodeRotation nodeRotation = NodeRotation(contractManager.getContract("NodeRotation"));
        SchainsInternal schainsInternal = SchainsInternal(
            contractManager.getContract("SchainsInternal")
        );
        emit BadGuy(badNode);
        emit FailedDKG(groupIndex);

        if (schainsInternal.isAnyFreeNode(groupIndex)) {
            uint newNode = nodeRotation.rotateNode(
                badNode,
                groupIndex,
                false
            );
            emit NewGuy(newNode);
        } else {
            _openChannel(groupIndex);
            schainsInternal.removeNodeFromSchain(
                badNode,
                groupIndex
            );
            channels[groupIndex].active = false;
        }
        Punisher(contractManager.getContract("Punisher")).slash(
            Nodes(contractManager.getContract("Nodes")).getValidatorId(badNode),
            SlashingTable(contractManager.getContract("SlashingTable")).getPenalty("FailedDKG")
        );
    }

    function _nodeIndexInSchain(bytes32 schainId, uint nodeIndex) private view returns (uint) {
        return SchainsInternal(contractManager.getContract("SchainsInternal"))
            .getNodeIndexInGroup(schainId, nodeIndex);
    }

    function _isNodeByMessageSender(uint nodeIndex, address from) private view returns (bool) {
        Nodes nodes = Nodes(contractManager.getContract("Nodes"));
        return nodes.isNodeExist(from, nodeIndex);
    }

    function _hashData(
        KeyShare[] memory secretKeyContribution,
        G2Operations.G2Point[] memory verificationVector
    )
        private
        pure
        returns (bytes32)
    {
        bytes memory data;
        for (uint i = 0; i < secretKeyContribution.length; i++) {
            data = abi.encodePacked(data, secretKeyContribution[i].publicKey, secretKeyContribution[i].share);
        }
        for (uint i = 0; i < verificationVector.length; i++) {
            data = abi.encodePacked(
                data,
                verificationVector[i].x.a,
                verificationVector[i].x.b,
                verificationVector[i].y.a,
                verificationVector[i].y.b
            );
        }
        return keccak256(data);
    }
}