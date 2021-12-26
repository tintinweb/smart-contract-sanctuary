/**
 *Submitted for verification at Etherscan.io on 2021-12-26
*/

pragma solidity >=0.8.11;

contract Distagram {
  struct Post {
    uint256 id;
    string url;
    address owner;
    uint256 totalTips;
    mapping(address => uint256) userToTip;
  }
  Post[] posts;
  event TippedPost(address _from, uint256 _postId, uint256 _value);

  modifier validPostId(uint256 _id) {
    require(_id < posts.length, 'Invalid post id');
    _;
  }

  function uploadPost(string memory _url) public returns (uint256) {
    Post storage post = posts.push();
    post.id = posts.length - 1;
    post.url = _url;
    post.owner = msg.sender;
    post.totalTips = 0;
    return post.id;
  }

  function getPost(uint256 _id)
    public
    view
    validPostId(_id)
    returns (
      string memory,
      address,
      uint256
    )
  {
    return (posts[_id].url, posts[_id].owner, posts[_id].totalTips);
  }

  function getPostsCount() public view returns (uint256) {
    return posts.length;
  }

  function tiptoPost(uint256 _id) public payable validPostId(_id) {
    require(msg.value > 0.1 ether, 'The tip should be minimum of 0.1ETH');
    Post storage post = posts[_id];
    post.totalTips += msg.value;
    post.userToTip[msg.sender] += msg.value;
    // emit TippedPost(msg.sender, _id, msg.value);
  }

  function getTipsToPost(uint256 _id)
    public
    view
    validPostId(_id)
    returns (uint256)
  {
    return posts[_id].totalTips;
  }
}