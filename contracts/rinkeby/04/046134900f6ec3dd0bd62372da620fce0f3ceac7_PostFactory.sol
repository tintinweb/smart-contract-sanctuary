/**
 *Submitted for verification at Etherscan.io on 2021-08-03
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
contract CloneFactory {

  function createClone(address target) public returns (address result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      result := create(0, clone, 0x37)
    }
  }

  function isClone(address target, address query) public view returns (bool result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
      mstore(add(clone, 0xa), targetBytes)
      mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

      let other := add(clone, 0x40)
      extcodecopy(query, other, 0, 0x2d)
      result := and(
        eq(mload(clone), mload(other)),
        eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
      )
    }
  }
}
contract PostFactory is CloneFactory {
     Post[] public posts;
     uint postCount;
     address masterContract;

     constructor(address _masterContract){
         masterContract = _masterContract;
     }

     function createChild(string memory data) external{
        Post post = Post(createClone(masterContract));
        post.init(data, msg.sender);
        posts.push(post);
        postCount++;
     }

     function getPosts() external view returns(Post[] memory){
         return posts;
     }
}

contract Post{
    string public data;
    address public poster;
    uint public likeCount;
    address[] public users;
    uint public commentCount;
    // use this function instead of the constructor
    // since creation will be done using createClone() function
    function init(string memory _data, address _sender) external {
        data = _data;
        poster = _sender;
    }
    struct Liker {
        bool liked; //turns true if already liked
        address[] user; //the address of the liker
    }
     event postLiked(
         bool liked,
         address user
         );
    struct Comment {
        uint id;
        string hash;
        address poster;
    }
    event commentCreated(
        uint id,
        string hash,
        address poster
        );
    mapping(address => Liker) public likers; //store likers
    function likePost() public {
        Liker storage sender = likers[msg.sender];
        require(!sender.liked, "Aleady liked.");
        users.push(msg.sender);
        likeCount +=1;
        sender.liked = true;
        emit postLiked(true, msg.sender);
    }
    mapping(uint => Comment) public comments;
    function createComment(string memory _hash) public {
        //has hash
        require(bytes(_hash).length > 0);
        //increment post id
        commentCount += 1;
        //add post
        comments[commentCount] = Comment(commentCount, _hash, msg.sender);
        //emits
        emit commentCreated(commentCount, _hash, msg.sender);
        users.push(msg.sender);
    }
    
}