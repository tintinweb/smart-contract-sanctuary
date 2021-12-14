/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

// SPDX-License-Identifier: MIT
// File: contracts/external/wormhole.sol


pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface Structs {
    struct Provider {
        uint16 chainId;
        uint16 governanceChainId;
        bytes32 governanceContract;
    }

    struct GuardianSet {
        address[] keys;
        uint32 expirationTime;
    }

    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
        uint8 guardianIndex;
    }

    struct VM {
        uint8 version;
        uint32 timestamp;
        uint32 nonce;
        uint16 emitterChainId;
        bytes32 emitterAddress;
        uint64 sequence;
        uint8 consistencyLevel;
        bytes payload;

        uint32 guardianSetIndex;
        Signature[] signatures;

        bytes32 hash;
    }
}


interface IWormhole {
    function publishMessage(uint32 nonce, bytes calldata payload, uint8 consistencyLevel) external returns (uint64 sequence);

    function parseAndVerifyVM(bytes calldata encodedVM) external view returns (Structs.VM memory vm, bool valid, string memory reason);
}
// File: contracts/test.sol

contract Test {
    address constant WORMHOLE_ADDRESS = 0x210c5F5e2AF958B4defFe715Dc621b7a3BA888c5;
    //uint256 exchangeRate;

    event BroadCastRate(uint sequence);
    event ReceiveRate(uint rate, uint timestamp);

    function serialize(uint a, uint b) internal pure returns (bytes memory data) {
        data = new bytes(64);
        
        assembly {
            mstore(add(data, 32), a)
            mstore(add(data, 64), b)
        }

        return data;
    }

    function deserialize(bytes memory data) internal pure returns(uint a, uint b) {
        assembly {
            a := mload(add(data, 32))
            b := mload(add(data, 64))
        }

        return (a, b);
    }

    function broadcastRate() public returns (uint64 sequence) {
        uint rate = 1e18;
        uint timestamp = block.timestamp;
        bytes memory data = serialize(rate, timestamp);

        IWormhole wormhole = IWormhole(WORMHOLE_ADDRESS);
        sequence = wormhole.publishMessage(0, data, 1);

        emit BroadCastRate(sequence);
    }

    function receiveRate(bytes calldata wormholeMessage) external {
        IWormhole wormhole = IWormhole(WORMHOLE_ADDRESS);
        (Structs.VM memory vm, bool valid, string memory reason) = wormhole.parseAndVerifyVM(wormholeMessage);
        require(valid, reason);

        (uint rate, uint timestamp) = deserialize(vm.payload);
        emit ReceiveRate(rate, timestamp);
    }
}