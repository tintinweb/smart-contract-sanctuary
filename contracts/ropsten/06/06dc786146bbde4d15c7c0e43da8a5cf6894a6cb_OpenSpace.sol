pragma solidity ^0.4.24;

contract OpenSpace {

  struct Topic {
    uint id;
    string name;
    uint voteCount;
  }

  mapping (address => bool) public voters;
  mapping (uint => Topic) public topics;
  address public owner;
  uint public topicCount;

  modifier restricted() {
    if (msg.sender == owner) _;
  }

  modifier justOneVote() {
    require (voters[msg.sender] != true, "You can just vote once!!");
    _;
  }

  event votedEvent (
    uint indexed _topicId
  );

  constructor() public {
    owner = msg.sender;

    addTopic("Angular");
    addTopic("ReactJS");
    addTopic("Vue");
  }

  function voteTopic(uint topicId) public justOneVote  {
    voters[msg.sender] = true;
    topics[topicId].voteCount ++;
    emit votedEvent(topicId);
  }

  function addTopic(string memory name) private {
    topicCount++;
    topics[topicCount] = Topic(topicCount, name, 0);
  }
}