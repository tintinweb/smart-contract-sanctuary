/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.8;

contract MessageLogger {

    mapping(uint256 => bytes32) public DOMAIN_SEPARATORS;
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Broadcast(bytes32 topic, string message)");

    constructor() {
        DOMAIN_SEPARATORS[1] = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("MessageLogger")),
                keccak256(bytes("1")),
                uint256(1),
                address(this)
            )
        );

        DOMAIN_SEPARATORS[4] = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("MessageLogger")),
                keccak256(bytes("1")),
                uint256(3),
                address(this)
            )
        );
        
        DOMAIN_SEPARATORS[4] = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("MessageLogger")),
                keccak256(bytes("1")),
                uint256(4),
                address(this)
            )
        );

        DOMAIN_SEPARATORS[4] = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("MessageLogger")),
                keccak256(bytes("1")),
                uint256(5),
                address(this)
            )
        );

        DOMAIN_SEPARATORS[100] = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("MessageLogger")),
                keccak256(bytes("1")),
                uint256(100),
                address(this)
            )
        );

        DOMAIN_SEPARATORS[42161] = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("MessageLogger")),
                keccak256(bytes("1")),
                uint256(42161),
                address(this)
            )
        );

        DOMAIN_SEPARATORS[421611] = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("MessageLogger")),
                keccak256(bytes("1")),
                uint256(421611),
                address(this)
            )
        );
        
    }

    event Message(bytes32 indexed topic, string message, address sender);

    function broadcast(bytes32 topic, string memory message) public {
        emit Message(topic, message, msg.sender);
    }

    function broadcastEIP712(
        bytes32 topic, string memory message, uint256 chainId, uint8 v, bytes32 r, bytes32 s
    ) external {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATORS[chainId],
                keccak256(abi.encode(PERMIT_TYPEHASH, topic, message))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress == msg.sender, "MessageLogger: Invalid signer");
        emit Message(topic, message, msg.sender);
    }

    function broadcastPublic(bytes32 topic, string memory message, address sender) public {
        emit Message(topic, message, sender);
    }
}