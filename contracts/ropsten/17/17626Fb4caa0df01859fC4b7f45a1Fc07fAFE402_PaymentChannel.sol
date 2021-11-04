/**
 *Submitted for verification at Etherscan.io on 2021-11-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract PaymentChannel {
    address payable public provider;
    // Resource price per second in wei
    uint256 public resourcePrice;
    struct session {
        uint256 start;
        uint256 end;
    }

    // Sessions per channel. Channel identifier => map(real address => consumer session)
    mapping(address => mapping(address => session)) public sessions;
    // Relation between ephemeral address and real address from consumer. Real address => ephemeral address
    mapping(address => address) public ephemeralMapping;
    // Wei amount deposited by consumers per channel. Real address => map(channel identifier => amount)
    mapping(address => mapping(address => uint256)) public totalAmount;

    event ChannelOpened(
        address indexed consumer,
        address indexed channelId,
        uint256 indexed expiration,
        address ephemeralConsumerAddress
    );
    event ChannelClosed(address indexed consumer, address indexed channelId);

    constructor(uint256 _resourcePrice) payable {
        provider = payable(msg.sender);
        resourcePrice = _resourcePrice;
    }

    // Used by the consumer to pay for resources for a given duration. The payment is provided as value parameter.
    function openChannel(
        address channelId,
        uint256 forDuration,
        address ephemeralConsumerAddress
    ) external payable {
        require(
            msg.value >= resourcePrice * forDuration,
            "The consumer has to pay at least for resource price"
        );
        require(
            sessions[channelId][msg.sender].start == 0,
            "The consumer requires not to have an active session for given channel"
        );
        // Sets session start time
        sessions[channelId][msg.sender].start = block.timestamp;
        // Sets session end time
        sessions[channelId][msg.sender].end = block.timestamp + forDuration;
        // Saves relation between ephemeral and real addresses
        ephemeralMapping[channelId] = ephemeralConsumerAddress;
        // Saves amount deposited by the consumer per channel
        totalAmount[msg.sender][channelId] = msg.value;
        // Emits event to notify BE
        emit ChannelOpened(
            msg.sender,
            channelId,
            block.timestamp + forDuration,
            ephemeralConsumerAddress
        );
    }

    // Used by the BE to close a channel using a signature sent by the consumer.
    function closeChannel(
        address channelId,
        uint256 amountToProvider,
        address consumerAddress,
        bytes memory signature
    ) external {
        // Splits signature.
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(signature);
        // Recreates the hashed message built in the FE
        bytes32 hashedMessage =
            prefixed(
                keccak256(abi.encodePacked(this, amountToProvider, channelId))
            );
        // Recovers the ephemeral address that created the signature.
        address ephemeralConsumerAddress = ecrecover(hashedMessage, v, r, s);
        require(
            ephemeralConsumerAddress == ephemeralMapping[channelId],
            "The ephemeral wallet that signed the payment transaction has to match the one that opened the channel"
        );
        require(
            sessions[channelId][consumerAddress].start > 0,
            "Only opened channels can be closed"
        );
        // Cancels consumer session.
        sessions[channelId][consumerAddress].start = 0;
        sessions[channelId][consumerAddress].end = 0;
        // Transfers the amount specified in the message to the resource provider.
        provider.transfer(amountToProvider);
        // Transfers the remaining amount deposited by the consumer in the contract to the consumer.
        payable(consumerAddress).transfer(
            totalAmount[consumerAddress][channelId] - amountToProvider
        );
        // Resets amount deposited by the consumer for the channel closed.
        totalAmount[consumerAddress][channelId] = 0;
        // Emits event to notify BE
        emit ChannelClosed(ephemeralConsumerAddress, channelId);
    }

    function splitSignature(bytes memory signature)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        require(signature.length == 65);
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        return (v, r, s);
    }

    // Builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    // Used for testing purposes.
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}