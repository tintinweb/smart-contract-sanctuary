/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Messaging {
    uint256 public threadCount = 0;
    mapping(address => string) private pubEncKeys; // mapping of address to public encryption key https://docs.metamask.io/guide/rpc-api.html#eth-getencryptionpublickey

    event MessageSent (
        address receiver,
        string uri,
        uint256 timestamp,
        address sender,
        uint256 thread_id
    );

    event ThreadCreated (
        address receiver,
        address sender,
        uint256 thread_id,
        uint256 timestamp,
        string _sender_key,
        string _receiver_key,
        bool _encrypted
    );

    function getPubEncKeys(address receiver) public view returns(string memory sender_key, string memory receiver_key) {

        require(bytes(pubEncKeys[msg.sender]).length != 0, "Sender isn't registered on Dakiya");

        if (bytes(pubEncKeys[msg.sender]).length != 0) {
            sender_key = pubEncKeys[msg.sender];
        }
        if (bytes(pubEncKeys[receiver]).length != 0) {
            receiver_key = pubEncKeys[receiver];
        }
        return (sender_key, receiver_key);
    }

    function checkUserRegistration() public view returns(bool) {
        return bytes(pubEncKeys[msg.sender]).length != 0;
    }

    function setPubEncKey(string memory encKey) public {
        pubEncKeys[msg.sender] = encKey;
    }

    function sendMessage(
        uint256 _thread_id,
        string memory _uri,
        address _receiver,
        string memory _sender_key,
        string memory _receiver_key,
        bool encrypted
    ) public {
        if (_thread_id == 0) {
            emit ThreadCreated(
                _receiver,
                msg.sender,
                threadCount,
                block.timestamp,
                _sender_key,
                _receiver_key,
                encrypted
            );

            emit MessageSent(_receiver, _uri, block.timestamp, msg.sender, threadCount);

            threadCount++;

        } else {
            emit MessageSent(_receiver, _uri, block.timestamp, msg.sender, _thread_id);
        }
    }
}