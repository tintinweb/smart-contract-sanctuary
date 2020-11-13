// SPDX-License-Identifier: AGPL-3.0-only

/*
    KeyStorage.sol - SKALE Manager
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
import "./Decryption.sol";
import "./Permissions.sol";
import "./SchainsInternal.sol";
import "./ECDH.sol";
import "./Precompiled.sol";
import "./FieldOperations.sol";

contract KeyStorage is Permissions {
    using Fp2Operations for Fp2Operations.Fp2Point;
    using G2Operations for G2Operations.G2Point;

    struct BroadcastedData {
        KeyShare[] secretKeyContribution;
        G2Operations.G2Point[] verificationVector;
    }

    struct KeyShare {
        bytes32[2] publicKey;
        bytes32 share;
    }

    mapping(bytes32 => mapping(uint => BroadcastedData)) private _data;
    mapping(bytes32 => G2Operations.G2Point) private _publicKeysInProgress;
    mapping(bytes32 => G2Operations.G2Point) private _schainsPublicKeys;
    mapping(bytes32 => G2Operations.G2Point[]) private _schainsNodesPublicKeys;
    mapping(bytes32 => G2Operations.G2Point[]) private _previousSchainsPublicKeys;

    function addBroadcastedData(
        bytes32 groupIndex,
        uint indexInSchain,
        KeyShare[] memory secretKeyContribution,
        G2Operations.G2Point[] memory verificationVector
    )
        external
        allow("SkaleDKG")
    {
        for (uint i = 0; i < secretKeyContribution.length; ++i) {
            if (i < _data[groupIndex][indexInSchain].secretKeyContribution.length) {
                _data[groupIndex][indexInSchain].secretKeyContribution[i] = secretKeyContribution[i];
            } else {
                _data[groupIndex][indexInSchain].secretKeyContribution.push(secretKeyContribution[i]);
            }
        }
        while (_data[groupIndex][indexInSchain].secretKeyContribution.length > secretKeyContribution.length) {
            _data[groupIndex][indexInSchain].secretKeyContribution.pop();
        }

        for (uint i = 0; i < verificationVector.length; ++i) {
            if (i < _data[groupIndex][indexInSchain].verificationVector.length) {
                _data[groupIndex][indexInSchain].verificationVector[i] = verificationVector[i];
            } else {
                _data[groupIndex][indexInSchain].verificationVector.push(verificationVector[i]);
            }
        }
        while (_data[groupIndex][indexInSchain].verificationVector.length > verificationVector.length) {
            _data[groupIndex][indexInSchain].verificationVector.pop();
        }
    }

    function deleteKey(bytes32 groupIndex) external allow("SkaleDKG") {
        _previousSchainsPublicKeys[groupIndex].push(_schainsPublicKeys[groupIndex]);
        delete _schainsPublicKeys[groupIndex];
    }

    function initPublicKeyInProgress(bytes32 groupIndex) external allow("SkaleDKG") {
        _publicKeysInProgress[groupIndex] = G2Operations.getG2Zero();
        delete _schainsNodesPublicKeys[groupIndex];
    }

    function adding(bytes32 groupIndex, G2Operations.G2Point memory value) external allow("SkaleDKG") {
        require(value.isG2(), "Incorrect g2 point");
        _publicKeysInProgress[groupIndex] = value.addG2(_publicKeysInProgress[groupIndex]);
    }

    function finalizePublicKey(bytes32 groupIndex) external allow("SkaleDKG") {
        if (!_isSchainsPublicKeyZero(groupIndex)) {
            _previousSchainsPublicKeys[groupIndex].push(_schainsPublicKeys[groupIndex]);
        }
        _schainsPublicKeys[groupIndex] = _publicKeysInProgress[groupIndex];
        delete _publicKeysInProgress[groupIndex];
    }

    function computePublicValues(bytes32 groupIndex, G2Operations.G2Point[] calldata verificationVector)
        external
        allow("SkaleDKG")
    {
        if (_schainsNodesPublicKeys[groupIndex].length == 0) {

            for (uint i = 0; i < verificationVector.length; ++i) {
                require(verificationVector[i].isG2(), "Incorrect g2 point verVec 1");

                G2Operations.G2Point memory tmp = verificationVector[i];
                _schainsNodesPublicKeys[groupIndex].push(tmp);

                require(_schainsNodesPublicKeys[groupIndex][i].isG2(), "Incorrect g2 point schainNodesPubKey 1");
            }

            while (_schainsNodesPublicKeys[groupIndex].length > verificationVector.length) {
                _schainsNodesPublicKeys[groupIndex].pop();
            }
        } else {
            require(_schainsNodesPublicKeys[groupIndex].length == verificationVector.length, "Incorrect length");

            for (uint i = 0; i < _schainsNodesPublicKeys[groupIndex].length; ++i) {
                require(verificationVector[i].isG2(), "Incorrect g2 point verVec 2");
                require(_schainsNodesPublicKeys[groupIndex][i].isG2(), "Incorrect g2 point schainNodesPubKey 2");

                _schainsNodesPublicKeys[groupIndex][i] = verificationVector[i].addG2(
                    _schainsNodesPublicKeys[groupIndex][i]
                );

                require(_schainsNodesPublicKeys[groupIndex][i].isG2(), "Incorrect g2 point addition");
            }

        }
    }

    function verify(
        bytes32 groupIndex,
        uint nodeToComplaint,
        uint fromNodeToComplaint,
        uint secretNumber,
        G2Operations.G2Point memory multipliedShare
    )
        external
        view
        returns (bool)
    {
        SchainsInternal schainsInternal = SchainsInternal(contractManager.getContract("SchainsInternal"));
        uint index = schainsInternal.getNodeIndexInGroup(groupIndex, nodeToComplaint);
        uint secret = _decryptMessage(groupIndex, secretNumber, nodeToComplaint, fromNodeToComplaint);

        G2Operations.G2Point[] memory verificationVector = _data[groupIndex][index].verificationVector;
        G2Operations.G2Point memory value = G2Operations.getG2Zero();
        G2Operations.G2Point memory tmp = G2Operations.getG2Zero();

        if (multipliedShare.isG2()) {
            for (uint i = 0; i < verificationVector.length; i++) {
                tmp = verificationVector[i].mulG2(index.add(1) ** i);
                value = tmp.addG2(value);
            }
            return value.isEqual(multipliedShare) &&
                _checkCorrectMultipliedShare(multipliedShare, secret);
        }
        return false;
    }

    function getBroadcastedData(bytes32 groupIndex, uint nodeIndex)
        external
        view
        returns (KeyShare[] memory, G2Operations.G2Point[] memory)
    {
        uint indexInSchain = SchainsInternal(contractManager.getContract("SchainsInternal")).getNodeIndexInGroup(
            groupIndex,
            nodeIndex
        );
        if (
            _data[groupIndex][indexInSchain].secretKeyContribution.length == 0 &&
            _data[groupIndex][indexInSchain].verificationVector.length == 0
        ) {
            KeyShare[] memory keyShare = new KeyShare[](0);
            G2Operations.G2Point[] memory g2Point = new G2Operations.G2Point[](0);
            return (keyShare, g2Point);
        }
        return (
            _data[groupIndex][indexInSchain].secretKeyContribution,
            _data[groupIndex][indexInSchain].verificationVector
        );
    }

    function getSecretKeyShare(bytes32 groupIndex, uint nodeIndex, uint index)
        external
        view
        returns (bytes32)
    {
        uint indexInSchain = SchainsInternal(contractManager.getContract("SchainsInternal")).getNodeIndexInGroup(
            groupIndex,
            nodeIndex
        );
        return (_data[groupIndex][indexInSchain].secretKeyContribution[index].share);
    }

    function getVerificationVector(bytes32 groupIndex, uint nodeIndex)
        external
        view
        returns (G2Operations.G2Point[] memory)
    {
        uint indexInSchain = SchainsInternal(contractManager.getContract("SchainsInternal")).getNodeIndexInGroup(
            groupIndex,
            nodeIndex
        );
        return (_data[groupIndex][indexInSchain].verificationVector);
    }

    function getCommonPublicKey(bytes32 groupIndex) external view returns (G2Operations.G2Point memory) {
        return _schainsPublicKeys[groupIndex];
    }

    function getPreviousPublicKey(bytes32 groupIndex) external view returns (G2Operations.G2Point memory) {
        uint length = _previousSchainsPublicKeys[groupIndex].length;
        if (length == 0) {
            return G2Operations.getG2Zero();
        }
        return _previousSchainsPublicKeys[groupIndex][length - 1];
    }

    function getAllPreviousPublicKeys(bytes32 groupIndex) external view returns (G2Operations.G2Point[] memory) {
        return _previousSchainsPublicKeys[groupIndex];
    }

    function getBLSPublicKey(bytes32 groupIndex, uint nodeIndex) external view returns (G2Operations.G2Point memory) {
        uint index = SchainsInternal(contractManager.getContract("SchainsInternal")).getNodeIndexInGroup(
            groupIndex,
            nodeIndex
        );
        return _calculateBlsPublicKey(groupIndex, index);
    }

    function initialize(address contractsAddress) public override initializer {
        Permissions.initialize(contractsAddress);
    }

    function _calculateBlsPublicKey(bytes32 groupIndex, uint index)
        private
        view
        returns (G2Operations.G2Point memory)
    {
        G2Operations.G2Point memory publicKey = G2Operations.getG2Zero();
        G2Operations.G2Point memory tmp = G2Operations.getG2Zero();
        G2Operations.G2Point[] memory publicValues = _schainsNodesPublicKeys[groupIndex];
        for (uint i = 0; i < publicValues.length; ++i) {
            require(publicValues[i].isG2(), "Incorrect g2 point publicValuesComponent");
            tmp = publicValues[i].mulG2(Precompiled.bigModExp(index.add(1), i, Fp2Operations.P));
            require(tmp.isG2(), "Incorrect g2 point tmp");
            publicKey = tmp.addG2(publicKey);
            require(publicKey.isG2(), "Incorrect g2 point publicKey");
        }
        return publicKey;
    }

    function _isSchainsPublicKeyZero(bytes32 schainId) private view returns (bool) {
        return _schainsPublicKeys[schainId].x.a == 0 &&
            _schainsPublicKeys[schainId].x.b == 0 &&
            _schainsPublicKeys[schainId].y.a == 0 &&
            _schainsPublicKeys[schainId].y.b == 0;
    }

    function _getCommonPublicKey(
        uint256 secretNumber,
        uint fromNodeToComplaint
    )
        private
        view
        returns (bytes32)
    {
        bytes32[2] memory publicKey = Nodes(contractManager.getContract("Nodes")).getNodePublicKey(fromNodeToComplaint);
        uint256 pkX = uint(publicKey[0]);

        (pkX, ) = ECDH(contractManager.getContract("ECDH")).deriveKey(secretNumber, pkX, uint(publicKey[1]));

        return bytes32(pkX);
    }

    function _decryptMessage(
        bytes32 groupIndex,
        uint secretNumber,
        uint nodeToComplaint,
        uint fromNodeToComplaint
    )
        private
        view
        returns (uint)
    {

        bytes32 key = _getCommonPublicKey(secretNumber, fromNodeToComplaint);

        // Decrypt secret key contribution
        SchainsInternal schainsInternal = SchainsInternal(contractManager.getContract("SchainsInternal"));
        uint index = schainsInternal.getNodeIndexInGroup(groupIndex, fromNodeToComplaint);
        uint indexOfNode = schainsInternal.getNodeIndexInGroup(groupIndex, nodeToComplaint);
        uint secret = Decryption(contractManager.getContract("Decryption")).decrypt(
            _data[groupIndex][indexOfNode].secretKeyContribution[index].share,
            key
        );
        return secret;
    }

    function _checkCorrectMultipliedShare(G2Operations.G2Point memory multipliedShare, uint secret)
        private view returns (bool)
    {
        G2Operations.G2Point memory tmp = multipliedShare;
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

        return Precompiled.bn256Pairing(
            share.a, share.b,
            g2.x.b, g2.x.a, g2.y.b, g2.y.a,
            g1.a, g1.b,
            tmp.x.b, tmp.x.a, tmp.y.b, tmp.y.a);
    }

}