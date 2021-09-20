//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./StringUtils.sol";
import "./RandomNumberUtils.sol";

contract SocialNetwork {

    using RandomNumberUtils for uint;
    using StringUtils for bool; 

    string public name;
    uint public postCount = 0;
    uint public bugCount = 0;
    bool public won = false;
    mapping(uint => Post) public posts;

    struct Bug{
        string name;
        address belongTo;
        uint winRate;
        uint luckyNumber;
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
        Bug memory bugNew = Bug(bugName, msg.sender, 10, RandomNumberUtils.luckyNumber());
        bugs[msg.sender].name = bugName;
        bugs[msg.sender].belongTo = msg.sender;
        bugs[msg.sender].luckyNumber = RandomNumberUtils.luckyNumber();
        bugs[msg.sender].winRate = 10;
        UserBugs.push(bugNew);
        bugCount++;
    }

    function createFirstBug(string calldata bugName, address owner) public returns (bytes memory) {
        require(StringUtils.equal(bugs[owner].name, ""), "ilk bug mevcut");
        Bug memory bugNew = Bug(bugName, owner, 10, RandomNumberUtils.luckyNumber());
        bugs[owner].name = bugName;
        bugs[owner].belongTo = owner;
        bugs[owner].luckyNumber = RandomNumberUtils.luckyNumber();
        bugs[owner].winRate = 10;
        UserBugs.push(bugNew);
        bugCount++;
        return bytes(bugs[owner].name);
    }

    function getBugs(address owner) external view returns (string memory, address, uint, uint256){
        return (bugs[owner].name, bugs[owner].belongTo, bugs[owner].winRate, bugs[owner].luckyNumber);
    }

    function pickIfWon(uint _winRate) public returns (uint[10] memory, uint, bool){
        uint[10] memory _winRateNew;
        uint _luckyNumber = RandomNumberUtils.luckyNumber();
        bool _winResult = false;

        if ((_winRate+9)>100) {
            for (uint index = 0; index < 10; index++) {
                _winRateNew[index] = _winRate-index;
            }
        }else{
            for (uint index = 0; index < 10; index++) {
                _winRateNew[index] = _winRate+index;
            }
        }
        for (uint index = 0; index < _winRateNew.length; index++) {
            if (_winRateNew[index]==_luckyNumber)
            _winResult = true;
            won = true;
        }
        return (uint[10](_winRateNew), _luckyNumber, _winResult);
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