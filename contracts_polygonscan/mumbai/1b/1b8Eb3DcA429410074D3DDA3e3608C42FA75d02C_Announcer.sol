// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

/// @title Public on-chain announcements for teams
/// @author Jorge A. Cortés - cortesja.com

contract Announcer {

    struct Topic {
        string name;
        address creator;
        address admin;
        mapping (address => bool) writers;
        string lastMessage;
    }
    uint256 public numTopics;
    mapping (uint256 => Topic) public topics;

    event MessageSent(uint256 indexed topic, address indexed from, string message);
    event NewTopic(uint256 indexed topic, address indexed creator, string name);
    event NewAdmin(uint256 indexed topic, address indexed admin);
    event NewWriter(uint256 indexed topic, address indexed writer);
    event RemovedWriter(uint256 indexed topic, address indexed writer);

    constructor() {} // solhint-disable-line no-empty-blocks

    /// Checks that the caller is a registered admin
    modifier onlyAdmin(uint256 topic) {
        require(
            msg.sender == topics[topic].admin,
            "Only topic admin allowed"
        );
        _;
    }

    /// Checks that the caller is a registered writer or admin
    modifier onlyTeam(uint256 topic) {
        require(
            msg.sender == topics[topic].admin || 
            true == topics[topic].writers[msg.sender],
            "Only topic admin or writers"
        );
        _;
    }

    modifier notEmpty(string calldata message) {
        require(bytes(message).length > 0, "Message cannot be empty");
        _;
    }

    /// Creates a new topic and the creator becomes topic admin
    function registerTopic(string memory name) external returns (uint256) {
        uint256 newTopic = numTopics;
        topics[numTopics].creator = msg.sender;
        topics[numTopics].admin = msg.sender;
        topics[numTopics].name = name;
        numTopics++;
        emit NewTopic(newTopic, msg.sender, name);
        return newTopic;
    }

    /// Transfer administration rights from one address to another
    function adminTransfer(uint256 topic, address newAdmin) external onlyAdmin(topic) {
        topics[topic].admin = newAdmin;
        emit NewAdmin(topic, newAdmin);
    }

    /// Leaves a topic without admin forever
    function adminResign(uint256 topic) external onlyAdmin(topic) {
        topics[topic].admin = address(0);
        emit NewAdmin(topic, address(0));
    }

    /// Adds a writer to the topic
    function addTopicWriter(uint256 topic, address writer) external onlyAdmin(topic) {
        topics[topic].writers[writer] = true;
        emit NewWriter(topic, writer);
    }

    /// Removes a writer to the topic
    function removeTopicWriter(uint256 topic, address writer) external onlyAdmin(topic) {
        topics[topic].writers[writer] = false;
        emit RemovedWriter(topic, writer);
    }

    /// Sends a new message to the topic and stores it.
    function sendNewMessage(uint256 topic, string calldata message) external onlyTeam(topic) notEmpty(message) {
        /// Store last message for easy quering
        topics[topic].lastMessage = message;
        emit MessageSent(topic, msg.sender, message);
    }

    /// Checks if an address is writer of a topic
    function isTopicWriter(uint256 topic, address writer) public view returns (bool) {
        return topics[topic].writers[writer];
    }

}