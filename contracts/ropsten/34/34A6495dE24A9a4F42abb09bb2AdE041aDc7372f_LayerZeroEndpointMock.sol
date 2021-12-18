// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* solium-disable */
import "../layer0/interfaces/ILayerZeroReceiver.sol";
import "../layer0/interfaces/ILayerZeroEndpoint.sol";

// mocked LayerZero endpoint to facilitate same chain testing of two UserApplications
contract LayerZeroEndpointMock is ILayerZeroEndpoint {
    mapping(uint16 => mapping(address => uint64)) public nonceMap;
    constructor(){}
    // send() is the primary function of this mock contract.
    //   its really the only reason you will use this contract in local testing.
    //
    // The user application on chain A (the source, or "from" chain) sends a message
    // to the communicator. It includes the following information:
    //      _chainId            - the destination chain identifier
    //      _destination        - the destination chain address (in bytes)
    //      _payload            - a the custom data to send
    //      _refundAddress      - address to send remainder funds to
    //      _zroPaymentAddress  - if 0x0, implies user app is paying in native token. otherwise
    //      txParameters        - optional data passed to the relayer via getPrices()
    function send(
        uint16 _chainId,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata txParameters
    ) override external payable {
        address destAddr = packedBytesToAddr(_destination);
        uint64 nonce;
        {
            nonce = nonceMap[_chainId][destAddr]++;
        }
        bytes memory bytesSourceUserApplicationAddr = addrToPackedBytes(address(msg.sender)); // cast this address to bytes
        ILayerZeroReceiver(destAddr).lzReceive(_chainId, bytesSourceUserApplicationAddr, nonce, _payload); // invoke lzReceive
    }
    // send() helper function
    function packedBytesToAddr(bytes calldata _b) public view returns (address){
        address addr;
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, sub(_b.offset, 2 ), add(_b.length, 2))
            addr := mload(sub(ptr,10))
        }
        return addr;
    }
    // send() helper function
    function addrToPackedBytes(address _a) public view returns (bytes memory){
        bytes memory data = abi.encodePacked(_a);
        return data;
    }
    // override from ILayerZeroEndpoint
    function estimateNativeFees(
        uint16 _chainId,
        address userApplication,
        bytes calldata _payload,
        bool payInZRO,
        bytes calldata txParameters
    ) override view external returns(uint totalFee) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILayerZeroReceiver {
    // the method which your contract needs to implement to receive messages
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILayerZeroEndpoint {
    // the send() method which sends a bytes payload to a another chain
    function send(uint16 _chainId, bytes calldata _destination, bytes calldata _payload, address payable refundAddress, address _zroPaymentAddress,  bytes calldata txParameters ) external payable;
    //
    function estimateNativeFees(uint16 chainId, address userApplication, bytes calldata payload, bool payInZRO, bytes calldata txParameters)  view external returns(uint totalFee);
}