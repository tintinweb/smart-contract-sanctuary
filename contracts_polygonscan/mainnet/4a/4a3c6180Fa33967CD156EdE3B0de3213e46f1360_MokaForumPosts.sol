/**
 *Submitted for verification at polygonscan.com on 2021-10-17
*/

// File: contracts/MokaForumPosts.sol


pragma solidity ^0.8.7;

contract MokaForumPosts {
  uint64 public id;
  string public parentUid;
  address public mokaForumAddr;

  struct Post {
    uint64 id;
    uint32 upvotes;
    string monthBlock;
    string weekBlock;
    string dayBlock;
    uint timestamp;
    address user;
    string title;
    string desc;
    string url;
    string[] tags;
  }

  mapping(uint64 => Post) public posts;
  mapping(address => mapping(uint64 => bool)) public upvotes;

  event postCreated(uint64 id, Post post);
  event postUpvoted(uint64 postId, address voter);

  constructor(address _mokaForumAddr, string  memory _parentUid) {
    id = 0;
    parentUid = _parentUid;
    mokaForumAddr = _mokaForumAddr;
  }

  function createPost(
    string memory _monthBlock,
    string memory _weekBlock,
    string memory _dayBlock,
    address _creator,
    string memory _title,
    string memory _desc,
    string memory _url,
    string[] memory _tags
  ) public returns (bool) {
    require(msg.sender == mokaForumAddr, "Incorrect Forum Address");
    id += 1;
    Post memory post = Post(id, 0, _monthBlock, _weekBlock, _dayBlock, block.timestamp, _creator, _title, _desc, _url, _tags);
    posts[id] = post;
    emit postCreated(id, post);
    return true;
  }

  function upvotePost(uint64 _id, address _voter) public returns(bool, address) {
    require(msg.sender == mokaForumAddr, "Incorrect Forum Address");
    Post storage post = posts[_id];
    require(_voter != post.user, "Cannot Upvote Own Post");
    require(upvotes[_voter][_id] == false, "User Already Upvoted");
    upvotes[_voter][_id] = true;
    post.upvotes += 1;
    emit postUpvoted(_id, _voter);
    return (true, post.user);
  }

  function getPostCreator(uint64 _id) public view returns(address) {
    Post storage post = posts[_id];
    return post.user;
  }
}