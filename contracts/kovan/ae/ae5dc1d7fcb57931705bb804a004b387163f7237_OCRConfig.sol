/**
 *Submitted for verification at Etherscan.io on 2021-11-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OCRConfig {
    struct SharedSecretEncryptions {
        bytes32 diffieHellmanPoint;
        bytes32 sharedSecretHash;
        bytes16[] encryptions;
    }
    struct SetConfigEncodedComponents {
        uint64 deltaProgress;
        uint64 deltaResend;
        uint64 deltaRound;
        uint64 deltaGrace;
        uint64 deltaC;
        uint64 alphaPPB;
        uint64 deltaStage;
        uint8 rMax;
        uint8[] s;
        bytes32[] offchainPublicKeys;
        string peerIDs;
        SharedSecretEncryptions sharedSecretEncryptions;
    }

    function _makeConfigEncodedComponents( 
        uint64[7] memory config,
        uint8 rMax,
        uint8[] memory s,
        bytes32[] memory offchainPublicKeys,
        string memory peerIDs,
        bytes32 diffieHellmanPoint,
        bytes32 sharedSecretHash,
        bytes16[] memory encryptions
        ) private pure returns(SetConfigEncodedComponents memory encodedComponenents) {            
        SharedSecretEncryptions memory sse = SharedSecretEncryptions(diffieHellmanPoint,sharedSecretHash,encryptions);
        encodedComponenents = SetConfigEncodedComponents({
            deltaProgress : uint64(config[0]),
            deltaResend : uint64(config[1]),
            deltaRound : uint64(config[2]),
            deltaGrace : uint64(config[3]),
            deltaC : uint64(config[4]),
            alphaPPB : uint64(config[5]),
            deltaStage : uint64(config[6]),
            rMax : rMax,
            s : s,
            offchainPublicKeys: offchainPublicKeys,
            peerIDs: peerIDs,
            sharedSecretEncryptions: sse
        });
    }
    function packDeltaComponent(
        uint64 deltaProgressNS,
        uint64 deltaResendNS,
        uint64 deltaRoundNS,
        uint64 deltaGraceNS,
        uint64 deltaC,
        uint64 alphaPPB,
        uint64 deltaStage
    ) public pure returns(uint64[7] memory packed) {
        require(deltaGraceNS < deltaRoundNS, "deltaGrace < deltaRound");
        require(deltaRoundNS < deltaProgressNS, "deltaRound < deltaProgress");
        packed[0] = deltaProgressNS;
        packed[1] = deltaResendNS;
        packed[2] = deltaRoundNS;
        packed[3] = deltaGraceNS;
        packed[4] = deltaC;
        packed[5] = alphaPPB;
        packed[6] = deltaStage;
    }

    function getDeltaParams(
        uint8 networkType,
        uint64 alphaPPB
    ) public pure returns(uint64[7] memory packed) {
        uint64 secondInNS = 1000000000;
        // these are the limits hardcoded inside libocr by chainId, value must be <= given with further restriction for grace/round/progress(see pack above)
        if (networkType == 1) {
            // moderate most POA
            return packDeltaComponent(23 * secondInNS, 10 * secondInNS, 20 * secondInNS, 15 * secondInNS, 1 * 60 * secondInNS, alphaPPB, 5 * secondInNS);
        }
        else if (networkType == 2) {
            // fast say BSC
            return packDeltaComponent(8 * secondInNS, 5 * secondInNS, 5 * secondInNS, 3 * secondInNS, 10 * secondInNS, alphaPPB, 5 * secondInNS);
        }
        else if (networkType == 3) {
            // public testnet(most, this is very fast)
            return packDeltaComponent(2 * secondInNS, 2 * secondInNS, 1 * secondInNS, 0, 1 * secondInNS, alphaPPB, 5 * secondInNS);
        }
        else {
           // slow, mainnet and private unknown
            return packDeltaComponent(23 * secondInNS, 10 * secondInNS, 20 * secondInNS, 15 * secondInNS, 10 * 60 * secondInNS, alphaPPB, 20 * secondInNS);
        }
    }

    function makeSlowSetConfigEncodedComponents(
        uint64 alphaPPB,
        uint8 rMax,
        uint8[] calldata s,
        bytes32[] calldata offchainPublicKeys,
        string calldata peerIDs,
        bytes32 diffieHellmanPoint,
        bytes32 sharedSecretHash,
        bytes16[] calldata encryptions
        ) public pure returns(bytes memory encodedComponenents) {  
        return makeSetConfigEncodedComponents(getDeltaParams(0, alphaPPB), rMax, s, offchainPublicKeys, peerIDs, diffieHellmanPoint, sharedSecretHash, encryptions);  
    }
    function makeModerateSetConfigEncodedComponents(
        uint64 alphaPPB,
        uint8 rMax,
        uint8[] calldata s,
        bytes32[] calldata offchainPublicKeys,
        string calldata peerIDs,
        bytes32 diffieHellmanPoint,
        bytes32 sharedSecretHash,
        bytes16[] calldata encryptions
        ) public pure returns(bytes memory encodedComponenents) {  
        return makeSetConfigEncodedComponents(getDeltaParams(1, alphaPPB), rMax, s, offchainPublicKeys, peerIDs, diffieHellmanPoint, sharedSecretHash, encryptions);  
    }
    function makeFastSetConfigEncodedComponents(
        uint64 alphaPPB,
        uint8 rMax,
        uint8[] calldata s,
        bytes32[] calldata offchainPublicKeys,
        string calldata peerIDs,
        bytes32 diffieHellmanPoint,
        bytes32 sharedSecretHash,
        bytes16[] calldata encryptions
        ) public pure returns(bytes memory encodedComponenents) {  
        return makeSetConfigEncodedComponents(getDeltaParams(2, alphaPPB), rMax, s, offchainPublicKeys, peerIDs, diffieHellmanPoint, sharedSecretHash, encryptions);  
    }
    function makeTestnetSetConfigEncodedComponents(
        uint64 alphaPPB,
        uint8 rMax,
        uint8[] calldata s,
        bytes32[] calldata offchainPublicKeys,
        string calldata peerIDs,
        bytes32 diffieHellmanPoint,
        bytes32 sharedSecretHash,
        bytes16[] calldata encryptions
        ) public pure returns(bytes memory encodedComponenents) {  
        return makeSetConfigEncodedComponents(getDeltaParams(3, alphaPPB), rMax, s, offchainPublicKeys, peerIDs, diffieHellmanPoint, sharedSecretHash, encryptions);  
    }

    function makeSetConfigEncodedComponents( 
        // uint64 deltaProgress,
        // uint64 deltaResend,
        // uint64 deltaRound,
        // uint64 deltaGrace,
        // uint64 deltaC,
        // uint64 alphaPPB,
        // uint64 deltaStage,
        uint64[7] memory config,
        uint8 rMax,
        uint8[] memory s,
        bytes32[] memory offchainPublicKeys,
        string memory peerIDs,
        bytes32 diffieHellmanPoint,
        bytes32 sharedSecretHash,
        bytes16[] memory encryptions
        ) public pure returns(bytes memory encodedComponenents) {   
        encodedComponenents = abi.encode(
            SetConfigEncodedComponents({
            deltaProgress : uint64(config[0]),
            deltaResend : uint64(config[1]),
            deltaRound : uint64(config[2]),
            deltaGrace : uint64(config[3]),
            deltaC : uint64(config[4]),
            alphaPPB : uint64(config[5]),
            deltaStage : uint64(config[6]),
            rMax : rMax,
            s : s,
            offchainPublicKeys: offchainPublicKeys,
            peerIDs: peerIDs,
            sharedSecretEncryptions: SharedSecretEncryptions(diffieHellmanPoint,sharedSecretHash,encryptions)
        }));
    }

    function setConfigEncodedComponents(
        SetConfigEncodedComponents calldata components
    ) public pure returns(bytes memory) {
        return abi.encode(components);
    }
}