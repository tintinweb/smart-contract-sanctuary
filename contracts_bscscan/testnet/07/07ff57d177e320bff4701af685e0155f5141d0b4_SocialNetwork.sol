/**
 *Submitted for verification at BscScan.com on 2021-09-13
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

contract SocialNetwork {
    string public name;

    uint public postCount = 0;
    mapping(uint => Post) public posts;

    struct Bug{
        string name;
        address belongTo;
    }

    mapping(address=>Bug) public bugs;

    address[] public UserBugs;

    struct Post {
        uint id;
        string content;
        uint tipAmount;
        address payable author;
        string title;
    }

    event PostCreated(
        uint id,
        string content,
        uint tipAmount,
        address payable author,
        string title
    );

    event PostTipped(
        uint id,
        string content,
        uint tipAmount,
        address payable author
    );

    constructor() {
        name = "Social Network";
    }

    function addBug(address owner, string calldata bugName) public {
        bugs[msg.sender].name = bugName;
        bugs[msg.sender].belongTo = owner;
        
        UserBugs.push(msg.sender);
    }

    function getBugs() external view returns (address[] memory){
        return UserBugs;
    }

    function createPost(string memory _content, string memory _title) public {
        // Require valid content
        require(bytes(_content).length > 0);
        require(bytes(_title).length > 0);
        // Increment the post count
        postCount ++;
        // Create the post
        posts[postCount] = Post(postCount, _content, 0, payable(msg.sender), _title);
        // Trigger event
        emit PostCreated(postCount, _content, 0, payable(msg.sender), _title);
    }

    function tipPost(uint _id) public payable {
        // Make sure the id is valid
        require(_id > 0 && _id <= postCount);
        // Fetch the post
        Post memory _post = posts[_id];
        // Fetch the author
        address payable _author = _post.author;
        // Pay the author by sending them Ether
        payable(address(_author)).transfer(msg.value);
        // Incremet the tip amount
        _post.tipAmount = _post.tipAmount + msg.value;
        // Update the post
        posts[_id] = _post;
        // Trigger an event
        emit PostTipped(postCount, _post.content, _post.tipAmount, _author);
    }
}