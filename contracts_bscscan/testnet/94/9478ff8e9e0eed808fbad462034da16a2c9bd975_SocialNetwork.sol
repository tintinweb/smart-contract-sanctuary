/**
 *Submitted for verification at BscScan.com on 2021-09-19
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

contract SocialNetwork {
    string public name;
    uint public postCount = 0;
    uint public bugCount = 0;
    mapping(uint => Post) public posts;

    struct Bug{
        string name;
        address belongTo;
    }

    mapping(address=>Bug) public bugs;

    Bug[] private UserBugs;

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

    function addBug(string calldata bugName) public {
        Bug memory bugNew = Bug(bugName, msg.sender);
        bugs[msg.sender].name = bugName;
        bugs[msg.sender].belongTo = msg.sender;
        UserBugs.push(bugNew);
        bugCount++;
    }

    function compare(string memory _a, string memory _b) pure private returns (int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        //@todo unroll the loop into increments of 32 and do full 32 byte comparisons
        for (uint i = 0; i < minLength; i ++)
            if (a[i] < b[i])
                return -1;
            else if (a[i] > b[i])
                return 1;
        if (a.length < b.length)
            return -1;
        else if (a.length > b.length)
            return 1;
        else
            return 0;
    }

    function equal(string memory _a, string memory _b) pure private returns (bool) {
        return compare(_a, _b) == 0;
    }
    function createFirstBug(string calldata bugName, address owner) public returns (bytes memory) {
        require(equal(bugs[owner].name, ""), "ilk bug mevcut");
        Bug memory bugNew = Bug(bugName, owner);
        bugs[owner].name = bugName;
        bugs[owner].belongTo = owner;
        UserBugs.push(bugNew);
        bugCount++;
        return bytes(bugs[owner].name);
    }

    function getBugs(address owner) external view returns (string memory, address){
        return (bugs[owner].name, bugs[owner].belongTo);
    }

    function getBug() public view returns (Bug[] memory){
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