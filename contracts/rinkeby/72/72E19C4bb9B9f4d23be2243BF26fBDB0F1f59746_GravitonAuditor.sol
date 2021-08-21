/**
 *Submitted for verification at Etherscan.io on 2021-08-20
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGravitonAuditor {

    event SetOwner(address ownerOld, address ownerNew);

    event AddSwap(
        bytes32 hash,
        string source_chain,
        string destination_chain,
        uint256 amount,
        bytes16 uuid,
        address sender,
        address receiver,
        bytes32 source_transaction,
        bytes32 destination_transaction
    );
}

contract GravitonAuditor is IGravitonAuditor {

    address public owner;

    constructor (address _owner) {
        owner = _owner;
    }

    struct swap {
        bytes16 uuid;
        address sender;
        string source_chain;
        address receiver;
        string destination_chain;
        uint256 amount;
        bytes32 source_transaction;
        bytes32 destination_transaction;
    }

    mapping(bytes32 => swap) public proof;

    function setOwner(address _owner) external {
        require(msg.sender == owner, "ACW"); // Access control owner error
        address ownerOld = owner;
        owner = _owner;
        emit SetOwner(ownerOld, owner);
    }

    function deserializeUint(
        bytes memory b,
        uint256 startPos,
        uint256 len
    ) private pure returns (uint256) {
        uint256 v = 0;
        for (uint256 p = startPos; p < startPos + len; p++) {
            v = v * 256 + uint256(uint8(b[p]));
        }
        return v;
    }

    function deserializeAddress(bytes memory b, uint256 startPos)
        private
        pure
        returns (address)
    {
        return address(uint160(deserializeUint(b, startPos, 20)));
    }

    function bytesToBytes16(bytes memory b, uint256 offset)
        private
        pure
        returns (bytes16)
    {
        bytes16 out;
        for (uint256 i = 0; i < 16; i++) {
            out |= bytes16(b[offset + i]) >> (i * 8);
        }
        return out;
    }

    function bytesToBytes32(bytes memory b, uint256 offset)
        private
        pure
        returns (bytes32)
    {
        bytes32 out;
        for (uint256 i = 0; i < 32; i++) {
            out |= bytes32(b[offset + i]) >> (i * 8);
        }
        return out;
    }

    function addSwap(
        bytes memory _uuid,
        bytes memory _sender,
        string memory source_chain,
        bytes memory _receiver,
        string memory destination_chain,
        uint256 amount,
        bytes memory _source_transaction,
        bytes memory _destination_transaction
    ) external {
        require(msg.sender == owner, "ACW"); // Access control owner error

        bytes16 uuid = bytesToBytes16(_uuid, 0);
        address sender = deserializeAddress(_sender, 0);
        address receiver = deserializeAddress(_receiver, 0);
        bytes32 source_transaction = bytesToBytes32(_source_transaction, 0);
        bytes32 destination_transaction = bytesToBytes32(_destination_transaction, 0);

        swap memory _swap = swap({
            uuid: uuid,
            sender: sender,
            source_chain: source_chain,
            receiver: receiver,
            destination_chain: destination_chain,
            amount: amount,
            source_transaction: source_transaction,
            destination_transaction: destination_transaction
        });

        bytes32 hash = keccak256(
            abi.encodePacked(
                uuid,
                sender,
                source_chain,
                receiver,
                destination_chain,
                amount
            )
        );
        proof[hash] = _swap;

        emit AddSwap(
            hash,
            source_chain,
            destination_chain,
            amount,
            uuid,
            sender,
            receiver,
            source_transaction,
            destination_transaction
        );
    }

    function checkSwap(
        bytes16 uuid,
        address sender,
        string calldata source_chain,
        address receiver,
        string calldata destination_chain,
        uint256 amount
    ) external view returns (swap memory _swap) {
        bytes32 hash = keccak256(abi.encodePacked(
            uuid,
            sender,
            source_chain,
            receiver,
            destination_chain,
            amount
            ));
        _swap = proof[hash];
    }
}