/**
 *Submitted for verification at polygonscan.com on 2021-10-18
*/

// File: contracts/MokaPosts.sol


pragma solidity ^0.8.7;

contract MokaPosts {
  address public mokaERC20Contract;
  uint256 public uid;

  struct Post {
    uint256 uid;
    uint32 upvotes;
    bytes32 monthId;
    bytes32 weekId;
    bytes32 dayId;
    uint timestamp;
    address user;
    string post;
    string[] tags;
  }

  mapping(uint256 => Post) public posts;
  mapping(address => mapping(uint256 => bool)) public postUpvotes;

  event postCreated(uint256 uid, Post post);
  event postUpvoted(uint256 uid, address voter);

  constructor(address _mokaERC20Contract) {
    mokaERC20Contract = _mokaERC20Contract;
    uid = 0;
  }

  function createPost(address _creator, bytes32 _monthId, bytes32 _weekId, bytes32 _dayId, string memory _post, string[] memory _tags) public returns (bool, uint256) {
    require(msg.sender == mokaERC20Contract, "ERC20 Contract Only");
    uid += 1;
    Post memory post = Post(uid, 0, _monthId, _weekId, _dayId, block.timestamp, _creator, _post, _tags);
    posts[uid] = post;
    emit postCreated(uid, post);
    return (true, uid);
  }

  function upvotePost(address _voter, address _creator, uint256 _uid) public returns (bool) {
    require(msg.sender == mokaERC20Contract, "ERC20 Contract Only");
    Post storage post = posts[_uid];
    require(_creator == post.user, "Post Doesn't Match Creator");
    require(_voter != post.user, "Cannot Upvote Own Post");
    require(postUpvotes[_voter][_uid] == false, "User Already Upvoted");
    postUpvotes[_voter][_uid] = true;
    post.upvotes += 1;
    emit postUpvoted(_uid, _voter);
    return true;
  }
}